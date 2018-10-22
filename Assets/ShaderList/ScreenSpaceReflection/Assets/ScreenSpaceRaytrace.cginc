#ifndef _YRC_SCREEN_SPACE_RAYTRACE_
#define _YRC_SCREEN_SPACE_RAYTRACE_

#define RAY_LENGTH 40.0	//maximum ray length.
#define STEP_COUNT 16	//maximum sample count.
#define PIXEL_STRIDE 16 //sample multiplier. it's recommend 16 or 8.
#define PIXEL_THICKNESS (0.03 * PIXEL_STRIDE)	//how thick is a pixel. correct value reduces noise.


//raya,rayb光线两端的深度值，sspt:屏幕空间的坐标点
bool RayIntersect(float raya, float rayb, float2 sspt) {
	//由于方向不同，需要对光线两端的深度值排序，保证rayb>raya
	if (raya > rayb) {
		float t = raya;
		raya = rayb;
		rayb = t;
	}

#if 1		//by default we use fixed thickness.默认的固定厚度
	float screenPCameraDepth = -LinearEyeDepth(tex2Dlod(_CameraDepthTexture, float4(sspt / 2 + 0.5, 0, 0)).r);

	return raya < screenPCameraDepth && rayb > screenPCameraDepth - PIXEL_THICKNESS;
#else
	//float backZ = tex2Dlod(_BackfaceTex, float4(sspt / 2 + 0.5, 0, 0)).r;
	//return raya < backZ && rayb > screenPCameraDepth;
#endif
}

bool traceRay(float3 start, float3 direction, float jitter, float4 texelSize, out float2 hitPixel, out float marchPercent,out float hitZ) {
	//限制raylength的长度
	float rayLength = ((start.z + direction.z * RAY_LENGTH) > -_ProjectionParams.y) ?(-_ProjectionParams.y - start.z) / direction.z : RAY_LENGTH;

	float3 end = start + direction * rayLength;

	//投影空间起点和终点坐标
	float4 H0 = mul(unity_CameraProjection, float4(start, 1));
	float4 H1 = mul(unity_CameraProjection, float4(end, 1));

	//屏幕空间起点和终点坐标
	float2 screenP0 = H0.xy / H0.w;
	float2 screenP1 = H1.xy / H1.w;	

	//H0和H1齐次坐标的w
	float k0 = 1.0 / H0.w;
	float k1 = 1.0 / H1.w;

	//NDC空间下的深度值
	float Q0 = start.z * k0;
	float Q1 = end.z * k1;

	//如果屏幕空间p1,p0距离小于0.01，p1加上一个像素的距离
	if (abs(dot(screenP1 - screenP0, screenP1 - screenP0)) < 0.00001) {
		screenP1 += texelSize.xy;
	}

	//_MainTex_TexelSize.zw：表示屏幕width和height的个数，deltaPixels：相隔像素数
	float2 deltaPixels = (screenP1 - screenP0) * texelSize.zw;
	
	//采样率
	float step;
	
	//使得每次至少一个像素被采样
	step = min(1 / abs(deltaPixels.y), 1 / abs(deltaPixels.x));

	//使得采样更快
	step *= PIXEL_STRIDE;

	//当远离屏幕时采样较慢，加快速度
	float sampleScaler = 1.0 - min(1.0, -start.z / 100); 
	step *= 1.0 + sampleScaler;	

	//避免报错
	float interpolationCounter = step;	
	
	float4 pqk = float4(screenP0, Q0, k0);

	//每次移动的向量
	float4 dpqk = float4(screenP1 - screenP0, Q1 - Q0, k1 - k0) * step;

	//jitter;抖动值
	pqk += jitter * dpqk;

	float prevZMaxEstimate = start.z;

	bool intersected = false;
	UNITY_LOOP		//强制循环
		for (int i = 1;i <= STEP_COUNT && interpolationCounter <= 1 && !intersected;i++,interpolationCounter += step) 
		{
		pqk += dpqk;

		//深度最大值和起始值
		float rayZMin = prevZMaxEstimate;
		float rayZMax = ( pqk.z) / ( pqk.w);
		

		//pqk.xy - dpqk.xy / 2：计算光线的屏幕空间的坐标时，可以取光线两个端点的中间点，投影到屏幕上作为采样点
		if (RayIntersect(rayZMin, rayZMax, pqk.xy - dpqk.xy / 2)) {
			//命中像素
			hitPixel = (pqk.xy - dpqk.xy / 2) / 2 + 0.5;
			//命中率
			marchPercent = (float)i / STEP_COUNT;
			intersected = true;
		}
		else {
			prevZMaxEstimate = rayZMax;
		}
	}

#if 1	  //二分搜索
	if (intersected) {
		//回退
		pqk -= dpqk;
		//强制循环
		UNITY_LOOP

			for (float gapSize = PIXEL_STRIDE; gapSize > 1.0; gapSize /= 2) {
				dpqk /= 2;
				float rayZMin = prevZMaxEstimate;
				float rayZMax = (pqk.z) / ( pqk.w);

				if (RayIntersect(rayZMin, rayZMax, pqk.xy - dpqk.xy / 2)) {		//命中了，起点不用动。（长度缩短一半即可）

				}
				else {							//没命中，将起点移动到中间。
					pqk += dpqk;
					prevZMaxEstimate = rayZMax;
				}
			}
		hitPixel = (pqk.xy - dpqk.xy / 2) / 2 + 0.5;
	}
#endif
	hitZ = pqk.z / pqk.w;

	return intersected;
}

#endif
#ifndef _YRC_SCREEN_SPACE_SHADOW
#define _YRC_SCREEN_SPACE_SHADOW


#define RAY_LENGTH 40.0	//maximum ray length.
#define STEP_COUNT 256	//maximum sample count.
#define PIXEL_STRIDE 4	 //sample multiplier. it's recommend 16 or 8.
#define PIXEL_THICKNESS (0.04 * PIXEL_STRIDE)	//how thick is a pixel. correct value reduces noise.

sampler2D _MainTex;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _CameraDepthTexture;
sampler2D _BackfaceTex;
float4x4 _WorldToView;
float4 _LightDir;

struct appdata {
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct v2f {
	float2 uv : TEXCOORD0;
	float4 vertex : SV_POSITION;
	float3 csRay : TEXCOORD1;
};

v2f vert(appdata v) {
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	float4 cameraRay = float4(v.uv * 2.0 - 1.0, 1.0, 1.0);
	cameraRay = mul(unity_CameraInvProjection, cameraRay);
	o.csRay = cameraRay / cameraRay.w;
	return o;
}
#include "ScreenSpaceRaytrace.cginc"
#define SCREEN_EDGE_MASK 0.98
float alphaCalc(float2 hitPixel, float hitZ) {
	float res = 1;
	float2 screenPCurrent = 2 * (hitPixel - 0.5);
	res *= 1 - max(
		(clamp(abs(screenPCurrent.x), SCREEN_EDGE_MASK, 1.0) - SCREEN_EDGE_MASK) / (1 - SCREEN_EDGE_MASK),
		(clamp(abs(screenPCurrent.y), SCREEN_EDGE_MASK, 1.0) - SCREEN_EDGE_MASK) / (1 - SCREEN_EDGE_MASK)
	);
	res *= 1 - (-(hitZ - 0.2) * _ProjectionParams.w);
	return res;
}

float4 fragDentisyAndOccluder(v2f i) : SV_Target	//we return dentisy in R, distance in G
{
	float decodedDepth = Linear01Depth(tex2D(_CameraDepthTexture, i.uv).r);
	float3 csRayOrigin = decodedDepth * i.csRay;
	float3 wsNormal = tex2D(_CameraGBufferTexture2, i.uv).rgb * 2.0 - 1.0;
	float3 csNormal = normalize(mul((float3x3)_WorldToView, wsNormal));
	float3 wsLightDir = -_LightDir;
	float3 csLightDir = normalize(mul((float3x3)_WorldToView, wsLightDir));
	float2 hitPixel;
	float marchPercent;
	float3 debugCol;

	float atten = 0;

	float2 uv2 = i.uv * float2(1024,1024);
	float c = (uv2.x + uv2.y) * 0.25;

	float hitZ;
	float rayBump = max(-0.010*csRayOrigin.z, 0.001);
	float rayLength;
	bool intersectd = traceRay(
		csRayOrigin + csNormal * rayBump,
		csLightDir,
		0,
		float4(1 / 991.0, 1 / 529.0, 991.0, 529.0),
		RAY_LENGTH,
		STEP_COUNT,
		PIXEL_STRIDE,
		PIXEL_THICKNESS,
		hitPixel,
		marchPercent,
		hitZ,
		rayLength
	);

	return intersectd ? float4(1 , rayLength, 0, 1) : 0;
}

float4 _MainTex_TexelSize;


#define BLURBOX_HALFSIZE 8
#define PENUMBRA_SIZE_CONST 4
#define MAX_PENUMBRA_SIZE 8
#define DEPTH_REJECTION_EPISILON 1.0	

fixed4 fragBlur(v2f i) :SV_TARGET{
	float2 dentisyAndOccluderDistance = tex2D(_MainTex,i.uv).rg;
	fixed dentisy = dentisyAndOccluderDistance.r;
	float occluderDistance = dentisyAndOccluderDistance.g;
	float maxOccluderDistance = 0;

	float3 uvOffset = float3(_MainTex_TexelSize.xy, 0);	//convenient writing here.
	for (int j = 0; j < BLURBOX_HALFSIZE; j++) {
		float top = tex2D(_MainTex, i.uv + j * uvOffset.zy).g;
		float bot = tex2D(_MainTex, i.uv - j * uvOffset.zy).g;
		float lef = tex2D(_MainTex, i.uv + j * uvOffset.xz).g;
		float rig = tex2D(_MainTex, i.uv - j * uvOffset.xz).g;
		if (top != 0 || bot != 0 || lef != 0 || rig != 0) {
			maxOccluderDistance = max(top, max(bot, max (lef, rig)));
			break;
		}
	}

	float penumbraSize = maxOccluderDistance * PENUMBRA_SIZE_CONST;

	float camDistance = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv));

	float projectedPenumbraSize = penumbraSize / camDistance;

	projectedPenumbraSize = min(1 + projectedPenumbraSize, MAX_PENUMBRA_SIZE);

	float depthtop = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + j * uvOffset.zy));
	float depthbot = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv - j * uvOffset.zy));
	float depthlef = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv + j * uvOffset.xz));
	float depthrig = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv - j * uvOffset.xz));

	float depthdx = min(abs(depthrig - camDistance), abs(depthlef - camDistance));
	float depthdy = min(abs(depthtop - camDistance), abs(depthbot - camDistance));

	float counter = 0;
	float accumulator = 0;
	UNITY_LOOP
	for (int j = -projectedPenumbraSize; j < projectedPenumbraSize; j++) {	//xaxis
		for (int k = -projectedPenumbraSize; k < projectedPenumbraSize; k++) {	//yaxis
			float depth = LinearEyeDepth(tex2Dlod(_CameraDepthTexture, float4(i.uv + uvOffset.xy * float2(j, k),0,0)));
			if (depthdx * abs(j) + depthdy * abs(k) + DEPTH_REJECTION_EPISILON < abs(camDistance - depth))
				break;
			counter += 1;
			accumulator += tex2Dlod(_MainTex, float4(i.uv + uvOffset.xy * float2(j, k),0,0)).r;
		}
	}
	return i.uv.x > 0.5 ? (1 - saturate(accumulator / counter)) : 1;
}

#endif
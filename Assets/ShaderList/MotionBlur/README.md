# MotionBlurEffect
# 1.简介
MotionBlurEffect 运动模糊效果，是游戏中最常见的特效之一，常用于MMO游戏轻功以及一些打斗技能特效。
# 2.实现原理
## 2.1 基于透明度混合的运动模糊
通过透明度混合的迭代运算，使得原来规律留下的物体影像透明度越来越低来实现残影的效果
## 2.2 基于深度计算的运动模糊
通过速度映射图存储每个像素的速度，然后使用这个速度来决定模糊的方向和大小
# 3.代码实现

    fixed4 frag(v2f i) : SV_Target {
			// 获得该片元的屏幕深度
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 重新映射回NDC坐标，屏幕空间
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// Transform by the view-projection inverse.
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// 得到世界空间下的坐标
			float4 worldPos = D / D.w;
			
			// 保存当前坐标的屏幕空间坐标
			float4 currentPos = H;
			// 通过_PreviousViewProjectionMatrix矩阵和当前世界坐标，计算之前帧屏幕空间坐标
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// 得到之前帧的屏幕空间下的坐标，通过除以w分量转换成非齐次点[-1,1]
			previousPos /= previousPos.w;
			
			// 计算前一帧和当前帧在屏幕空间的坐标差，计算出该像素的速度
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
			//迭代，模糊程度_BlurSize
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}

# 4.效果图

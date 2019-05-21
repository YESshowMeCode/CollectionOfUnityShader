# FlashEffect

# 1.简介
FlashEffect 闪光特效，经常用于提升游戏中物品的质感。

# 2.实现原理
需要一张流光图和一张遮罩贴图，计算流光贴图的uv的时候，会根据流光贴图和遮罩贴图的alpha值的乘积来确定最终输出的颜色是否可见，也就是说如果两个贴图任意一个的alpha值为0，那么最终输出值也就等于0，也就是输出透明颜色，也即是计算出此处没有流光效果，主纹理uv坐标的y值也乘以流光贴图和遮罩贴图的alpha值乘积，再根据时间调整uv上的采样，即可得到流光效果。

# 3.代码实现

    			fixed4 frag(v2f i) : SV_Target
			{
				//=====================计算流光贴图的uv=====================
				//缩放流光区域
				float2 flashUV = i.uv*_FlashScale;
				//不断改变uv的x轴，让他往x轴方向移动
				flashUV.x += -_Time.y*_FlashSpeedX;
				//不断改变uv的y轴，让他往y轴方向移动
				flashUV.y += -_Time.y*_FlashSpeedY;

				//================计算流光贴图的可见区域
				//取流光贴图的alpha值
				fixed flashAlpha = tex2D(_FlashTex, flashUV).a;
				//取遮罩贴图的alpha值
				fixed maskAlpha = tex2D(_MaskTex, i.uv).a;
				//最终在主纹理上的可见值（flashAlpha和maskAlpha任意为0则该位置不可见）
				fixed visible = flashAlpha*maskAlpha*_FlashIntensity*_Visibility;

				//=====================计算主纹理的uv=====================
				//被流光贴图覆盖的区域凸起（uv的y值增加）
				float2 mainUV = i.uv;
				mainUV.y += visible*_RaisedValue;

				//=====================最终输出=====================
				//主纹理 + 可见的流光
				fixed4 col = tex2D(_MainTex, mainUV) + visible*_FlashColor;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}

# 4.效果图

# FishEye
# 1.简介
FishEye 鱼眼效果，常用于实现FPS游戏瞄准镜、某些物品的特殊展示或移动等效果。

# 2.实现原理

 1. 获取图像每个像素在剪裁坐标系下的坐标，将屏幕中心当做坐标原点重新建立坐标系，
 2. 设置一个变化系数intensity ，通过x=(1-y*y)*x*intensity,实现y距原点越近，x距原点越远，偏移越大，y也同样处理，得到纹理偏移，在采样时坐标减去偏移得到偏移后的采样结果。实现鱼眼效果。
# 3.代码实现

    v2f vert (appdata_t v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);
				//获取到纹理的坐标
				o.texcoord = v.texcoord;
				return o;
			}
	
			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				//获取纹理坐标
				half2 uv = i.texcoord;
				//因为屏幕坐标是0到1，这样计算就将屏幕中心当作坐标原点重新建立坐标系
				uv = (uv - 0.5) * 2.0;

				half2 realuv;
				//计算偏移，x轴=(1-y*y)*x*变化系数，这样就造成了y离原点（屏幕中心）的距离越近，x离原点越远，偏移越大
				realuv.x = (1 - uv.y * uv.y) * intensity.y * uv.x;
				//与计算x轴相同
				realuv.y = (1 - uv.x * uv.x) * intensity.x * uv.y;
				//UnityStereoScreenSpaceUVAdjust()纹理坐标的材质球调节偏移计算，源纹理坐标减去偏移得到目标纹理坐标
				return tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(i.texcoord - realuv, _MainTex_ST));
			}

#4.效果图
![image](https://github.com/YESshowMeCode/CollectionOfUnityShader/blob/master/Assets/ShaderList/FishEye/FishEye.gif)
 

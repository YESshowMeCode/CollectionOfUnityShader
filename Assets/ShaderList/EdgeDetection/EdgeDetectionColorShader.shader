//色差描边，通过对生成图像后处理，生成相邻像素颜色相差的sobel函数值，再进行插值完成描边。弊端：物体的纹理和阴影都会被描边，得到很多多余的边缘线

Shader "Hidden/EdgeDetectionColorShader"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
}
	//子着色器
    SubShader { 
		//开启深度测试，关闭裁剪和深度写入
		ZTest Always Cull Off ZWrite Off
		//通道
		Pass { 
			//CG着色器语言编写模块
			CGPROGRAM
			//告知编译器顶点和片段着色函数的名称
			#pragma vertex vert
			#pragma fragment frag

			//CG头文件
			#include "UnityCG.cginc"
			
			
			//片元着色器输入结构
			struct v2f {
				float4 vertex : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};
			//声明外部变量
			sampler2D _MainTex;  
			//通过_MainTex_TexelSize来计算各个相邻区域的纹理坐标，_MainTex_TexelSize对应着纹理中每个像素的大小
			uniform half4 _MainTex_TexelSize;
			//边缘线强度,EdgeOnly为1时，只显示边缘，不渲染源图像用_BackgroundColor代替；为0时，边缘会叠加在源图像上
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			//顶点着色器
			v2f vert (appdata_img v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);
				//获取到纹理的坐标
				half2 uv = v.texcoord ;

				//计算该顶点周围8个相邻顶点的纹理坐标
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);

				return o;
			}
			//luminance:亮度，计算该像素的亮度值
			fixed luminance(fixed4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}

			//计算改片元与周边片元的颜色差值
			half Sobel(v2f i) {
				const half Gx[9] = {-1,  0,  1,
									-2,  0,  2,
									-1,  0,  1};
				const half Gy[9] = {-1, -2, -1,
									0,  0,  0,
									1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				//分别计算周围8个片元的颜色和比例值Gx、Gy乘积
				for (int it = 0; it < 9; it++) {
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}
				//得到颜色相差的值
				half edge = 1 - abs(edgeX) - abs(edgeY);
				return edge;
			}
	
			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				//获取该片元的颜色差值
				half edge = Sobel(i);
				//边缘线颜色与源片元颜色进行插值
				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);
				//边缘线颜色与背景颜色进行插值
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
				//将前两次计算的颜色再进行一次插值，边缘线颜色、源片元颜色和背景颜色混合
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
			}
			ENDCG 
		} 
	}
	Fallback off

}

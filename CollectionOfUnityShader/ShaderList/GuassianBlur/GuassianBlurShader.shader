Shader "Hidden/GuassianBlurShader"{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	//子着色器
    SubShader { 
		CGINCLUDE
		//CG头文件
		#include "UnityCG.cginc"

		//声明外部变量
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		float _BlurSize;

		//片元着色器输入结构体
		struct v2f{
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
		};

		//竖直方向顶点着色器
		v2f vertBlurVertical(appdata_img v) {
			v2f o;
			//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
			o.pos = UnityObjectToClipPos(v.vertex);
			//获取纹理坐标
			half2 uv = v.texcoord;
			
			//_MainTex_TexelSize.y 每一个像素的尺寸，uv数组存储了这个坐标上下各两个像素的坐标，
			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
					 
			return o;
		}
		
		//水平方向顶点着色器
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
			o.pos = UnityObjectToClipPos(v.vertex);
			//获取纹理坐标
			half2 uv = v.texcoord;
			//_MainTex_TexelSize.y 每一个像素的尺寸，uv数组存储了这个坐标上下各两个像素的坐标，
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}

		//片元着色器
		fixed4 fragBlur(v2f i) : SV_Target {
			//片元最终颜色受源颜色和周围片元颜色的比重
			float weight[3] = {0.4026, 0.2442, 0.0545};
			//获得源片元颜色和比重的乘积
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			//获取周边片元的颜色混合，使得片元间颜色过渡更加平滑，实现模糊效果
			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return fixed4(sum, 1.0);
		}
		ENDCG

		//开启深度测试，关闭裁剪和深度写入
		ZTest Always Cull Off ZWrite Off
		
		Pass {
			NAME "GAUSSIAN_BLUR_VERTICAL"
			//CG着色器语言编写模块
			CGPROGRAM
			//告知编译器顶点和片段着色函数的名称
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			  
			ENDCG  
		}
		
		Pass {  
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			//CG着色器语言编写模块
			CGPROGRAM  
			//告知编译器顶点和片段着色函数的名称
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			
			ENDCG
		}	
	}
	Fallback "Diffuse"

}

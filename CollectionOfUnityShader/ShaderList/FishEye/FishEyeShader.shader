Shader "Hidden/FishEyeShader"
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
			//透明度混合，源Alpha+(1-源Alpha)，
			Blend SrcAlpha OneMinusSrcAlpha
			//RGB通道,仅渲染RGB通道
			ColorMask RGB
			//参数绑定
		    BindChannels { 
				Bind "vertex", vertex 
				Bind "texcoord", texcoord
			} 
			//CG着色器语言编写模块
			CGPROGRAM
			//告知编译器顶点和片段着色函数的名称
			#pragma vertex vert
			#pragma fragment frag

			//CG头文件
			#include "UnityCG.cginc"
			
			//顶点着色器输入结构体
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD;
			};
			
			//片元着色器输入结构
			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD;
			};
			//声明外部变量
				sampler2D _MainTex;
				half4 _MainTex_ST;
				float2 intensity;
			//顶点着色器
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
			ENDCG 
		} 
	}
}

Shader "Hidden/MotionBlurShader" {
//属性值
Properties {

}
	//子着色器
    SubShader { 
		//开启深度测试，关闭裁剪和深度写入
		ZTest Always Cull Off ZWrite Off
		//通道,通过透明度混合的迭代运算，使得原来规律留下的物体影像透明度越来越低来实现残影的效果
		Pass {
			//透明度混合，最终颜色 = 源颜色 * 源透明值 + 目标颜色*（1 - 源透明值）_BlurAmount越大，残影越多
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
			//MainTex_ST的ST是应该是SamplerTexture,顶点的uv去和材质球的tiling和offset作运算
			float4 _MainTex_ST;
			uniform float _BlurAmount;
			uniform sampler2D _MainTex;
			//顶点着色器
			v2f vert (appdata_t v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);
				//获取到纹理的坐标，TRANSFORM_TEX主要作用是拿顶点的uv去和材质球的tiling和offset作运算， 确保材质球里的缩放和偏移设置是正确的，等于o.texcoord = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
	
			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				//tex2D纹理采样函数，_BlurAmount透明度，通过
				return half4(tex2D(_MainTex, i.texcoord).rgb, _BlurAmount );
			}
			ENDCG 
		} 

		//通道二，对Alpha通道进行处理
		Pass {
			//仅显示贴图的RGB部分，无Alpha透明通道处理
			Blend One Zero
			//A通道
			ColorMask A
			
		    BindChannels { 
				Bind "vertex", vertex 
				Bind "texcoord", texcoord
			} 
		
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
	
			#include "UnityCG.cginc"
	
			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD;
			};
	
			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD;
			};
			
			float4 _MainTex_ST;
			
			v2f vert (appdata_t v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return o;
			}
	
			sampler2D _MainTex;
			
			half4 frag (v2f i) : SV_Target
			{
				return tex2D(_MainTex, i.texcoord);
			}
			//结束CG编写模块
			ENDCG 
		}
		
	}
}

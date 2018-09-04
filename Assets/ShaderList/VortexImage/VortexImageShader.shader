Shader "Hidden/VortexImageShader"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
}
	//子着色器
    SubShader { 
		//开启深度测试，关闭裁剪和深度写入
		ZTest Always Cull Off ZWrite Off
		//通道,通过透明度混合的迭代运算，使得原来规律留下的物体影像透明度越来越低来实现残影的效果
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
				float2 uvOrig : TEXCOORD1;
			};
			//声明外部变量
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			half4 _MainTex_ST;
			uniform float4 _CenterRadius;
			uniform float _Angle;
			//顶点着色器
			v2f vert (appdata_t v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);
				//获取到纹理的坐标到中心的向量
				float2 uv = v.texcoord - _CenterRadius.xy;
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uvOrig = uv;
				return o;
			}
	
			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				//纹理的坐标到中心的向量
				float2 offset = i.uvOrig;
				float angleTmp = 1 - length(offset/_CenterRadius.zw);
				angleTmp = max(0,angleTmp);
				angleTmp = angleTmp * angleTmp * _Angle;
				float cosLength,sinLength;
				sincos(angleTmp,sinLength,cosLength);

				float2 uv;
				uv.x = cosLength * offset[0] - sinLength * offset[1];
				uv.y = sinLength * offset[0] + cosLength * offset[1];
				uv += _CenterRadius.xy;
				//UnityStereoScreenSpaceUVAdjust()纹理坐标的材质球调节偏移计算，
				return tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(uv, _MainTex_ST));
			}
			ENDCG 
		} 
	}
	Fallback off

}

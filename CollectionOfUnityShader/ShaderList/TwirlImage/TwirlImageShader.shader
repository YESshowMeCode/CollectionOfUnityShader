Shader "Hidden/TwirlImageShader"
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
			};
			//声明外部变量
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_TexelSize;
			half4 _MainTex_ST;
			uniform float4 _CenterRadius;
			uniform float4x4 _RotationMatrix;
			//顶点着色器
			v2f vert (appdata_t v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);
				//获取到纹理的坐标到中心的向量
				o.texcoord = v.texcoord - _CenterRadius.xy;
				return o;
			}
	
			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				//纹理的坐标到中心的向量
				float2 offset = i.texcoord;
				//获取偏移后，纹理坐标到中心点的向量
				float2 distortedOffset = MultiplyUV (_RotationMatrix, offset.xy);
				//限制扭曲的半径
				float2 tmp = offset / _CenterRadius.zw;
				float t = min (1, length(tmp));
				
				//对偏移量进行插值
				offset = lerp (distortedOffset, offset, t);
				//获得纹理偏移后的屏幕坐标
				offset += _CenterRadius.xy;
				//UnityStereoScreenSpaceUVAdjust()纹理坐标的材质球调节偏移计算，
				return tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(offset, _MainTex_ST));
			}
			ENDCG 
		} 
	}
}

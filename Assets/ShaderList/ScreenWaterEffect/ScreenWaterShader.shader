Shader "Hidden/ScreenWaterShader"
{
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
}
	//子着色器
    SubShader { 
		//开启深度测试，关闭裁剪和深度写入
		ZTest Always 
		//通道
		Pass {

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
				float4 color : COLOR;
				float2 texcoord : TEXCOORD;
			};
			
			//片元着色器输入结构
			struct v2f {
				float4 vertex : SV_POSITION;
				float2 texcoord : TEXCOORD;
				float2 color : COLOR;
			};
			//声明外部变量
			uniform sampler2D _MainTex;
			uniform sampler2D _ScreenWaterDropTex;
			uniform float _CurTime;
			uniform float _DropSpeed;
			uniform float _SizeX;
			uniform float _SizeY;
			uniform float _Distortion;
			uniform float2 _MainTex_TexelSize;
			//顶点着色器
			v2f vert (appdata_t v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);
				//获取到纹理的坐标到中心的向量
				o.texcoord = v.texcoord;
				o.color = v.color;
				return o;
			}
	
			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				//获取纹理坐标
				float2 uv = i.texcoord.xy;

				//解决平台差异的问题。校正方向，若和规定方向相反，则将速度反向并加1
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					_DropSpeed = 1 - _DropSpeed;
				#endif

				//设置三层水流效果，按照一定的规律在水滴纹理上分别进行取样
				float3 rainTex1 = tex2D(_ScreenWaterDropTex, float2(uv.x * 1.15* _SizeX, (uv.y* _SizeY *1.1) + _CurTime* _DropSpeed *0.15)).rgb / _Distortion;
				float3 rainTex2 = tex2D(_ScreenWaterDropTex, float2(uv.x * 1.25* _SizeX - 0.1, (uv.y *_SizeY * 1.2) + _CurTime *_DropSpeed * 0.2)).rgb / _Distortion;
				float3 rainTex3 = tex2D(_ScreenWaterDropTex, float2(uv.x* _SizeX *0.9, (uv.y *_SizeY * 1.25) + _CurTime * _DropSpeed* 0.032)).rgb / _Distortion;

				//整合三层水流效果的颜色信息，存于finalRainTex中
				float2 finalRainTex = uv.xy - (rainTex1.xy - rainTex2.xy - rainTex3.xy) / 3;

				//按照finalRainTex的坐标信息，在主纹理上进行采样
				float3 finalColor = tex2D(_MainTex, finalRainTex.xy).rgb;

				//返回加上alpha分量的最终颜色值
				return fixed4(finalColor, 1.0);
			}
			ENDCG 
		} 
	}
	Fallback off

}

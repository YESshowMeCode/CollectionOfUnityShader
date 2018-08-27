Shader "Hidden/EdgeDetextionNormalShader"
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
				half2 uv[5] : TEXCOORD0;
			};
			//声明外部变量
			sampler2D _MainTex;
			half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			float _SampleDistance;
			half4 _Sensitivity;
			sampler2D _CameraDepthNormalsTexture;

			//顶点着色器
			v2f vert (appdata_img v)
			{
				//声明输出的结构对象
				v2f o;
				//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
				o.vertex = UnityObjectToClipPos(v.vertex);

				//获取到纹理的坐标
				half2 uv = v.texcoord;

				//对不同平台处理
				#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					uv.y = 1 - uv.y;
				#endif

				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

				return o;
			}
			
			half CheckSame(half4 center, half4 sample) {
				half2 centerNormal = center.xy;
				float centerDepth = DecodeFloatRG(center.zw);
				half2 sampleNormal = sample.xy;
				float sampleDepth = DecodeFloatRG(sample.zw);
			
				// difference in normals
				// do not bother decoding normals - there's no need here
				half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
				int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
				// difference in depth
				float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
				// scale the required threshold by the distance
				int isSameDepth = diffDepth < 0.1 * centerDepth;
			
				// return:
				// 1 - if normals and depth are similar enough
				// 0 - otherwise
				return isSameNormal * isSameDepth ? 1.0 : 0.0;
			}
	

			//片元着色器
			half4 frag (v2f i) : SV_Target
			{
				half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
				half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
				half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
				half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
			
				half edge = 1.0;
			
				edge *= CheckSame(sample1, sample2);
				edge *= CheckSame(sample3, sample4);
			
				fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
				fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
			
				return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
			}
			ENDCG 
		} 
	}
	Fallback off

}

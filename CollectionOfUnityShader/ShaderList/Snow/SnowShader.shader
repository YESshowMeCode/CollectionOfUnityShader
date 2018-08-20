//先将渲染调整成延迟渲染

Shader "Hidden/SnowShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			//CameraDepthNormalsTexture  可以获取Normals和Depth
			sampler2D _CameraDepthNormalsTexture;
			float4x4 _CamToWorld;
			sampler2D _SnowTex;
			float _SnowTexScale;
			half4 _SnowColor;
			fixed _BottomThreshold;
			fixed _TopThreshold;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 normal;
				float depth;
				//DecodeDepthNormal(float4 enc, out float depth, out float3 normal)函数可以用来从pixel value中解码出depth和normal值，返回的depth为0..1的范围。
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, normal);
				//将法线从相机空间转换到世界空间，以这种方式检索的法线是相机空间法线。如果我们旋转相机，法线的面也会改变，这就是为什么要把它乘以之前脚本中的_CamToWorld矩阵集合。它将把法线从相机转换为世界坐标，这样它们就不再依赖于相机的视角了。
				normal = mul( (float3x3)_CamToWorld, normal);
				// 因为某点的法线信息是被保存到法线贴图上对应像素点的.实际计算是把法线x,y,z方向大小映射到颜色空间rgb里.就是把x值存在r里,
				// 把y值存在g里,把z值存在b里.因为rgb是8字节为单位的.所以高模的法线信息存储到像素里是要丢失精度的.而且前面计算高模与低模
				// 对应点也不可能完全匹配到,本来就是个模拟过程.此过程是为了获取法线的y方向值
				half snowAmount = normal.g;
				
				half scale = (_BottomThreshold + 1 - _TopThreshold) / 1 + 1;

				snowAmount = saturate( (snowAmount - _BottomThreshold) * scale);
				// 获取相机投影矩阵的11和22，缩放因子
				float2 p11_22 = float2(unity_CameraProjection._11, unity_CameraProjection._22);
				//vpos是视口坐标，wpos是由视口坐标与_CamToWorld矩阵相乘而得到的世界坐标，并且它通过除以远平面的位置（_ProjectionParams.z）来转换为有效的世界坐标
				float3 vpos = float3( (i.uv * 2 - 1) / p11_22, -1) * depth;
				//转换到世界空间
				float4 wpos = mul(_CamToWorld, float4(vpos, 1));
				//_ProjectionParams.z用于在使用翻转投影矩阵时翻转xy的坐标值。wpos加上世界坐标系相机坐标，得到世界空间的坐标
				wpos += float4(_WorldSpaceCameraPos, 0) / _ProjectionParams.z;
				//获取雪的纹理坐标
				wpos *= _SnowTexScale * _ProjectionParams.z;
				//获取雪color
				half4 snowColor = tex2D(_SnowTex, wpos.xz) * _SnowColor;
				// 获取原图像颜色
				half4 col = tex2D(_MainTex, i.uv);
				//混合得到最终颜色
				return lerp(col, snowColor, snowAmount);
			}
			ENDCG
		}
	}
}
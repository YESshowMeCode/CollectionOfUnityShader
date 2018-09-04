//puppet_master
//2018.4.20
//后处理方式实现GodRay
Shader "GodRay/PostEffect" {
 
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurTex("Blur", 2D) = "white"{}
	}
 
	CGINCLUDE
	#define RADIAL_SAMPLE_COUNT 6
	#include "UnityCG.cginc"
	
	//用于阈值提取高亮部分
	struct v2f_threshold
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
	};
 
	//用于blur
	struct v2f_blur
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 blurOffset : TEXCOORD1;
	};
 
	//用于最终融合
	struct v2f_merge
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};
 
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	float4 _BlurTex_TexelSize;
	float4 _ViewPortLightPos;
	
	float4 _offsets;
	float4 _ColorThreshold;
	float4 _LightColor;
	float _LightFactor;
	float _PowFactor;
	float _LightRadius;
 
	//高亮部分提取shader
	v2f_threshold vert_threshold(appdata_img v)
	{
		v2f_threshold o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		
		//dx中纹理从左上角为初始坐标，需要反向
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif	
		return o;
	}
 
	fixed4 frag_threshold(v2f_threshold i) : SV_Target
	{
		fixed4 color = tex2D(_MainTex, i.uv);
		float distFromLight = length(_ViewPortLightPos.xy - i.uv);
		float distanceControl = saturate(_LightRadius - distFromLight);
		//仅当color大于设置的阈值的时候才输出
		float4 thresholdColor = saturate(color - _ColorThreshold) * distanceControl;
		float luminanceColor = Luminance(thresholdColor.rgb);
		luminanceColor = pow(luminanceColor, _PowFactor);
		return fixed4(luminanceColor, luminanceColor, luminanceColor, 1);
	}
 
	//径向模糊 vert shader
	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		//径向模糊采样偏移值*沿光的方向权重
		o.blurOffset = _offsets * (_ViewPortLightPos.xy - o.uv);
		return o;
	}
 
	//径向模拟pixel shader
	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		half4 color = half4(0,0,0,0);
		for(int j = 0; j < RADIAL_SAMPLE_COUNT; j++)   
		{	
			color += tex2D(_MainTex, i.uv.xy);
			i.uv.xy += i.blurOffset; 	
		}
		return color / RADIAL_SAMPLE_COUNT;
	}
 
	//融合vertex shader
	v2f_merge vert_merge(appdata_img v)
	{
		v2f_merge o;
		//mvp矩阵变换
		o.pos = UnityObjectToClipPos(v.vertex);
		//uv坐标传递
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif	
		return o;
	}
 
	fixed4 frag_merge(v2f_merge i) : SV_Target
	{
		fixed4 ori = tex2D(_MainTex, i.uv1);
		fixed4 blur = tex2D(_BlurTex, i.uv);
		//输出= 原始图像，叠加体积光贴图
		return ori + _LightFactor * blur * _LightColor;
	}
 
		ENDCG
 
	SubShader
	{
		//pass 0: 提取高亮部分
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
 
			CGPROGRAM
			#pragma vertex vert_threshold
			#pragma fragment frag_threshold
			ENDCG
		}
 
		//pass 1: 径向模糊
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
 
			CGPROGRAM
			#pragma vertex vert_blur
			#pragma fragment frag_blur
			ENDCG
		}
 
		//pass 2: 将体积光模糊图与原图融合
		Pass
		{
 
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
 
			CGPROGRAM
			#pragma vertex vert_merge
			#pragma fragment frag_merge
			ENDCG
		}
	}
}

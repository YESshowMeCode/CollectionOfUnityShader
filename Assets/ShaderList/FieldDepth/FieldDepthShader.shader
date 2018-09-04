// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/FieldDepthShader" {
 
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurTex("Blur", 2D) = "white"{}
	}
 
	CGINCLUDE
	#include "UnityCG.cginc"
 
	struct v2f_blur
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float4 uv01 : TEXCOORD1;
		float4 uv23 : TEXCOORD2;
		float4 uv45 : TEXCOORD3;
	};
 
	struct v2f_dof
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};
 
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	sampler2D_float _CameraDepthTexture;
	float4 _offsets;
	float _focalDistance;
	float _nearBlurScale;
	float _farBlurScale;
 
	//高斯模糊 vert shader（上一篇文章有详细注释）
	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		_offsets *= _MainTex_TexelSize.xyxy;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
 
		o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);
		o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
		o.uv45 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 3.0;
 
		return o;
	}
 
	//高斯模糊 pixel shader（上一篇文章有详细注释）
	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		fixed4 color = fixed4(0,0,0,0);
		color += 0.40 * tex2D(_MainTex, i.uv);
		color += 0.15 * tex2D(_MainTex, i.uv01.xy);
		color += 0.15 * tex2D(_MainTex, i.uv01.zw);
		color += 0.10 * tex2D(_MainTex, i.uv23.xy);
		color += 0.10 * tex2D(_MainTex, i.uv23.zw);
		color += 0.05 * tex2D(_MainTex, i.uv45.xy);
		color += 0.05 * tex2D(_MainTex, i.uv45.zw);
		return color;
	}
 
	//景深效果 vertex shader
	v2f_dof vert_dof(appdata_img v)
	{
		v2f_dof o;
		//mvp矩阵变换
		o.pos = UnityObjectToClipPos(v.vertex);
		//uv坐标传递
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;
		//dx中纹理从左上角为初始坐标，需要反向
		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
		#endif	
		return o;
	}
 
	fixed4 frag_dof(v2f_dof i) : SV_Target
	{
		//取原始清晰图片进行uv采样
		fixed4 ori = tex2D(_MainTex, i.uv1);
		//取模糊普片进行uv采样
		fixed4 blur = tex2D(_BlurTex, i.uv);
		//取当位置对应的深度值
		float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
		//将深度值转化到01线性空间
		depth = Linear01Depth(depth);
		
		//如果depth小于焦点的物体，那么使用原始清晰图像，否则使用模糊的图像与清晰图像的差值，通过差值避免模糊和清晰之间明显的边界，结果为远景模糊效果
		fixed4 final = (depth <= _focalDistance) ? ori : lerp(ori, blur, clamp((depth - _focalDistance) * _farBlurScale, 0, 1));
		//上面的结果，再进行一次计算，如果depth大于焦点的物体，使用上面的结果和模糊图像差值，得到近景模糊效果
		final = (depth > _focalDistance) ? final : lerp(ori, blur, clamp((_focalDistance - depth) * _nearBlurScale, 0, 1));
		//焦点位置是清晰的图像，两边分别用当前像素深度距离焦点的距离进行差值，这样就达到原理焦点位置模糊的效果
 
		//上面的？在编译时会被编译成if语句，GPU并不擅长分支计算，而且如果有分支，两个分支都要跑。这里给了一个更优化一些的计算方式，不过语法比较晦涩
		//float focalTest = clamp(sign(depth - _focalDistance),0,1);
		//fixed4 final = (1 - focalTest) * ori + focalTest * lerp(ori, blur, clamp((depth - _focalDistance) * _farBlurScale, 0, 1));
		//final = (focalTest)* final + (1 - focalTest) * lerp(ori, blur, clamp((_focalDistance - depth) * _nearBlurScale, 0, 1));
		return final;
	}
 
	ENDCG
 
	SubShader
	{
		//pass 0: 高斯模糊
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
 
		//pass 1: 景深效果
		Pass
		{
 
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
			ColorMask RGBA
 
			CGPROGRAM
			#pragma vertex vert_dof
			#pragma fragment frag_dof
			ENDCG
		}
 
	}
}

//puppet_master
//2018.4.15
//Shadow Gun中贴片方式实现GodRay代码，升级unity2017.3，增加一些注释
Shader "GodRay/ShadowGunSimple" 
{
 
	Properties 
	{
		_MainTex ("Base texture", 2D) = "white" {}
		_FadeOutDistNear ("Near fadeout dist", float) = 10	
		_FadeOutDistFar ("Far fadeout dist", float) = 10000	
		_Multiplier("Multiplier", float) = 1
		_ContractionAmount("Near contraction amount", float) = 5
		//增加一个颜色控制(仅RGB生效)
		_Color("Color", Color) = (1,1,1,1)
	}
 
	SubShader 
	{	
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		
		//叠加方式Blend
		Blend One One
		Cull Off 
		Lighting Off 
		ZWrite Off 
		Fog { Color (0,0,0,0) }
		
		CGINCLUDE	
		#include "UnityCG.cginc"
		sampler2D _MainTex;
		
		float _FadeOutDistNear;
		float _FadeOutDistFar;
		float _Multiplier;
		float _ContractionAmount;
		float4 _Color;
 
		struct v2f {
			float4	pos	: SV_POSITION;
			float2	uv		: TEXCOORD0;
			fixed4	color	: TEXCOORD1;
		};
		
		v2f vert (appdata_full v)
		{
			v2f 		o;
			//update mul(UNITY_MATRIX_MV, v.vertex) 根据UNITY_USE_PREMULTIPLIED_MATRICES宏控制，可以预计算矩阵，减少逐顶点计算
			float3		viewPos		= UnityObjectToViewPos(v.vertex);
			float		dist		= length(viewPos);
			float		nfadeout	= saturate(dist / _FadeOutDistNear);
			float		ffadeout	= 1 - saturate(max(dist - _FadeOutDistFar,0) * 0.2);
			
			//乘方扩大影响
			ffadeout *= ffadeout;
			nfadeout *= nfadeout;
			nfadeout *= nfadeout;
			nfadeout *= ffadeout;
			
			float4 vpos = v.vertex;
			//沿normal反方向根据fade系数控制顶点位置缩进，刷了顶点色控制哪些顶点需要缩进
			//黑科技：mesh是特制的，normal方向是沿着面片方向的，而非正常的垂直于面片
			vpos.xyz -=   v.normal * saturate(1 - nfadeout) * v.color.a * _ContractionAmount;
							
			o.uv	= v.texcoord.xy;
			o.pos	= UnityObjectToClipPos(vpos);
			//直接在vert中计算淡出效果
			o.color	= nfadeout * v.color * _Multiplier* _Color;
							
			return o;
		}
		
		fixed4 frag (v2f i) : COLOR
		{			
				return tex2D (_MainTex, i.uv.xy) * i.color ;
		}
		ENDCG
 
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest			
			ENDCG 
		}	
	}
}

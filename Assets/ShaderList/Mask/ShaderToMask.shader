Shader "Hidden/ShaderToMask" 
{
	Properties 
	{
		_MainTex("_MainTex",2D)="white"{}
	}
	SubShader 
	{
		Tags{ "Queue"="Transparent" "IngnoreProjector"="True" "RenderType"="Transparent" }
 
		Pass 
		{
			Tags{ "LightMode" = "ForwardBase" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off
			CGPROGRAM
 
			#include "UnityCG.cginc"
			#include "Lighting.cginc"  
 
			#pragma vertex vert
			#pragma fragment frag
 
			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			uniform float _Radius;
 
			struct a2v
			{
				float4 position:POSITION ;
				float4 texcoord:TEXCOORD0 ; 
			};
 
			struct v2f
			{
				float4 position:SV_POSITION ;
				float2 texcoord:TEXCOORD0 ; 
			};
 
			v2f vert(a2v v)
			{
				v2f f;
				f.position=UnityObjectToClipPos(v.position) ;
 				f.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				return f;
			}
 
			fixed4 frag(v2f f):SV_Target
			{
				float4 color = tex2D(_MainTex,f.texcoord);
				float2 r;
				r.x = abs(f.texcoord.x-0.5);
				r.y = abs(f.texcoord.y-0.5);
				float temp = step(length(r),_Radius);
				float4 tempColor = float4(1,1,1,0);
				float4 finColor = lerp(color,tempColor,1-temp);
				return finColor;
			}
			ENDCG
		}
	}
 
	Fallback "Diffuse"
}
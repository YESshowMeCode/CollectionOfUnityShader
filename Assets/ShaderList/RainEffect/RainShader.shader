// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Luoyinan/ImageEffect/ScreenSpaceRain"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
 
	SubShader
	{
		Cull Off 
		ZWrite Off 
		ZTest Always
		Fog { Mode off }  
 
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
 
			struct appdata
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};
 
			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 ray : TEXCOORD1;
			};
 
			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
 
				// screen pos -> view pos
				float4 cameraRay = mul(unity_CameraInvProjection, float4(v.texcoord * 2 - 1, 1, 1)); // farPlane
				cameraRay.z *= -1; // 摄像机的正向是-Z轴,正好和Unity默认的Z轴相反.
				o.ray = cameraRay.xyz / cameraRay.w;
				return o;
			}
			
			sampler2D _MainTex;
			sampler2D _CameraDepthNormalsTexture;
			float4x4 _CamToWorld;
 
			sampler2D _RippleTex;
			float _RippleTexScale;
			fixed _RippleIntensity;
			fixed _RippleBlendFactor;
			sampler2D _WaveTex;
			fixed _WaveIntensity;
			fixed _WaveTexScale;
			half4 _WaveForce;
			samplerCUBE _ReflectionTex;		
 
			fixed _RainIntensity;
			half _MaxDistance;
			
			half4 frag (v2f i) : SV_Target
			{
				fixed4 finalColor = tex2D(_MainTex, i.uv);
 
			    // normal & depth
				half3 normal;
				float depth;
				DecodeDepthNormal(tex2D(_CameraDepthNormalsTexture, i.uv), depth, normal);
				normal = mul((float3x3)_CamToWorld, normal);
				//normal = mul((float3x3)unity_CameraToWorld, normal);
				half filter = normal.y;
 
				// view pos -> world pos
				float4 viewPos = float4(i.ray * depth, 1);
				float4 worldPos = mul(unity_CameraToWorld, viewPos); 
				
				// distance
				half d = length(worldPos.xyz - _WorldSpaceCameraPos.xyz);
				if (d < _MaxDistance) // performance
				{
					// wave
					half3 bump = UnpackNormal(tex2D(_WaveTex, worldPos.xz * _WaveTexScale + _Time.xx * _WaveForce.xy));
					bump += UnpackNormal(tex2D(_WaveTex, worldPos.xz * _WaveTexScale + _Time.xx * _WaveForce.zw));
					bump *= 0.5; 
 
					// ripple
					half3 ripple = UnpackNormal(tex2D(_RippleTex, worldPos.xz * _RippleTexScale));
					normal.xy = lerp(normal.xy, ripple.xy * _RippleIntensity + bump.xy * _WaveIntensity, _RippleBlendFactor);
 
					// reflection
					half3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);	
					half3 reflUVW = normalize(reflect(-viewDir, normal));
					//half fresnel = 1 - saturate(dot(viewDir, normal));	
					//fresnel = 0.25 + fresnel * 0.75;
					half4 reflection = texCUBE(_ReflectionTex, reflUVW) * _RainIntensity;		
					finalColor += reflection * normal.y * step(0.1, filter) * filter * 2;
				}
 
				return  finalColor;
			}
 
			ENDCG
		}
	}
}

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 15/Water Wave" {
	Properties {
		_Color ("Main Color", Color) = (0, 0.15, 0.115, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_WaveMap ("Wave Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1, 0.1)) = 0.01
		_Distortion ("Distortion", Range(0, 100)) = 10
	}
	SubShader {
		// "Queue"="Transparent"并把后面的RenderType设置成Opaque，确保该物体渲染时，其他不透明物体已经被渲染到屏幕上了，否则就可能无法得到“透过水面看到的图像”
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		// 定义一个抓取屏幕图像的pass，抓取的图像会存储在_RefractionTex这个纹理中
		GrabPass { "_RefractionTex" }
		
		Pass {

			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 _Color;
			sampler2D _MainTex;//水面材质纹理
			float4 _MainTex_ST;
			sampler2D _WaveMap;//由噪声纹理生成的法线纹理
			float4 _WaveMap_ST;
			samplerCUBE _Cubemap;//立方体纹理
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;	
			sampler2D _RefractionTex;//抓取得到的纹理
			float4 _RefractionTex_TexelSize;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				//得到对应被抓取屏幕图样的采样坐标
				o.scrPos = ComputeGrabScreenPos(o.pos);
				//得到水面纹理和法线纹理的坐标
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _WaveMap);
				//得到世界坐标
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//切线空间计算
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				//保存切线空间转换到世界空间的变换矩阵
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//获取世界坐标
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				//视线方向，worldpos-camerapos
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				//移动偏移
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);
				
				// 对法线纹理进行两次采样，模拟两层交叉水面波动的效果
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);
				
				// 对屏幕采样坐标进行偏移，模拟折射效果
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				//计算偏移后的屏幕坐标，将偏移量和屏幕坐标的z分量相乘是为了模拟深度越大、折射程度越大的效果
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				//
				fixed3 refrCol = tex2D( _RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				// 法线纹理从切线空间转换到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				//水面纹理采样
				fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
				//得到反射方向
				fixed3 reflDir = reflect(-viewDir, bump);
				//同反射方向对Cubemap采样
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb * _Color.rgb;
				//菲涅耳系数
				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
				fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	// Do not cast shadow
	FallBack Off
}

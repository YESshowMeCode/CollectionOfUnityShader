// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Stein/CustomPBR"
{
    Properties
    {
        _Matel("Matel",2D) = "white"{}
        _Albedo("Albedo", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase_fullshadows

            #include "UnityCG.cginc"  
            #include "AutoLight.cginc"
            #define PI 3.14159265359

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                 float4 tangent : TANGENT;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };

            uniform float4 _LightColor0;

            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Matel;
            float4 _Matel_ST;
            uniform sampler2D _Normal;
            uniform float4 _Normal_ST;


            VertexOutput vert (appdata v)
            {
                 VertexOutput o = (VertexOutput)0;

                o.pos = UnityObjectToClipPos(v.vertex );
                o.uv0 = v.uv;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

                //世界坐标下的几个向量值，参考ShaderForge
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);

                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
                 i.normalDir = normalize(i.normalDir);

                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

                //法线左边转换
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);//法线的TBN旋转矩阵
                float4 _Normal_var = tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal));
                float3 normalLocal =_Normal_var.rgb*2-1;//之前的问题是没有Unpack，整个坐标是偏了的，参考UnityCG.cginc
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // 最终的法线

                //从matellic图上取数据
                fixed4 matelTex = tex2D(_Matel,TRANSFORM_TEX(i.uv0,_Matel));
                float matellic = matelTex.r;//unity matellic 值，是一个grayscale value ，存在 r 通道
                float roughness = 1-matelTex.a;//unity 用的是smoothness，在matellic map的alpha 通道，这里转换一下
                float f0 = matelTex.r;//HACK 这个就是先这样用……

                //预先计算一些常量
                float3 h =normalize( lightDirection+viewDirection);//h，l和v的半角向量
                float a = roughness*roughness;//alpha
                float a2 = a*a;//alpha^2

                float NoL =saturate( dot(normalDirection,lightDirection));
                float NoV =saturate(dot(normalDirection,viewDirection));
                float NoH =saturate(dot(normalDirection,h));
                float VoH =saturate(dot(viewDirection,h));

                //light & light color
                float3 attenColor = LIGHT_ATTENUATION(i) * _LightColor0.xyz;

                // sample the _Albedo texture
                fixed4 albedo = tex2D(_Albedo, i.uv0);

                //diffuse part
                float3 directDiffuse =dot( normalDirection, lightDirection ) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                float3 diffuse = (directDiffuse + indirectDiffuse) * albedo*(1-matellic);

                //specular part
                //微表面BRDF公式
                //                D(h) F(v,h) G(l,v,h)
                //f(l,v) = ---------------------------
                //                4(n·l)(n·v)

                //这个是GGX
                //                alpha^2
                //D(m) = -----------------------------------
                //                pi*((n·m)^2 *(alpha^2-1)+1)^2

                //简化 D(h)*PI/4
                float sqrtD = rcp(NoH*NoH*(a2-1)+1);
//                float D = a2*sqrtD*sqrtD/rcp(PI*4);
                float D = a2*sqrtD*sqrtD/4;//在 direct specular时，BRDF好像要乘PI，这里就直接约去。Naty Hoffman的那个文没太看懂

                //in smith model G(l,v,h) = g(l)*g(v)，这个公式是Schlick的趋近公式，参数各有不同
                //                n·v
                //G(v) = -----------------
                //                (n·v) *(1-k) +k

//                float k = a2*sqrt(2/PI);             //Schlick-Beckmann
//                float k = a2/2;                        //Schlick-GGX
                float k =(a2+1)*(a2+1)/8;        //UE4，咱们就挑NB的抄

                //简化G(l,v,h)/(n·l)(n·v)
                float GV=(NoV *(1-k) +k);
                float GL =(NoL *(1-k) +k);

                //F(v,h)
                float f = f0 +(1-f0)*pow(2,(-5.55473*VoH-6.98316)*VoH);//参数是从UE4那里抄来的，应该是Schlick公式的趋近

                fixed3 specularTerm = D*f *rcp(GV*GL);

                fixed3 specular = albedo*attenColor*(1/PI+ specularTerm)*NoL*matellic;//albedo/PI是BRDF公式的diffuse部分，没有就会偏黑
                fixed4 finalcolor = (fixed4)0;
                finalcolor.rgb =diffuse +specular;
                finalcolor.a = albedo.a;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, finalcolor);
                return finalcolor;
            }
            ENDCG
        }

        Pass
        {
            Name "FORWARD_DELTA"
            Tags {
                "LightMode"="ForwardAdd"
            }
             Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase_fullshadows

            #include "UnityCG.cginc"  
            #include "AutoLight.cginc"
            #define PI 3.14159265359

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal:NORMAL;
                 float4 tangent : TANGENT;
            };

            struct VertexOutput
            {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                LIGHTING_COORDS(5,6)
                UNITY_FOG_COORDS(7)
            };

            uniform float4 _LightColor0;

            sampler2D _Albedo;
            float4 _Albedo_ST;
            sampler2D _Matel;
            float4 _Matel_ST;
            uniform sampler2D _Normal;
            uniform float4 _Normal_ST;


            VertexOutput vert (appdata v)
            {
                 VertexOutput o = (VertexOutput)0;

                o.pos = UnityObjectToClipPos(v.vertex );
                o.uv0 = v.uv;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);

                //世界坐标下的几个向量值，参考ShaderForge
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);

                UNITY_TRANSFER_FOG(o,o.pos);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (VertexOutput i) : SV_Target
            {
                 i.normalDir = normalize(i.normalDir);


                //light dir & light color
                 float3 lightDirection  =(float3)0;
                 float3 attenColor = (float3)0;

                 if(_WorldSpaceLightPos0.w==0)
                 {
                    lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                    attenColor = LIGHT_ATTENUATION(i) * _LightColor0.xyz;
                 }
                 else
                 {
                     lightDirection =_WorldSpaceLightPos0.xyz- i.posWorld;
                     attenColor =_LightColor0.xyz /(1+length(lightDirection));
                     lightDirection = normalize(lightDirection);
                 }

//                float3 attenColor = LIGHT_ATTENUATION(i) * _LightColor0.xyz;

                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

                //法线左边转换
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.normalDir);//法线的TBN旋转矩阵
                float4 _Normal_var = tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal));
                float3 normalLocal =_Normal_var.rgb*2-1;//之前的问题是没有Unpack，整个坐标是偏了的，参考UnityCG.cginc
                float3 normalDirection = normalize(mul( normalLocal, tangentTransform )); // 最终的法线

                //从matellic图上取数据
                fixed4 matelTex = tex2D(_Matel,TRANSFORM_TEX(i.uv0,_Matel));
                float matellic = matelTex.r;//unity matellic 值，是一个grayscale value ，存在 r 通道
                float roughness = 1-matelTex.a;//unity 用的是smoothness，在matellic map的alpha 通道，这里转换一下
                float f0 = matelTex.r;//HACK 这个就是先这样用……

                //预先计算一些常量
                float3 h =normalize( lightDirection+viewDirection);//h，l和v的半角向量
                float a = roughness*roughness;//alpha
                float a2 = a*a;//alpha^2

                float NoL =saturate( dot(normalDirection,lightDirection));
                float NoV =saturate(dot(normalDirection,viewDirection));
                float NoH =saturate(dot(normalDirection,h));
                float VoH =saturate(dot(viewDirection,h));


                // sample the _Albedo texture
                fixed4 albedo = tex2D(_Albedo, i.uv0);

                //diffuse part
                float3 directDiffuse =dot( normalDirection, lightDirection ) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                float3 diffuse = (directDiffuse + indirectDiffuse) * albedo*(1-matellic);

                //specular part
                //微表面BRDF公式
                //                D(h) F(v,h) G(l,v,h)
                //f(l,v) = ---------------------------
                //                4(n·l)(n·v)

                //这个是GGX
                //                alpha^2
                //D(m) = -----------------------------------
                //                pi*((n·m)^2 *(alpha^2-1)+1)^2

                //简化 D(h)*PI/4
                float sqrtD = rcp(NoH*NoH*(a2-1)+1);
//                float D = a2*sqrtD*sqrtD/rcp(PI*4);
                float D = a2*sqrtD*sqrtD/4;//在 direct specular时，BRDF好像要乘PI，这里就直接约去。Naty Hoffman的那个文没太看懂

                //in smith model G(l,v,h) = g(l)*g(v)，这个公式是Schlick的趋近公式，参数各有不同
                //                n·v
                //G(v) = -----------------
                //                (n·v) *(1-k) +k

//                float k = a2*sqrt(2/PI);             //Schlick-Beckmann
//                float k = a2/2;                        //Schlick-GGX
                float k =(a2+1)*(a2+1)/8;        //UE4，咱们就挑NB的抄

                //简化G(l,v,h)/(n·l)(n·v)
                float GV=(NoV *(1-k) +k);
                float GL =(NoL *(1-k) +k);

                //F(v,h)
                float f = f0 +(1-f0)*pow(2,(-5.55473*VoH-6.98316)*VoH);//参数是从UE4那里抄来的，应该是Schlick公式的趋近

                fixed3 specularTerm = D*f *rcp(GV*GL);

                fixed3 specular = albedo* attenColor*(1/PI+ specularTerm)*NoL*matellic;//albedo/PI是BRDF公式的diffuse部分，没有就会偏黑
                fixed4 finalcolor = (fixed4)0;
                finalcolor.rgb =diffuse +specular;
                finalcolor.a = 0;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, finalcolor);
                return finalcolor;
            }
            ENDCG
        }
    }
}
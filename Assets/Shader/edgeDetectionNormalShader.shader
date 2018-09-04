// 利用两个pass，第一个pass顶点沿法线方向外扩，第二个pass渲染原物体，叠加生成描边效果
Shader "Hidden/edgeDetectionNormalShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutLineWidth("OutLineWidth",Range(0,1)) = 0
        _OutLineColor("OutLineColor",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _OutLineWidth;
            float4 _OutLineColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 normal:normal;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				//将法线转换到世界左边系
                float3 normal = UnityObjectToWorldNormal(v.normal);
				//再将法线转换到投影坐标系
                normal = mul(UNITY_MATRIX_VP,normal);
				//顶点坐标向法线方向增加_OutLineWidth距离
                o.vertex.xyz += normal* _OutLineWidth;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _OutLineColor;
            }
            ENDCG
        }
		//第二个pass渲染源物体，与pass0叠加，pass0外露的部分就形成了描边效果
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
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }
}
Shader "Unlit/Flash"
{
	Properties
	{
		//主纹理
		_MainTex("Main Texture", 2D) = "white" {}
		//流光纹理
		_FlashTex("Flash Texture",2D) = "white"{}
		//遮罩纹理
		_MaskTex("Mask Texture",2D) = "white"{}
		//流光颜色
		_FlashColor("Flash Color",Color) = (1,1,1,1)
		//流光强度
		_FlashIntensity("Flash Intensity", Range(0, 1)) = 0.6
		//流光区域缩放
		_FlashScale("Flash Scale", Range(0.1, 1)) = 0.5
		//水平流动速度
		_FlashSpeedX("Flash Speed X", Range(-5, 5)) = 0.5
		//垂直流动速度
		_FlashSpeedY("Flash Speed Y", Range(-5, 5)) = 0
		//主纹理凸起值
		_RaisedValue("Raised Value", Range(-0.5, 0.5)) = -0.01
		//流光能见度
		_Visibility("Visibility", Range(0, 1)) = 1
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" }
		LOD 100
		
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			float4 _MainTex_ST;
			sampler2D _MainTex;
			sampler2D _FlashTex;
			sampler2D _MaskTex;
			fixed4 _FlashColor;
			fixed _FlashIntensity;
			fixed _FlashScale;
			fixed _FlashSpeedX;
			fixed _FlashSpeedY;
			fixed _RaisedValue;			
			fixed _Visibility;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//=====================计算流光贴图的uv=====================
				//缩放流光区域
				float2 flashUV = i.uv*_FlashScale;
				//不断改变uv的x轴，让他往x轴方向移动
				flashUV.x += -_Time.y*_FlashSpeedX;
				//不断改变uv的y轴，让他往y轴方向移动
				flashUV.y += -_Time.y*_FlashSpeedY;

				//=====================计算流光贴图的可见区域=====================
				//取流光贴图的alpha值
				fixed flashAlpha = tex2D(_FlashTex, flashUV).a;
				//取遮罩贴图的alpha值
				fixed maskAlpha = tex2D(_MaskTex, i.uv).a;
				//最终在主纹理上的可见值（flashAlpha和maskAlpha任意为0则该位置不可见）
				fixed visible = flashAlpha*maskAlpha*_FlashIntensity*_Visibility;

				//=====================计算主纹理的uv=====================
				//被流光贴图覆盖的区域凸起（uv的y值增加）
				float2 mainUV = i.uv;
				mainUV.y += visible*_RaisedValue;

				//=====================最终输出=====================
				//主纹理 + 可见的流光
				fixed4 col = tex2D(_MainTex, mainUV) + visible*_FlashColor;

				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}


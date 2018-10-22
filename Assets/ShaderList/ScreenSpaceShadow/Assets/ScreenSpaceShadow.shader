Shader "Hidden/ScreenSpaceShadow"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass		//dentisy and occluder distance pass.
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragDentisyAndOccluder

			#include "UnityCG.cginc"
			#include "ScreenSpaceShadow.cginc"

			ENDCG
		}

		Pass	//blur pass.
		{
		Blend Zero SrcAlpha
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment fragBlur

		#include "UnityCG.cginc"
		#include "ScreenSpaceShadow.cginc"

		ENDCG
		}
	}
}

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Blinking GodRays" {
	Properties {
		_MainTex ("Base texture", 2D) = "white" {}                                        //用于模拟光照的透明纹理
		_FadeOutDistNear ("Near fadeout dist", float) = 10	                              //小于这个距离时 会出现淡出效果
		_FadeOutDistFar ("Far fadeout dist", float) = 10000	                              //大于这个距离时 会出现淡出效果
		_Multiplier("Color multiplier", float) = 1                                        //光照颜色的乘数  可以用来调节最后的模拟光照
		_Bias("Bias",float) = 0                                                           //模拟闪烁时  波形的偏移  可以理解为波形图像Y方向的移动量
		_TimeOnDuration("ON duration",float) = 0.5                                        //模拟闪烁时  闪烁时亮着的时间
		_TimeOffDuration("OFF duration",float) = 0.5                                      //模拟闪烁时  闪烁时暗着的时间
		_BlinkingTimeOffsScale("Blinking time offset scale (seconds)",float) = 5          //模拟闪烁时  指定闪烁在波形中开始位置
		_SizeGrowStartDist("Size grow start dist",float) = 5                              //大于这个距离时，会开始对顶点进行扩展，即从0开始增长。
		_SizeGrowEndDist("Size grow end dist",float) = 50                                 //达到这个距离时，扩张达到最大程度，即扩展程度为1。
		_MaxGrowSize("Max grow size",float) = 2.5                                         //扩张的最大大小
		_NoiseAmount("Noise amount (when zero, pulse wave is used)", Range(0,0.5)) = 0    //模拟闪烁时，噪声的程度，用于混合均匀的脉冲波和噪声波
		_Color("Color", Color) = (1,1,1,1)                                                //用于改变光照颜色。
	}
	
	SubShader{
	   
	   Tags{ "Queue" = "Transparent"  "IgnoreProjector" = "True"  "RenderType" = "Transparent" }
 
	   Blend One One    // 贴图和背景叠加   无Alpha透明通道处理 
	   Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }
 
	   CGINCLUDE
	   #include "UnityCG.cginc"
	    sampler2D _MainTex;
	
	    float   _FadeOutDistNear;
		float   _FadeOutDistFar;
		float   _Multiplier;
		float   _Bias;
		float   _TimeOnDuration;
		float   _TimeOffDuration;
		float   _BlinkingTimeOffsScale;
		float   _SizeGrowStartDist;
		float   _SizeGrowEndDist;
		float   _MaxGrowSize;
		float   _NoiseAmount;
		float4  _Color;
 
		struct v2f{
		   float4 pos : SV_POSITION;   //裁剪空间中的顶点坐标  
		   float2 uv  : TEXCOORD0;     //顶点的纹理坐标  
		   fixed4 color : TEXCOORD1;    //顶点颜色 
		};
 
		v2f vert(appdata_full  v)
		{ 
		    v2f  o;
 
		    float		time 			=  _Time.y + _BlinkingTimeOffsScale * v.color.b;		
			float3	    viewPos		    =  mul(UNITY_MATRIX_MV,v.vertex);                           //mul(x, y) 返回x、y矩阵相乘的积。
			float		dist			=  length(viewPos);                                         //length(v)  返回v向量的长度  dist  距离视角的远近
			float		nfadeout	    =  saturate(dist / _FadeOutDistNear);                       //saturate(x) 把x截取在[0, 1]之间    如果小于了_FadeOutDistNear，那么就会开始模拟淡出的效果
			float		ffadeout	    =  1 - saturate(max(dist - _FadeOutDistFar,0) * 0.2);       //0.2是模拟了淡入的速率
			float		fracTime	    =  fmod(time,_TimeOnDuration + _TimeOffDuration);           //fmod(x, y)  返回x/y的浮点余数。
			float		wave			=  smoothstep(0,_TimeOnDuration * 0.25,fracTime)  * (1 - smoothstep(_TimeOnDuration * 0.75,_TimeOnDuration,fracTime));  //smoothstep(min, max, x) 如果x的范围是[min, max]，则返回一个介于0和1之间的Hermite插值。
			float		noiseTime	    =  time *  (6.2831853f / _TimeOnDuration);
			float		noise			=  sin(noiseTime) * (0.5f * cos(noiseTime * 0.6366f + 56.7272f) + 0.5f);
			float		noiseWave	    =  _NoiseAmount * noise + (1 - _NoiseAmount);
			float		distScale	    =  min(max(dist - _SizeGrowStartDist,0) / _SizeGrowEndDist,1);
			
				
			wave = _NoiseAmount < 0.01f ? wave : noiseWave;    //这里主要是为了模拟闪烁的效果
			
			distScale = distScale * distScale * _MaxGrowSize * v.color.a;  //扩大顶点区域  这主要是为了模拟射灯的效果 ，我们在远离光源的过程中会感觉好像光照范围范围变大了
			
			wave += _Bias;
			
			ffadeout *= ffadeout;
			
			nfadeout *= nfadeout;
			nfadeout *= nfadeout;
			
			nfadeout *= ffadeout;
			
			float4	mdlPos = v.vertex;
			
			mdlPos.xyz += distScale * v.normal;
					
			o.uv		= v.texcoord.xy;
			o.pos	= UnityObjectToClipPos(mdlPos);
			o.color	= nfadeout * _Color * _Multiplier * wave;
 
		    return o;
		}
	   ENDCG
 
	   Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest		
			fixed4 frag (v2f i) : COLOR
			{		
				return tex2D (_MainTex, i.uv.xy) * i.color;
			}
			ENDCG 
	}	
 
	}
}

# WaterWaveImageEffect

# 1.简介
WaterWaveImageEffect 水波效果，常用于游戏中的屏幕点击特效，每次点击都会从点击处发出水波一样的纹络。

# 2.实现原理
我们通过一个sin值，可以把线性的输入变化成波形的输出，这样就可以模拟了水波纹的效果。知道了用什么函数，函数的输入和输出分别是什么，就是偶们下一步要考虑的问题了。我们上一步中是通过像素采样时uv坐标增加一个偏移值来达到拉伸的效果，我们就可以让这个偏移值作为这个三角函数的输出，这样，有的地方拉伸的少，有的地方拉伸的多，这样就形成了不同的拉伸效果，也就形成了一个波纹的感觉。

# 3.代码实现

    fixed4 frag(v2f_img i) : SV_Target
	{
		//DX下纹理坐标反向问题
		#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			_startPos.y = 1 - _startPos.y;
		#endif


		//计算uv到中间点的向量(向外扩，反过来就是向里缩)
		float2 dv = _startPos.xy - i.uv;

		//按照屏幕长宽比进行缩放
		dv = dv * float2(_ScreenParams.x / _ScreenParams.y, 1);

		//计算像素点距中点的距离
		float dis = sqrt(dv.x * dv.x + dv.y * dv.y);

		//用sin函数计算出波形的偏移值factor
		//dis在这里都是小于1的，所以我们需要乘以一个比较大的数，比如60，这样就有多个波峰波谷
		//sin函数是（-1，1）的值域，我们希望偏移值很小，所以这里我们缩小100倍，据说乘法比较快,so...
		float sinFactor = sin(dis * _distanceFactor + _Time.y * _timeFactor) * _totalFactor * 0.01;

		//距离当前波纹运动点的距离，如果小于waveWidth才予以保留，否则已经出了波纹范围，factor通过clamp设置为0
		float discardFactor = clamp(_waveWidth - abs(_curWaveDis - dis), 0, 1) / _waveWidth;

		//归一化
		float2 dv1 = normalize(dv);

		//计算每个像素uv的偏移值
		float2 offset = dv1  * sinFactor * discardFactor;

		//像素采样时偏移offset
		float2 uv = offset + i.uv;
		return tex2D(_MainTex, uv);	
	}

# 4.效果图
![image](https://github.com/YESshowMeCode/CollectionOfUnityShader/tree/master/Assets/ShaderList/WaterWaveImageEffect/L4VRGduUqq.gif)

# GuassianBlur
# 1.简介
GuassianBlur 高斯模糊，又叫做高斯平滑。高斯模糊主要的功能是对图片进行加权平均的过程，与均值模糊中周围像素取平均值不同，高斯模糊进行的是一个加权平均操作，每个像素的颜色值都是由其本身和相邻像素的颜色值进行加权平均得到的，越靠近像素本身，权值越高，越偏离像素的，权值越低。而这种权值符合我们比较熟悉的一种数学分布-正态分布，又叫高斯分布，所以这种模糊就是高斯模糊。
# 2.实现原理

 - 先对原始图像降低分辨率保存在一张RT中，降采样的次数。此值越大,则采样间隔越大,需要处理的像素点越少,运行速度越快。
 - 对每一个像素采样周边的像素乘上对应的高斯值，相加之和即为高斯模糊后的采样颜色。
 
# 3.代码实现

    v2f vertBlurVertical(appdata_img v) {
			v2f o;
			//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
			o.pos = UnityObjectToClipPos(v.vertex);
			//获取纹理坐标
			half2 uv = v.texcoord;
			
			//_MainTex_TexelSize.y 每一个像素的尺寸，uv数组存储了这个坐标上下各两个像素的坐标，
			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
					 
			return o;
		}
		
		//水平方向顶点着色器
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			//输出的顶点位置为模型视图投影矩阵乘以顶点位置，也就是将三维空间中的坐标投影到了二维窗口
			o.pos = UnityObjectToClipPos(v.vertex);
			//获取纹理坐标
			half2 uv = v.texcoord;
			//_MainTex_TexelSize.y 每一个像素的尺寸，uv数组存储了这个坐标上下各两个像素的坐标，
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
					 
			return o;
		}

		//片元着色器
		fixed4 fragBlur(v2f i) : SV_Target {
			//片元最终颜色受源颜色和周围片元颜色的比重
			float weight[3] = {0.4026, 0.2442, 0.0545};
			//获得源片元颜色和比重的乘积
			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];
			//获取周边片元的颜色混合，使得片元间颜色过渡更加平滑，实现模糊效果
			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it*2-1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it*2]).rgb * weight[it];
			}
			
			return fixed4(sum, 1.0);
		}

# 4.效果图
![image](https://github.com/YESshowMeCode/CollectionOfUnityShader/blob/master/Assets/ShaderList/GuassianBlur/Blur.gif)
 

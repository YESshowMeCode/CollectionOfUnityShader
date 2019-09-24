# Bloom

# 1.简介
Bloom特效是游戏中常见的一种屏幕效果，又称“全屏泛光”或者“荧光效果”，有时候也叫Glow特效，使用了Bloom特效后，画面的对比会得到增强，亮的地方曝光会增强，画面会有一种朦胧感，和HDR的效果近似，但是比HDR要节省性能很多。
# 2.实现原理

 -  先获取屏幕图像，设置一个Bloom的亮度阀值，然后对每个像素进行亮度检测，若大于某个阀值即保留原始颜色值，否则筛掉该像素置为黑色，这样我们就得到一个只包含需要泛光部分的贴图。
 - 对上一步获取的贴图，添加一个模糊，通常使用高斯模糊。
 - 将模糊后的图片和原图片做一个加权和。

# 3.代码实现

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (curShader!=null)
        {
            //申请两块RT，并且分辨率按照downSameple降低
            RenderTexture temp1 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);
            RenderTexture temp2 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0, source.format);

            //直接将场景图拷贝到低分辨率的RT上达到降分辨率的效果
            Graphics.Blit(source, temp1);


            //根据阈值提取高亮部分,使用pass0进行高亮提取
            material.SetVector("_colorThreshold", colorThreshold);
            Graphics.Blit(temp1, temp2, material, 0);

            //高斯模糊，两次模糊，横向纵向，使用pass1进行高斯模糊
            material.SetVector("_offsets", new Vector4(0, samplerScale, 0, 0));
            Graphics.Blit(temp2, temp1, material, 1);
            material.SetVector("_offsets", new Vector4(samplerScale, 0, 0, 0));
            Graphics.Blit(temp1, temp2, material, 1);

            //Bloom，将模糊后的图作为Material的Blur图参数
            material.SetTexture("_BlurTex", temp2);
            material.SetVector("_bloomColor", bloomColor);
            material.SetFloat("_bloomFactor", bloomFactor);

            //使用pass2进行景深效果计算，清晰场景图直接从source输入到shader的_MainTex中
            Graphics.Blit(source, destination, material, 2);

            //释放申请的RT
            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }
    }
    
# 4.效果图    
![image](https://github.com/YESshowMeCode/CollectionOfUnityShader/blob/master/Assets/ShaderList/BloomImage/ABFP01Nm2I.gif)
 

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GuassianBlurEffect : MonoBehaviour
{


    // 迭代计算次数，次数越高模糊程度越高
    [Range(0, 4)]
    public int iterations = 3;

    // 每次迭代模糊范围
    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int downSample = 2;

    public Shader curShader;
    private Material curMaterial;


    //获取材质，get
    Material material
    {

        get
        {
            if (curMaterial == null)
            {
                curMaterial = new Material(curShader);
                curMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return curMaterial;
        }
    }

    //当材质变为不可用或是非激活状态，调用删除此材质
    void OnDisable()
    {
        if (curMaterial)
        {
            DestroyImmediate(curMaterial);
        }
    }

    //此函数在当完成所有渲染图片后被调用，用来渲染图片后期效果
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {

        if (curShader != null)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(source, buffer0);

            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 渲染竖直通道
                Graphics.Blit(buffer0, buffer1, material, 0);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 渲染水平通道
                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            Graphics.Blit(buffer0, destination);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            //直接复制源纹理到目标纹理，不做特效处理
            Graphics.Blit(source, destination);
        }

    }

}

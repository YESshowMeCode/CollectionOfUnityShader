using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurEffect : MonoBehaviour {


    [Range(0.0f,0.95f)]
    public float blurAmount = 0.8f;

    public bool extraBlur = false;
    public Shader curShader;

    private Material curMaterial;
    private RenderTexture tempRT;


    //获取材质，get
    Material material {

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
            //创建符合要求的RenderTexture
            if (tempRT == null || tempRT.width != source.width || tempRT.height != source.height)
            {
                DestroyImmediate(tempRT);
                tempRT = new RenderTexture(source.width, source.height, 0);
                tempRT.hideFlags = HideFlags.HideAndDontSave;
                Graphics.Blit(source, tempRT);
            }

            //是否开启额外模糊效果
            if (extraBlur)
            {
                //将源纹理tempTR复制到blurBuffer,在复制到tempTR，实现将分辨率降低为原来的1/4的效果
                RenderTexture blurBuffer = RenderTexture.GetTemporary(source.width / 4, source.height / 4, 0);
                tempRT.MarkRestoreExpected();
                Graphics.Blit(tempRT, blurBuffer);
                Graphics.Blit(blurBuffer, tempRT);
                //渲染完成后，释放blurBuffer
                RenderTexture.ReleaseTemporary(blurBuffer);
            }

            //设置shader 的外部变量
            material.SetTexture("_MainTex", tempRT);
            material.SetFloat("_BlurAmount", 1 - blurAmount);

            //复制源纹理到目标纹理，加上材质效果，分两次渲染是为了判断是否添加extraBlur的模糊效果
            Graphics.Blit(source, tempRT, material);
            Graphics.Blit(tempRT, destination);
        }
        else
        {
            //直接复制源纹理到目标纹理，不做特效处理
            Graphics.Blit(source, destination);
        }

    }

}

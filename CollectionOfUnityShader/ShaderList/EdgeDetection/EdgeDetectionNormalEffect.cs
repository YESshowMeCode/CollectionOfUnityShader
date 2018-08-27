using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetectionNormalEffect : MonoBehaviour
{
    
    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;
    public Color edgeColor = Color.black;
    public Color backgroundColor = Color.white;
    public float sampleDistance = 1.0f;
    public float sensitivityDepth = 1.0f;
    public float sensitivityNormals = 1.0f;

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

    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
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
            //设置shader 的外部变量
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));
            //复制源纹理到目标纹理，加上材质效果
            Graphics.Blit(source, destination, material);
        }
        else
        {
            //直接复制源纹理到目标纹理，不做特效处理
            Graphics.Blit(source, destination);
        }

    }

}

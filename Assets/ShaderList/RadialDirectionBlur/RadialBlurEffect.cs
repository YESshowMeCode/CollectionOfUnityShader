using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RadialBlurEffect : MonoBehaviour {

    [Range(0.0f,0.05f)]
    public float blurDegree = 0.02f;
    public int sampleCount = 3;

    public Vector2 blurCenter = new Vector2(0.5f, 0.5f);

    public Shader curShader;
    private Material curMaterial;



    Material material
    {
        get
        {
            if (curMaterial == null)
            {
                curMaterial = new Material(curShader);
                curShader.hideFlags = HideFlags.HideAndDontSave;
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

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (curShader != null)
        {
            material.SetVector("_BlurCenter", blurCenter);
            material.SetFloat("_BlurDegree", blurDegree);
            material.SetInt("_SampleCount", sampleCount);
            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}

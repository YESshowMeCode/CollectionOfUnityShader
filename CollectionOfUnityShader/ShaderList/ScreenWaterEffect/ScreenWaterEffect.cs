using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ScreenWaterEffect: MonoBehaviour
{
    [Range(5, 64)]
    public float Distortion = 8.0f;
    [Range(0, 7)]
    public float SizeX = 1f;
    [Range(0, 7)]
    public float SizeY = 0.5f;
    [Range(0, 10)]
    public float DropSpeed = 3.6f;

    public Texture WaterTexture;
    public Shader curShader;
    private Material curMaterial;
    private float TimeX = 0f;

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
            TimeX += Time.deltaTime;
            if (TimeX >= 100)
                TimeX = 0;


            //设置shader 的外部变量
            material.SetFloat("_CurTime", TimeX);
            material.SetFloat("_Distortion", Distortion);
            material.SetFloat("_SizeX", SizeX);
            material.SetFloat("_SizeY", SizeY);
            material.SetFloat("_DropSpeed", DropSpeed);
            material.SetTexture("_ScreenWaterDropTex", WaterTexture);


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

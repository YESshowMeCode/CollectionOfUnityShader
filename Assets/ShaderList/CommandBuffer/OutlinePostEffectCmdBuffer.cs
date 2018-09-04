/********************************************************************
 FileName: OutlinePostEffectCmdBuffer.cs
 Description: 后处理描边效果CommandBuffer版本
 Created: 2017/06/07
 by puppet_master
*********************************************************************/
using UnityEngine;
using System.Collections;
using UnityEngine.Rendering;

public class OutlinePostEffectCmdBuffer : MonoBehaviour
{
    private RenderTexture renderTexture = null;
    private CommandBuffer commandBuffer = null;
    private Material outlineMaterial = null;
    //描边prepass shader（渲染纯色贴图的shader）
    public Shader outlineShader = null;
    public Shader outlintEffectShader;
    //采样率
    public float samplerScale = 1;
    //降采样
    public int downSample = 1;
    //迭代次数
    public int iteration = 2;
    //描边颜色
    public Color outLineColor = Color.green;
    //描边强度
    [Range(0.0f, 10.0f)]
    public float outLineStrength = 3.0f;
    //目标对象
    public GameObject targetObject = null;

    private Material curMaterial;

    Material material
    {
        get
        {
            if (curMaterial == null)
            {
                curMaterial = new Material(outlintEffectShader);
                curMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return curMaterial;
        }
    }

    void OnEnable()
    {
        if (outlineShader == null)
            return;
        if (outlineMaterial == null)
            outlineMaterial = new Material(outlineShader);
        Renderer[] renderers = targetObject.GetComponentsInChildren<Renderer>();
        if (renderTexture == null)
            renderTexture = RenderTexture.GetTemporary(Screen.width >> downSample, Screen.height >> downSample, 0);
        //创建描边prepass的command buffer
        commandBuffer = new CommandBuffer();
        commandBuffer.SetRenderTarget(renderTexture);
        commandBuffer.ClearRenderTarget(true, true, Color.black);
        foreach (Renderer r in renderers)
            commandBuffer.DrawRenderer(r, outlineMaterial);
    }

    void OnDisable()
    {
        if (renderTexture)
        {
            RenderTexture.ReleaseTemporary(renderTexture);
            renderTexture = null;
        }
        if (outlineMaterial)
        {
            DestroyImmediate(outlineMaterial);
            outlineMaterial = null;
        }
        if (commandBuffer != null)
        {
            commandBuffer.Release();
            commandBuffer = null;
        }

    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material && renderTexture && outlineMaterial && commandBuffer != null)
        {
            //通过Command Buffer可以设置自定义材质的颜色
            outlineMaterial.SetColor("_OutlineCol", outLineColor);
            //直接通过Graphic执行Command Buffer
            Graphics.ExecuteCommandBuffer(commandBuffer);

            //对RT进行Blur处理
            RenderTexture temp1 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0);
            RenderTexture temp2 = RenderTexture.GetTemporary(source.width >> downSample, source.height >> downSample, 0);

            //高斯模糊，两次模糊，横向纵向，使用pass0进行高斯模糊
            material.SetVector("_offsets", new Vector4(0, samplerScale, 0, 0));
            Graphics.Blit(renderTexture, temp1, material, 0);
            material.SetVector("_offsets", new Vector4(samplerScale, 0, 0, 0));
            Graphics.Blit(temp1, temp2, material, 0);

            //如果有叠加再进行迭代模糊处理
            for (int i = 0; i < iteration; i++)
            {
                material.SetVector("_offsets", new Vector4(0, samplerScale, 0, 0));
                Graphics.Blit(temp2, temp1, material, 0);
                material.SetVector("_offsets", new Vector4(samplerScale, 0, 0, 0));
                Graphics.Blit(temp1, temp2, material, 0);
            }

            //用模糊图和原始图计算出轮廓图
            material.SetTexture("_BlurTex", temp2);
            Graphics.Blit(renderTexture, temp1, material, 1);

            //轮廓图和场景图叠加
            material.SetTexture("_BlurTex", temp1);
            material.SetFloat("_OutlineStrength", outLineStrength);
            Graphics.Blit(source, destination, material, 2);

            RenderTexture.ReleaseTemporary(temp1);
            RenderTexture.ReleaseTemporary(temp2);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }


}

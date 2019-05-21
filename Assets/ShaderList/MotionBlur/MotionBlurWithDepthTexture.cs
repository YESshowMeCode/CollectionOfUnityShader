using UnityEngine;
using System.Collections;

public class MotionBlurWithDepthTexture : MonoBehaviour
{

    public Shader motionBlurShader;
    private Material curMaterial;

    public Material material
    {
        get
        {
            if (curMaterial == null)
            {
                curMaterial = new Material(motionBlurShader);
                curMaterial.hideFlags = HideFlags.HideAndDontSave;
            
            }
            return curMaterial;
        }
    }

    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    [Range(0.0f, 1.0f)]
    public float blurSize = 0.5f;

    private Matrix4x4 previousViewProjectionMatrix;

    void OnEnable()
    {
        //设置的相机的状态
        camera.depthTextureMode |= DepthTextureMode.Depth;
        //
        previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_BlurSize", blurSize);

            material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
            //相机的投影矩阵和视角矩阵，他们相乘后取逆，得到当前帧的视角*投影矩阵的逆矩阵
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);

            //将取逆前的矩阵存储在previousViewProjectionMatrix，以便下一帧使用
            previousViewProjectionMatrix = currentViewProjectionMatrix;

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}

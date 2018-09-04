using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VortexImageEffect : MonoBehaviour
{


    public Vector2 radius = new Vector2(0.3F, 0.3F);
    public float angle = 0;
    public Vector2 center = new Vector2(0.5F, 0.5F);

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
        //针对不同平台处理
        bool invertY = source.texelSize.y < 0.0f;
        if (invertY)
        {
            center.y = 1.0f - center.y;
            angle = -angle;
        }


        angle += Time.deltaTime * 200;

        if (curShader != null)
        {
            Matrix4x4 rotationMatrix = Matrix4x4.TRS(Vector3.zero, Quaternion.Euler(0, 0, angle), Vector3.one);

            //设置shader 的外部变量
            material.SetMatrix("_RotationMatrix", rotationMatrix);
            material.SetVector("_CenterRadius", new Vector4(center.x, center.y, radius.x, radius.y));
            material.SetFloat("_Angle", angle * Mathf.Deg2Rad);
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

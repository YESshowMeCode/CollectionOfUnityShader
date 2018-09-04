using UnityEngine;
using System.Collections;

public class BloomImageEffect: MonoBehaviour
{
    //分辨率
    public int downSample = 1;
    //采样率
    public int samplerScale = 1;
    //高亮部分提取阈值
    public Color colorThreshold = Color.gray;
    //Bloom泛光颜色
    public Color bloomColor = Color.white;
    //Bloom权值
    [Range(0.0f, 1.0f)]
    public float bloomFactor = 0.5f;
    public Shader curShader;
    private Material curMaterial;

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
}

using UnityEngine;
using System.Collections;


public class RainEffect : MonoBehaviour
{
    public float maxDistance = 100.0f;
    public Texture2D[] rippleTextures;
    public Texture2D waveTexture;
    public Cubemap reflectionTexture;
    public float rippleTextureScale = 0.3f;
    public float rippleFrequency = 20.0f;
    [Range(0.5f, 2)]
    public float rippleIntensity = 1.25f;
    [Range(0, 1)]
    public float rippleBlendFactor = 0.9f;

    public Vector4 waveForce = new Vector4(1.0f, 1.0f, -1.0f, -1.0f);
    public float waveIntensity = 0.2f;
    public float waveTextureScale = 0.15f;

    public float rainIntensity = 1.0f;

    public Shader curShader;
    private Material curMaterial;
    private int m_CurRippleTextureIndex = 0;
    private float m_LastTime = 0;


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



    void Update()
    {


        float f = rippleFrequency * (rainIntensity * 0.5f + 0.5f);
        if (Time.time - m_LastTime > 1.0f / f)
        {
            m_LastTime = Time.time;
            ++m_CurRippleTextureIndex;
            if (m_CurRippleTextureIndex >= rippleTextures.Length)
                m_CurRippleTextureIndex = 0;
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (curShader == null)
        {
            Graphics.Blit(src, dest);
            return;
        }

        material.SetMatrix("_CamToWorld", GetComponent<Camera>().cameraToWorldMatrix);
        material.SetFloat("_MaxDistance", maxDistance);
        material.SetTexture("_RippleTex", rippleTextures[m_CurRippleTextureIndex]);
        material.SetTexture("_WaveTex", waveTexture);
        material.SetTexture("_ReflectionTex", reflectionTexture);
        material.SetFloat("_RippleTexScale", rippleTextureScale);
        material.SetFloat("_RippleFrequency", rippleFrequency);
        material.SetFloat("_RippleIntensity", rippleIntensity);
        material.SetFloat("_RippleBlendFactor", rippleBlendFactor);
        material.SetFloat("_RainIntensity", rainIntensity);
        material.SetVector("_WaveForce", waveForce);
        material.SetFloat("_WaveIntensity", waveIntensity);
        material.SetFloat("_WaveTexScale", waveTextureScale);

        Graphics.Blit(src, dest, material);
    }

}


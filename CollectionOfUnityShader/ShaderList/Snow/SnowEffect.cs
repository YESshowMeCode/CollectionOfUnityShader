using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class SnowEffect : MonoBehaviour
{

    public Texture2D SnowTexture;

    public Color SnowColor = Color.white;

    public float SnowTextureScale = 0.1f;

    [Range(0, 1)]
    public float BottomThreshold = 0f;
    [Range(0, 1)]
    public float TopThreshold = 1f;

    public Shader curShader;
    private Material _material;

    void OnEnable()
    {
        _material = new Material(curShader);
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        // set shader properties
        _material.SetMatrix("_CamToWorld", GetComponent<Camera>().cameraToWorldMatrix);
        _material.SetColor("_SnowColor", SnowColor);
        _material.SetFloat("_BottomThreshold", BottomThreshold);
        _material.SetFloat("_TopThreshold", TopThreshold);
        _material.SetTexture("_SnowTex", SnowTexture);
        _material.SetFloat("_SnowTexScale", SnowTextureScale);

        // execute the shader on input texture (src) and write to output (dest)
        Graphics.Blit(src, dest, _material);
    }
}

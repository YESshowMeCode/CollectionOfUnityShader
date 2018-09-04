using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MaskEffect : MonoBehaviour {

    [Range(0.0f,1.0f)]
    public float radius = 0.5f;

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



    void onDisable()
    {
        DestroyImmediate(curMaterial);
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        material.SetFloat("_Radius", radius);
        Graphics.Blit(source, destination, material);
    }
}

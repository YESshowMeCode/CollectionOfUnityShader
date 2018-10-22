using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[RequireComponent(typeof(Light))]
public class ScreenSpaceShadow : MonoBehaviour {

    public Shader sssShader;

    private Light dlight { get {
            return GetComponent<Light>();
        } }

    private Material _mat;
    private Material mat {
        get {
            return _mat ?? (_mat = new Material(sssShader));
        }
    }
    
    private CommandBuffer cmdBuf;   //executed before shadow map.
    private CommandBuffer afterCmdBuf;
    private RenderTexture tempScreenSpaceShadow;
    private void UpdateCommandBuffers() {
        if (tempScreenSpaceShadow != null)
            DestroyImmediate(tempScreenSpaceShadow);
        tempScreenSpaceShadow = new RenderTexture(Screen.width, Screen.height, 0,RenderTextureFormat.RGFloat);
        tempScreenSpaceShadow.filterMode = FilterMode.Point;

        cmdBuf = new CommandBuffer();
        cmdBuf.Blit(null, tempScreenSpaceShadow, mat, 0);  
        afterCmdBuf = new CommandBuffer();
        afterCmdBuf.Blit(tempScreenSpaceShadow, BuiltinRenderTextureType.CurrentActive, mat, 1);
    }

    //doesn't work for multi camera.
    //I can't find a way to make it compatitable with multi camera.
    //if you know how to access correct view matrix inside shader(Currently UNITY_MATRIX_V doesn't work), you can remove this, and multi camera will work.
    private void Update() {
        mat.SetMatrix("_WorldToView", Camera.main.worldToCameraMatrix);
    }

    private void OnEnable() {
        UpdateCommandBuffers();
        dlight.AddCommandBuffer(LightEvent.BeforeScreenspaceMask, cmdBuf);
        dlight.AddCommandBuffer(LightEvent.AfterScreenspaceMask, afterCmdBuf);
    }

    private void OnDisable() {
        dlight.RemoveCommandBuffer(LightEvent.BeforeScreenspaceMask, cmdBuf);
        dlight.RemoveCommandBuffer(LightEvent.AfterScreenspaceMask, afterCmdBuf);
    }
}

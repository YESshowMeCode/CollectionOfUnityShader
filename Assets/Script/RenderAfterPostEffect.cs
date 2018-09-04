//在后处理之后渲染
//by: puppet_master
//2017.6.5

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
[ExecuteInEditMode]

public class RenderAfterPostEffect : MonoBehaviour
{
    private CommandBuffer commandBuffer = null;
    private Renderer targetRenderer = null;

    void OnEnable()
    {
        targetRenderer = this.GetComponentInChildren<Renderer>();
        if (targetRenderer)
        {
            commandBuffer = new CommandBuffer();
            commandBuffer.DrawRenderer(targetRenderer, targetRenderer.sharedMaterial);
            //直接加入相机的CommandBuffer事件队列中,
            Camera.main.AddCommandBuffer(CameraEvent.AfterImageEffects, commandBuffer);
            targetRenderer.enabled = false;
        }
    }

    void OnDisable()
    {
        if (targetRenderer)
        {
            //移除事件，清理资源
            Camera.main.RemoveCommandBuffer(CameraEvent.AfterImageEffects, commandBuffer);
            commandBuffer.Clear();
            targetRenderer.enabled = true;
        }
    }
}

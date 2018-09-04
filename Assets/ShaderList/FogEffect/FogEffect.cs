using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogEffect : MonoBehaviour
{


    [Tooltip("Apply distance-based fog?")]
    public bool distanceFog = true;
    [Tooltip("Exclude far plane pixels from distance-based fog? (Skybox or clear color)")]
    public bool excludeFarPixels = true;
    [Tooltip("Distance fog is based on radial distance from camera when checked")]
    public bool useRadialDistance = false;
    [Tooltip("Apply height-based fog?")]
    public bool heightFog = true;
    [Tooltip("Fog top Y coordinate")]
    public float height = 1.0f;
    [Range(0.001f, 10.0f)]
    public float heightDensity = 2.0f;
    [Tooltip("Push fog away from the camera by this amount")]
    public float startDistance = 0.0f;

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

        if (curShader != null)
        {
            if (!distanceFog && !heightFog)
            {
                Graphics.Blit(source, destination);
                return;
            }

            Camera cam = GetComponent<Camera>();
            Transform camtr = cam.transform;

            Vector3[] frustumCorners = new Vector3[4];
            cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1), cam.farClipPlane, cam.stereoActiveEye, frustumCorners);
            var bottomLeft = camtr.TransformVector(frustumCorners[0]);
            var topLeft = camtr.TransformVector(frustumCorners[1]);
            var topRight = camtr.TransformVector(frustumCorners[2]);
            var bottomRight = camtr.TransformVector(frustumCorners[3]);

            Matrix4x4 frustumCornersArray = Matrix4x4.identity;
            frustumCornersArray.SetRow(0, bottomLeft);
            frustumCornersArray.SetRow(1, bottomRight);
            frustumCornersArray.SetRow(2, topLeft);
            frustumCornersArray.SetRow(3, topRight);

            var camPos = camtr.position;
            float FdotC = camPos.y - height;
            float paramK = (FdotC <= 0.0f ? 1.0f : 0.0f);
            float excludeDepth = (excludeFarPixels ? 1.0f : 2.0f);
            material.SetMatrix("_FrustumCornersWS", frustumCornersArray);
            material.SetVector("_CameraWS", camPos);
            material.SetVector("_HeightParams", new Vector4(height, FdotC, paramK, heightDensity * 0.5f));
            material.SetVector("_DistanceParams", new Vector4(-Mathf.Max(startDistance, 0.0f), excludeDepth, 0, 0));

            var sceneMode = RenderSettings.fogMode;
            var sceneDensity = RenderSettings.fogDensity;
            var sceneStart = RenderSettings.fogStartDistance;
            var sceneEnd = RenderSettings.fogEndDistance;
            Vector4 sceneParams;
            bool linear = (sceneMode == FogMode.Linear);
            float diff = linear ? sceneEnd - sceneStart : 0.0f;
            float invDiff = Mathf.Abs(diff) > 0.0001f ? 1.0f / diff : 0.0f;
            sceneParams.x = sceneDensity * 1.2011224087f; // density / sqrt(ln(2)), used by Exp2 fog mode
            sceneParams.y = sceneDensity * 1.4426950408f; // density / ln(2), used by Exp fog mode
            sceneParams.z = linear ? -invDiff : 0.0f;
            sceneParams.w = linear ? sceneEnd * invDiff : 0.0f;
            material.SetVector("_SceneFogParams", sceneParams);
            material.SetVector("_SceneFogMode", new Vector4((int)sceneMode, useRadialDistance ? 1 : 0, 0, 0));

            int pass = 0;
            if (distanceFog && heightFog)
                pass = 0; // distance + height
            else if (distanceFog)
                pass = 1; // distance only
            else
                pass = 2; // height only
            Graphics.Blit(source, destination, material, pass);
        }
        else
        {
            //直接复制源纹理到目标纹理，不做特效处理
            Graphics.Blit(source, destination);
        }

    }

}

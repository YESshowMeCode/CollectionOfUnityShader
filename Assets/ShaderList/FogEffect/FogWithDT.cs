using UnityEngine;
using System.Collections;

public class FogWithDT : PostEffectsBase
{

    public Shader fogShader;
    private Material fogMaterial = null;

    //获取材质球
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    //获取相机
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

    //获取相机参数
    private Transform myCameraTransform;
    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = camera.transform;
            }

            return myCameraTransform;
        }
    }

    //控制雾浓度
    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;
    //雾颜色
    public Color fogColor = Color.white;
    //雾起始高度
    public float fogStart = 0.0f;
    //雾终止高度
    public float fogEnd = 2.0f;

    void OnEnable()
    {
        //设置相机状态
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            Matrix4x4 frustumCorners = Matrix4x4.identity;

            //计算近剪裁平面的四个角对应的向量，并把它们储存在矩阵类型的变量frustumCorners中
            //jin近剪裁平面的4个角的特定向量的插值可以求得interpolatedRay,linearDepth*interpolatedRay可以计算得到该像素相对于摄像机的偏移量；
            //linearDepth是由深度纹理得到的线性深度值，interpolatedRay是由顶点着色器输出并插值后得到的射线

            float fov = camera.fieldOfView;//相机竖直方向的视角范围
            float near = camera.nearClipPlane;//近剪裁平面距离
            float aspect = camera.aspect;//纵横比

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);//tan三角函数，直角下边near*tan（视角范围fov/2）=垂直竖边
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;//近剪裁平面中心到最右边的垂直距离,cameraTransform.right向右方向单位向量
            Vector3 toTop = cameraTransform.up * halfHeight;//近剪裁平面中心到最上边的垂直距离

            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;//向量加减转换
            float scale = topLeft.magnitude / near;//由于4个点相互对称，其他三个向量的模和topLeft相等，因此使用一个因子可求得比例值
            topLeft.Normalize();
            topLeft *= scale;//求得四个向量

            Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
            bottomRight.Normalize();
            bottomRight *= scale;

            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            material.SetMatrix("_FrustumCornersRay", frustumCorners);

            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}

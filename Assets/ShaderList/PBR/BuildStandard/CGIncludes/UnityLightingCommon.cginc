// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#ifndef UNITY_LIGHTING_COMMON_INCLUDED
#define UNITY_LIGHTING_COMMON_INCLUDED

fixed4 _LightColor0;
fixed4 _SpecColor;

struct UnityLight
{
    half3 color;
    half3 dir;
    half  ndotl; // Deprecated: Ndotl is now calculated on the fly and is no longer stored. Do not used it.
};

// 漫反射颜色和镜面反射颜色
struct UnityIndirect
{
    half3 diffuse;
    half3 specular;
};

// 记录了一个记录灯光信息的UnityLight对象和一个记录间接光照信息的UnityIndirect对象。
struct UnityGI
{
    UnityLight light;
    UnityIndirect indirect;
};

// 包括一个UnityLight对象，以及片段的世界空间坐标
// 世界空间视线，灯光的衰减，环境色。光照贴图的UV，出于精度考虑使用float来避免光照贴图采样精度丢失。
// xy分量是静态光照贴图UV，zw分量是动态光照贴图UV。之后是用于反射探针盒投影，反射探针混合，以及HDR天空的变量，在FragmentGI函数中会用到。
struct UnityGIInput
{
    UnityLight light; // pixel light, sent from the engine

    float3 worldPos;
    half3 worldViewDir;
    half atten;
    half3 ambient;

    // interpolated lightmap UVs are passed as full float precision data to fragment shaders
    // so lightmapUV (which is used as a tmp inside of lightmap fragment shaders) should
    // also be full float precision to avoid data loss before sampling a texture.
    float4 lightmapUV; // .xy = static lightmap UV, .zw = dynamic lightmap UV

    // UNITY_SPECCUBE_BOX_PROJECTION&UNITY_SPECCUBE_BLENDING——UnityStandardConfig.cginc。
    // TierSettings来控制的，当设置为启用时，会自动生成相关的宏定义。具体使用查看Unity Scripting API。
    // UNITY_SPECCUBE_BOX_PROJECTION: TierSettings.reflectionProbeBoxProjection——指定反射探针盒投影是否启用。
    // UNITY_SPECCUBE_BLENDING: TierSettings.reflectionProbeBlending——指定反射探针混合是否启用。
    #if defined(UNITY_SPECCUBE_BLENDING) || defined(UNITY_SPECCUBE_BOX_PROJECTION) || defined(UNITY_ENABLE_REFLECTION_BUFFERS)
    float4 boxMin[2];
    #endif
    #ifdef UNITY_SPECCUBE_BOX_PROJECTION
    float4 boxMax[2];
    float4 probePosition[2];
    #endif
    // HDR cubemap properties, use to decompress HDR texture
    float4 probeHDR[2];
};

#endif

#ifndef UNIVERSAL_PIPELINE_ZANYAHLSL_INCLUDED
#define UNIVERSAL_PIPELINE_ZANYAHLSL_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
// #define SHADERQUALITY 2



half3 dotMap(half PosWStime, half PosWScale, half dotBright, float positionWSX, float positionWSZ, half3 texColor)
{
    float Uset = step(frac(positionWSX* PosWStime), PosWScale);
    float Vset = step(frac(positionWSZ * PosWStime), PosWScale);
    float UVset = saturate(Uset + Vset) + dotBright;
    half3 dotColor = (texColor.rgb * saturate(UVset));
    return dotColor;
}

float CheapContrast (float Input, float HeightContract)
{
    float o = saturate(lerp(-HeightContract, HeightContract+1, Input));
    return o;
}


half3 LightingCustum(float3 normalWS, Light mainLight)//, uint meshRenderingLayers)
{ 
    //灯光剔除判断
    //if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers)) // 1111 1111 & ? != 0
    //{
    half3 attenuatedLightColor = mainLight.color * (mainLight.distanceAttenuation * mainLight.shadowAttenuation);//灯光颜色和强度
    half NdotL = saturate(dot(normalWS, mainLight.direction));
    half3 finalColor = attenuatedLightColor * NdotL;
    //}
    return finalColor;
}
#endif
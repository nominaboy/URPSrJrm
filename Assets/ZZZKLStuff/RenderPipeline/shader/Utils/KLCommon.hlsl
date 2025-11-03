#ifndef KL_COMMON_INCLUDED
#define KL_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

#include "KLUtils.hlsl"





///////////////////////////////////////////////////////////////////////////////
//                          Lighting Data                                    //
///////////////////////////////////////////////////////////////////////////////
struct KLLightingData
{
    half3 lightColor;
    half3 HalfDir;
    half3 lightDir;
    half NdotL;
    half NdotLClamp;
    half HalfLambert;
    half NdotVClamp;
    half NdotHClamp;
    half LdotHClamp;
    half VdotHClamp;
    half attenuation;
    half NDotVCPow4;
};


///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////


half LightingLambert(KLLightingData lightingData, half useHalfLambert)
{
    half lambert = lerp(lightingData.NdotLClamp, lightingData.HalfLambert, useHalfLambert);
    lambert = saturate(lambert) * lightingData.attenuation;
    return lambert;
}



#endif
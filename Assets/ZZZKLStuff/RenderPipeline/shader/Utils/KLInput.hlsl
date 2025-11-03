#ifndef KL_INPUT_INCLUDED
#define KL_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "KLSurfaceData.hlsl"


CBUFFER_START(UnityPerMaterial)
    half4 _BaseMap_ST;
    half4 _BaseColor;
    half4 _EmissionColor;

    half4 _LightColor;
    half4 _DarkColor;
    half4 _SpecularColor;
    half4 _RimColor;
    
    half _Metallic;
    half _Roughness;
    half _AlphatestThreshold;
    half _ClearCoatMask;
    half _ClearCoatSmoothness;
    half _UseHalfLambert;
    half _CelThreshold;
    half _CelSmoothing;
    half _CelBandSoftness;
    half _CelBands;
    half _RampUOffset;
    half _RampVOffset;
    half _SDFSoftness;
    half _SDFReversal;

    half _StylizedSpecularSize;
    half _StylizedSpecularSoftness;
    half _StylizedSpecularAlbedoWeight;
    half _Shininess;
    half _AngelRingThreshold;
    half _SpecularIntensity;

    half _EmiIntensity;
    half _EmiFlashFrequency;

    half _RimDirectionLightContribution;
    half _RimThreshold;
    half _RimSoftness;
    half _RimPow;

    // float _DistanceScale;
    // float _DistanceSensitivity;
    half4 _Tint;
    //half _FogHeight;
    //half4 _FogColor;
CBUFFER_END

//uniform float2 _RoleScreenPos;

SamplerState kl_linear_clamp_sampler;
//SamplerState kl_linear_repeat_sampler;


#if _EMISSION_ON
    TEXTURE2D(_EmissionTex);
#endif
#if _PBRFUNCTEX_ON
    TEXTURE2D(_PBRFuncTex);
#endif
#if _DIFFUSE_RAMPSHADING
    TEXTURE2D(_DiffuseRampMap);
#endif
#if _DIFFUSE_SDFFACE
    TEXTURE2D(_SDFFaceTex);
#endif
#if _SPECULAR_ANGELRING
    TEXTURE2D(_AngelRingTex);
#endif

half3 EmissionColor(half4 emissionTex, half emiIntensity)
{
    return emissionTex.rgb * emissionTex.a * emiIntensity;
}

inline void InitializeKLSurfaceData(float2 uv, out KLSurfaceData outSurfaceData)
{
    outSurfaceData = (KLSurfaceData) 0;
    half4 albedoAlpha = SAMPLE_TEXTURE2D(_BaseMap, kl_linear_clamp_sampler, uv);
    half4 pbrFuncTex = half4(1, 1, 0, 1);
    #if _PBRFUNCTEX_ON
        pbrFuncTex = SAMPLE_TEXTURE2D(_PBRFuncTex, kl_linear_clamp_sampler, uv);
    #endif

    #if _ALPHATEST_ON
        outSurfaceData.alpha = albedoAlpha.a;
    #else
        outSurfaceData.alpha = _BaseColor.a;
    #endif

    outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;
    //outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
    outSurfaceData.smoothness = saturate(1 - _Roughness * pbrFuncTex.g);
    outSurfaceData.metallic = _Metallic * pbrFuncTex.r;
    //outSurfaceData.occlusion = LerpWhiteTo(pbrFuncTex.b, _OcclusionStrength);
    outSurfaceData.occlusion = 1; // no AO in current project
    outSurfaceData.rampMapID = pbrFuncTex.b;
    outSurfaceData.clearCoatMask = _ClearCoatMask;
    outSurfaceData.clearCoatSmoothness = _ClearCoatSmoothness;
    outSurfaceData.specularIntensity = _SpecularIntensity;
    
    #if _EMISSION_ON
        half4 emissionTex = SAMPLE_TEXTURE2D(_EmissionTex, kl_linear_clamp_sampler, uv).rgba;
        outSurfaceData.emission = EmissionColor(emissionTex, _EmiIntensity);
        outSurfaceData.emission *= abs(-2 * frac(_Time.y * _EmiFlashFrequency) + 1);
    #else
        outSurfaceData.emission = half3(0, 0, 0);
    #endif
    
    #if _ALPHATEST_ON
        clip(outSurfaceData.alpha - _AlphatestThreshold);
    #endif
}




#endif
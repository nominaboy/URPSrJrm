#ifndef KL_LIGHTING_INCLUDED
#define KL_LIGHTING_INCLUDED

#include "KLBSDF.hlsl"


///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////

inline half3 CelShadingDiffuse(half lambert, half cellThreshold, half cellSmooth, half3 lightColor, half3 darkColor)
{
    half3 diffuse = 0;
    lambert = saturate(1 + (lambert - cellThreshold - cellSmooth) / max(cellSmooth, 0.001));
    diffuse = lerp(darkColor.rgb, lightColor.rgb, lambert);
    return diffuse;
}


inline half3 RampShadingDiffuse(half lambert, half uOffset, half vOffset, half rampIndex, TEXTURE2D_PARAM(rampMap, sampler_rampMap))
{
    half3 diffuse = 0;
    float2 uv = float2(saturate(lambert + uOffset), saturate(rampIndex + vOffset));
    diffuse = SAMPLE_TEXTURE2D(rampMap, sampler_rampMap, uv).rgb;
    return diffuse;
}


inline half3 CelBandsShadingDiffuse(half lambert, half cellThreshold, half cellBandSoftness, half cellBands, half3 lightColor, half3 darkColor)
{
    half3 diffuse = 0;
    lambert = saturate(1 + (lambert - cellThreshold - cellBandSoftness) / max(cellBandSoftness, 0.001));

    lambert = saturate((LinearStep(0.5 - cellBandSoftness, 0.5 + cellBandSoftness, frac(lambert * cellBands)) + floor(lambert * cellBands)) / cellBands);

    diffuse = lerp(darkColor.rgb, lightColor.rgb, lambert);
    return diffuse;
}

inline half3 SDFFaceDiffuse(float2 uv, KLLightingData lightingData, half softness, half3 lightColor, half3 darkColor, half reversal, 
    TEXTURE2D_PARAM(_SDFFaceTex, sampler_SDFFaceTex))
{
    half2 L = normalize(lightingData.lightDir.xz);
    half2 R = normalize(float2(UNITY_MATRIX_M[0][0], UNITY_MATRIX_M[2][0]));
    half2 F = normalize(float2(UNITY_MATRIX_M[0][2], UNITY_MATRIX_M[2][2]));
    //half2 R = normalize(unity_ObjectToWorld._11_31);
    //half2 F = normalize(unity_ObjectToWorld._13_33);

    half FdotLRev = 1 - (dot(F, L) * 0.5 + 0.5);
    half RdotL = dot(R, L) * lerp(1, -1, reversal);
    half sign = 2 * step(RdotL, 0) - 1;

    half SDFMap = SAMPLE_TEXTURE2D(_SDFFaceTex, sampler_SDFFaceTex, uv * float2(sign, 1)).a;
    // No NDotL Coe, so we should add light attenuation
    half diffuseRadiance = smoothstep(-softness * 0.1, softness * 0.1, (SDFMap - FdotLRev)) * lightingData.attenuation;
    half3 diffuseColor = lerp(darkColor.rgb, lightColor.rgb, diffuseRadiance);
    return diffuseColor;
}









half GGXDirectBRDFSpecular(BRDFData brdfData, half3 LoH, half3 NoH)
{
    float d = NoH.x * NoH.x * brdfData.roughness2MinusOne + 1.00001f;
    half LoH2 = LoH.x * LoH.x;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles

    return specularTerm;
}

half3 StylizedSpecular(half3 albedo, half ndothClamp, half specularSize, half specularSoftness, half albedoWeight)
{
    half specSize = 1 - (specularSize * specularSize);
    half ndothStylized = (ndothClamp - specSize * specSize) / (1 - specSize);
    half3 specular = LinearStep(0, specularSoftness, ndothStylized);
    specular = lerp(specular, albedo * specular, albedoWeight);
    return specular;
}


half BlinnPhongSpecular(half shininess, half ndoth)
{
    half phongSmoothness = exp2(10 * shininess + 1);
    half normalize = (phongSmoothness + 7) * INV_PI8;
    half specular = max(pow(ndoth, phongSmoothness) * normalize, 0.001);
    return specular;
}

half AngelRingSpecular(float2 uv, half ndotvClamp, half angelRingThreshold, TEXTURE2D_PARAM(_AngelRingTex, sampler_AngelRingTex))
{
    half NDotVStep = step(angelRingThreshold, ndotvClamp);
    half angelRing = SAMPLE_TEXTURE2D(_AngelRingTex, sampler_AngelRingTex, uv).a;
    half specular = angelRing * NDotVStep;
    return specular;
}


















half3 KLGlossyEnvironmentReflection(half3 reflectVector, half3 positionWS, half2 normalizedScreenSpaceUV, half perceptualRoughness, half occlusion)
{
    // Simplified Version of Inspecular
    half3 irradiance;
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);
    irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
    return irradiance * occlusion;
}





















///////////////////////////////////////////////////////////////////////////////
//                         Shading Function                                  //
///////////////////////////////////////////////////////////////////////////////



void PreInitializeKLInputData(Varyings input, out InputData inputData)
{
    inputData = (InputData) 0;
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    inputData.positionWS = input.positionWS;
    inputData.normalWS = SafeNormalize(input.normalWS);
    inputData.viewDirectionWS = viewDirWS;
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

    #if defined(DEBUG_DISPLAY)
        #if defined(LIGHTMAP_ON)
            inputData.staticLightmapUV = input.staticLightmapUV;
        #else
            inputData.vertexSH = input.vertexSH;
        #endif
    #endif
}

void InitializeKLInputData(Varyings input, inout InputData inputData)
{
    //inputData.bakedGI = SampleLightmap(input.staticLightmapUV, inputData.normalWS);
    inputData.bakedGI = SAMPLE_GI(input.staticLightmapUV, input.vertexSH, inputData.normalWS);
}

KLLightingData InitializeKLLightingData(Light mainLight, Varyings input, half3 normalWS, half3 viewDirectionWS)
{
    KLLightingData lightingData;
    lightingData.lightColor = mainLight.color;
    lightingData.NdotL = dot(normalWS, mainLight.direction.xyz);
    lightingData.NdotLClamp = saturate(lightingData.NdotL);
    lightingData.HalfLambert = lightingData.NdotL * 0.5 + 0.5;
    half3 halfDir = SafeNormalize(mainLight.direction + viewDirectionWS);
    lightingData.LdotHClamp = saturate(dot(mainLight.direction.xyz, halfDir.xyz));
    lightingData.NdotHClamp = saturate(dot(normalWS.xyz, halfDir.xyz));
    lightingData.NdotVClamp = saturate(dot(normalWS.xyz, viewDirectionWS.xyz));
    lightingData.NDotVCPow4 = Pow4(1 - lightingData.NdotVClamp);
    lightingData.HalfDir = halfDir;
    lightingData.lightDir = mainLight.direction;
    lightingData.attenuation = mainLight.shadowAttenuation * mainLight.distanceAttenuation;
    return lightingData;
}




half3 KLDiffuseLighting(BRDFData brdfData, KLSurfaceData surfaceData, half lambert, KLLightingData lightingData, float2 uv)
{
    half3 diffuse = 0;
    #if _DIFFUSE_OFF
        diffuse = 0;
    #elif _DIFFUSE_CELSHADING
        diffuse = CelShadingDiffuse(lambert, _CelThreshold, _CelSmoothing, _LightColor.rgb, _DarkColor.rgb);
    #elif _DIFFUSE_LAMBERTIAN
        diffuse = lerp(_DarkColor.rgb, _LightColor.rgb, lambert);
    #elif _DIFFUSE_RAMPSHADING
        diffuse = RampShadingDiffuse(lambert, _RampUOffset, _RampVOffset, surfaceData.rampMapID, TEXTURE2D_ARGS(_DiffuseRampMap, kl_linear_clamp_sampler));
    #elif _DIFFUSE_CELBANDSHADING
        diffuse = CelBandsShadingDiffuse(lambert, _CelThreshold, _CelBandSoftness, _CelBands,  _LightColor.rgb, _DarkColor.rgb);
    #elif _DIFFUSE_SDFFACE
        diffuse = SDFFaceDiffuse(uv, lightingData, _SDFSoftness, _LightColor.rgb, _DarkColor.rgb, _SDFReversal, TEXTURE2D_ARGS(_SDFFaceTex, kl_linear_clamp_sampler));
    #endif
    diffuse *= brdfData.diffuse;
    return diffuse;
}

half3 KLSpecularLighting(BRDFData brdfData, KLSurfaceData surfData, Varyings input, InputData inputData, half3 albedo,
                          half lambert, KLLightingData lightingData, float2 uv)
{
    half3 specular = 0;
    #if _SPECULAR_GGX
        specular = GGXDirectBRDFSpecular(brdfData, lightingData.LdotHClamp, lightingData.NdotHClamp) * surfData.specularIntensity;
    #elif _SPECULAR_STYLIZED
        specular = StylizedSpecular(albedo, lightingData.NdotHClamp, _StylizedSpecularSize, _StylizedSpecularSoftness, _StylizedSpecularAlbedoWeight) * surfData.specularIntensity;
    #elif _SPECULAR_BLINNPHONG
        specular = BlinnPhongSpecular(_Shininess, lightingData.NdotHClamp) * surfData.specularIntensity;
    #elif _SPECULAR_ANGELRING
        specular = AngelRingSpecular(uv, lightingData.NdotVClamp, _AngelRingThreshold, TEXTURE2D_ARGS(_AngelRingTex, kl_linear_clamp_sampler));
    #endif
    specular *= _SpecularColor.rgb * lambert * brdfData.specular;
    return specular;
}












half3 KLMainLightDirectLighting(BRDFData brdfData, BRDFData brdfDataClearCoat, Varyings input, InputData inputData,
                                 KLSurfaceData surfaceData, KLLightingData lightingData)
{
    half lambert = LightingLambert(lightingData, _UseHalfLambert);

    half3 diffuse = KLDiffuseLighting(brdfData, surfaceData, lambert, lightingData, input.uv);
    half3 specular = KLSpecularLighting(brdfData, surfaceData, input, inputData, surfaceData.albedo, lambert, lightingData, input.uv);
    half3 directColor = (diffuse + specular) * lightingData.lightColor;
    #if defined(_CLEARCOAT)
        half3 brdfCoat = kDielectricSpec.r * KLSpecularLighting(brdfDataClearCoat, surfaceData, input, inputData, surfaceData.albedo, lambert, lightingData, input.uv);
        //half NoV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS));
        half coatFresnel = kDielectricSpec.x + kDielectricSpec.a * lightingData.NDotVCPow4;
        directColor = directColor * (1.0 - surfaceData.clearCoatMask * coatFresnel) + brdfCoat * surfaceData.clearCoatMask * lightingData.lightColor;
    #endif 
    return directColor;
}




half3 KLAdditionalLightDirectLighting(BRDFData brdfData, BRDFData brdfDataClearCoat, Varyings input, InputData inputData,
                                 KLSurfaceData surfaceData)
{
    half3 additionalLightColor = 0;
    uint pixelLightCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(pixelLightCount)
    
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        KLLightingData lightingData = InitializeKLLightingData(light, input, inputData.normalWS, inputData.viewDirectionWS);
        half3 addLightColor = KLMainLightDirectLighting(brdfData, brdfDataClearCoat, input, inputData, surfaceData, lightingData);
        additionalLightColor += addLightColor;
    
    LIGHT_LOOP_END
    
    return additionalLightColor;
}




half3 KLIndirectLighting(BRDFData brdfData, InputData inputData, KLLightingData lightingData, Varyings input, half occlusion)
{
    #if defined(_INDIRDIFFUSE)
        half3 indirectDiffuse = inputData.bakedGI * occlusion;
    #else
        half3 indirectDiffuse = 0;
    #endif
    
    #if defined(_INDIRSPECULAR)
        half3 reflectVector = reflect(-inputData.viewDirectionWS, inputData.normalWS);
        half3 indirectSpecular = KLGlossyEnvironmentReflection(reflectVector, inputData.positionWS, inputData.normalizedScreenSpaceUV, brdfData.perceptualRoughness, occlusion);
    #else
        half3 indirectSpecular = 0;
    #endif
    half3 indirectColor = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, lightingData.NDotVCPow4);
    return indirectColor;
}



































half3 KLRimLighting(KLLightingData lightingData)
{
    half3 rimColor = 0;

    //half ndvPow = pow(1 - lightingData.NdotVClamp, _RimPow);
    //half ndvPow = Pow4(1 - lightingData.NdotVClamp);
    rimColor = LinearStep(_RimThreshold, _RimThreshold + _RimSoftness, lightingData.NDotVCPow4);
    rimColor *= LerpWhiteTo(lightingData.NdotLClamp, _RimDirectionLightContribution);

    rimColor *= _RimColor.rgb;
    return rimColor;
}


///////////////////////////////////////////////////////////////////////////////
//                         Interface Function                                //
///////////////////////////////////////////////////////////////////////////////
half3 KLHitLighting(KLLightingData lightingData)
{
    return lightingData.NDotVCPow4 * (_Tint.a * 10) * _Tint.rgb;
}

//half3 KLHeightFog(half3 originalColor, float3 positionWS)
//{
//    half fogFactor = saturate((_FogHeight - positionWS.y) / _FogHeight);
//    return lerp(originalColor.rgb, _FogColor.rgb, fogFactor * _FogColor.a);
//}



#endif
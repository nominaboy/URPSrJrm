#ifndef KL_FORWARD_PASS_INCLUDED
#define KL_FORWARD_PASS_INCLUDED

#include "KLCommon.hlsl"
#include "KLVaryings.hlsl"
#include "KLLighting.hlsl"








///////////////////////////////////////////////////////////////////////////////
//                  Vertex and Fragment functions                            //
///////////////////////////////////////////////////////////////////////////////

Varyings LitPassVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    
    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
    
    output.uv.xy = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.normalWS = normalInput.normalWS;
    
    OUTPUT_LIGHTMAP_UV(input.staticLightmapUV, unity_LightmapST, output.staticLightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);
    
    output.positionWS = vertexInput.positionWS;
    output.positionCS = vertexInput.positionCS;
    
    return output;
}


half4 LitPassFragment(Varyings input) : SV_Target
{
    //#if _OCCLUSION_FADE
    //    clip(OcclusionFade(input.positionCS, _DistanceScale, _DistanceSensitivity, _RoleScreenPos));
    //#endif
    
    InputData inputData;
    PreInitializeKLInputData(input, inputData);
    
    KLSurfaceData surfaceData;
    InitializeKLSurfaceData(input.uv.xy, surfaceData);
    
    InitializeKLInputData(input, inputData); 
    
    Light mainLight = GetMainLight();
    
    BRDFData brdfData, clearCoatbrdfData;
    InitializeKLBRDFData(surfaceData, brdfData, clearCoatbrdfData);
    
    KLLightingData lightingData = InitializeKLLightingData(mainLight, input, inputData.normalWS, inputData.viewDirectionWS);
    
    half4 finalColor = half4(1, 1, 1, surfaceData.alpha);
    
    finalColor.rgb = KLMainLightDirectLighting(brdfData, clearCoatbrdfData, input, inputData, surfaceData, lightingData);
    
    #if defined(_ADDLIGHT_ON)
        finalColor.rgb += KLAdditionalLightDirectLighting(brdfData, clearCoatbrdfData, input, inputData, surfaceData);
    #endif
    
    #if defined(_INDIRDIFFUSE) || defined(_INDIRSPECULAR)
        finalColor.rgb += KLIndirectLighting(brdfData, inputData, lightingData, input, surfaceData.occlusion);
    #endif
    
    #if _RIM_ON
        finalColor.rgb += KLRimLighting(lightingData);
    #endif
    
    finalColor.rgb += surfaceData.emission;
    finalColor.rgb += KLHitLighting(lightingData);

    //#ifdef _KL_HEIGHTFOG_ON
    //    finalColor.rgb += KLHeightFog(finalColor.rgb, input.positionWS);
    //#endif
    
    #ifdef _KLFogOfWar
        finalColor.rgb = CalcFogOfWar(finalColor.rgb, input.positionWS, input.positionCS.y / _ScaledScreenParams.y);
    #endif
    
    return finalColor;
}











#endif
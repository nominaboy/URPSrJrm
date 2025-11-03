Shader "Jeremy/Standard/KLStdCharStencil"
{
    Properties
    {
        [Header(_________Textures_________)]
        [Space]
        _BaseMap ("Base Map", 2D) = "white" { }
        _PBRFuncTex ("PBR Func Tex M/R/RampID/E", 2D) = "white" { }
        _EmissionTex ("Emission Tex", 2D) = "black" {}
        _DiffuseRampMap ("Ramp Map", 2D) = "white" {}
        _SDFFaceTex ("SDF Face Tex", 2D) = "white" {}
        _AngelRingTex ("Angel Ring Tex", 2D) = "white" {}

        [Header(_________Surface_________)]
        [Space]
        [Toggle] _UseHalfLambert ("Use HalfLambert", Float) = 1
		[Toggle(_PBRFUNCTEX_ON)] _PBRFUNCTEX_ON("_PBRFUNCTEX_ON", Float) = 0
        _BaseColor ("Base Color", color) = (1, 1, 1, 1)
        _Metallic("Metallic", Range(0, 1.0)) = 0.0
        _Roughness("Roughness", Range(0, 1.0)) = 0.5 
        //_OcclusionStrength("Occlusion Strength", Range(0, 1.0)) = 0.0
		[Toggle(_ALPHATEST_ON)] _ALPHATEST_ON("_ALPHATEST_ON", Float) = 0
        _AlphatestThreshold("Alphatest Threshold", Range(0, 1.0)) = 0.0
		[Toggle(_ADDLIGHT_ON)] _ADDLIGHT_ON("_ADDLIGHT_ON", Float) = 0



        [Header(_________DirDiffuse_________)]
        [Space]
		[KeywordEnum(OFF, CELSHADING, LAMBERTIAN, RAMPSHADING, CELBANDSHADING, SDFFACE)] _DIFFUSE("_DIFFUSE", Int) = 0  
        [HDR] _LightColor ("Light Color", Color) = (1, 1, 1, 1)
        _DarkColor ("Dark Color", Color) = (0, 0, 0, 1)
        _CelBands ("Cel Bands(Int)", Range(1, 10)) = 1
        _CelThreshold ("Cel Threshold", Range(0.01, 1)) = 0.5
        _CelSmoothing ("Cel Smoothing", Range(0.001, 1)) = 0.001
        _CelBandSoftness ("Cel Softness", Range(0.001, 1)) = 0.001
        _RampUOffset ("Ramp U Offset", Range(-1, 1)) = 0
        _RampVOffset ("Ramp V Offset", Range(0, 1)) = 0
        _SDFSoftness ("SDF Softness", Range(0, 1)) = 0
        [Toggle] _SDFReversal ("SDF Reversal", Float) = 0

        [Header(_________DirSpecular_________)]
        [Space]
		[KeywordEnum(OFF, GGX, STYLIZED, BLINNPHONG, ANGELRING)] _SPECULAR("_SPECULAR", Int) = 0  
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularIntensity ("Specular Intensity", Range(0,8)) = 1
        _StylizedSpecularSize ("Stylized Specular Size", Range(0, 1)) = 0.1
        _StylizedSpecularSoftness ("Stylized Specular Softness", Range(0.001, 1)) = 0.05
        _StylizedSpecularAlbedoWeight ("Specular Color Albedo Weight", Range(0, 1)) = 0
        _Shininess ("BlinnPhong Shininess", Range(0,1)) = 1
        _AngelRingThreshold("AngelRing Threshold", Range(0,1)) = 0.3

        [Header(_________IndirDiffSpec_________)]
        [Space]
		[Toggle(_INDIRDIFFUSE)] _INDIRDIFFUSE("_INDIRDIFFUSE", Float) = 0
		[Toggle(_INDIRSPECULAR)] _INDIRSPECULAR("_INDIRSPECULAR", Float) = 0

        [Header(_________Emission_________)]
        [Space]
		[Toggle(_EMISSION_ON)] _EMISSION_ON("_EMISSION_ON", Float) = 0
        _EmiIntensity("Emission Intensity", Range(0, 10)) = 0
        _EmiFlashFrequency ("Emission Flash Frequency", Range(0.0, 2.0)) = 0

        [Header(_________Rim_________)]
        [Space]
		[Toggle(_RIM_ON)] _RIM_ON("_RIM_ON", Float) = 0
        //_RimPow ("Rim Pow", Range(1,5)) = 4
        _RimDirectionLightContribution("Directional Light Contribution", Range(0, 1)) = 1.0
        [HDR] _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimThreshold ("Rim Threshold", Range(0, 1)) = 0.5
        _RimSoftness ("Rim Softness", Range(0.001, 1)) = 0.5

        [Header(_________ClearCoat_________)]
        [Space]
		[Toggle(_CLEARCOAT)] _CLEARCOAT("_CLEARCOAT", Float) = 0
        _ClearCoatMask("Clear Coat Mask", Range(0,1)) = 1.0
        _ClearCoatSmoothness("Clear Coat Smoothness", Range(0,1)) = 1.0

        [Header(_________Functions_________)]
        [Space]
        //[Toggle(_OCCLUSION_FADE)] _OCCLUSION_FADE("_OCCLUSION_FADE", Float) = 0
        //_DistanceScale("_DistanceScale", Float) = 1
        //_DistanceSensitivity("_DistanceSensitivity", Float) = 1
        _Tint("_Tint", Color) = (0, 0, 0, 0)
        //[Toggle(_KL_HEIGHTFOG_ON)] _KL_HEIGHTFOG_ON("_KL_HEIGHTFOG_ON", Float) = 0
        //_FogHeight("_FogHeight", Float) = 0
        //_FogColor("_FogColor", Color) = (0, 0, 0, 0)

        [Header(_________RenderSettings_________)]
        [Space]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 2
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "Queue"="Transparent" }
        Pass
        {
            Name "KLForwardLitStencil"
            Tags {"LightMode"="UniversalForward"}
            
            ZTest [_ZTest]
            ZWrite [_ZWrite]
            Cull [_Cull]

            Stencil
            {
                Ref 2
                Comp GEqual
                Pass Replace
            }

            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment
            //#pragma enable_d3d11_debug_symbols

            

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ _PBRFUNCTEX_ON
            #pragma shader_feature_local _ _ALPHATEST_ON
            #pragma shader_feature_local _DIFFUSE_OFF _DIFFUSE_CELSHADING _DIFFUSE_LAMBERTIAN _DIFFUSE_RAMPSHADING _DIFFUSE_CELBANDSHADING _DIFFUSE_SDFFACE
            #pragma shader_feature_local _SPECULAR_OFF _SPECULAR_GGX _SPECULAR_STYLIZED _SPECULAR_BLINNPHONG _SPECULAR_ANGELRING
            #pragma shader_feature_local _ _ADDLIGHT_ON
            #pragma shader_feature_local _ _INDIRDIFFUSE
            #pragma shader_feature_local _ _INDIRSPECULAR
            #pragma shader_feature_local _ _EMISSION_ON
            #pragma shader_feature_local _ _RIM_ON
            #pragma shader_feature_local _ _CLEARCOAT

            //#pragma shader_feature_local _ _OCCLUSION_FADE
            //#pragma shader_feature_local _ _KL_HEIGHTFOG_ON


            // -------------------------------------
            // Unity Keywords
            #pragma multi_compile _ LIGHTMAP_ON


            #pragma multi_compile_fragment _ DEBUG_DISPLAY






            // -------------------------------------

            #include "../Utils/KLInput.hlsl"
            #include_with_pragmas "../Utils/KLFogOfWar.hlsl"
            #include "../Utils/KLForwardPass.hlsl"
            ENDHLSL
        }
    }
	CustomEditor "KLStandardGUI"
}

Shader "Jeremy/BakeGI/Bake_GI"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _MainTex ("BaseMap", 2D) = "white" {}

        [Header(_________Emission_________)]
        [Space]
		[Toggle(_EMISSION_ON)] _EMISSION_ON("_EMISSION_ON", Float) = 0
        _EmissionTex ("Emission Tex", 2D) = "black" {}
        _EmiIntensity("Emission Intensity", Range(0, 10)) = 0
        //_EmiFlashFrequency ("Emission Flash Frequency", Range(0.0, 2.0)) = 0

        [Toggle(_OCCLUSION_FADE)] _OCCLUSION_FADE("_OCCLUSION_FADE", Float) = 0
        _DistanceScale("_DistanceScale", Range(0.1, 50)) = 1
        _DistanceSensitivity("_DistanceSensitivity", Range(0.1, 10)) = 1
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+5"}
        Pass
        {
            Tags { "LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature _ _OCCLUSION_FADE
            #pragma shader_feature_local _ _EMISSION_ON

            #pragma multi_compile _ LIGHTMAP_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include_with_pragmas "../Utils/KLFogOfWar.hlsl"
            TEXTURE2D(_MainTex);
            #if defined(_EMISSION_ON)
                TEXTURE2D(_EmissionTex);
            #endif
            SAMPLER(sampler_MainTex);

            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;

                half _EmiIntensity;
                //half _EmiFlashFrequency;

                float _DistanceScale;
                float _DistanceSensitivity;
            CBUFFER_END

            uniform float2 _RoleScreenPos;

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv0AndLightmapUV : TEXCOORD0; // xy: uv0, zw: staticLightmapUV
                float3 normalWS : VAR_NORMALWS;
                float3 positionWS : VAR_POSITIONWS;
            };
            
            half3 EmissionColor(half3 baseColor, half emissionTex, half emiIntensity)
            {
                return baseColor.rgb * emissionTex * emiIntensity;
            }

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                
                o.uv0AndLightmapUV.xy = TRANSFORM_TEX(i.uv, _MainTex);
                o.uv0AndLightmapUV.zw = i.staticLightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                return o;
            }           
            
            half4 frag(Varyings i) : SV_TARGET
            {
                #ifdef _OCCLUSION_FADE
                    float cameraDistance = abs(i.positionCS.w);
                    float cameraDistanceFactor = max(0.0, cameraDistance / max(_DistanceScale, 0.1));
                    cameraDistanceFactor = pow(cameraDistanceFactor, _DistanceSensitivity);
                    float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
                    float ratio = _ScaledScreenParams.y / _ScaledScreenParams.x;
                    float2 sphere = float2(screenUV.x - _RoleScreenPos.x, (screenUV.y - _RoleScreenPos.y) * ratio);
                    float distanceSS = length(sphere);

                    float sphereRange = 1 - 3.33 * distanceSS;
                    float sphereRangePow = 2.33 * sphereRange;
                    sphereRangePow = sphereRangePow * sphereRangePow;
                    sphereRangePow = pow(2.72, sphereRangePow);
                    sphereRangePow = 1 / sphereRangePow;
                    float result = sphereRange > 0 ? sphereRangePow : 1.0;
                    result = abs(sphereRange) > 0.1 ? result : 1.0;

                    result = result * cameraDistanceFactor;
                    result = saturate(result);
                    float noise = InterleavedGradientNoise(float2(i.positionCS.x * 0.5, i.positionCS.y), 0);
                    result = noise + result - 1.0;
                    clip(result);
                #endif

                half4 finalColor;
                //固有色
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0AndLightmapUV.xy);//固有色采样
                finalColor = baseColor * _Color;
                //烘焙GI采样
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.uv0AndLightmapUV.zw, i.normalWS.xyz);
                    finalColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    finalColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif

                #ifdef _EMISSION_ON
                    half emission = SAMPLE_TEXTURE2D(_EmissionTex, sampler_MainTex, i.uv0AndLightmapUV.xy).r;
                    finalColor.rgb += (EmissionColor(baseColor.rgb, emission, _EmiIntensity)); 
                        // * abs(-2 * frac(_Time.y * _EmiFlashFrequency) + 1);
                #endif

                #ifdef _KLFogOfWar
                    finalColor.rgb = CalcFogOfWar(finalColor.rgb, i.positionWS, i.positionCS.y / _ScaledScreenParams.y);
                #endif

                return finalColor;
            }
            ENDHLSL
        }
    }
}

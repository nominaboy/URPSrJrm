Shader "Jeremy/Standard/KLStdWater"
{
    Properties
    {
        [Header(_______Depth Controller_______)]
        [Space]
        _DepthFactor("Depth Factor", Range(0, 1)) = 1.0
        _DepthValue("Depth Value", Float) = 1.0
        _MaxAlpha("Max Alpha", Range(0, 1)) = 0.8

        [Header(_______Normal_______)]
        [Space]
        _WaveDir("Wave Dir", Vector) = (1, 1, 1, 1)
        _NormalTexture("Normal Texture", 2D) = "bump"{}
        _NormalSpeedVector("Normal Speed Vector", Vector) = (1, 1, 1, 1)
        _NormalSpeed("Normal Speed", Float) = 1
        _NormalLerpFactor("Normal Lerp Factor", Range(0, 1)) = 0.1

        [Header(_______Deep Shallow_______)]
        [Space]
        [HDR]_ShallowColor("Shallow Color", Color) = (1,1,1,1)
        [HDR]_DeepColor("Deep Color", Color) = (1,1,1,1)

        [Header(_______Fake Specular_______)]
        [Space]
        _SunDir ("Sun Dir", Vector) = (0, 100, 1000, 0)
        _SunSpecThreshold ("Sun Spec Threshold", Range(0.8, 1)) = 0.9
        [HDR]_SunSpecColor("Sun Spec Color", Color) = (1,1,1,1)


        [Header(_______Reflection_______)]
        [Space]
        //_SkyTexture ("Sky Texture", 2D) = "black"{} 
        _FresnelFactor ("Fresnel Factor", Range(0, 1)) = 0.02
        _ReflectionIntensity("Reflection Intensity", Range(0,1)) = 1
        _ReflectionColor("Reflection Color", Color) = (1, 1, 1, 1)

        //[Header(_______Refraction_______)]
        //[Space]
        //_RefractionIntensity ("Refraction Intensity", Range(0, 1)) = 0

        [Header(_______Edge Foam_______)]
        [Space]
        _EdgeFoamTexture ("Edge Foam Texture", 2D) = "black"{}
        [HDR]_EdgeFoamColor ("Edge Foam Color", Color) = (1, 1, 1, 1)
        _EdgeFoamDepth ("Edge Foam Depth", float) = 10.0
        _EdgeFoamStep ("Edge Foam Step", Range(0, 3)) = 1
        _EdgeFoamSmoothness ("Edge Foam Smoothness", Range(0, 1)) = 0.1

        [Header(_______Caustics_______)]
        [Space]
        _CausticsTexture("Caustics Texture", 2D) = "white"{}
        _CausticsUVSpeed ("Caustics UV Speed", float)= 0.2
        _CausticsDistortion("Caustics Distortion", Range(0, 0.1)) = 0.01
        _CausticsSpeed("Caustics Speed", Range(0, 0.5)) = 0.1
        [HDR]_CausticsColor("Caustics Color", Color) = (1, 1, 1, 1)

        [Header(_______Scene Interaction_______)]
        [Space]
        _CRBumpScale("CR Bump Scale", Range(0, 5)) = 1

    }
    SubShader
    {
        Tags { "Queue" = "Transparent-15" }
        

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            #pragma multi_compile KL_QUALITY_LOW KL_QUALITY_MEDIUM KL_QUALITY_HIGH
            #if defined(KL_QUALITY_HIGH)
                #define _CAUSTICS 
                #define _EDGE_FOAM
            #elif defined(KL_QUALITY_MEDIUM)
                #define _CAUSTICS 
                #define _EDGE_FOAM
            #elif defined(KL_QUALITY_LOW)
                #define _CAUSTICS 
                #define _EDGE_FOAM
            #endif

            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include_with_pragmas "../Utils/KLFogOfWar.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 positionWS : VAR_POSITIONWS;
                float3 normalWS : VAR_NORMALWS;
                float4 tangentWS : VAR_TANGENTWS;
            };  
            
            TEXTURE2D_FLOAT(_CustomDepthTexture0);
            SAMPLER(sampler_CustomDepthTexture0);

            TEXTURE2D(_SceneInteractionColorTexture);

            TEXTURE2D(_EdgeFoamTexture);
            TEXTURE2D(_NormalTexture);
            //TEXTURE2D(_SkyTexture);
            TEXTURE2D(_CausticsTexture);
            SamplerState kl_linear_repeat_sampler;

            //TEXTURE2D(_CustomColorTexture0);
            //float4 _CustomColorTexture0_TexelSize;
            //SamplerState kl_linear_clamp_sampler;

            CBUFFER_START(UnityPerMaterial)
                float _DepthFactor;
                float _DepthValue;
                float _MaxAlpha;

                float2 _WaveDir;
                float4 _NormalSpeedVector;
                float _NormalSpeed;
                float _NormalLerpFactor;

                half3 _ShallowColor;
                half3 _DeepColor;

                float4 _SunDir;
                float _SunSpecThreshold;
                half3 _SunSpecColor;

                float _FresnelFactor;
                float _ReflectionIntensity;
                half3 _ReflectionColor;

                //float _RefractionIntensity;

                half3 _EdgeFoamColor;
                float _EdgeFoamDepth;
                float _EdgeFoamStep;
                float _EdgeFoamSmoothness;

                float _CausticsDistortion;
                float _CausticsUVSpeed;
                float _CausticsSpeed;
                half3 _CausticsColor;

                float _CRBumpScale;

                float4 _NormalTexture_ST;
                float4 _EdgeFoamTexture_ST;
                float4 _CausticsTexture_ST;
            CBUFFER_END

            Varyings vert (Attributes i) {
                Varyings o = (Varyings) 0;

                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);

                o.uv.xy = TRANSFORM_TEX(i.uv, _NormalTexture);
                o.uv.zw = TRANSFORM_TEX(i.uv, _EdgeFoamTexture);
 
                float2 waveDir = normalize(_WaveDir.xy);
                o.uv.xy += _NormalSpeed * _Time.y * waveDir;
                o.uv.zw += _CausticsUVSpeed * _Time.y * waveDir;

                float crossSign = i.tangentOS.w * GetOddNegativeScale();
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.tangentWS.xyz = TransformObjectToWorldDir(i.tangentOS.xyz);
                o.tangentWS.w = crossSign;
                return o;
            }

            half4 frag (Varyings i) : SV_Target {
                float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;

                float3 viewDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 lightDirWS = _MainLightPosition.xyz;

                // TBN
                float crossSign = i.tangentWS.w;
                float3 bitangentWS = crossSign * cross(i.normalWS.xyz, i.tangentWS.xyz);
                float3x3 tanToWorld = float3x3(i.tangentWS.xyz, bitangentWS.xyz, i.normalWS.xyz);

                // Depth Diff n->f
                float sceneDepth = SAMPLE_DEPTH_TEXTURE(_CustomDepthTexture0, sampler_CustomDepthTexture0, screenUV);
                // _ZBufferParams fix REVERSED_Z automatically
                float fragDepth = LinearEyeDepth(sceneDepth, _ZBufferParams);
                float linearVertexDepth = LinearEyeDepth(i.positionCS.z, _ZBufferParams);
                float distanceFactor = saturate(10 / max(linearVertexDepth, 0.001));
                float opticalDepth = fragDepth - linearVertexDepth;

                // Depth Color
                float depthValue = pow(saturate(opticalDepth / _DepthValue), max(_DepthFactor, 0.01));
                half3 baseColor = lerp(_ShallowColor, _DeepColor, depthValue);
                half alpha = lerp(0, _MaxAlpha, depthValue);

                //Character Ripple
                float3 charRippleBumpTS = float3(0, 0, 0);
                #if defined(_CHAR_RIPPLE)
                    charRippleBumpTS = SAMPLE_TEXTURE2D(_SceneInteractionColorTexture, kl_linear_repeat_sampler, screenUV).rgb;
                    float rippleMask = charRippleBumpTS.b;
                    charRippleBumpTS.xy = charRippleBumpTS.xy * 2 - 1;
                    charRippleBumpTS.xy *= _CRBumpScale;
                    charRippleBumpTS.z = sqrt(1.0 - saturate(dot(charRippleBumpTS.xy, charRippleBumpTS.xy)));
                    charRippleBumpTS *= rippleMask;
                #endif

                //charRipple.xy = charRipple.xy * 2 - 1;
                //float3 crBumpTS = float3(charRipple.xy, 1.0);
                //float3 crBumpWS = normalize(TransformTangentToWorld(normalize(crBumpTS), tanToWorld));
                //crBumpWS *= charRipple.b * 0.5;

                float3 normalTS = float3(0, 0, 1) + charRippleBumpTS;
                float3 normalWS =  normalize(TransformTangentToWorld(normalize(normalTS), tanToWorld));
                //float NDotL = dot(lightDirWS, normalWS);

                // Fresnel
                float NDotV = dot(viewDirWS, normalWS);
                float F0 = _FresnelFactor;
                // based on Spherical Gaussian approximation - Unreal
                float fresnel = F0 + (1 - F0) * exp2((-5.55473 * NDotV - 6.98316) * NDotV);
                
                //return half4(normalTS.xyz,1);

                float4 time = _Time.yyyy * _NormalSpeedVector;
                time = frac(abs(time));
                float2 reverseUV = i.uv.xy * float2(1, -1);
                float3 bumpTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTexture, kl_linear_repeat_sampler, reverseUV + time.xy));
                bumpTS += UnpackNormal(SAMPLE_TEXTURE2D(_NormalTexture, kl_linear_repeat_sampler, i.uv.xy + time.zw));

                //// Refraction
                //half3 refractionColor = SAMPLE_TEXTURE2D(_CustomColorTexture0, kl_linear_clamp_sampler,
                //    bumpTS.xy * _RefractionIntensity * i.positionCS.z + screenUV);

                float3 bumpWS = normalize(TransformTangentToWorld(normalize(bumpTS + charRippleBumpTS), tanToWorld));
                normalWS = lerp(normalWS, bumpWS, _NormalLerpFactor);
                //normalWS = bumpWS;

                // Caustics
                half3 causticsCol = half3(0, 0, 0);
                #if defined(_CAUSTICS)
                    half3 caustics = SAMPLE_TEXTURE2D(_CausticsTexture, kl_linear_repeat_sampler, 
                        (i.uv.zw + normalWS.xz * _CausticsDistortion) * _CausticsTexture_ST.xy + _CausticsTexture_ST.zw + _Time.yy * _CausticsSpeed);
                    // Caustics only exists in shallow area
                    causticsCol = /*NDotL */ caustics.rgb * (1 - depthValue) * _CausticsColor;
                #endif

                // Reflection
                //float3 reflectDir = reflect(-viewDirWS, normalWS);
                //float2 skyUV = float2(reflectDir.x * 0.5 + 0.5, saturate(reflectDir.y));
                //half3 reflectColor = SAMPLE_TEXTURE2D(_SkyTexture, kl_linear_repeat_sampler, skyUV).xyz;
                half3 reflectColor = _ReflectionColor.rgb * _ReflectionIntensity;
                
                // Edge Foam
                half3 edgeFoamColor = half3(0, 0, 0);
                #if defined(_EDGE_FOAM)
                    float edgeFoamMask = saturate(opticalDepth / _EdgeFoamDepth) * _EdgeFoamStep;
                    float edgeNoise = SAMPLE_TEXTURE2D(_EdgeFoamTexture, kl_linear_repeat_sampler, i.uv.zw * _EdgeFoamTexture_ST.xy + _EdgeFoamTexture_ST.zw).x;
                    //float oneMinusEdgeNoise = 1 - step(edgeNoise, edgeFoamMask - randomMask);
                    float oneMinusEdgeNoise = 1 - smoothstep(edgeNoise - _EdgeFoamSmoothness, edgeNoise, edgeFoamMask - 0.5);
                    edgeFoamColor = _EdgeFoamColor * oneMinusEdgeNoise;
                #endif
                
                // Fake LightDir
                lightDirWS = normalize(_SunDir.xyz);
                float3 halfVec = normalize(viewDirWS + lightDirWS);
                float sunSpecIntensity = step(_SunSpecThreshold + 9.0, dot(halfVec, normalWS) * 10.0);
                

                half3 diffuseColor = lerp(baseColor, reflectColor, fresnel); 
                half3 color = saturate(/*NDotL */ diffuseColor + causticsCol.xyz + edgeFoamColor) + sunSpecIntensity * _SunSpecColor;

                #ifdef _KLFogOfWar
                    color.rgb = CalcFogOfWar(color.rgb, i.positionWS, screenUV.y);
                #endif

                return half4(color, alpha);
            }

            ENDHLSL
        }
        
    }
}


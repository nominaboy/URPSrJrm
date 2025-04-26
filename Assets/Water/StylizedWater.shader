Shader "JRMAdvanced/StylizedWater"
{
    Properties
    {
        [Header(_______Time Of Day_______)]
        [Space]
        [Toggle(_TIME_OF_DAY)] _TimeOfDay("Time Of Day", Float) = 1

        [Header(_______Depth Controller_______)]
        [Space]
        _DepthFactor("Depth Factor", Range(0, 1)) = 1.0
        _DepthValue("Depth Value", Float) = 1.0
        _MaxAlpha("Max Alpha", Range(0, 1)) = 0.8

        [Header(_______Normal_______)]
        [Space]
        _NormalSpeedVector("Normal Speed Vector", Vector) = (1, 1, 1, 1)
        _NormalSpeed("Normal Speed", Float) = 1
        _NormalTexture("Wave Normal Texture", 2D) = "bump"{}
        _NormalLerpFactor("Tex/Wave Normal Lerp Factor", Range(0, 1)) = 0.1

        [Header(_______Wave_______)]
        [Space]
        [Header(Vertex Waves #1)]
        _Wave1Direction("Direction(Main)", Range(0, 1)) = 0
        _Wave1Amplitude("Amplitude", float) = 1
        _Wave1Wavelength("Wavelength", Range(1, 10)) = 10
        _Wave1Speed("Speed", float) = 1
        
        [Header(Vertex Waves #2)]
        _Wave2Direction("Direction", Range(0, 1)) = 0
        _Wave2Amplitude("Amplitude", float) = 1
        _Wave2Wavelength ("Wavelength", Range(1, 10)) = 10
        _Wave2Speed("Speed", float) = 1

        [Header(_______Deep Shallow_______)]
        [Space]
        [HDR]_NoonShallowColor("Noon Shallow Color",Color) =(1,1,1,1)
        [HDR]_DuskShallowColor("Dusk Shallow Color",Color) = (1,1,1,1)
        [HDR]_NightShallowColor("Night Shallow Color",Color) = (1,1,1,1)

        [HDR]_NoonDeepColor("Noon Deep Color",Color) = (1,1,1,1)
        [HDR]_DuskDeepColor("Dusk Deep Color",Color) = (1,1,1,1)
        [HDR]_NightDeepColor("Night Deep Color",Color) = (1,1,1,1)

        [Header(_______Fake Specular_______)]
        [Space]
        _SunPos ("Sun Position", Vector) = (0, 100, 1000, 0)
        _SunSpecThreshold ("Specular Threshold", Range(0, 1)) = 0.999
        _SunStrength ("Specular Strength", float) = 128
        _SunSpecNearDis ("Specular Near Distance", float) = 30
        _SunSpecFarDis("Specular Far Distance", float) = 80
        [Space]
        [HDR]_NoonSunSpecularColor("Noon Specular Color",Color) = (1,1,1,1)
        [HDR]_DuskSunSpecularColor("Dusk Specular Color", Color) = (1,1,1,1)
        [HDR]_NightSunSpecularColor("Night Specular Color", Color) = (1,1,1,1)


        [Header(_______Reflection_______)]
        [Space]
        _FresnelFactor ("Fresnel Factor", Range(0, 1)) = 0.02
        _SkyTexture ("Reflection Sky Texture", 2D) = "black"{} 
        _ReflectionIntensity("Noon Reflection Intensity", Range(0,1)) = 1
        _DuskReflectionIntensity("Dusk Reflection Intensity",Range(0,1)) = 1
        _NightReflectionIntensity("Night Reflection Intensity",Range(0, 1)) = 1

        [Header(_______Refraction_______)]
        [Space]
        _RefractFactor("Refraction Factor", Range(0, 0.1)) = 0.02

        [Header(_______Foam_______)]
        [Space]
        [HDR]_EdgeFoamColor ("Edge Foam Color", Color) = (1, 1, 1, 1)
        _EdgeFoamDepth ("Edge Foam Depth", float) = 10.0
        _EdgeFoamStep ("Edge Foam Step", Range(0, 3)) = 1
        _FoamNoiseTexture ("Edge Foam Noise Texture", 2D) = "black"{}
        _FoamSmoothTrans("Foam/Water Trans Smoothness", Range(0, 1)) = 0.1

        [Header(_______Caustics_______)]
        [Space]
        _CausticsMask("Caustics Mask",2D)="white"{}
        _CausticsUVSpeed ("Caustics UVflow Speed", float)= 0.2
        _CausticsDistortion("Caustics Distortion", Range(0,1))=0.01
        _CausticsSpeed("Caustics Speed", Range(0, 10))=0.1
        _CausticsIntensity("Caustics Intensity", Range(0, 10))=10.0
        _CausticsColor("Caustics Color", Color) = (1, 1, 1, 1)

        [Header(_______Weather_______)]
        [Space]
        _RippleNormalScale("Rain Ripple Scale", Range(0.01, 100)) = 1
        _RippleNormalIntensity("Rain Ripple Normal Intensity",Range(0.1, 10))=1
        


    }
    SubShader
    {
        Tags { "Queue" = "Transparent-1" }
        

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma enable_d3d11_debug_symbols
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma shader_feature_local _ _TIME_OF_DAY
            #pragma multi_compile _ _RAIN
            #pragma multi_compile _ _FOG_OF_WAR



            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float4 positionSS : TEXCOORD2;
            };

            
            sampler2D _FoamNoiseTexture;
            sampler2D _NormalTexture;
            sampler2D _SkyTexture;
            sampler2D _CausticsMask;
            sampler2D _RippleNormalTexture;
            uniform int _RainRippleSwitch;
            uniform float _DurationFlag;
            uniform float _CurTimeLerpVal;

            CBUFFER_START(UnityPerMaterial)
                float _DepthFactor;
                float _DepthValue;
                float _MaxAlpha;

                float4 _NormalSpeedVector;
                float _NormalSpeed;
                float _NormalLerpFactor;

                float _Wave1Direction;
                float _Wave1Amplitude;
                float _Wave1Wavelength;
                float _Wave1Speed;
                float _Wave2Direction;
                float _Wave2Amplitude;
                float _Wave2Wavelength;
                float _Wave2Speed;

                half3 _NoonShallowColor;
                half3 _DuskShallowColor;
                half3 _NightShallowColor;
                half3 _NoonDeepColor;
                half3 _DuskDeepColor;
                half3 _NightDeepColor;

                float4 _SunPos;
                float _SunSpecThreshold;
                float _SunStrength;
                float _SunSpecNearDis;
                float _SunSpecFarDis;
                half3 _NoonSunSpecularColor;
                half3 _DuskSunSpecularColor;
                half3 _NightSunSpecularColor;

                float _FresnelFactor;
                float _ReflectionIntensity;
                float _DuskReflectionIntensity;
                float _NightReflectionIntensity;

                float _RefractFactor;

                half3 _EdgeFoamColor;
                float _EdgeFoamDepth;
                float _EdgeFoamStep;
                float _FoamSmoothTrans;

                float _CausticsDistortion;
                float _CausticsUVSpeed;
                float _CausticsSpeed;
                float _CausticsIntensity;
                half3 _CausticsColor;
               
                float _RippleNormalScale;
                float _RippleNormalIntensity;

                float4 _NormalTexture_ST;
                float4 _FoamNoiseTexture_ST;
                float4 _FoamMask_ST;
            CBUFFER_END

            //Utility Functions
            // Asin(2PI/l * (x-vt))
            float SineWave(float2 position, float2 direction, float wavelength, float amplitude, float speed) {
                float offset = dot(position, direction) - speed * _Time.y;
                float multiplier = 2 * PI / max(wavelength, 0.001);
                return amplitude * sin(multiplier * offset);
            }

            float GetWaveHeight(float2 positionWS) {
                float2 dir1 = float2(cos(PI * _Wave1Direction), sin(PI * _Wave1Direction));
                float2 dir2 = float2(cos(PI * _Wave2Direction), sin(PI* _Wave2Direction));
                float wave1 = SineWave(positionWS, dir1, _Wave1Wavelength, _Wave1Amplitude, _Wave1Speed);
                float wave2 = SineWave(positionWS, dir2, _Wave2Wavelength, _Wave2Amplitude, _Wave2Speed);
                return wave1 + wave2;
            }

            float3x3 GetWaveTBN(float2 positionWS, float d) {
                float waveHeight = GetWaveHeight(positionWS);
                float waveHeightDX = GetWaveHeight(positionWS - float2(d, 0));
                float waveHeightDZ = GetWaveHeight(positionWS - float2(0, d));

                // Old Ver
                //float3 tangent = normalize(float3(0, waveHeight - wavelHeightDZ, d));
                //float3 bitangent = normalize(float3(d, waveHeight - waveHeightDX(0));
                //float3 normal = normalize(cross(tangent, bitangent));
                //return transpose(float3x3(tangent, bitangent, normal));

                float3 tangent = normalize(float3(1, (waveHeight - waveHeightDX) / d, 0));
                float3 bitangent = normalize(float3(0, (waveHeight - waveHeightDZ) / d, 1));
                float3 normal = normalize(cross(bitangent, tangent));
                return transpose(float3x3(tangent, bitangent, normal));  
            }



            Varyings vert (Attributes i) {
                Varyings o = (Varyings) 0;

                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionWS.y += GetWaveHeight(o.positionWS.xz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.positionSS = o.positionCS;

                o.uv.xy = TRANSFORM_TEX(i.uv, _NormalTexture);
                o.uv.zw = TRANSFORM_TEX(i.uv, _FoamNoiseTexture);
 
                // wave1Dir is the main direction
                float2 waveDir = float2(cos(PI * _Wave1Direction), sin(PI * _Wave1Direction));
                o.uv.xy += _NormalSpeed * _Time.x * waveDir;
                o.uv.zw += _CausticsUVSpeed * _Time.x * waveDir;
                return o;
            }



            half4 frag (Varyings i) : SV_Target {
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 lightDirWS = _MainLightPosition.xyz;
                float3x3 tanToWorld = GetWaveTBN(i.positionWS.xz, 0.1);
                float3 normalWS = transpose(tanToWorld)[2];
                #ifdef _RAIN
                    float3 rippleNormal;
                    if(_RainRippleSwitch > 0) {
                        rippleNormal = tex2D(_RippleNormalTexture, i.positionWS.xz/_RippleNormalScale);
                        rippleNormal = rippleNormal * 2.0 - 1.0;
                        rippleNormal.xy *= _RippleNormalIntensity;
                        rippleNormal = normalize(rippleNormal);
                        float3 worldRippleNormal = mul(tanToWorld, rippleNormal);
                        normalWS += worldRippleNormal;
                        normalWS = normalize(normalWS);
                    }
                #endif
                float3 bumpWS = 0;
                float NDotL = dot(lightDirWS, normalWS);
                // Fresnel
                float NDotV = dot(viewDirWS, normalWS);
                float F0 = _FresnelFactor;
                // based on Spherical Gaussian approximation - Unreal
                float fresnel = F0 + (1 - F0) * exp2((-5.55473 *NDotV - 6.98316) * NDotV);

                // Fake LightDir
                lightDirWS = normalize(_SunPos.xyz - i.positionWS);
                //#if defined (ENABLE_NORMALMAP)
                    float4 time = _Time.xxxx * _NormalSpeedVector;
                    time = frac(abs(time));
                    float2 reverseUV = i.uv.xy * float2(1, -1);
                    bumpWS = UnpackNormal(tex2D(_NormalTexture, reverseUV + time.xy));
                    bumpWS += UnpackNormal(tex2D(_NormalTexture, i.uv.xy + time.zw));
                    #ifdef _RAIN
                        if(_RainRippleSwitch > 0) { bumpWS += rippleNormal; }
                    #endif
                    bumpWS = normalize(mul(tanToWorld, normalize(bumpWS)));
                //#endif
                normalWS = lerp(bumpWS, normalWS, _NormalLerpFactor);

                float4 causticsM = tex2D(_CausticsMask, (i.uv.zw + normalWS.xz * _CausticsDistortion) * _FoamMask_ST.xy + _FoamMask_ST.zw + _Time.xx *_CausticsSpeed);
                float3 reflectDir = reflect(-viewDirWS, normalWS);
                float2 skyUV = float2(reflectDir.x * 0.5 + 0.5, saturate(reflectDir.y));
                half3 reflectCol = tex2D(_SkyTexture, skyUV).xyz;
                float reflectIntensity = _ReflectionIntensity;
                #if defined(_TIME_OF_DAY)
                    if(_DurationFlag < 0) {
                        reflectIntensity = lerp(_NightReflectionIntensity, _ReflectionIntensity, _CurTimeLerpVal);
                    }
                    else if(_DurationFlag == 0) {
                        reflectIntensity = lerp(_ReflectionIntensity, _DuskReflectionIntensity, _CurTimeLerpVal);
                    }
                    else {
                        reflectIntensity = lerp(_DuskReflectionIntensity, _NightReflectionIntensity, _CurTimeLerpVal);
                    }
                #endif

                reflectCol *= reflectIntensity;
                i.positionSS.y *= _ProjectionParams.x;
                float2 screenCoord = (i.positionSS.xy/i.positionSS.w) * 0.5 + 0.5;
                // Depth diff n->f
                float fragDepth = LinearEyeDepth(SampleSceneDepth(screenCoord), _ZBufferParams);
                float linearVertexDepth = LinearEyeDepth(i.positionCS.z, _ZBufferParams);
                float distanceFactor = saturate(10 / linearVertexDepth);
                float opticalDepth = fragDepth - linearVertexDepth;


                //#if defined (ENABLE_DEPTHMAP)
                    float edgeFoamMask = saturate(opticalDepth / _EdgeFoamDepth) * _EdgeFoamStep;
                    float edgeNoise = tex2D(_FoamNoiseTexture, i.uv.zw).x;
                    //float oneMinusEdgeNoise = 1 - step(edgeNoise, edgeFoamMask - randomMask);
                    float oneMinusEdgeNoise = 1 - smoothstep(edgeNoise - _FoamSmoothTrans, edgeNoise, edgeFoamMask - 0.5);
                    float3 edgeFoamColor = _EdgeFoamColor * oneMinusEdgeNoise;
                    //#if defined (ENABLE_DISTORT)
                        // Subsurface distort
                        // Do distort twice to make the object and refraction continues
                        for (int index = 0; index < 2; index++) {
                            //float3 distortVec = bumpWS * _RefractFactor * saturate(opticalDepth * 0.2) * distanceFactor;
                            float3 distortVec = normalWS * _RefractFactor * saturate(opticalDepth * 0.2) * distanceFactor;
                            distortVec.y = 0;
                            distortVec = TransformWorldToHClipDir(distortVec);
                            float2 distortUV = screenCoord + distortVec.xy;
                            float fragDepthDistort = SampleSceneDepth(distortUV.xy);
                            float linearFragDepthDistort = LinearEyeDepth(fragDepthDistort, _ZBufferParams);
                            // Update only if Zdistort>Zfrag
                            float isDistort = step(linearVertexDepth, linearFragDepthDistort);
                            opticalDepth = lerp(opticalDepth, linearFragDepthDistort - linearVertexDepth, isDistort);
                        }
                    //#endif
                    // Direct Specular  _Near < _Far
                    // np -> _Near 0.2; _Near -> _Far 0; _Far -> fp 1.0
                    float sunSpecMask = step(_SunSpecFarDis, fragDepth) + step(fragDepth, _SunSpecNearDis) * 0.2;
                    float3 halfVec = normalize(viewDirWS + lightDirWS);
                    float3 sunSpecIntensity = (dot(halfVec, normalWS) > _SunSpecThreshold) * _SunStrength * sunSpecMask;
                //#else
                //    //float opticalDepth = LinearEyeDepth(i.positionCS.z, _ZBBufferParams)
                //    float3 edgeFoamColor = 0;
                //    float3 sunSpecIntensity = 0;
                //#endif
                // [0, 1]
                float depthValue = pow(saturate(opticalDepth / _DepthValue), max(_DepthFactor, 0.01));

                int pixelLightCount = GetAdditionalLightsCount();
                float3 additionalDiffuse = 0;
                for(int j = 0; j < pixelLightCount; j++) {
                    Light light = GetAdditionalLight(j, i.positionWS);
                    half3 additionLightCol = light.color * (light.distanceAttenuation * light.shadowAttenuation);
                    additionalDiffuse += max(dot(normalWS, light.direction),0.0) * additionLightCol;
                }
                
                half3 shallowColor = 0;
                half3 deepColor = 0;
                half3 sunSpecColor = 0;
                #if defined(_TIME_OF_DAY)
                    if(_DurationFlag < 0) {
                        shallowColor = lerp(_NightShallowColor,_NoonShallowColor,_CurTimeLerpVal);
                        deepColor = lerp(_NightDeepColor, _NoonDeepColor, _CurTimeLerpVal);
                        sunSpecColor = lerp(_NightSunSpecularColor, _NoonSunSpecularColor, _CurTimeLerpVal);
                        additionalDiffuse *= (1 - _CurTimeLerpVal);
                    }
                    
                    else if(_DurationFlag == 0) {
                        shallowColor = lerp(_NoonShallowColor,_DuskShallowColor,_CurTimeLerpVal);
                        deepColor = lerp(_NoonDeepColor, _DuskDeepColor, _CurTimeLerpVal);
                        sunSpecColor = lerp(_NoonSunSpecularColor, _DuskSunSpecularColor, _CurTimeLerpVal);
                        additionalDiffuse *= _CurTimeLerpVal;
                    }
                    else {
                        shallowColor = lerp(_DuskShallowColor,_NightShallowColor,_CurTimeLerpVal);
                        deepColor = lerp(_DuskDeepColor, _NightDeepColor, _CurTimeLerpVal);
                        sunSpecColor = lerp(_DuskSunSpecularColor, _NightSunSpecularColor, _CurTimeLerpVal);
                        additionalDiffuse *= _CurTimeLerpVal;
                    }
                #else
                    shallowColor = _NoonShallowColor;
                    deepColor = _NoonDeepColor;
                    sunSpecColor = _NoonSunSpecularColor;
                #endif
                
                half3 baseColor = lerp(shallowColor, deepColor.xyz, depthValue);
                //reflection.xyz =NDotL * lerp(causticsM.rgb*_CausticsInteensity, reflection.xyz, depthValue);
                // Caustics only exists in shallow area
                half3 causticsCol = NDotL * causticsM.rgb * _CausticsIntensity *(1 - depthValue) *_CausticsColor;
                float alpha = lerp(causticsM.r, _MaxAlpha, depthValue);
                half3 diffuseColor = lerp(baseColor, reflectCol, fresnel); 
                half3 color = saturate(NDotL * diffuseColor + causticsCol.xyz + edgeFoamColor) + sunSpecIntensity * sunSpecColor + additionalDiffuse * diffuseColor;
                
                //#ifdef FOG OF WAR
                //    color.rgb = CalcFogOfWar(color.rgb, i.positionWS.xyz);
                //#endif
                return half4(color, alpha);
            }

            ENDHLSL
        }
        
    }
}

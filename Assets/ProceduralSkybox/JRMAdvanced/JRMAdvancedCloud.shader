Shader "JRMAdvanced/JRMAdvancedCloud"
{
    Properties
    {
        // 不考虑角色高于云层/云褪隐，忽略大气散射
        //[Header(_________Rayleigh Scatter_________)]
        //[NoScaleOffset]_IrradianceMap("Irradiance Map", 2D) = "white" {}
        //_UpPartSunColor("Up Part Sun Color", Color) = (0.00326,0.18243,0.63132,1)
        //_UpPartSkyColor("Up Part Sky Color", Color) = (0.02948,0.1609,0.27936,1)
        //_DownPartSunColor("Down Part Sun Color", Color) = (0.30759,0.346,0.24592,1)
        //_DownPartSkyColor("Down Part Sky Color", Color) = (0.04305,0.26222,0.46968,1)
        //_MainColorSunGatherFactor("Sun Gather Factor", Range(0, 1)) = 0.31277
        //_RayleighScatterAngle("Rayleigh Scatter Angle", Range(0, 1)) = 0.4

        //[Header(_________Mie Scatter_________)]
        //_SunAdditionColor("Sun Addition Color", Color) = (0.90409,0.7345,0.13709, 1)
        //_SunAdditionIntensity("Sun Addition Intensity", Range(0, 3)) = 1.48499
        //_MieScatterAngle("Mie Scatter Angle", Range(0, 1)) = 0.5

        [Header(_________Sun_________)]
        _SunScatterPower("Sun Scatter Power", Range(0, 1000)) = 1000
        _SunColor("Sun Color", Color) = (1, 1, 1, 1)
        _SunColorIntensity("Sun Color Intensity", Range(0, 10)) = 1
        _SunShineColor ("Sun Shine Color", Color) = (1, 1, 1, 1)

        [Header(_________Moon_________)]
        _MoonIntensity("Moon Intensity", Range(0, 1)) = 0.50 
        _MoonShineColor("Moon Shine Color", Color) = (1, 1, 1, 1)
        _MoonIntensityMax("Moon Intensity Max", Range(0, 1)) = 0.19794 

        [Header(_________Transmission_________)]
        _SunTransmission("Sun Transmission", Range(0, 10)) = 4.09789
        _MoonTransmission("Moon Transmission", Range(0, 10)) = 3.29897
        _TransmissionLDotVStartAt("Transmission LDotV StartAt", Range(0, 1)) = 0.80205

        [Header(_________Cloud_________)]
        _NoiseMap("Noise Map", 2D) = "white" {}
        _NoiseSpeed("Noise Speed", Float) = 0
        [NoScaleOffset]_CloudMap("Cloud Map", 2D) = "white" {}
        _NearBrightCloudColor("Near Bright Cloud Color", Color) = (1, 1, 1, 1)
        _FarBrightCloudColor("Far Bright Cloud Color", Color) = (1, 1, 1, 1)
        _NearDarkCloudColor("Near Dark Cloud Color", Color) = (1, 1, 1, 1)
        _FarDarkCloudColor("Far Dark Cloud Color", Color) = (1, 1, 1, 1)
        _CloudGatherFactor("Cloud Gather Factor", float) = 0.0881
        _CloudMoreBright("Cloud More Bright", Range(0, 1)) = 0.8299
        _NoiseScale("Noise Scale", float) = 0.0123
        _CloudSDFThreshold("Cloud SDF Threshold", Range(0, 1.1)) = 0.5

        [Header(_________Direction_________)]
        _RoleViewPos("Fake Role Pos", Vector) = (0, -100, 0)

    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float4 viewDirAndAngleToDown : TEXCOORD1;
                float4 cloudBrightAndDisapperFac : TEXCOORD2;
                //half3 dayPartColor : TEXCOORD3;
                half3 shineColor : TEXCOORD4;
                half3 transmissionColor : TEXCOORD5;
                half3 brightCloudColor : TEXCOORD6;
                half3 darkCloudColor : TEXCOORD7;
            };

            //sampler2D _IrradianceMap;
            sampler2D _NoiseMap;
            sampler2D _CloudMap;

            CBUFFER_START(UnityPerMaterial)
                //half3 _UpPartSunColor; 
                //half3 _UpPartSkyColor; 
                //half3 _DownPartSunColor; 
                //half3 _DownPartSkyColor; 
                //float _MainColorSunGatherFactor;
                //float _RayleighScatterAngle;

                //half3 _SunAdditionColor;
                //float _SunAdditionIntensity;
                //float _MieScatterAngle;

                float _SunScatterPower;
                half3 _SunColor;
                float _SunColorIntensity;
                half3 _SunShineColor;

                float _MoonIntensity;
                half3 _MoonShineColor; 
                float _MoonIntensityMax;

                float _SunTransmission;
                float _MoonTransmission;
                float _TransmissionLDotVStartAt;

                float4 _NoiseMap_ST;
                float _NoiseSpeed;
                half3 _NearBrightCloudColor;
                half3 _FarBrightCloudColor;
                half3 _NearDarkCloudColor;
                half3 _FarDarkCloudColor;
                float _CloudGatherFactor;
                float _CloudMoreBright; 
                float _NoiseScale;
                float _CloudSDFThreshold;
                float3 _RoleViewPos;
            CBUFFER_END

            float FastAcosForAbsCos(float in_abs_cos) {
                float _local_tmp = ((in_abs_cos * -0.0187292993068695068359375 + 0.074261002242565155029296875) * in_abs_cos - 0.212114393711090087890625) * in_abs_cos + 1.570728778839111328125;
                return _local_tmp * sqrt(1.0 - in_abs_cos);
            }

            float FastAcos(float in_cos) {
                float local_abs_cos = abs(in_cos);
                float local_abs_acos = FastAcosForAbsCos(local_abs_cos);
                return in_cos < 0.0 ?  PI - local_abs_acos : local_abs_acos;
            }

            Varyings vert (Attributes i)
            {
                Varyings o;
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);

                //float3 viewDirWS = normalize(positionWS - _WorldSpaceCameraPos);
                float3 viewDirWS = normalize(positionWS - _RoleViewPos);
                float VDotL = dot(viewDirWS, _MainLightPosition.xyz);
                float VDotLRemap = saturate(VDotL * 0.5 + 0.5);
                float VDotU = dot(viewDirWS, float3(0, 1, 0));
                float angleMiu = clamp(VDotU, -1.0, 1.0);
                float angleUpToDown = (HALF_PI - FastAcos(angleMiu)) * INV_HALF_PI;
                float VDotMoonRemap = dot(viewDirWS, -_MainLightPosition.xyz) * 0.5 + 0.5;
                //float VDotLDamp = max(0, lerp(1, VDotL, _MainColorSunGatherFactor));
                //VDotLDamp = VDotLDamp * VDotLDamp * VDotLDamp;
                float cloudDamp = max(0, lerp(1, VDotL, _CloudGatherFactor));
                cloudDamp = cloudDamp * cloudDamp * cloudDamp;
                float VDotUCoe1 = abs(VDotU) * _SunScatterPower;
                o.viewDirAndAngleToDown.w = angleUpToDown;
                o.viewDirAndAngleToDown.xyz = viewDirWS.xyz;
                o.uv.xy = i.uv.xy;
                o.uv.zw = (i.uv.xy + _Time.x * _NoiseSpeed) * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
                o.cloudBrightAndDisapperFac.x = VDotLRemap * _CloudMoreBright;
                o.cloudBrightAndDisapperFac.w = 1.0 - smoothstep(0, 0.4, _CloudSDFThreshold) * (1.0 - smoothstep(0.6, 1.0, _CloudSDFThreshold));
               
                o.brightCloudColor = lerp(_FarBrightCloudColor, _NearBrightCloudColor, cloudDamp);
                o.darkCloudColor = lerp(_FarDarkCloudColor, _NearDarkCloudColor, cloudDamp);


                // Atmospheric Scattering
                //float2 irradianceRuv = float2(abs(angleUpToDown) / max(_RayleighScatterAngle, 0.001), 0.5);
                //float irradianceR = tex2Dlod(_IrradianceMap, float4(irradianceRuv, 0.0, 0.0)).x;
                //half3 downPartColor = lerp(_DownPartSkyColor, _DownPartSunColor, VDotLDamp);
                //half3 upPartColor = lerp(_UpPartSkyColor, _UpPartSunColor, VDotLDamp);
                //half3 mainColor = lerp( upPartColor, downPartColor, irradianceR);

                //float2 irradianceGuv = float2(abs(angleUpToDown) / max(_MieScatterAngle, 0.001), 0.5);
                //float irradianceG = tex2Dlod(_IrradianceMap, float4(irradianceGuv, 0.0, 0.0)).y;
                //float3 sunAdditionPartColor = irradianceG * _SunAdditionColor * _SunAdditionIntensity;
                //float upFactor = smoothstep(0, 1, clamp((abs(_MainLightPosition.y) - 0.2) * 10/3, 0, 1));
                //float VDotLFactor = smoothstep(0, 1, (VDotLRemap-1)/0.7 + 1);
                //float sunAdditionPartFactor = lerp(VDotLFactor, 1.0, upFactor);
                //float3 additionPart = sunAdditionPartColor * sunAdditionPartFactor;
                //half3 sumIrradianceRGColor = mainColor + additionPart;

                //float sunDisk = dot(min(1, pow(VDotLRemap, VDotUCoe1 * float3(1, 0.1, 0.01))),
                //    float3(1, 0.12, 0.03)) * _SunColorIntensity * _SunColor;
        
                //float VDotLRemapSmooth = smoothstep(0, 1, 2 * VDotLRemap - 1.0);
                //o.dayPartColor = sunDisk * VDotLRemapSmooth + sumIrradianceRGColor;

                float VDotMoon = saturate(dot(viewDirWS, -_MainLightPosition.xyz));
                float moonIntensity = -abs(_MoonIntensity - 0.5) * 2.0 + 1.0;
                VDotMoon = smoothstep(0, 1, 2 * pow(VDotMoon, 5) - 1.0);
                half3 moonShine = moonIntensity * VDotMoon * _MoonShineColor * clamp(_MoonTransmission, 0.0, 0.8) * _MoonIntensityMax;
                half3 sunShine = saturate(pow(VDotLRemap, VDotUCoe1 * 0.5) * VDotU) * _SunShineColor * _SunColorIntensity;
                o.shineColor = moonShine + sunShine;
                    
                float VDotMoonFade = smoothstep(_TransmissionLDotVStartAt, 1.0, VDotMoonRemap) * _MoonTransmission * 0.1;
                float3 moonTransmission = VDotMoonFade * VDotMoonFade * _MoonShineColor;
                float VDotLFade = smoothstep(_TransmissionLDotVStartAt, 1.0, VDotLRemap) * _SunTransmission * 0.125;
                float sunTransmission = VDotLFade * VDotLFade * _SunColor;
        
                o.transmissionColor = moonTransmission + sunTransmission;
                return o;
            }



            half4 frag (Varyings i) : SV_Target
            {
                float disappearFactor = i.cloudBrightAndDisapperFac.w;
                float featherFactor = 0.1;
                float alphaDenominator =  min(disappearFactor + featherFactor, 1.0) - max(disappearFactor - featherFactor, 0.0);
                float3 noise = tex2D(_NoiseMap, i.uv.zw).xyz;
                float4 cloudMap = tex2D(_CloudMap, noise.z * (noise.xy - 0.5) * _NoiseScale + i.uv.xy);
                float alphaNumerator = cloudMap.z - max(disappearFactor - featherFactor, 0.0);
                float angleUpToDownBias = i.viewDirAndAngleToDown.w + 0.1;
                float outputAlpha = smoothstep(0, 1, alphaNumerator / alphaDenominator) * smoothstep(0, 1, angleUpToDownBias * 5.0)  * cloudMap.w;
                outputAlpha *= saturate((1 - disappearFactor) / 0.01);
                if (outputAlpha < 0.01)
                {
                    discard;
                }
                float alphaDenominator2 =  min(disappearFactor + featherFactor, 1.0) - max(disappearFactor - featherFactor, 0.0);
                float transmission = lerp(cloudMap.y, (1.0 - smoothstep(0, 1, alphaNumerator / alphaDenominator2)) * 4.0, disappearFactor);
                half3 cloudMainColor = lerp(i.darkCloudColor,  i.brightCloudColor, cloudMap.x);

                half3 sumCloudColor = cloudMainColor + i.transmissionColor * transmission + i.brightCloudColor * 0.04 +
                    i.shineColor * cloudMap.x;
                float cloudMoreBright = i.cloudBrightAndDisapperFac.x + 1.0;
                //float cloudVisableFactor = min(1.0, smoothstep(0, 1, i.viewDirAndAngleToDown.w * 10.0));
                //half4 finalColor = half4(lerp(i.dayPartColor, sumCloudColor * cloudMoreBright, cloudVisableFactor), outputAlpha);
                half4 finalColor = half4((sumCloudColor * cloudMoreBright), outputAlpha);
                return finalColor;
            }

            ENDHLSL
        }
        
    }
}

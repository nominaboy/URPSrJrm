Shader "JRMAdvanced/JRMAdvancedSkybox"
{
    Properties
    {
        [Header(_________Rayleigh Scatter_________)]
        [NoScaleOffset]_IrradianceMap("Irradiance Map", 2D) = "white" {}
        _UpPartSunColor("Up Part Sun Color", Color) = (0.00326,0.18243,0.63132,1)
        _UpPartSkyColor("Up Part Sky Color", Color) = (0.02948,0.1609,0.27936,1)
        _DownPartSunColor("Down Part Sun Color", Color) = (0.30759,0.346,0.24592,1)
        _DownPartSkyColor("Down Part Sky Color", Color) = (0.04305,0.26222,0.46968,1)
        _MainColorSunGatherFactor("Sun Gather Factor", Range(0, 1)) = 0.31277
        _RayleighScatterAngle("Rayleigh Scatter Angle", Range(0, 1)) = 0.4

        [Header(_________Mie Scatter_________)]
        _SunAdditionColor("Sun Addition Color", Color) = (0.90409,0.7345,0.13709, 1)
        _SunAdditionIntensity("Sun Addition Intensity", Range(0, 3)) = 1.48499
        _MieScatterAngle("Mie Scatter Angle", Range(0, 1)) = 0.5
        
        [Header(_________Sun_________)]
        _SunScatterPower("Sun Scatter Power", Range(0, 1000)) = 1000
        _SunColor("Sun Color", Color) = (1, 1, 1, 1)
        _SunColorIntensity("Sun Color Intensity", Range(0, 10)) = 1
        _SunRadius("Sun Radius", Range(0, 50)) = 1
        _SunInnerBoundary("Sun Inner Boundary", Range(0, 10)) = 1
        _SunOuterBoundary("Sun Outer Boundary", Range(0, 10)) = 1

        [Header(_________Horizon_________)]
        _HorizonScatter("Horizon Scatter", Range(0, 2)) = 1
        _HorizonScatterColor("Horizon Scatter Color", Color) = (0.1, 0.1, 0.1, 1)
        
        [Header(_________Moon_________)]
        _MoonTex("Moon Texture", 2D) = "white"{}
        _MoonRadius ("Moon Radius", Range(0, 10)) = 3
        _MoonMaskRadius("Moon Mask Radius", range(1, 10)) = 5
        _MainColorMoonGatherFactor("Moon Gather Factor", Range(0, 1)) = 0.31277
        _MoonScatterColor("Moon Scatter Color", Color) = (1,1,1,1)
        _MoonColor("Moon Color", Color) = (0.90625, 0.43019, 0.11743, 1)
        _MoonColorIntensity("Moon Color Intensity", Range(0, 10)) = 1.18529
        _MoonSGThreshold("Moon SG Threshold", Range(0, 0.2)) = 0.01

        [Header(_________Star_________)]
        _StarColorIntensity("Star Color Intensity", Range(0, 30)) = 0.8466
        _StarOcclusion("Star Occlusion", Range(0, 1)) = 0.80829
        _StarTex("Star Texture", 2D) = "white" {}
        _StarColorLut("Star Color Lut", 2D) = "white" {}
        _NoiseMap("Noise Map", 2D) = "white" {}
        _NoiseSpeed("Noise Speed", Range(0 , 1)) = 0.293
        
        [Header(_________Galaxy_________)]
        _GalaxyTex("Galaxy Texture", 2D) = "white"{}
        _GalaxyIntensity("Galaxy Intensity", range(0,2)) = 1

        [Header(_________Direction_________)]
        _RoleViewPos("Fake Role Pos", Vector) = (0, -100, 0)
        _SkyboxRotation("Skybox Rotation", Range(0, 360)) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "PreviewType" = "Skybox" }
        ZWrite Off
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _IrradianceMap;
            sampler2D _MoonTex;
            sampler2D _StarTex;
            sampler2D _StarColorLut;
            sampler2D _NoiseMap;
            sampler2D _GalaxyTex;

            CBUFFER_START(UnityPerMaterial)
                half3 _UpPartSunColor;
                half3 _UpPartSkyColor;
                half3 _DownPartSunColor;
                half3 _DownPartSkyColor;
                float _MainColorSunGatherFactor;
                float _RayleighScatterAngle;

                half3 _SunAdditionColor;
                float _SunAdditionIntensity;
                float _MieScatterAngle;
            
                float _SunScatterPower;
                half3 _SunColor;
                float _SunColorIntensity;
                float _SunRadius;
                float _SunInnerBoundary;
                float _SunOuterBoundary;
            
                float _HorizonScatter;
                half3 _HorizonScatterColor;

                float4 _MoonTex_ST;
                float _MoonRadius;
                float _MoonMaskRadius;
                float  _MainColorMoonGatherFactor;
                half3 _MoonScatterColor;
                half3  _MoonColor;
                float _MoonColorIntensity;
                float _MoonSGThreshold;

                float _StarColorIntensity;
                float _StarOcclusion;
                float4 _StarTex_ST;
                float4 _StarColorLut_ST;

                float4 _GalaxyTex_ST;
                float  _GalaxyIntensity;
            
                float4 _NoiseMap_ST;
                float _NoiseSpeed;
            
                float3 _RoleViewPos;
                float _SkyboxRotation;
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

            float3 RotateAroundYInDegrees (float3 positionWS, float degrees)
            {
                float alpha = degrees * PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float3(mul(m, positionWS.xz), positionWS.y).xzy;
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float4 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 uv : TEXCOORD0;
                float4 starUV : TEXCOORD1;
                float4 noiseUV : TEXCOORD2;
                float4 positionWSAndAngleToDown : TEXCOORD3;
                float4 positionCS : SV_POSITION;
            };
            

            Varyings vert (Attributes i)
            {
                Varyings o;
                o.uv = i.uv;
                //o.uv.xyz = RotateAroundYInDegrees(i.uv.xyz, _SkyboxRotation);
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                //positionWS = RotateAroundYInDegrees(positionWS, _SkyboxRotation);
                o.positionCS = TransformWorldToHClip(positionWS);

                o.starUV.xy = TRANSFORM_TEX(i.uv.xz, _StarTex);

                float4 timeScaleValue = _Time.y * _NoiseSpeed * float4(0.4, 0.2, 0.1, 0.5);
                o.noiseUV.xy = (i.uv.xy * _NoiseMap_ST.xy) + timeScaleValue.xy;
                o.noiseUV.zw = (i.uv.xz * _NoiseMap_ST.xy * 2.0) + timeScaleValue.zw;

                float3 viewDirWS = normalize(positionWS - _RoleViewPos);
                float VDotU = dot(viewDirWS, float3(0, 1, 0));
                float angleMiu = clamp(VDotU, -1.0, 1.0);
                float angleUpToDown = (HALF_PI - FastAcos(angleMiu)) * INV_HALF_PI;

                o.positionWSAndAngleToDown.xyz = positionWS;
                o.positionWSAndAngleToDown.w = angleUpToDown;

                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float3 viewDirWS = normalize(i.positionWSAndAngleToDown.xyz - _RoleViewPos);
                float VDotL = dot(viewDirWS, _MainLightPosition.xyz);
                float VDotLRemap = saturate(VDotL * 0.5 + 0.5);
                
                /******** Atmospheric Scattering ********/
                float VDotLDamp = max(0, lerp(1, VDotL, _MainColorSunGatherFactor));
                VDotLDamp = VDotLDamp * VDotLDamp * VDotLDamp;

                float2 irradianceRuv = float2(abs(i.positionWSAndAngleToDown.w) / max(_RayleighScatterAngle, 0.001), 0.5);
                float irradianceR = tex2Dlod(_IrradianceMap, float4( irradianceRuv, 0.0, 0.0)).x;
                half3 downPartColor = lerp(_DownPartSkyColor, _DownPartSunColor, VDotLDamp);
                half3 upPartColor = lerp(_UpPartSkyColor, _UpPartSunColor, VDotLDamp);
                half3 mainColor = lerp(upPartColor, downPartColor, irradianceR);

                float2 irradianceGuv = float2(abs(i.positionWSAndAngleToDown.w) / max(_MieScatterAngle, 0.001), 0.5);
                float irradianceG = tex2Dlod(_IrradianceMap, float4(irradianceGuv, 0.0, 0.0)).y;
                half3 sunAdditionPartColor = irradianceG * _SunAdditionColor * _SunAdditionIntensity;
                float upFactor = smoothstep(0, 1, clamp((abs(_MainLightPosition.y) - 0.2) * 10/3, 0, 1));
                float VDotLFactor = smoothstep(0, 1, (VDotLRemap-1)/0.7 + 1);
                float sunAdditionPartFactor = lerp(VDotLFactor, 1.0, upFactor);
                half3 additionPart = sunAdditionPartColor * sunAdditionPartFactor;

                half3 atmosphericScatteringColor = mainColor + additionPart;

                /******** Sun and Moon ********/
                float VDotU = dot(viewDirWS, float3(0, 1, 0));
                float VDotUCoe1 = abs(VDotU) * _SunScatterPower;

                half3 sunColor = dot(min(1, pow(VDotLRemap, VDotUCoe1 * float3(1, 0.1, 0.01))),
                    float3(1, 0.12, 0.03)) * _SunColorIntensity * _SunColor;

                float sunDist = distance(i.uv.xyz, _MainLightPosition.xyz);
                float moonDist = distance(i.uv.xyz, -_MainLightPosition.xyz);
                float sunArea = 1 - (sunDist * _SunRadius);
                sunArea = smoothstep(_SunInnerBoundary, _SunOuterBoundary, sunArea);
                float moonArea = 1 - saturate(moonDist * _MoonMaskRadius);
                float moonGalaxyMask = step(_MoonSGThreshold, moonDist);

                float moonArea2 = 1 - (moonDist * 0.5);
                moonArea2 = smoothstep(0.5, 1, moonArea2);
                float sunArea3 = 1 - (sunDist * 0.4);
                sunArea3 = smoothstep(0.05, 1.21, sunArea3);

                float3 lightDir = normalize(_MainLightPosition.xyz);
                float3 up = float3(0, 1, 0);
                if (abs(dot(up, lightDir)) > 0.99) // 避免up和光方向平行
                {
                    up = float3(1, 0, 0);
                }
                float3 right = normalize(cross(up, lightDir)); 
                float3 newUp = cross(lightDir, right);
                float3x3 lightMatrix = float3x3(right, newUp, lightDir);
                float2 moonUV = (mul(lightMatrix, i.uv.xyz)).xy;
                moonUV = moonUV * _MoonTex_ST.xy * _MoonRadius + _MoonTex_ST.zw;

                float _WorldPosDotUpstep = smoothstep(0, 0.1, VDotU);
                float _WorldPosDotUpstep1  = 1 - abs(VDotU);
                _WorldPosDotUpstep1 = smoothstep(0.4, 1, _WorldPosDotUpstep1);
                float4 moonTex = tex2D(_MoonTex, moonUV) * moonArea * _WorldPosDotUpstep; 
                sunArea = sunArea *  _WorldPosDotUpstep;
                float3 sunDiskArea = sunArea * _SunColorIntensity * _SunColor;
                sunColor = sunColor + sunDiskArea * 3;
                float nearToFarSmooth = smoothstep(0, 1, sunArea3);
                sunColor *= nearToFarSmooth;

                float VDotMoonDamp = max(0, lerp( 1, moonArea2 , _MainColorMoonGatherFactor ));
                VDotMoonDamp = VDotMoonDamp * VDotMoonDamp* VDotMoonDamp;
                half3 moonColor = moonTex.xyz * _MoonColor * _MoonColorIntensity + VDotMoonDamp * _MoonScatterColor;

                /******** Horizon Scattering ********/
                float sunArea2 = 1 - (sunDist * _HorizonScatter);// 地平线散射扩散
                float VDotSunDamp = max(0, lerp( 1, sunArea2 , _MainColorSunGatherFactor ));
                VDotSunDamp = VDotSunDamp * VDotSunDamp * VDotSunDamp;
                half3 horizonScatterColor = smoothstep(0.02, 0.5, saturate(VDotSunDamp * _WorldPosDotUpstep1)) * _HorizonScatterColor;
                // 过滤地平线以下
                //float _WorldPosDotUpstep2 = clamp(0,1,smoothstep(0,0.01,VDotU)+ smoothstep(0.5,1,_WorldPosDotUpstep1)) ;
                //horizonScatter = horizonScatter *  _WorldPosDotUpstep2;
                

                /******** Star ********/
                float starNoise1 = tex2D(_NoiseMap, i.noiseUV.xy).r;
                float starNoise2 = tex2D(_NoiseMap, i.noiseUV.zw).r;
                float star = tex2D(_StarTex, i.starUV.xy).r;
                star = star * starNoise1 * starNoise2;
                float starAngle = saturate(i.positionWSAndAngleToDown.w * 1.5);
                float starIntensity = star * starAngle * 3;
                float starColorNoise = tex2D(_NoiseMap, i.uv.xy * 20).r;
                float starOcclusion = saturate((starColorNoise - _StarOcclusion) / max(1.0 -_StarOcclusion, 0.01));
                starIntensity *= starOcclusion;
                float3 starColorLut = tex2D(_StarColorLut, float2(starColorNoise * _StarColorLut_ST.x + _StarColorLut_ST.z, 0.5)).xyz;
                half3 starColor = starColorLut * _StarColorIntensity;
                starColor = starIntensity * starColor * moonGalaxyMask;

                /******** Galaxy ********/
                float4 galaxyTex = tex2D(_GalaxyTex, i.uv.xz * _GalaxyTex_ST.xy + _GalaxyTex_ST.zw);
                half3 galaxyColor = saturate((galaxyTex.xyz * galaxyTex.w * VDotU * moonGalaxyMask * _GalaxyIntensity));

                return half4(horizonScatterColor + sunColor + moonColor + atmosphericScatteringColor + 
                    (starColor + galaxyColor) * saturate(-_MainLightPosition.y * 5), 1);
            }
            ENDHLSL
        }
    }
}

Shader "Jeremy/Boss/Boss"
{
    Properties
    {
        _Tint("Tint", Color) = (0,0,0,0.2)
        [HideInInspector]_ToonMap("Toon Map", 2D) = "white"{}
        _MainTex("MainTex", 2D) = "grey"{}
        // _FresnelColor("Fresnel Color",Color)=(1,0.5,0,1)
        _vect2("dif-x,fre-y,pow-z,Ill-w", Vector) = (2,2,2,4)
        // [MatierialToggle(_ILLUM_ON)]_Illum("Illum Enable",int)=0
        [Header(Illum)]
        [KeywordEnum(Off, On, Mask)] _Illum("Illum Type", Float) = 0
        [HDR]_MaskColor("Mask Color", Color) = (1,1,1,1)
        _MaskTex("MaskTex", 2D) = "white"{}
        _vectEF("ani-UV-xy,pow-z,null-w",Vector) = (2,2,2,4)

        [Header(Black Hole)]
        [Space]
		[Toggle(_BLACK_HOLE)] _BLACK_HOLE("_BLACK_HOLE", Float) = 0
        _Num("_Num", Int) = 1
        _NoiseTex("Noise Tex", 2D) = "white"{}

        _CenterUVScale1("_CenterUVScale1", Vector) = (0.25, 0.25, 1, 1)
        _Range1("_Range1", Range(0, 0.1)) = 0.05
        _SmoothIntensity1("_SmoothIntensity1", Range(0, 0.1)) = 0
        _SmoothWidth1("_SmoothWidth1", Range(0, 0.1)) = 0.01
        _OutlineWidth1("_OutlineWidth1", Range(0, 0.1)) = 0.01
        _NoiseIntensity1("_NoiseIntensity1", Range(0, 0.5)) = 0.05
        [Space]
        _CenterUVScale2("_CenterUVScale2", Vector) = (0.75, 0.75, 1, 1)
        _Range2("_Range2", Range(0, 0.1)) = 0.05
        _SmoothIntensity2("_SmoothIntensity2", Range(0, 0.1)) = 0
        _SmoothWidth2("_SmoothWidth2", Range(0, 0.1)) = 0.01
        _OutlineWidth2("_OutlineWidth2", Range(0, 0.1)) = 0.01
        _NoiseIntensity2("_NoiseIntensity2", Range(0, 0.5)) = 0.05

        _InsideColor("_InsideColor", Color) = (0, 0, 0, 0)
        _SmoothColor("_SmoothColor", Color) = (0, 0, 0, 0)
        _OutlineColor("_OutlineColor", Color) = (0, 0, 0, 0)
    }
    SubShader
    {
        
        Tags {"Renderpipeline"="UniveralRenderPipeline" "RenderType"="Opaque" "Queue"="Geometry"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _vect2;
            half4 _Tint;
            //#ifdef _ILLUM_MASK
                float4 _MaskTex_ST;
                half4 _vectEF;
                half4 _MaskColor;
            float _Illum;
            //#endif

            int _Num;
            float4 _NoiseTex_ST;
            float4 _CenterUVScale1;
            float4 _CenterUVScale2;
            float _Range1;
            float _SmoothIntensity1;
            float _SmoothWidth1;
            float _OutlineWidth1;
            float _NoiseIntensity1;
            float _Range2;
            float _SmoothIntensity2;
            float _SmoothWidth2;
            float _OutlineWidth2;
            float _NoiseIntensity2;
            half3 _InsideColor;
            half3 _SmoothColor;
            half3 _OutlineColor;

        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags { "LightMode"="UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature _ILLUM_OFF _ILLUM_ON _ILLUM_MASK
            #pragma shader_feature_local _ _BLACK_HOLE

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                #ifdef _ILLUM_MASK
                    float2 uvEF : VAR_UVEF;
                #endif
            };
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_ToonMap);SAMPLER(sampler_ToonMap);
            TEXTURE2D(_NoiseTex);SAMPLER(sampler_NoiseTex);
            #ifdef _ILLUM_MASK
                #define smp _linear_repeat
                TEXTURE2D(_MaskTex);
                SAMPLER(smp);
            #endif
            
            void BlackHole(float2 uv, float4 centerUVScale, float smoothIntensity, float noiseIntensity, float noise, float range, 
                float smoothWidth, float outlineWidth, in out half3 col)
            {
                float distance = length((uv - centerUVScale.xy) * centerUVScale.zw);

                float insideArea = smoothstep(distance - smoothIntensity, distance + smoothIntensity, range + noiseIntensity * noise);
                float smoothArea = step(distance, range + smoothWidth + noiseIntensity * noise);
                float outlineArea = step(distance, range + smoothWidth + outlineWidth + noiseIntensity * noise);

                col.rgb = lerp(col.rgb, _InsideColor.rgb, insideArea);
                col.rgb = lerp(col.rgb, _SmoothColor.rgb, smoothArea - insideArea);
                col.rgb = lerp(col.rgb, _OutlineColor.rgb, outlineArea - smoothArea);
            }




            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings)0;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.uv.xy = TRANSFORM_TEX(i.uv, _MainTex); 
                #ifdef _ILLUM_MASK
                    o.uvEF = i.uv * _MaskTex_ST.xy + _Time.y * _vectEF.xy;
                #endif

                #if defined(_BLACK_HOLE)
                    o.uv.zw = i.uv * _NoiseTex_ST.xy + _NoiseTex_ST.zw * _Time.y;                
                #endif
                return o;
            }
            
            half4 frag (Varyings i) : SV_Target
            {
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float NdotV = pow(1 - saturate(dot(N,V)), _vect2.y )*_vect2.z;
                float NdotL = saturate(dot(N, _MainLightPosition.xyz));
                
                half3 col = 1;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half4 toonMap = SAMPLE_TEXTURE2D(_ToonMap, sampler_ToonMap, NdotL);
                
                half4 diffuse = mainTex * (toonMap * _MainLightColor + unity_AmbientSky) ;
                col.rgb = diffuse.rgb * _vect2.x;//_LightColor0 unity_AmbientSky
                
                // //Shadow
                // float shadow = 1;
                // half4 shadowCoord = TransformWorldToShadowCoord(i.positionWS);
                // half3 bakedGI = half3(1, 1, 1);
                // ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                // half4 shadowParams = GetMainLightShadowParams();
                // #ifdef _SHADOWS_SOFT
                // shadow = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData);
                // #else
                // //// 1-tap hardware comparison
                // shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz);
                // #endif
                // col.rgb += NdotV * _vect2.w * _FresnelColor.rgb;
                #if defined(_ILLUM_ON)
                    col.rgb +=  mainTex.rgb * mainTex.a * _vect2.w;
                #elif defined(_ILLUM_MASK)
                    half4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, smp, i.uvEF.xy);
                    col.rgb += diffuse.a * maskTex.rgb * _MaskColor.rgb;
                #endif
                col.rgb += NdotV * ( _Tint.a * 10) * _Tint.rgb;

                #if defined(_BLACK_HOLE)
                    float noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.uv.zw).r - 0.5;

                    BlackHole(i.uv.xy, _CenterUVScale1, _SmoothIntensity1, _NoiseIntensity1, noise, _Range1, _SmoothWidth1, _OutlineWidth1, col);

                    if(_Num > 1) 
                    {
                        BlackHole(i.uv.xy, _CenterUVScale2, _SmoothIntensity2, _NoiseIntensity2, noise, _Range2, _SmoothWidth2, _OutlineWidth2, col);
                    }
                    
                #endif

                return half4(col, 1);
            }
            ENDHLSL
        }
        
        // UsePass "URP/Template/ShadowCast/ShadowCast"
    }
}

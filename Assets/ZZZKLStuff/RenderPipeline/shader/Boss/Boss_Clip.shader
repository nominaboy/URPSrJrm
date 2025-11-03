Shader "Jeremy/Boss/Boss_Clip"
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

        [Header(________PositionWSClip________)]
        [Space(10)]
        _ClipThresholdWS("Clip Threshold", Float) = 0
    }
    SubShader
    {
        
        Tags {"Renderpipeline"="UniveralRenderPipeline"  "Queue"="AlphaTest"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _vect2;
            half4 _Tint;
            float _Illum;
            //#ifdef _ILLUM_MASK
                float4 _MaskTex_ST;
                half4 _vectEF;
                half4 _MaskColor;
            //#endif
            half _ClipThresholdWS;
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

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 normalOS : NORMAL;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                #ifdef _ILLUM_MASK
                    float2 uvEF : VAR_UVEF;
                #endif
            };
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_ToonMap);SAMPLER(sampler_ToonMap);
            #ifdef _ILLUM_MASK
                #define smp _linear_repeat
                TEXTURE2D(_MaskTex);
                SAMPLER(smp);
            #endif
            
            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings)0;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex); 
                #ifdef _ILLUM_MASK
                    o.uvEF = i.uv * _MaskTex_ST.xy + _Time.y * _vectEF.xy;
                #endif
                return o;
            }
            
            half4 frag (Varyings i) : SV_Target
            {
                clip(i.positionWS.y - _ClipThresholdWS);
                float3 N = normalize(i.normalWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float NdotV = pow(1 - saturate(dot(N,V)), _vect2.y )*_vect2.z;
                float NdotL = saturate(dot(N, _MainLightPosition.xyz));
                
                half4 col = 1;
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
                return col;
                
            }
            ENDHLSL
        }
        
        // UsePass "URP/Template/ShadowCast/ShadowCast"
    }
}

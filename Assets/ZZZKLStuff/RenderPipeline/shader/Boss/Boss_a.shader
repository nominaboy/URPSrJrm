Shader "Jeremy/Boss/Boss_a"
{
    Properties
    {
        _Tint("Tint", Color) = (1,1,1,0.75)
        [HideInInspector]_ToonMap("Toon Map", 2D) = "white"{}
        _MainTex("MainTex", 2D) = "grey"{}
        _vect2("dif-x,fre-y,pow-z,Ill-w",Vector)=(2,2,2,4)
        // _Alpha("Alpha", Range(0,1))=1
        // [Toggle]_Illum("Illum Enable",int)=0
    }
    
    SubShader
    {
        
        Tags {"Renderpipeline"="UniveralRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent"}
        Blend SrcAlpha OneMinusSrcAlpha
        // ZWrite Off
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _vect2;
            half4 _Tint; //_FresnelColor,
            // int _Illum;
            // half _Alpha;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            // #pragma shader_feature _ _ILLUM_ON
            // #pragma multi_compile _ _ILLUM_ON

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
            };
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_ToonMap);SAMPLER(sampler_ToonMap);
            
            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings)0;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = TRANSFORM_TEX(i.uv, _MainTex); 
                return o;
            }
            
            half4 frag (Varyings i) : SV_Target
            {
                // half3 L = _MainLightPosition.xyz;
                // i.uv.zw = saturate(dot(i.worldNormal, L));
                // half3 N = i.worldNormal;
                // half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                // half NdotV = pow(1 - saturate(dot(N,V)), _vect2.y )*_vect2.z;
                // half3 H = normalize(L + V);
                // half3 L = _MainLightPosition.xyz;
                // half NdotL = max(0, dot(N,L));
                // i.uv.zw = NdotL * _uvScale.xy ;
                
                float3 N = normalize(i.normalWS);
                float NdotL = saturate(dot(N, _MainLightPosition.xyz));

                half4 col = 1;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half4 toonMap = SAMPLE_TEXTURE2D(_ToonMap, sampler_ToonMap, NdotL);
                
                half4 diffuse = mainTex * (toonMap * _MainLightColor + unity_AmbientSky) ;
                col.rgb = diffuse.rgb * _vect2.x;//_LightColor0 unity_AmbientSky
                // col.a = _Alpha;
                col *= _Tint;
                // //Shadow
                // float shadow = 1;
                // half4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
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
                // #if _ILLUM_ON
                // col.rgb +=  mainTex.rgb * mainTex.a * _vect2.w;
                // #endif
                // col.rgb += NdotV * ( _Tint.a * 10) * _Tint.rgb;
                return col;
                
            }
            ENDHLSL
        }
        
        // UsePass "URP/Template/ShadowCast/ShadowCast"
    }
}

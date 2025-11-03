Shader "Jeremy/BakeGI/Bake_GI_AlphaTest"
{
    Properties
    {
        [Enum (UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode",int) = 2
        _MainTex ("BaseMap(RGB A)", 2D) = "white" {}
        _Cutoff("Cutoff",Range(0,1.1)) = 0.5
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half _Cutoff;
    CBUFFER_END
    
    TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="TransparentCutout" "Queue"="AlphaTest"}
        Cull [_CullMode]

        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile _ LIGHTMAP_ON
            
            struct appdata
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
            };
            
            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float4 uv0AndLightmapUV : TEXCOORD0; // xy: uv0, zw: LightmapUV
                half3 normalWS : VAR_NORMALWS;
            };
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv0AndLightmapUV.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv0AndLightmapUV.zw = v.staticLightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                return o;
            }           
            
            half4 frag(v2f i) : SV_TARGET
            {
                half4 finalColor;
                //固有色
                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0AndLightmapUV.xy);//固有色采样
                finalColor = baseMap;
                clip(finalColor.a - _Cutoff);
                //烘焙GI采样
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.uv0AndLightmapUV.zw, i.normalWS.xyz);
                    finalColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    finalColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif

                return finalColor;
            }
            ENDHLSL
        }
    }
}

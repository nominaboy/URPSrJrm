Shader "Jeremy/Lit/LitSimple_Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "Queue"="Geometry" }
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include_with_pragmas "../Utils/KLFogOfWar.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 positionWS : VAR_POSITIONWS;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                finalColor.rgb *= _MainLightColor.xyz;
                #ifdef _KLFogOfWar
                    finalColor.rgb = CalcFogOfWar(finalColor.rgb, i.positionWS, i.positionCS.y / _ScaledScreenParams.y);
                #endif
                return finalColor;
            }
            ENDHLSL
        }
    }
}

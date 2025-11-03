Shader "Jeremy/Lit/LitSimple_Clip"
{
    Properties
    {
        [Space(10)]
        [Header(_________________________CbufferStart_________________________)]
        [Space(10)]
        [HDR]_Color("Color",Color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        _clipNum("ClipNum", Range(-1,1))=0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="TransparentCutout" "LightMode"="UniversalForward" "Queue"="AlphaTest" "IgnoreProject"="True"}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                float4 _MainTex_ST;
                half _clipNum;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half4 diffuse = mainTex * _MainLightColor;
                c = diffuse * _Color;
                clip(c.a - 0.5 - _clipNum);
                return c;
            }
            ENDHLSL
        }
    }
    // Fallback "Hidden/Shader Graph/FallbackError"
}

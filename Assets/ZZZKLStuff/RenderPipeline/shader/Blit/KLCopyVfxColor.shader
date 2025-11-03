Shader "Hidden/Jeremy/CopyVfxColor"
{
    Properties
    {
    }

    SubShader
    {
        Tags { "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}
        
        Pass
        {
            Name "KLCopyVfxColor"

            ZTest Always
            ZWrite Off
            Blend One SrcAlpha


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
                float2 uv : TEXCOORD0;
            };

            uniform TEXTURE2D(_CustomColorTexture0);
            uniform SAMPLER(sampler_CustomColorTexture0);

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }


            half4 frag(Varyings i) : SV_target
            {
                return SAMPLE_TEXTURE2D(_CustomColorTexture0, sampler_CustomColorTexture0, i.uv).rgba;
            }

            ENDHLSL

        }
    }
}

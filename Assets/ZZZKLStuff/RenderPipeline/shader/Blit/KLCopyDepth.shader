Shader "Jeremy/Blit/KLCopyDepth"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}

        Pass
        {
            Name "KL Copy Depth"
            ZTest Always ZWrite On ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionHCS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            uniform float _ScaleBiasDepthRT;

            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = float4(input.positionHCS.xyz, 1.0);
                output.uv = input.uv;
                output.positionCS.y *= _ScaleBiasDepthRT;
                return output;
            }

            TEXTURE2D_FLOAT(_CameraDepthAttachment);
            SAMPLER(sampler_CameraDepthAttachment);

            float frag(Varyings i) : SV_Depth
            {
                return SAMPLE_DEPTH_TEXTURE(_CameraDepthAttachment, sampler_CameraDepthAttachment, i.uv);
            }

            ENDHLSL
        }
    }
}


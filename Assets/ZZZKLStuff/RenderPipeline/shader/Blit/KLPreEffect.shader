Shader "Jeremy/Blit/KLPreEffect"
{
    HLSLINCLUDE
        #pragma exclude_renderers gles

        /******** KL Custom Post Processing ********/
        #pragma multi_compile_fragment _ _KL_RADIAL_BLUR
        #pragma multi_compile_fragment _ _KL_PIXELIZE_QUAD
        #pragma multi_compile_fragment _ _KL_RGB_SPLIT _KL_IMAGE_BLOCK _KL_ADVANCED_IMAGE_BLOCK
        #pragma multi_compile_fragment _ _KL_SCANLINE
        #pragma multi_compile_fragment _ _KL_HEAT_DISTORTION

        /******** KL Custom Post Processing ********/
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "../Utils/KLPPCommon.hlsl"
        
        TEXTURE2D(_CustomColorTexture0);

    ENDHLSL

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "PreEffect"

            HLSLPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                struct Attributes
                {
                    float4 positionOS : POSITION;
                    float2 uv         : TEXCOORD0;
                };

                struct Varyings
                {
                    float4 positionCS : SV_POSITION;
                    float2 uv         : TEXCOORD0;
                };

                Varyings vert(Attributes i)
                {
                    Varyings o;
                    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                    o.uv = i.uv;
                    return o;
                }

                half4 frag(Varyings input) : SV_Target
                {
                    half3 color = (0.0).xxx;
                    float2 uv = input.uv;
                    color = SAMPLE_TEXTURE2D(_CustomColorTexture0, rt_linear_clamp_sampler, uv).xyz;

                    /******** KL Custom Post Processing ********/

                    #if _KL_RADIAL_BLUR
                    {
                        color = ApplyRadialBlur(uv, TEXTURE2D_ARGS(_CustomColorTexture0, rt_linear_clamp_sampler));
                    }
                    #endif

                    #if _KL_HEAT_DISTORTION
                    {
                        color = ApplyHeatDistortion(uv, TEXTURE2D_ARGS(_CustomColorTexture0, rt_linear_clamp_sampler));
                    }
                    #endif

                    #if _KL_PIXELIZE_QUAD
                    {
                        color = ApplyPixelizeQuad(uv, TEXTURE2D_ARGS(_CustomColorTexture0, rt_linear_clamp_sampler));
                    }
                    #endif

                    #if _KL_RGB_SPLIT
                    {
                        color = ApplyRGBSplit(color, uv, TEXTURE2D_ARGS(_CustomColorTexture0, rt_linear_clamp_sampler));
                    }
                    #elif _KL_IMAGE_BLOCK
                    {
                        color = ApplyImageBlock(color, uv, TEXTURE2D_ARGS(_CustomColorTexture0, rt_linear_clamp_sampler));
                    }
                    #elif _KL_ADVANCED_IMAGE_BLOCK
                    {
                        color = ApplyAdvancedImageBlock(color, uv, TEXTURE2D_ARGS(_CustomColorTexture0, rt_linear_clamp_sampler));
                    }
                    #endif

                    #if _KL_SCANLINE
                    {
                        color = ApplyScanline(color, uv);
                    }
                    #endif

                    /******** KL Custom Post Processing ********/
            
                    return half4(color, 1.0);
                }
            ENDHLSL
        }
    }
}

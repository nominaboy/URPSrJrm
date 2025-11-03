Shader "Jeremy/Standard/KLStdScreenEffect"
{
    Properties
    {
        [Header(_________Functions_________)]
        [Space]
		[KeywordEnum(IMAGE_BLOCK, HEAT_DISTORTION, DEPTH_DECAL)] _FUNC("_FUNC", Int) = 0  

        [Header(_________Image Block_________)]
        [Space]
        _ImageBlockSize("Image Block Size", Range(1, 20)) = 1.0
        _ImageBlockRatio("Image Block Ratio", Range(1, 10)) = 4.0
        _ImageBlockSpeed("Image Block Speed", Range(0, 50)) = 10.0

        [Header(_________Heat Distortion_________)]
        [Space]
        _HeatDsrtNoiseTex("Heat Dsrt Noise Tex", 2D) = "white"{}
        _HeatDsrtMaskTex("Heat Dsrt Mask Tex", 2D) = "white"{}
        _HeatDsrtIntensity("Heat Dsrt Intensity", Range(0, 0.1)) = 0.0

        [Header(_________Depth Decal_________)]
        [Space]
        _DepthDecalTex("Depth Decal Tex", 2D) = "white"{}
        _DepthDecalColor("Depth Decal Color", Color) = (1, 1, 1, 1)

        _Rows("Rows", Int) = 1
        _Columns("Columns", Int) = 1
        _Frame("Frame", Int) = 0

    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Pass
        {
            Tags { "LightMode" = "KLStdScreenEffect" }
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _FUNC_IMAGE_BLOCK _FUNC_HEAT_DISTORTION _FUNC_DEPTH_DECAL

             

            // -------------------------------------

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "../Utils/KLUtils.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : VAR_UV;
            };

            TEXTURE2D(_CustomColorTexture0);
            SamplerState kl_linear_clamp_sampler;
            SamplerState kl_linear_repeat_sampler;

            #if defined(_FUNC_HEAT_DISTORTION)
                TEXTURE2D(_HeatDsrtNoiseTex);
                TEXTURE2D(_HeatDsrtMaskTex);
            #endif
            

            #if defined(_FUNC_DEPTH_DECAL)
                TEXTURE2D_FLOAT(_CustomDepthTexture0);
                SAMPLER(sampler_CustomDepthTexture0);
                TEXTURE2D(_DepthDecalTex);
            #endif

            CBUFFER_START(UnityPerMaterial)
                float _ImageBlockSize;
                float _ImageBlockRatio;
                float _ImageBlockSpeed;

                float _HeatDsrtIntensity;
                float4 _HeatDsrtNoiseTex_ST;

                half4 _DepthDecalColor;
                int _Rows;
                int _Columns;
                int _Frame;
            CBUFFER_END

            Varyings vert (Attributes i) {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            half4 frag (Varyings i) : SV_Target {
                half4 color = 1.0f;
                float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;

                #if defined(_FUNC_IMAGE_BLOCK)
                    float block = RandomImageBlockNoiseV2(floor(i.uv * _ImageBlockSize * float2(1, _ImageBlockRatio)), _ImageBlockSpeed);
                    block = block * block;
                    block = block * block;
                    block = block * block;
                    color.r = SAMPLE_TEXTURE2D(_CustomColorTexture0, kl_linear_clamp_sampler, screenUV).r;
                    color.g = SAMPLE_TEXTURE2D(_CustomColorTexture0, kl_linear_clamp_sampler, screenUV + 
                        float2(block * 0.05 * RandomImageBlockNoise(7.0, _ImageBlockSpeed), 0.0)).g;
                        // * ((float2(block * 0.05 * RandomImageBlockNoise(7.0, _ImageBlockSpeed), 0.0)) * _TestVector.y);
                    color.b = SAMPLE_TEXTURE2D(_CustomColorTexture0, kl_linear_clamp_sampler, screenUV - 
                        float2(block * 0.05 * RandomImageBlockNoise(13.0, _ImageBlockSpeed), 0.0)).b;
                        // * ((float2(block * 0.05 * RandomImageBlockNoise(13.0, _ImageBlockSpeed), 0.0)) * _TestVector.z);
                    // alpha = color.r + color.g + color.b;

                #elif defined(_FUNC_HEAT_DISTORTION)
                    float2 dsrtNoiseUV = i.uv * _HeatDsrtNoiseTex_ST.xy + _HeatDsrtNoiseTex_ST.zw * _Time.y;
                    float dsrtNoise = SAMPLE_TEXTURE2D(_HeatDsrtNoiseTex, kl_linear_repeat_sampler, dsrtNoiseUV).r;
                    float dsrtMask = SAMPLE_TEXTURE2D(_HeatDsrtMaskTex, kl_linear_clamp_sampler, i.uv).r;
                    float2 dsrtUV = lerp(screenUV, dsrtNoise, _HeatDsrtIntensity * dsrtMask);
                    color.rgb = SAMPLE_TEXTURE2D(_CustomColorTexture0, kl_linear_clamp_sampler, dsrtUV).rgb;

                #elif defined(_FUNC_DEPTH_DECAL)
                    float depth = SAMPLE_DEPTH_TEXTURE(_CustomDepthTexture0, sampler_CustomDepthTexture0, screenUV);
                    #if UNITY_REVERSED_Z
                        depth = depth;
                    #else
                        // Adjust Z to match NDC for OpenGL ([-1, 1])
                        depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
                    #endif
                    float3 positionWS = ComputeWorldSpacePosition(screenUV, depth, UNITY_MATRIX_I_VP);
                    float3 positionOS = TransformWorldToObject(positionWS);
                    clip(float3(0.5, 0.5, 0.5) - abs(positionOS));
                    float2 decalUV = positionOS.xz + 0.5;

                    // Sequence Animation
                    int totalFrames = _Rows * _Columns;
                    //int frameIndex = (int)(_Time.y * 10) % totalFrames;
                    int frameIndex = (int)_Frame;
                    frameIndex = clamp(frameIndex, 0, totalFrames - 1);
                    int row = floor(frameIndex / _Columns);
                    int col = frameIndex % _Columns;
                    float2 frameSize = float2(1.0 / _Columns, 1.0 / _Rows);
                    float2 offset = float2(col * frameSize.x, 1 - (row + 1) * frameSize.y);
                    decalUV = decalUV * frameSize + offset;

                    color = SAMPLE_TEXTURE2D(_DepthDecalTex, kl_linear_clamp_sampler, decalUV).rgba;
                    color *= _DepthDecalColor.rgba;
                #endif


                return color;
            }

            ENDHLSL
        }
        
    }
}

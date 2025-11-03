Shader "Jeremy/Weather/KLMapFogRT"
{
	Properties
    {
        _NoiseTexture("Noise Texture", 2D) = "black"{}
        _MaskTexture("Mask Texture", 2D) = "black"{}
        _Speed("Speed", Vector) = (-0.08, -0.01, 0, 0)
        _NoiseIntensity("Noise Intensity", Float) = 0.18
        _MaskIntensity("Mask Intensity", Range(0, 5)) = 4
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        Pass
        {
            Tags { "LightMode" = "ChapterMapFog" }
            Blend One Zero
            BlendOp Min
            ColorMask R
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma enable_d3d11_debug_symbols
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : VAR_UV;
            };
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);

            TEXTURE2D(_MaskTexture);
            SAMPLER(sampler_MaskTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _NoiseTexture_ST;
                float2 _Speed;
                float _NoiseIntensity;
                float _MaskIntensity;
            CBUFFER_END

            Varyings vert (Attributes i) 
            {
                Varyings o = (Varyings) 0;
                o.uv.xy = i.uv;
                o.uv.zw = TRANSFORM_TEX(i.uv, _NoiseTexture) + frac(_Time.y * _Speed.xy);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target 
            {
                half noise = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, i.uv.zw).r;
                float2 maskUV = i.uv.xy + noise * _NoiseIntensity;
                half mask = SAMPLE_TEXTURE2D(_MaskTexture, sampler_MaskTexture, maskUV).r;
                mask = saturate(mask * _MaskIntensity);
                return half4(mask, 0, 0, 0);
            }

            ENDHLSL
        }
        
    }
}

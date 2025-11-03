Shader "JRMFOWCloud/2DMapFOWRT"
{
    Properties
    {
        _NoiseTexture("Noise Texture", 2D) = "black"{}
        _OriginalMask("Original Mask", 2D) = "black"{}
        _Speed("Speed", Vector) = (-0.08, -0.01, 0, 0)
        _NoiseIntensity("Noise Intensity", Float) = 0.18
        _MaskIntensity("Mask Intensity", Range(0, 5)) = 4
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
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
                float4 uv : TEXCOORD0;
            };
            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);

            TEXTURE2D(_OriginalMask);
            SAMPLER(sampler_OriginalMask);

            CBUFFER_START(UnityPerMaterial)
                float4 _NoiseTexture_ST;
                float2 _Speed;
                float _NoiseIntensity;
                float _MaskIntensity;
            CBUFFER_END

            


            Varyings vert (Attributes i) {
                Varyings o = (Varyings) 0;

                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv.xy = i.uv;

                o.uv.zw = TRANSFORM_TEX(i.uv, _NoiseTexture) + frac(_Time.y * _Speed.xy);
                
                return o;
            }



            half4 frag (Varyings i) : SV_Target {
                half3 color = 0.0f;

                half noise = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, i.uv.zw).r;
                float2 actUV = i.uv.xy + noise * _NoiseIntensity;


                half originalMask = SAMPLE_TEXTURE2D(_OriginalMask, sampler_OriginalMask, actUV).a;
                originalMask = saturate(originalMask * _MaskIntensity);
                
                return half4(originalMask.rrr, originalMask);
            }

            ENDHLSL
        }
        
    }
}

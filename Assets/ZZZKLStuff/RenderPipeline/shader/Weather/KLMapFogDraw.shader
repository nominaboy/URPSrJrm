Shader "Jeremy/Weather/KLMapFogDraw"
{
    Properties
    {
        _NoiseTexture("Noise Texture", 2D) = "black"{}
        _MaskTexture("Mask Texture", 2D) = "black"{}
        _BaseColor("Base Color", Color) = (0.765, 0.765, 0.765, 1)
        _NoiseIntensity("Noise Intensity", Float) = 0.17
        _FogIntensity("Fog Intensity", Float) = 1.5
        _Speed("Speed", Vector) = (-0.06, -0.01, 0, 0)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
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
                float4 uv : VAR_UV;
            };
            TEXTURE2D(_MapFogRenderTexture);
            SamplerState rt_linear_clamp_sampler;

            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);

            TEXTURE2D(_MaskTexture);
            SAMPLER(sampler_MaskTexture);

            CBUFFER_START(UnityPerMaterial)
                float4 _NoiseTexture_ST;
                half4 _BaseColor;
                half _NoiseIntensity;
                half _FogIntensity;
                float2 _Speed;
            CBUFFER_END

            Varyings vert (Attributes i) {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv.xy = i.uv;
                o.uv.zw = TRANSFORM_TEX(i.uv, _NoiseTexture) + frac(_Time.y * _Speed.xy);
                return o;
            }

            half4 frag (Varyings i) : SV_Target {
                half4 color = 0.0f;
                float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
                half noise = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, i.uv.zw).r;
                noise = noise * 2 - 1;
                float2 maskUV = i.uv.xy + noise * _NoiseIntensity;
                half mask = SAMPLE_TEXTURE2D(_MaskTexture, sampler_MaskTexture, maskUV).r; // World Mask
                half rt = SAMPLE_TEXTURE2D(_MapFogRenderTexture, rt_linear_clamp_sampler, screenUV).r;
                half rtLerpVal = lerp(rt, mask, rt);
                color.rgb = _BaseColor.rgb;
                color.a = saturate(rtLerpVal * _FogIntensity) * _BaseColor.a;
                return color;
            }

            ENDHLSL
        }
        
    }
}

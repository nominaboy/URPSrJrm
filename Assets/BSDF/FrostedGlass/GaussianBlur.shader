Shader "Jeremy/Translucent/GaussianBlur"
{
	Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
    }

    SubShader
    {
        ZTest Always
        Cull Back
        ZWrite Off

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct Attributes
        {
            float4 positionOS : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct Varyings
        {
            float2 uv[5] : TEXCOORD0;
            float4 positionCS : SV_POSITION;
        };

        float _BlurSize;
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        float4 _MainTex_TexelSize;

        Varyings vertBlurVertical(Attributes i)
        {
            Varyings o;
            o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
            float2 uv = i.uv;
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            return o;
        }

        Varyings vertBlurHorizontal(Attributes i)
        {
            Varyings o = (Varyings)0;
            o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
            float2 uv = i.uv;
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            return o;
        }

        half4 fragBlur(Varyings i) : SV_Target
        {
            float weight[3] = {0.4026, 0.2442, 0.0545};
            half3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]).rgb * weight[0];
            for (int j = 1; j < 3; j++)
            {
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[j * 2 - 1]).rgb * weight[j];
                sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[j * 2]).rgb * weight[j];
            }
            return half4(sum, 1.0);
        }
        ENDHLSL

        Pass
        {
            Name "Vertical Gaussian Blur"
            HLSLPROGRAM
            #pragma vertex vertBlurVertical
            #pragma fragment fragBlur
            ENDHLSL
        }

        Pass
        {
            Name "Horizontal Gaussian Blur"
            HLSLPROGRAM
            #pragma vertex vertBlurHorizontal
            #pragma fragment fragBlur
            ENDHLSL
        }
    }
}
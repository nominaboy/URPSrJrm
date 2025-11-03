Shader "Jeremy/Translucent/FrostedGlass"
{
    Properties
    {
        [Header(_______Diffuse_______)]
        [Space]
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_MaskTex("Mask Texture", 2D) = "white"{}
        _MaskPow("Mask Pow", Range(0.01, 2)) = 0.1
    }

    SubShader
    {
		Tags { "Queue" = "Transparent" }

        Pass
        {
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On

            Tags { "LightMode" = "Translucent" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			TEXTURE2D(_MaskTex);
			TEXTURE2D(_GaussianBlurBuffer0);
			SamplerState kl_linear_clamp_sampler;
			SamplerState kl_linear_repeat_sampler;
			
            CBUFFER_START(UnityPerMaterial)
				half4 _BaseColor;
                float4 _MaskTex_ST;
                float _MaskPow;
            CBUFFER_END

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

            Varyings vert (Attributes i)
            {
				Varyings o = (Varyings)0;
                o.uv = TRANSFORM_TEX(i.uv, _MaskTex);
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
                half3 blurColor = SAMPLE_TEXTURE2D(_GaussianBlurBuffer0, kl_linear_clamp_sampler, screenUV).rgb;
                half mask = SAMPLE_TEXTURE2D(_MaskTex, kl_linear_repeat_sampler, i.uv).r;
				half4 finalColor = half4(0, 0, 0, 0);
                finalColor.rgb = blurColor * _BaseColor.rgb;
                finalColor.a = pow(mask, _MaskPow);
				return finalColor;
            }
            ENDHLSL
        }
    }
}

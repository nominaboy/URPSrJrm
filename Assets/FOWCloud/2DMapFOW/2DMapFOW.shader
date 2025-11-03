Shader "JRMFOWCloud/2DMapFOW"
{
    Properties
    {
        _FOWRT("FOW RT", 2D) = "black"{}
        _NoiseTexture("Noise Texture", 2D) = "black"{}
        _FinalMask("Final Mask", 2D) = "black"{}
        _Speed("Speed", Vector) = (-0.08, -0.01, 0, 0)

        _TestVec1("TestVec1", Vector) = (1.45, 1.0, 0, 0)
        _BaseColor("Base Color", Color) = (0.766, 0.766, 0.766, 1)
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
            TEXTURE2D(_FOWRT);
            SAMPLER(sampler_FOWRT);

            TEXTURE2D(_NoiseTexture);
            SAMPLER(sampler_NoiseTexture);

            TEXTURE2D(_FinalMask);
            SAMPLER(sampler_FinalMask);

            CBUFFER_START(UnityPerMaterial)
                float4 _NoiseTexture_ST;
                float2 _Speed;

                float4 _TestVec1;
                half4 _BaseColor;
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




                half noise = SAMPLE_TEXTURE2D(_NoiseTexture, sampler_NoiseTexture, i.uv.zw).b;
                float2 actUV = i.uv.xy + noise * 0.18;

                half finalMask = SAMPLE_TEXTURE2D(_FinalMask, sampler_FinalMask, actUV).a; // World Mask
                
                half fowRT = SAMPLE_TEXTURE2D(_FOWRT, sampler_FOWRT, screenUV).r;
                
                half val = lerp(fowRT, finalMask, fowRT);

                color.rgb = _BaseColor.rgb;

                color.a = saturate(val * _TestVec1.x) * _BaseColor.a;

                return color;

            }

            ENDHLSL
        }
        
    }
}

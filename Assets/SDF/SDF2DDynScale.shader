Shader "Jeremy/SDF/SDF2DDynScale"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVScale("UV Scale", Range(0, 100)) = 1

        _InsideColor("Inside Color", Color) = (1, 1, 1, 1)
        _EdgeColor1("Edge Color", Color) = (1, 1, 1, 1)
        _EdgeColor2("Edge Color2", Color) = (1, 1, 1, 1)
        _EdgeWidth1("Edge Width1", Range(0,1)) = 0.3
        _EdgeWidth2("Edge Width2", Range(0,1)) = 0.5
        _EdgeWidth3("Edge Width3", Range(0,1)) = 0.7

        _RectMain("Rect Main", Vector) = (0.23, 0.382, 1, 0)
        _RoundRectRatio("Round Rect Ratio", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags{ "Queue" = "Transparent" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest Always
            ZWrite Off
            Cull Off
            Tags{ "LightMode" = "UniversalForward" }

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #pragma vertex vert
            #pragma fragment frag

            CBUFFER_START(UnityPerMaterial)
                half _UVScale;
                half4 _InsideColor;
                half4 _EdgeColor1;
                half4 _EdgeColor2;
                half _EdgeWidth1;
                half _EdgeWidth2;
                half _EdgeWidth3;
                half4 _RectMain;
                half _RoundRectRatio;
            CBUFFER_END

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

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            float sdfRoundRect(float2 coord,  float2 center, float width, float height, float r)
            {
                float2 d = abs(coord - center) - float2(width, height);
                return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                float ratio = _ScaledScreenParams.x / _ScaledScreenParams.y;
                float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
                float2 scale = float2(ratio, 1) * _UVScale;
                screenUV *= scale;
                float sdfValue = sdfRoundRect(screenUV, float2(_RectMain.x, 1 - _RectMain.y) * scale, _RectMain.z, _RectMain.w, _RoundRectRatio);

                half lerpVal1 = step(0, sdfValue);
                half lerpVal2 = step(_EdgeWidth1, sdfValue);
                half lerpVal3 = step(_EdgeWidth2, sdfValue);
                half lerpVal4 = step(_EdgeWidth3, sdfValue);

                half4 transColor = half4(0, 0, 0, 0);
                half4 color = lerp(_InsideColor, transColor, lerpVal1);
                color = lerp(color, _EdgeColor1, lerpVal1 - lerpVal2);
                color = lerp(color, transColor, lerpVal2 - lerpVal3);
                color = lerp(color, _EdgeColor2, lerpVal3 - lerpVal4);

                return color;
            }
            ENDHLSL
        }
    }
}
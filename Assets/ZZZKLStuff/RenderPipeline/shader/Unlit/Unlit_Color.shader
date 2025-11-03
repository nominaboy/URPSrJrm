Shader "Jeremy/Unlit/Unlit_Color"
{
    Properties
    {
        _Tint("Tint", Color) = (0, 0, 0, 0)
        _vect2("dif-x,fre-y,pow-z,Ill-w", Vector) = (2,2,2,4)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "Queue"="Geometry" }
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _Tint;
                half4 _vect2;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                return half4(_Tint.rgb * ( _vect2.x + 2), 1);
            }
            ENDHLSL
        }
    }
}

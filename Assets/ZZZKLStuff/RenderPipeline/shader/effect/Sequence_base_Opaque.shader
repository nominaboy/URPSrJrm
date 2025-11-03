Shader "Jeremy/Sequence/SequenceBase_Opaque"
{
    Properties
    {
        [Enum (UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode",int) = 2
        [HDR]_Color("Color",Color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        [Header(Row(X)  Cloum(Y)  Frame(Z)  Null(W))]
        [Space(10)]
        _Sequence("",vector)=(3,3,2,0)
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline"  "LightMode"="UniversalForward" "Queue"="Geometry" "IgnoreProject"="True"}

        Pass
        {
            Cull [_CullMode]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color,_Sequence;
                float4 _MainTex_ST;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float3 positionWS : VAR_POSITIONWS;
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;
                o.color = i.color;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv.xy = float2(i.uv.x/_Sequence.y, i.uv.y/_Sequence.x+(_Sequence.x-1)/_Sequence.x);

                o.uv.x = o.uv.x + frac(floor(_Sequence.z)/_Sequence.y);
                o.uv.y = o.uv.y - frac(floor(_Sequence.z/_Sequence.y)/_Sequence.x);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half3 c;
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb;
                c = mainTex * _Color.rgb;         
                c.rgb *= i.color.rgb;
                return half4(c, 1);
            }

            ENDHLSL

        }
    }
    //CustomEditor "Sequence_baseGUI"
    Fallback "Hidden/Shader Graph/FallbackError"
}

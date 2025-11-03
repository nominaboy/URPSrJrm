Shader "Jeremy/Sequence/Sequence_uvAnim"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0

        [HDR]_Color("Color",Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
        [NoScaleOffset]_MaskSequenceTex ("MaskSequenceTex", 2D) = "white" {}
        [Header(Row(X)  Cloum(Y)  Frame(Z)  Null(W))]
        [Space(10)]
        _Sequence("",vector)=(3,3,2,0)
        [Header(U(X)  V(Y)  null(Z)  Null(W))]
        [Space(10)]
        _UVSpeed("",vector)=(0,0,0,0)

        [Header(____________UV Animation____________)]
        [Space(10)]
        [Toggle(_XYANIM)] _XYAnimation("XYAnimation On", float) = 0
        [Toggle(_ZWANIM)] _ZWAnimation("ZWAnimation On", float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "LightMode"="UniversalForward" "Queue"="Transparent" "IgnoreProject"="True"}

        Pass
        {
            Blend [_SrcFactor] [_DstFactor]
            Cull back
            ZWrite off
            //ZTest LEqual

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _XYANIM
            #pragma shader_feature _ZWANIM
            //pragmas
            #pragma target 3.0
            

            //Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color,_Sequence;
                half4 _UVSpeed;
                float4 _MainTex_ST;
            CBUFFER_END

            // #define smp _linear_clamp//sampler_MaskSequenceTex //_linear_clampU_repeatV, mirror
            TEXTURE2D(_MaskSequenceTex);SAMPLER(sampler_MaskSequenceTex);
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            // SAMPLER(smp);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD;
                float4 color : COLOR;
            };

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;
                float timeXY = 1;
                float timeZW = 1;
                #ifdef _XYANIM
                    timeXY = _Time.w;
                #endif
                #ifdef _ZWANIM
                    timeZW = _Time.y;
                #endif

                o.color = i.color;
                o.positionCS = TransformObjectToHClip(i.positionOS);
                o.uv.xy = float2(i.uv.x/_Sequence.y, i.uv.y/_Sequence.x+(_Sequence.x-1)/_Sequence.x);

                o.uv.x = o.uv.x + frac(floor(timeXY * _Sequence.z)/_Sequence.y);
                o.uv.y = o.uv.y - frac(floor(timeXY * _Sequence.z/_Sequence.y)/_Sequence.x);

                o.uv.zw = i.uv * _MainTex_ST.xy + frac(timeZW * _UVSpeed.xy);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 c;
                half4 maskSequenceTex = SAMPLE_TEXTURE2D(_MaskSequenceTex, sampler_MaskSequenceTex, i.uv.xy);
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.zw);
                c = mainTex * _Color * i.color;      
                c.a = c.a * maskSequenceTex.a;
                return c;
            }

            ENDHLSL

        }
    }
    Fallback "Hidden/Shader Graph/FallbackError"
}

Shader "Jeremy/Sequence/Sequence_Base_Clip"
{
    Properties
    {
        [HDR]_Color("Color",Color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        _LightLerpCoe("_LightLerpCoe", Range(0, 1)) = 1
        [Header(Row(X)  Cloum(Y)  Frame(Z)  Null(W))]
        [Space(10)]
        _Sequence("",vector)=(3,3,2,0)
        
        [Header(____________BillBorad____________)]
        [Space(10)]
        [Toggle(_BILLBORAD)] _BillboardOn("Billboard On", float) = 0

        [Header(____________UV Animation____________)]
        [Space(10)]
        [Toggle(_UVANIM)] _UVAnimation("UVAnimation On", float) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="TransparentCutout" "LightMode"="UniversalForward" "Queue"="AlphaTest" "IgnoreProject"="True"}

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _BILLBORAD
            #pragma shader_feature _UVANIM

            #pragma target 3.0
            // #pragma target 2.0
            // #pragma multi_compile_instancing

            //Includes
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _Color,_Sequence;
                float4 _MainTex_ST;
                half _LightLerpCoe;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
                // float4 normalOS :NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
                // float3 normalWS : TEXCOORD1;
            };

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;

                float3 positionOS = i.positionOS.xyz;
                #ifdef _BILLBORAD
                    float3 viewDir = mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos,1)).xyz;
                    viewDir = normalize(viewDir);
                    float3 upDir = float3(0,1,0);
                    float3 rightDir = normalize(cross(viewDir,upDir));
                    upDir = cross(rightDir,viewDir);
                    positionOS = rightDir * positionOS.x + upDir * positionOS.y + viewDir * positionOS.z;
                #endif

                float time = 1;
                #ifdef _UVANIM
                    time *= _Time.w;
                #endif


                o.positionCS = TransformObjectToHClip(positionOS);
                o.uv.xy = float2(i.uv.x/_Sequence.y, i.uv.y/_Sequence.x+(_Sequence.x-1)/_Sequence.x);

                o.uv.x = o.uv.x + frac(floor(time * _Sequence.z)/_Sequence.y);
                o.uv.y = o.uv.y - frac(floor(time * _Sequence.z/_Sequence.y)/_Sequence.x);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half3 diffuse = mainTex.rgb * lerp(1, _MainLightColor.rgb, _LightLerpCoe);
                c = half4(diffuse, mainTex.a) * _Color;
                clip(c.a - 0.5 - _Sequence.w);
                return c;
            }
            ENDHLSL
        }
    }
    // Fallback "Hidden/Shader Graph/FallbackError"
}

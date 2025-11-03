Shader "Jeremy/Outline/OutlineUVs"
{
    Properties
    {
        [Header(TexCoord3_UV4ToAvarageNormal)]
        _OutlineColor("OutlineColor", Color) = (0.5, 0.5, 0.5, 1)
        _OutlineLen("OutlineWidth", Range(0, 20)) = 1

        [Header(________PositionWSClip________)]
        [Space(10)]
        _ClipThresholdWS("Clip Threshold", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        HLSLINCLUDE
            #pragma target 3.0
            // #pragma enable_d3d11_debug_symbols
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			CBUFFER_START(UnityPerMaterial)
				float _OutlineLen;
				half3 _OutlineColor;
                half _ClipThresholdWS;
			CBUFFER_END

            float3 OctahedronToUnitVector(float2 oct)
            {
                float3 unitVec = float3(oct, 1 - dot(float2(1, 1), abs(oct)));
                if (unitVec.z < 0)
                {
                    unitVec.xy = (1 - abs(unitVec.yx)) * float2(unitVec.x >= 0 ? 1 : -1, unitVec.y >= 0 ? 1 : -1);
                }
                return normalize(unitVec);
            }
    
            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 smoothNormal : TEXCOORD3;
            };
                
            struct Varyings
            {
                float3 positionWS : VAR_POSITIONWS;
                float4 positionCS : SV_POSITION;
            };

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(i.positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                
                float3 normalTS = OctahedronToUnitVector(i.smoothNormal);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS, i.tangentOS);
                float3x3 tangentToWorld = float3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS);
                float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                float3 normalCS = TransformWorldToHClipDir(normalWS);
                float2 offset = normalize(normalCS.xy) / _ScreenParams.xy * _OutlineLen * o.positionCS.w;
                o.positionCS.xy += offset;
                return o;
            }
    
            half4 frag(Varyings i) : SV_Target
            {
                return half4(_OutlineColor, 1);
            }

            half4 fragClip(Varyings i) : SV_Target
            {
                clip(i.positionWS.y - _ClipThresholdWS);
                return half4(_OutlineColor, 1);
            }

        ENDHLSL

        Pass
        {
            Name "BLACK/RED OUTLINE"
            Cull Front
            Stencil
            {
                Ref 2
                Comp NotEqual
                Pass Replace
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            ENDHLSL
        }

        Pass
        {
            Name "WHITE OUTLINE"
            Cull Front
            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Replace
                Fail Keep
                ZFail Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            ENDHLSL
        }

        Pass
        {
            Name "BLACK OUTLINE WITHOUT STENCIL"
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            ENDHLSL
        }

        Pass
        {
            Name "BLACK OUTLINE CLIP"
            Cull Front
            Stencil
            {
                Ref 2
                Comp NotEqual
                Pass Replace
                Fail Keep
                ZFail Keep
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragClip
            ENDHLSL
        }

    }
}

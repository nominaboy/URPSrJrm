Shader "Jeremy/Shadow/MeshShadow_Simple"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (0.2145, 0.2069, 0.2830, 0.9019)
        _ShadowOffsest("ShadowOffset-xyz,null-W", vector) = (-0.7, 0.01, -0.7, 0)
    }

    SubShader
    {
        Tags { "Renderpipeline"="UniveralRenderPipeline" "RenderType" = "Transparent" "Queue"="Transparent-5" "ForceNoShadowCasting" = "True" }
        Pass //Mesh Shadow Pass
        {
            Name "MeshShadow"
            Tags{ "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha// Traditional transparency
            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Replace
            }
            // Offset -1,-1
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(half4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _ShadowOffsest)
            UNITY_INSTANCING_BUFFER_END(Props)

            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                float4 shadow = UNITY_ACCESS_INSTANCED_PROP(Props, _ShadowOffsest);
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                float positionWSY =  positionWS.y;
                positionWS.y = shadow.y;
                positionWS.xz += shadow.xz * (positionWSY - shadow.y);
                o.positionCS = TransformWorldToHClip(positionWS.xyz);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(i);
                return UNITY_ACCESS_INSTANCED_PROP(Props, _BaseColor).rgba;
            }
            ENDHLSL
        }    
    }
}
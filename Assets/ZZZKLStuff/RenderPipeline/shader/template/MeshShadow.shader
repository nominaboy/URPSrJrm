Shader "Jeremy/Shadow/MeshShadow"
{
    Properties
    {
        _BaseColor("Color",Color)=(0.01,0.005,0.05,1)
        _ShadowOffsest ("ShadowOffset-x,y,z dotSize-w", vector)=(0.7,0,0.7,0.75)
        [NoScaleOffset]_dotMap("dot Map", 2D) = "white"{}
    }

    SubShader
    {
        
        Tags {"Renderpipeline"="UniveralRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent"}
        
        Pass //Mesh Shadow Pass
        {
            Name "MeshShadow" 
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            Offset -1,-1
            ZWrite Off

            Stencil
            {
                Ref 1
                Comp NotEqual
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                // float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _ShadowOffsest;
            CBUFFER_END
            TEXTURE2D(_dotMap);SAMPLER(sampler_dotMap);

            Varyings vert (Attributes i)
            {
                Varyings o;
                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
                float worldPosY = positionWS.y;
                positionWS.y = _ShadowOffsest.y;
                positionWS.xz += _ShadowOffsest.xz * (worldPosY - _ShadowOffsest.y);
                o.positionCS = TransformWorldToHClip(positionWS);
                o.uv = positionWS.xz / _ShadowOffsest.w;;
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                
                half dotMap = SAMPLE_TEXTURE2D(_dotMap, sampler_dotMap, i.uv.xy).r;
                half4 col = _BaseColor;
                col.a -= dotMap;
                return col;
            }
            ENDHLSL
        }
    }
}

   

Shader "JRMAdvanced/PlanarReflection"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Cull Back
        //Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionSS : VAR_POS_SS;
            };

            sampler2D _PlanarReflectionRenderTexture;

            CBUFFER_START(UnityPerMaterial)
                
            CBUFFER_END


            Varyings vert (Attributes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.positionSS = o.positionCS;
                return o;
            }



            half4 frag (Varyings i) : SV_Target
            {
                i.positionSS.y *= _ProjectionParams.x;
                float2 screenUV = (i.positionSS.xy / i.positionSS.w) * 0.5 + 0.5;
                half4 reflCol = tex2Dlod(_PlanarReflectionRenderTexture, float4(screenUV.xy, 0, 0));
                return reflCol;
            }

            ENDHLSL
        }
        
    }
}

Shader "JRMAdvanced/Easy1"
{
    Properties
    {
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "LightMode" = "PlanarReflection"}
        Cull Back
        //Blend SrcAlpha OneMinusSrcAlpha
        //ZWrite Off

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
            };

            sampler2D _PlanarReflectionRenderTexture;

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
            CBUFFER_END


            Varyings vert (Attributes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }



            half4 frag (Varyings i) : SV_Target
            {
                return _BaseColor.xyzw;
            }

            ENDHLSL
        }
        
    }
}

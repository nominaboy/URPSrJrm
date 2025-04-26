Shader "JRMTest/JRMCloud"
{
    Properties
    {
        [HDR] _BrightColor("Cloud Bright Color", Color) = (1, 1, 1, 1)
        [HDR] _ShadowColor("Cloud Shadow Color", Color) = (1, 1, 1, 1)
        [HDR] _EdgeColor("Cloud Edge Color", Color) = (1, 1, 1, 1)

        [NoScaleOffset] _CloudMap("Cloud Map", 2D) = "white" {}
        _NoiseMap("Noise Map", 2D) = "white" {}  
        _CloudSDFThreshold("Cloud SDF Threshold", Range(0, 1.1)) = 0.5
        _NoiseSpeed("Noise Speed", Float) = 0
    }
    SubShader
    {
        Tags {
            "Queue" = "Transparent"
        }
        Pass
        {
            Name "JRMCloud"

            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : VAR_BASE_UV;
                float3 positionWS : VAR_POS_WS;
            };
 
             
            sampler2D _CloudMap;
            sampler2D _NoiseMap;

            CBUFFER_START(UnityPerMaterial)
                 half4 _BrightColor;
                 half4 _ShadowColor;
                 half4 _EdgeColor;

                 float _CloudSDFThreshold;
                 float _NoiseSpeed;
                 float4 _NoiseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes i)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);

                o.uv.xy = i.uv;
                o.uv.zw = (i.uv + _Time.x * _NoiseSpeed) * _NoiseMap_ST.xy + _NoiseMap_ST.zw;

                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                //return half4(_MainLightPosition.xyz,1);
                float PosWSDotL = saturate(dot(normalize(i.positionWS.xyz), _MainLightPosition.xyz));
                PosWSDotL *= 5;

                float noise = tex2D(_NoiseMap,i.uv.zw).r * 0.03;
                float4 baseMap = tex2D(_CloudMap, i.uv + noise);

                float sdfThreshold = smoothstep(saturate(_CloudSDFThreshold - 0.1), _CloudSDFThreshold, baseMap.b);

                float3 cloudColor = lerp(_ShadowColor, _BrightColor, baseMap.r);
                float3 edgeColor = _EdgeColor * baseMap.g * PosWSDotL;
                return half4(cloudColor + edgeColor, sdfThreshold * baseMap.a);
            }
            ENDHLSL
        }
    }
}
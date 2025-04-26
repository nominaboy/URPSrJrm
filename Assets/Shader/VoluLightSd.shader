
Shader "Jeremy/VoluLightSd"
{
    Properties
    {
        _StartAngle("Start Angle", Float) = 0.0
        _EndAngle("End Angle", Float) = 1.0
        _NoiseMap("Noise Map", 2D) = "white" {}
        _NoiseSpeed("Noise Speed", Float) = 1.0
        _LightColor("Light Color", Color) = (1, 1, 1, 1)
        _LightIntensity("Light Intensity", Float) = 1.0
        _F_Power("Fresnel Power", Float) = 1.0
        _F_Scale("Fresnel Scale", Float) = 1.0
        _F_Bias("Fresnel Bias", Float) = 0.0
        _FadePower("Fade Power", Float) = 1.0
        _FadeOffset("Fade Offset", Float) = 0.0
    }
    SubShader
    {
        Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent" }
        Cull [_CullMode]
		ZWrite Off
		Blend SrcAlpha One

        Pass 
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float _StartAngle;
                float _EndAngle;
                sampler2D _NoiseMap;
                float4 _NoiseMap_ST;
                float _NoiseSpeed;
                half3 _LightColor;
                float _LightIntensity;
                float _F_Power;
                float _F_Scale;
                float _F_Bias;
                float _FadePower;
                float _FadeOffset;
            CBUFFER_END

            Varyings vert(Attributes i)
            {
                Varyings o;
                float3 normal = normalize(i.normalOS);
                i.positionOS.xyz += normal * (i.uv.x * _EndAngle + (1 - i.uv.x) * _StartAngle);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS.xyz);
                o.normalWS = TransformObjectToWorldNormal(normal);
                o.uv = i.uv;
                return o;
            }


            half4 frag(Varyings i) : SV_Target 
            {
                float2 uv = TRANSFORM_TEX(i.uv, _NoiseMap);
                half3 emission = _LightColor.rgb * _LightIntensity * tex2D(_NoiseMap, uv + _Time.y * _NoiseSpeed).r;
                float3 viewdirWS = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                float fresnel = saturate(pow(abs(dot(i.normalWS, viewdirWS)), _F_Power) * _F_Scale + _F_Bias);
                float alpha = fresnel * pow(abs(1 - i.uv.x - _FadeOffset), _FadePower);
                return half4(emission, alpha);
            }

            ENDHLSL
        
        
        }

        
    }
}

Shader "Jeremy/Weather/AdvancedRainDrop"
{
    Properties
    {
        [NoScaleOffset]_MainTex("Main Texture", 2D) = "white"{}
        [HDR]_TintColor("Tint Color", Color) = (1, 1, 1, 1)
        _Multiplier1("Multiplier1", Range(0, 0.5)) = 0
        _Multiplier2("Multiplier2", Range(0, 0.5)) = 0
        _Multiplier3("Multiplier3", Range(0, 0.5)) = 0
        _RainDropSpeed("Rain Drop Speed", Range(0, 5)) = 1
        _RainRotation("Rain Rotation", Range(1, 360)) = 30
        _RainIntensity("Rain Intensity", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Pass
        {
            Cull Back
            Blend SrcAlpha One
            ZWrite Off
            ZTest Always
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma enable_d3d11_debug_symbols

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float2 RotateUV(float2 uv, float uvRotate)
            {
                float2 outUV;
                float s = sin(uvRotate / 57.2958);
                float c = cos(uvRotate / 57.2958);

                outUV = uv - float2(0.5, 0.5);
                outUV = float2(outUV.x * c - outUV.y * s, outUV.x * s + outUV.y * c);
                outUV += float2(0.5, 0.5);
                return outUV;
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : VAR_BASE_UV;
            };

            sampler2D _MainTex;
            //uniform float _GlobalGameSpeed;
            CBUFFER_START(UnityPerMaterial)
                half4 _TintColor;
                half _Multiplier1;
                half _Multiplier2;
                half _Multiplier3;
                half _RainIntensity;
                float _RainDropSpeed;
                float _RainRotation;
            CBUFFER_END


            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv.xy = RotateUV(i.uv, _RainRotation);
                o.uv.zw = i.uv;
                return o;
            }



            half4 frag (Varyings i) : SV_Target
            {
                // float rainSpeed = _GlobalGameSpeed * _RainDropSpeed;
                half3 mainColor = tex2D(_MainTex, i.uv.xy + float2(0, frac(_Time.y * _RainDropSpeed))).rgb;
                half4 finalColor = half4(mainColor, 1);
                float noiseSpeed = _RainDropSpeed * 0.1;
                half noise = tex2D(_MainTex, i.uv.zw + frac(_Time.y * float2(noiseSpeed * 2, noiseSpeed))).a;
                noise = noise * 3 + 0.5;

                half3 tempColor = saturate(_RainIntensity * 3) * finalColor.rrr * noise * _Multiplier1;
                tempColor += saturate((_RainIntensity - 0.3333) * 3) * finalColor.ggg * noise * _Multiplier2;
                tempColor += saturate((_RainIntensity - 0.6666) * 3) * finalColor.bbb * noise * _Multiplier3;
                finalColor.rgb = tempColor * _TintColor.rgb;
                finalColor.a *= _TintColor.a;
                return finalColor;
            }

            ENDHLSL
        }
        
    }
}

Shader "Hidden/Jeremy/SDFBlend"
{
    Properties
    {
        _MainTex0 ("Texture", 2D) = "white" {}
        _MainTex1 ("Texture", 2D) = "white" {}
        _MainTex2 ("Texture", 2D) = "white" {}
        _MainTex3 ("Texture", 2D) = "white" {}
        _MainTex4 ("Texture", 2D) = "white" {}
        _MainTex5 ("Texture", 2D) = "white" {}
        _MainTex6 ("Texture", 2D) = "white" {}
        _MainTex7 ("Texture", 2D) = "white" {}
        _MainTex8 ("Texture", 2D) = "white" {}
	    _Smooth ("smooth", Range(0,0.05)) = 0.01
    }
    SubShader
    {
        Pass
        {
            Name "SDF Blend"

            ColorMask A
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            sampler2D _MainTex0;
            sampler2D _MainTex1;
            sampler2D _MainTex2;
            sampler2D _MainTex3;
            sampler2D _MainTex4;
            sampler2D _MainTex5;
            sampler2D _MainTex6;
            sampler2D _MainTex7;
            sampler2D _MainTex8;
			float _Smooth;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            Varyings vert (Attributes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.uv;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float cols[9];
                cols[0] = tex2D(_MainTex0, i.uv).a;
                cols[1] = tex2D(_MainTex1, i.uv).a;
                cols[2] = tex2D(_MainTex2, i.uv).a; 
                cols[3] = tex2D(_MainTex3, i.uv).a; 
                cols[4] = tex2D(_MainTex4, i.uv).a; 
                cols[5] = tex2D(_MainTex5, i.uv).a; 
                cols[6] = tex2D(_MainTex6, i.uv).a; 
                cols[7] = tex2D(_MainTex7, i.uv).a; 
                cols[8] = tex2D(_MainTex8, i.uv).a;

                float alpha = 0;
                float averageColor = 0;
                for (float j = 1; j <= 256.0; j++) {
                    float stepNum = j / 256.0;
                    for (int i = 0; i < 8; i++) {
                        if (i / 8.0 < stepNum && stepNum <= (i + 1) / 8.0) {
                            averageColor = lerp(cols[i], cols[i+1], stepNum * 8 - i);
                            averageColor = smoothstep(0.5 - _Smooth, 0.5 + _Smooth, averageColor);
                            alpha = ((j-1) * alpha + averageColor) / j; // (c1 + c2 + ... + cn) / 256
                            break;
                        }
                    }
                }

                return half4(0, 0, 0, alpha);
            }
            ENDHLSL
        }
    }
}
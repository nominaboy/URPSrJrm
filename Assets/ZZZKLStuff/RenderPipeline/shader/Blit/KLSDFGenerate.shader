Shader "Hidden/Jeremy/SDFGenerate"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _Range ("_Range", Range(16, 256)) = 16
    }

    SubShader
    {
        Pass
        {
            Name "SDF Generator"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes 
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings {
                float4 positionCS : SV_POSITION;
                float2 uv : VAR_UV;
            };

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            float _Range;
    
            bool isIn(float2 uv) {
                float4 texColor = tex2D(_MainTex, uv);
                return texColor.r > 0.5;
            }

            float sqrDist(float2 uv1, float2 uv2)
            {
                float2 delta = uv1 - uv2;
                float dist = (delta.x * delta.x) + (delta.y * delta.y);
                return dist;
            }

            Varyings vert (Attributes i)
            {
               Varyings o;
               o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
               o.uv = i.uv;
               return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                bool fragIsIn = isIn(i.uv);
                int intRange = (int)_Range;
                float halfRange = _Range / 2.0;
                float maxSqrDist = (halfRange * _MainTex_TexelSize.x * halfRange * _MainTex_TexelSize.x) +
                    (halfRange * _MainTex_TexelSize.y * halfRange * _MainTex_TexelSize.y);


                float2 startPosition = float2(i.uv.x - halfRange * _MainTex_TexelSize.x, i.uv.y - halfRange * _MainTex_TexelSize.y);
                float sqrDistToEdge = maxSqrDist;

                for (int dx = 0; dx < intRange; dx++) {
                    for (int dy = 0; dy < intRange; dy++) {
                        float2 currentUV = startPosition + float2(dx * _MainTex_TexelSize.x, dy * _MainTex_TexelSize.y);
                        bool currentIsIn = isIn(currentUV);
                        if (currentIsIn != fragIsIn) {
                            float currentDist = sqrDist(i.uv, currentUV);
                            if (currentDist < sqrDistToEdge) {
                                sqrDistToEdge = currentDist;
                            }
                        }
                    }
                }

                float normalizedDist = sqrt(sqrDistToEdge / maxSqrDist);
                if (fragIsIn)
                {
                    normalizedDist = 0.5 + 0.5 * normalizedDist;
                }
                else
                {
                    normalizedDist = 0.5 - 0.5 * normalizedDist;
                }
                return half4(1, 1, 1, normalizedDist);
            }
            ENDHLSL

        }
    }
}
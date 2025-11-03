Shader "Jeremy/Unlit/Unlit_Transparent"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0

        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", float) = 0
        [Toggle(_TINTFUNC)]_TintFunc("Tint Function", float) = 0
        _Tint("Tint Color", Color) = (0,0,0,0.3)
        [Space(10)]
        [HDR]_Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
        Pass
        {
            Blend [_SrcFactor] [_DstFactor]
            Cull back
            ZWrite [_ZWrite]
            // Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _TINTFUNC
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                half4 _Tint;
                float _ZWrite;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c = mainTex * _Color; 
                #ifdef _TINTFUNC
                    c.rgb += _Tint.rgb * _Tint.a * 10;
                #endif
                return c;
            }
            ENDHLSL
        }
    }
}

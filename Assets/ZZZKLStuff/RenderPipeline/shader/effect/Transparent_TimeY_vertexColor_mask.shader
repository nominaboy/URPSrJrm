Shader "Jeremy/Transparent/Mask"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0

        [HDR]_Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [Header(U(X)  V(Y)  mask_U(Z)  Mask_V(W))]
        [Space(10)]
        _Sequence("",vector)=(3,3,2,0)
        _MaskTex ("MaskTex", 2D) = "white" {}
    }
    
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProject"="True"}
        Pass
        {
            // Tags {"LightMode"="UniversalForward"}
            Blend [_SrcFactor] [_DstFactor]
            Cull back
            ZWrite off
            // ZTest LEqual
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            
            //Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            CBUFFER_START(UnityPerMaterial)
            half4 _Color,_Sequence;
            float4 _MainTex_ST,_MaskTex_ST;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv : TEXCOORD;
                float4 vertexColor : TEXCOORD1;
            };
            
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                // o.uv.xy = float2(v.uv.x/_Sequence.y, v.uv.y/_Sequence.x+(_Sequence.x-1)/_Sequence.x);
                // o.uv.x = o.uv.x + frac(floor(_Time.w*_Sequence.z)/_Sequence.y);
                // o.uv.y = o.uv.y - frac(floor(_Time.w*_Sequence.z/_Sequence.y)/_Sequence.x);
                o.uv.xy = v.uv * _MainTex_ST.xy + frac(_Sequence.xy*_Time.y);
                o.uv.zw = v.uv * _MaskTex_ST.xy + frac(_Sequence.zw*_Time.y);
                o.vertexColor = v.color;
                return o;
            }
            
            half4 frag(Varyings i) : SV_TARGET
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.zw);
                c = mainTex * _Color * i.vertexColor * maskTex; 
                // c.rgb *= c.a;
                return c;
            }
            
            ENDHLSL
            
        }
    }
    Fallback "Hidden/Shader Graph/FallbackError"
}

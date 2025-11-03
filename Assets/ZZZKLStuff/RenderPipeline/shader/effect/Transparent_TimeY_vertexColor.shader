Shader "Jeremy/Transparent/base"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0

        [Space(10)]
        [HDR]_Color("Color",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}

        [Header(____________UV Animation____________)]
        [Space(10)]
        [Header(U_speed(X)  V_speed(Y)  null(Z)  Null(W))]
        [Space(10)]
        _Sequence("",vector)=(3,3,2,0)

        [Header(____________BillBorad____________)]
        [Space(10)]
        [Toggle(_BILLBORAD)] _BillboardOn("Billboard On", float) = 0
        [Enum(Billboard, 1, VerticalBillboard, 0)]_BillboardTypeY("BillboardType", int) = 1
    }
    
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProject"="True"}
        Pass
        {
            Blend [_SrcFactor] [_DstFactor]
            Cull back
            ZWrite off
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            
            //Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _Color,_Sequence;
                float4 _MainTex_ST;
                int _BillboardTypeY;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            
            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
                float4 vertexColor : TEXCOORD1;
            };
            
            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;

                float3 positionOS = i.positionOS.xyz;
                #ifdef _BILLBORAD
                    float3 viewDir = mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos,1)).xyz;
                    viewDir = normalize(viewDir);
                    viewDir.y *= _BillboardTypeY;
                    float3 upDir = float3(0,1,0);
                    float3 rightDir = normalize(cross(viewDir,upDir));
                    upDir = cross(rightDir,viewDir);
                    positionOS = rightDir * positionOS.x + upDir * positionOS.y + viewDir * positionOS.z;
                #endif

                o.positionCS = TransformObjectToHClip(positionOS);
                o.uv.xy = i.uv * _MainTex_ST.xy + frac(_Sequence.xy*_Time.y);
                o.vertexColor = i.color;
                return o;
            }
            
            half4 frag(Varyings i) : SV_TARGET
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                c = mainTex * _Color * i.vertexColor; 
                return c;
            }
            
            ENDHLSL
            
        }
    }
    Fallback "Hidden/Shader Graph/FallbackError"
}

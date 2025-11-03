Shader "Jeremy/Unlit/Unlit_Transparent_vertexColor_uv"
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
        _uvAnim("x-u,y-v,z-0,w-0",vector)=(0,0,0,0)

        [Header(____________BillBorad____________)]
        [Space(10)]
        [Toggle(_BILLBORAD)] _BillboardOn("Billboard On", float) = 0
        [Enum(Billboard, 1, VerticalBillboard, 0)]_BillboardTypeY("BillboardType", int) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
        Pass
        {
            Blend [_SrcFactor] [_DstFactor]
            Cull back
            ZWrite off
            // Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _BILLBORAD
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                float4 _uvAnim;
                int _BillboardTypeY;
            CBUFFER_END
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 vertexColor: COLOR0;
            };

            Varyings vert (Attributes i)
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

                o.uv = i.uv * _MainTex_ST.xy + _uvAnim.xy;
                o.vertexColor = i.color;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                c = mainTex * _Color * i.vertexColor; 
                return c;
            }
            ENDHLSL
        }
    }
}

Shader "Jeremy/Effect/EffectBase"
{
    Properties
    {
        [HDR]_Color("Color",Color) = (1,1,1,1)
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode",int) = 2
        _MainTex ("Main Texture", 2D) = "white" {}

        [Toggle]_MaskEnabled("MaskEnabled",int)=0//变体定义方式1，#pragma 需要加_ON
        _MaskTex ("Mask Texture", 2D) = "white" {}

        [MaterialToggle(_DISTORTENABLED)]_DistortEnabled("MaskEnabled",int)=0//变体定义方式2，#pragma 直接用_DISTORTENABLED
        _DistortTex ("Distort Texture", 2D) = "white" {}
        _VectorData ("Anim Main-xy Mask-zw", vector) = (0,0,0,0)
        _DistortValue ("Distort Value-xy", vector) = (0.1,0.1,1,0)

        [MaterialToggle(_CLIP_ON)]_ClipOn("Clip On",int)=0//变体定义方式2，#pragma 直接用_ClipOn
        _ClipTex ("Clip Texture", 2D) = "white" {}

        [HideInInspector]_Blend("Blend",int) = 0
        [HideInInspector]__SaveValue01("",vector) = (0,0,0,0)
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "queue"="Transparent"}
        LOD 100
        Blend [_SrcFactor] [_DstFactor]
        Cull [_CullMode]
        ZWrite off

        Pass
        {      
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature _ _MASKENABLED_ON
            #pragma shader_feature _ _DISTORTENABLED
            #pragma shader_feature _ _CLIP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST,_MaskTex_ST,_DistortTex_ST,_ClipTex_ST;
                half4 _VectorData,_DistortValue;
                half4 _Color;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            #if _MASKENABLED_ON
                TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);
            #endif

            TEXTURE2D(_DistortTex);SAMPLER(sampler_DistortTex);

            #if _CLIP_ON
                TEXTURE2D(_ClipTex);SAMPLER(sampler_ClipTex);
            #endif

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 VertexColor : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 uv2 : TEXCOORD1;
                float2 uv3 : TEXCOORD2;
                float4 positionCS : SV_POSITION;
                float4 VertexColor : COLOR; 
                 float fogCoord : TEXCOORD3;//fog(1)
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv.xy = v.uv * _MainTex_ST.xy + _MainTex_ST.zw + _VectorData.xy*_Time.y;
                #if _MASKENABLED_ON
                    o.uv.zw = v.uv * _MaskTex_ST.xy + _MaskTex_ST.zw + _VectorData.zw*_Time.y;
                #endif
                #if _DISTORTENABLED
                    o.uv2.xy = v.uv * _DistortTex_ST.xy + _DistortTex_ST.zw + _VectorData.xy*_Time.y;
                    o.uv2.zw = v.uv * _DistortTex_ST.xy + _DistortTex_ST.zw + _VectorData.zw*_Time.y;
                #endif
                #if _CLIP_ON
                    o.uv3 = TRANSFORM_TEX(v.uv, _ClipTex);
                #endif
                o.VertexColor = v.VertexColor;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);//fog(2)
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                half4 col = 0;
                half2 distortMain = i.uv.xy;

                #if _DISTORTENABLED
                    half4 distortTex = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv2.xy);
                    distortMain = lerp(i.uv.xy, distortTex.xy, _DistortValue.x);
                #endif

                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, distortMain);
                col = mainTex*_Color;

                #if _MASKENABLED_ON
                    half4 distortTex2 = SAMPLE_TEXTURE2D(_DistortTex, sampler_DistortTex, i.uv2.zw);
                    half2 distortMask = lerp(i.uv.zw, distortTex2.xy, _DistortValue.y);
                    half4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, distortMask);
                    col *= maskTex;
                #endif

                col.rgb *= _DistortValue.z;
                col.a *= _Color.a;

                #if _CLIP_ON
                    half4 clipTex = SAMPLE_TEXTURE2D(_ClipTex, sampler_ClipTex, i.uv3);
                    clip(clipTex - _DistortValue.w);
                #endif
                
                col.rgb += i.VertexColor.r * half3(0,0.5,0);
                col.a *= i.VertexColor.a;
                col.rgb -= i.VertexColor.g * half3(0.1,0.1,0.2);
                col.rgb = MixFog(col.rgb, i.fogCoord);//fog(3)
                return col;
            }
            ENDHLSL
        }
    }
    CustomEditor "EffectBaseGUI"
}

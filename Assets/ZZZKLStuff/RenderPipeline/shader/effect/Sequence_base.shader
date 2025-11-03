Shader "Jeremy/Sequence/SequenceBase"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0

		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4

        [HDR]_Color("Color",Color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        [Header(Row(X)  Cloum(Y)  Frame(Z)  Null(W))]
        [Space(10)]
        _Sequence("",vector)=(3,3,2,0)

        [Header(____________BillBorad____________)]
        [Space(10)]
        [Toggle(_BILLBORAD)] _BillboardOn("Billboard On", float) = 0
        [Enum(Billboard, 1, VerticalBillboard, 0)]_BillboardType("BillboardType", int) = 1

        [Header(____________UV Animation____________)]
        [Space(10)]
        [Toggle(_UVANIM)] _UVAnimation("UVAnimation On", float) = 0
        // [HideInInspector]_Blend("Blend",int) = 0

        [Header(____________WS Soft Particles____________)]
        [Space(10)]
        [Toggle(_WSSOFTPARTICLES)] _WSSoftParticlesOn("World Space SP On", float) = 0
        _SPIntensity ("Soft Particles Intensity", float) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "LightMode"="UniversalForward" "Queue"="Transparent" "IgnoreProject"="True"}

        Pass
        {
            Blend [_SrcFactor] [_DstFactor]
            Cull back
            ZWrite off
			ZTest [_ZTest]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _BILLBORAD
            #pragma shader_feature _UVANIM
            #pragma shader_feature _WSSOFTPARTICLES

            #pragma target 3.0
            // #pragma target 2.0
            // #pragma multi_compile_instancing

            //Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color,_Sequence;
                float4 _MainTex_ST;
                int _BillboardType;
                float _SPIntensity;
            CBUFFER_END

            // #define smp _linear_clamp//sampler_MainTex //_linear_clampU_repeatV, mirror
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            // SAMPLER(smp);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float3 positionWS : VAR_POSITIONWS;
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
                float4 color : COLOR;
            };

            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;

                float3 positionOS = i.positionOS.xyz;
                #ifdef _BILLBORAD
                    float3 viewDir = mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos,1)).xyz;
                    viewDir = normalize(viewDir);
                    viewDir.y *= _BillboardType;
                    float3 upDir = float3(0,1,0);
                    float3 rightDir = normalize(cross(viewDir,upDir));
                    upDir = cross(rightDir,viewDir);
                    positionOS = rightDir * positionOS.x + upDir * positionOS.y + viewDir * positionOS.z;
                #endif

                float time = 1;
                #ifdef _UVANIM
                    time *= _Time.w;
                #endif

                o.color = i.color;
                o.positionWS = TransformObjectToWorld(positionOS);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.uv.xy = float2(i.uv.x/_Sequence.y, i.uv.y/_Sequence.x+(_Sequence.x-1)/_Sequence.x);

                o.uv.x = o.uv.x + frac(floor(time * _Sequence.z)/_Sequence.y);
                o.uv.y = o.uv.y - frac(floor(time * _Sequence.z/_Sequence.y)/_Sequence.x);
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half4 c;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                c = mainTex * _Color;         
                c.rgba *= i.color.rgba;
                #ifdef _WSSOFTPARTICLES
                    c.a *= saturate(i.positionWS.y * _SPIntensity);
                #endif
                // c.rgb *= c.a;
                return c;
            }

            ENDHLSL

        }
    }
    //CustomEditor "Sequence_baseGUI"
    Fallback "Hidden/Shader Graph/FallbackError"
}

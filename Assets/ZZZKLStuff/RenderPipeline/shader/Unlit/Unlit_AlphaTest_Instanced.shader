Shader "Jeremy/Unlit/Unlit_AlphaTest_Instanced"
{
    Properties
    {
        [Header(__________Base__________)]
        [Space(10)]
        [NoScaleOffset]_MainTex("Texture", 2D) = "white" {}
		_Color("Color", Color) = (1, 1, 1, 1)
        _ClipThreshold("Clip Threshold", Float) = 0

        [Header(__________Scale__________)]
        [Space(10)]
		[Toggle(_SCALE)] _SCALE("_SCALE", Float) = 0
        _ScaleSpeed("Scale Speed", Float) = 1
        _ScaleAmplitude("Scale Amplitude", Float) = 1
        _ScaleOffset("Scale Offset", Float) = 0
        
        [Header(__________Billboard__________)]
        [Space(10)]
		[Toggle(_BILLBOARD)] _BILLBOARD("_BILLBOARD", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="AlphaTest"  "Queue"="AlphaTest" }
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile_instancing
            #pragma shader_feature_local _SCALE
            #pragma shader_feature_local _BILLBOARD
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            UNITY_INSTANCING_BUFFER_START(Props)
		        UNITY_DEFINE_INSTANCED_PROP(half4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float, _ClipThreshold)
                UNITY_DEFINE_INSTANCED_PROP(float, _ScaleSpeed)
                UNITY_DEFINE_INSTANCED_PROP(float, _ScaleAmplitude)
                UNITY_DEFINE_INSTANCED_PROP(float, _ScaleOffset)
            UNITY_INSTANCING_BUFFER_END(Props)

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);

                float3 positionOS = i.positionOS.xyz;

                #ifdef _SCALE
                    float scale = abs(UNITY_ACCESS_INSTANCED_PROP(Props, _ScaleAmplitude) * 
                        sin(_Time.y * UNITY_ACCESS_INSTANCED_PROP(Props, _ScaleSpeed))) + 
                        UNITY_ACCESS_INSTANCED_PROP(Props, _ScaleOffset);
                    positionOS *= scale;
                #endif

                #ifdef _BILLBOARD
                    float3 viewDir = mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos, 1)).xyz;
                    viewDir = normalize(viewDir);
                    float3 upDir = float3(0,1,0);
                    float3 rightDir = normalize(cross(viewDir,upDir));
                    upDir = cross(rightDir,viewDir);
                    positionOS = rightDir * positionOS.x + upDir * positionOS.y + viewDir * positionOS.z;
                #endif

                o.positionCS = TransformObjectToHClip(positionOS);
                o.uv = i.uv;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                half4 finalColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                finalColor *= UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
                clip(finalColor.a - UNITY_ACCESS_INSTANCED_PROP(Props, _ClipThreshold));
                return finalColor;
            }
            ENDHLSL
        }
    }
}

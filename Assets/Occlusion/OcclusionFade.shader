Shader "JRMAdvanced/Occlusion_Fade"
{
    Properties
    {
		[Toggle(_OCCLUSION_FADE)] _OCCLUSION_FADE("_OCCLUSION_FADE", Float) = 0
        _DistanceScale("_DistanceScale", Float) = 1
        _DistanceSensitivity("_DistanceSensitivity", Float) = 1

    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _OCCLUSION_FADE
            #pragma enable_d3d11_debug_symbols
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normalOS : NORMAL;
            };
        
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : VAR_POSITIONWS;
            };
        
            float _DistanceScale;
            float _DistanceSensitivity;
        
            uniform float2 _RoleScreenPos;
            Varyings vert (Attributes i)
            {
                Varyings o;
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = i.texcoord;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                return o;
            }
        
            half4 frag (Varyings i) : SV_Target
            {
                #ifdef _OCCLUSION_FADE
                    // float3 positionVS = TransformWorldToView(i.positionWS);
                    //float cameraDistance = abs(positionVS.z);
                    float cameraDistance = abs(i.positionCS.w);
                    float cameraDistanceFactor = max(0.0, cameraDistance / _DistanceScale);
                    cameraDistanceFactor = pow(cameraDistanceFactor, _DistanceSensitivity);

                    float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
                    float ratio = _ScaledScreenParams.y / _ScaledScreenParams.x;
                    float2 sphere = float2(screenUV.x - _RoleScreenPos.x, (screenUV.y - _RoleScreenPos.y) * ratio);
                    // float distanceSS = sqrt(dot(sphere, sphere));
                    float distanceSS = length(sphere);

                    float sphereRange = 1 - 3.33 * distanceSS;
                    float sphereRangePow = 2.33 * sphereRange;
                    sphereRangePow = sphereRangePow * sphereRangePow;

                    sphereRangePow = pow(2.72, sphereRangePow); // E
                    sphereRangePow = 1 / sphereRangePow;

                    float result = sphereRange > 0 ? sphereRangePow : 1.0;
                    result = abs(sphereRange) > 0.1 ? result : 1.0;

                    result = result * cameraDistanceFactor;
                    result = saturate(result);

                    float noise = InterleavedGradientNoise(float2(i.positionCS.x * 0.5, i.positionCS.y), 0);

                    result = noise + result - 1.0;
                    clip(result);
                #endif
                Light mainLight = GetMainLight();
                float3 lDir = normalize(mainLight.direction);
                float LdN = dot(lDir, i.normalWS);
                half4 col = 1;
                col.xyz = LdN * 0.5 + 0.5;//用简单的半兰伯特光照模型
                return col;
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}

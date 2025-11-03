Shader "Jeremy/BakeGI/BakeGI_Mix2_VertexColor"
{
    Properties
    {
        [Header(Layer1(x)  Layer2(y))]
        [Space(10)]
        _HeightContract("Range:0-1, HeightContract", vector)=(0.1, 0.1, 0, 0)
        [Header(VertexColor R(Layer1) G(null) B(Layer2) A(null))]
        [Space(10)]
        _Layer1Map("Layer1Map RGB(color) A(height)", 2D) = "white"{}
        _Layer2Map("Layer2Map RGB(color) A(height)", 2D) = "white"{}

        [Toggle(_OCCLUSION_FADE)] _OCCLUSION_FADE("_OCCLUSION_FADE", Float) = 0
        _DistanceScale("_DistanceScale", Range(0.1, 50)) = 1
        _DistanceSensitivity("_DistanceSensitivity", Range(0.1, 10)) = 1
    }
    HLSLINCLUDE
        #include "../template/ZanyaHLSL.hlsl"
        CBUFFER_START(UnityPerMaterial)
            half4 _HeightContract;
            float4 _Layer1Map_ST;
            float4 _Layer2Map_ST;
            float _DistanceScale;
            float _DistanceSensitivity;
        CBUFFER_END
        #define smp _linear_repeat
        TEXTURE2D(_Layer1Map); SAMPLER(smp);
        TEXTURE2D(_Layer2Map); //SAMPLER(sampler_Layer2Map);

        uniform float2 _RoleScreenPos;
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry+10"}
        LOD 200
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature _OCCLUSION_FADE
            
            #pragma multi_compile _ LIGHTMAP_ON

            struct appdata
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
                float4 tangentOS        : TANGENT;
                float4 vertexColor : COLOR;
            };
            
            struct v2f
            {
                float4 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
                float4 positionCS : SV_POSITION;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
            };
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                //Mix Maps
                o.vertexColor = v.vertexColor;
                o.uv0.xy = TRANSFORM_TEX(v.uv,_Layer1Map);
                o.uv0.zw = TRANSFORM_TEX(v.uv,_Layer2Map);
                // o.uv1.xy = TRANSFORM_TEX(v.uv,_Layer3Map);
                // o.uv1.zw = TRANSFORM_TEX(v.uv,_Layer4Map);
                //Bake GI
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(positionWS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.staticLightmapUV = v.staticLightmapUV  * unity_LightmapST.xy + unity_LightmapST.zw;
                o.positionWS = positionWS;
                return o;
            }
            
            
            half4 frag(v2f i) : SV_TARGET
            {
                #ifdef _OCCLUSION_FADE
                    float cameraDistance = abs(i.positionCS.w);
                    float cameraDistanceFactor = max(0.0, cameraDistance / max(_DistanceScale, 0.1));
                    cameraDistanceFactor = pow(cameraDistanceFactor, _DistanceSensitivity);
                    float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
                    float ratio = _ScaledScreenParams.y / _ScaledScreenParams.x;
                    float2 sphere = float2(screenUV.x - _RoleScreenPos.x, (screenUV.y - _RoleScreenPos.y) * ratio);
                    float distanceSS = length(sphere);

                    float sphereRange = 1 - 3.33 * distanceSS;
                    float sphereRangePow = 2.33 * sphereRange;
                    sphereRangePow = sphereRangePow * sphereRangePow;
                    sphereRangePow = pow(2.72, sphereRangePow);
                    sphereRangePow = 1 / sphereRangePow;
                    float result = sphereRange > 0 ? sphereRangePow : 1.0;
                    result = abs(sphereRange) > 0.1 ? result : 1.0;

                    result = result * cameraDistanceFactor;
                    result = saturate(result);
                    float noise = InterleavedGradientNoise(float2(i.positionCS.x * 0.5, i.positionCS.y), 0);
                    result = noise + result - 1.0;
                    clip(result);
                #endif

                //Mix Maps--------------------
                half4 maskMap = 0;
                maskMap.r = i.vertexColor.x;
                maskMap.g = i.vertexColor.z;
                //Textures
                half4 layer1Map = SAMPLE_TEXTURE2D(_Layer1Map, smp, i.uv0.xy);     
                half4 layer2Map = SAMPLE_TEXTURE2D(_Layer2Map, smp, i.uv0.zw);
                //BlendWeight
                half heighAddL1 = maskMap.r + CheapContrast(layer1Map.a, _HeightContract.x);
                half heighAddL2 = maskMap.g + CheapContrast(layer2Map.a, _HeightContract.y);
                
                half heighMax = max(heighAddL1, heighAddL2) - _HeightContract.z;
                half4 BlendWeight = 0;
                BlendWeight.x = max((heighAddL1 - heighMax), 0);
                BlendWeight.y = max((heighAddL2 - heighMax), 0);
                
                half BlendWeightAdd = max(BlendWeight.x + BlendWeight.y, 0.001);
                BlendWeight = BlendWeight / BlendWeightAdd;
                //Color
                half4 colorMix = half4(layer1Map.rgb * BlendWeight.x + layer2Map.rgb * BlendWeight.y, 1);
                
                //GI----------------------------------
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.staticLightmapUV.xy, i.normalWS.xyz);
                    colorMix.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    colorMix.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif
                
                return half4(colorMix.rgb,1);
            }
            ENDHLSL
        }
    }
    CustomEditor "BakeGI_Mix2_VertexColorGUI"
}

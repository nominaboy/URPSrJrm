Shader "Jeremy/BakeGI/BakeGI_Mix3_VertexColor"
{
    Properties
    {
        // [Toggle]_MiddleQuality("Middle & High Quality",int) = 1
        [Header(Layer1(X)  Layer2(y)  Layer3(z)  global(w))]
        [Space(10)]
        _HeightContract("Range:0-1,HeightContract",vector)=(0.1,0.1,0.1,0.1)
        [Header(VertexColor R(Layer1) G(Layer2) B(Layer3)]
        [Space(10)]
        _Layer1Map("Layer1Map RGB(color) A(height)",2D) = "white"{}
        // _HSV1("Layer1 HSV", vector) = (1.0, 1.0, 1.0, 1.0)
        _Layer2Map("Layer2Map RGB(color) A(height)",2D) = "white"{}
        // _HSV2("Layer2 HSV", vector) = (1.0, 1.0, 1.0, 1.0)
        _Layer3Map("Layer3Map UV2 RGB(color) A(height)",2D) = "white"{}
        // _HSV3("Layer3 HSV", vector) = (1.0, 1.0, 1.0, 1.0)
        // _dotVector("x-repeat,y-space,z-bright,w-null)",vector) = (3, 0.5, 0.5, 0)
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "../template/ZanyaHLSL.hlsl"
    #include_with_pragmas "../Utils/KLFogOfWar.hlsl"
    CBUFFER_START(UnityPerMaterial)
    float4 _Layer1Map_ST;
    float4 _Layer2Map_ST;
    float4 _Layer3Map_ST;
    
    // float3 _HSV1;
    // float3 _HSV2;
    // float3 _HSV3;
    half4 _HeightContract;
    // half4 _dotVector;
    CBUFFER_END
    
    #define smp _linear_repeat
    TEXTURE2D(_Layer1Map); SAMPLER(smp);
    TEXTURE2D(_Layer2Map); 
    TEXTURE2D(_Layer3Map); 
    ENDHLSL
    
    SubShader////LOD 200
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+10"}
        LOD 200
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            // #pragma multi_compile _ _MIDDLEQUALITY_ON

            #pragma multi_compile _ LIGHTMAP_ON

            // half3 RGB2HSV(half3 c)
            // {
            //     half4 K = half4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            //     half4 p = lerp(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
            //     half4 q = lerp(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));

            //     half d = q.x - min(q.w, q.y);
            //     half e = 1.0e-10;
            //     return half3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            // }

            // half3 HSV2RGB( half3 c )
            // {
            //     half3 rgb = clamp( abs(fmod(c.x*6.0+half3(0.0,4.0,2.0),6)-3.0)-1.0, 0, 1);
            //     rgb = rgb*rgb*(3.0-2.0*rgb);
            //     return c.z * lerp( half3(1,1,1), rgb, c.y);
            // }

            // half3 ColorTransform(half3 color, half3 hsvCoe)
            // {
            //     half3 finalColor;
            //     finalColor = RGB2HSV(color);
            //     finalColor *= hsvCoe;
            //     finalColor = HSV2RGB(finalColor);
            //     return finalColor;
            // }


            struct appdata
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
                float4 vertexColor      : COLOR;
            };
            struct v2f
            {
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;
                float4 vertexColor : COLOR;
                // #if _MIDDLEQUALITY_ON
                // float3 positionWS : TEXCOORD3;
                // #endif
                float4 positionCS : SV_POSITION;
                half3 normalWS : TEXCOORD4;
                float3 positionWS : VAR_POSITIONWS;
            };
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                
                // #if _MIDDLEQUALITY_ON
                // o.positionWS = positionWS;
                // #endif

                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                //Mix Maps
                o.vertexColor = v.vertexColor;
                o.uv0.xy = TRANSFORM_TEX(v.uv,_Layer1Map);
                o.uv0.zw = TRANSFORM_TEX(v.uv,_Layer2Map);
                o.uv1.xy = TRANSFORM_TEX(v.uv,_Layer3Map);
                o.uv1.zw = v.staticLightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                
                return o;
            }
            half4 frag(v2f i) : SV_TARGET
            {
                half3 finalColor =0;
                ////Mix Maps--------------------
                half4 maskMap = 0;
                maskMap.r = i.vertexColor.x;
                maskMap.g = i.vertexColor.y;
                maskMap.b = i.vertexColor.z;
                maskMap.a = i.vertexColor.w;
                ////Textures
                half4 layer1Map = SAMPLE_TEXTURE2D(_Layer1Map, smp, i.uv0.xy);
                //layer1Map.rgb = ColorTransform(layer1Map.rgb, _HSV1);
                half4 layer2Map = SAMPLE_TEXTURE2D(_Layer2Map, smp, i.uv0.zw);
                //layer2Map.rgb = ColorTransform(layer2Map.rgb, _HSV2);
                half4 layer3Map = SAMPLE_TEXTURE2D(_Layer3Map, smp, i.uv1.xy);
                //layer3Map.rgb = ColorTransform(layer3Map.rgb, _HSV3);
                

                half heighAddL1 = maskMap.r + CheapContrast(layer1Map.a, _HeightContract.x);
                half heighAddL2 = maskMap.g + CheapContrast(layer2Map.a, _HeightContract.y);
                half heighAddL3 = maskMap.b + CheapContrast(layer3Map.a, _HeightContract.z);
                half heighMax = max(max(heighAddL1, heighAddL2), heighAddL3 ) - _HeightContract.w;
                half4 BlendWeight = 0;
                BlendWeight.x = max((heighAddL1 - heighMax), 0);
                BlendWeight.y = max((heighAddL2 - heighMax), 0);
                BlendWeight.z = max((heighAddL3 - heighMax), 0);
                half BlendWeightAdd = BlendWeight.x + BlendWeight.y + BlendWeight.z;
                BlendWeight = BlendWeight/BlendWeightAdd;
                ////Color
                half3 colorMix = half3(layer1Map.rgb*BlendWeight.x + layer2Map.rgb*BlendWeight.y +layer3Map.rgb*BlendWeight.z);
                finalColor = colorMix; 
                // #endif

                // #if _MIDDLEQUALITY_ON
                // ////Dot Map---------------------------------------
                // half PosWStime = _dotVector.x;
                // half PosWScale = _dotVector.y;
                // half dotBright = _dotVector.z;
                // half3 dotColor = dotMap(PosWStime, PosWScale, dotBright, i.positionWS.x, i.positionWS.z, texColor.rgb);
                // texColor.rgb = lerp( texColor.rgb,   saturate(dotColor),   maskMap.a);
                // #endif
                    
                ////GI----------------------------------
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.uv1.zw, i.normalWS.xyz);
                    finalColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    finalColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif

                #ifdef _KLFogOfWar
                    finalColor.rgb = CalcFogOfWar(finalColor.rgb, i.positionWS, i.positionCS.y / _ScaledScreenParams.y);
                #endif

                return half4(finalColor,1);                
                }
                ENDHLSL
            }  
        }
        Fallback "Hidden/Shader Graph/FallbackError"
    }
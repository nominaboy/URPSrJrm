Shader "Jeremy/BakeGI/BakeGI_Mix2_VertexColor_uv1_3"
{
    Properties
    {
        // _dotMap("dotMap Map)",2D) = "black"{}
        [Header(Layer1(X)  Layer2(y))]
        [Space(10)]
        _HeightContract("Range:0-1,HeightContract",vector)=(0.1,0.1,0.1,0.1)
        [Header(VertexColor R(Layer1) G(Layer2)]
        [Space(10)]
        _Layer1Map("Layer1Map RGB(color) A(height)",2D) = "white"{}
        _Layer2Map("Layer2Map RGB(color) A(height)",2D) = "white"{}
        // _Layer3Map("Layer3Map UV2 RGB(color) A(height)",2D) = "white"{}
        // _ShadowVector("ShadowVector(XY)",vector) = (1, 5, 0.1, 0)
    }

    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../template/ZanyaHLSL.hlsl"
        #include_with_pragmas "../Utils/KLFogOfWar.hlsl"
        CBUFFER_START(UnityPerMaterial)
        half4 _HeightContract;
        // float4 _dotMap_ST;
        float4 _Layer1Map_ST;
        float4 _Layer2Map_ST;
        // float4 _ShadowVector;
        CBUFFER_END
        #define smp _linear_repeat
        TEXTURE2D(_Layer1Map); SAMPLER(smp);
        TEXTURE2D(_Layer2Map); //SAMPLER(sampler_Layer2Map);
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
            #pragma multi_compile _ LIGHTMAP_ON
            // #pragma multi_compile_fog
            // #pragma multi_compile_instancing
            // TEXTURE2D(_dotMap);   // SAMPLER(sampler_dotMap);
            struct appdata
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float2 uv3 : TEXCOORD2;
                float3 normalOS         : NORMAL;
                float4 vertexColor : COLOR;
            };
            struct v2f
            {
                //Mix Maps
                float4 uv0 : TEXCOORD6;
                float2 uv1 : TEXCOORD2;
                float4 uv0AndLightmapUV  : TEXCOORD5;
                float4 vertexColor : COLOR;
                float4 positionCS : SV_POSITION;
                float3 positionWS : VAR_POSITIONWS;
                // float4 screenUV : TEXCOORD0; // xy: uv0, z: fogCoord
                // DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 1);//staticLightmapUV,vertexSH已定义
                half3 normalWS : TEXCOORD4;
            };
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                //Mix Maps
                o.vertexColor = v.vertexColor;
                o.uv0.xy = TRANSFORM_TEX(v.uv,_Layer1Map);
                o.uv0.zw = TRANSFORM_TEX(v.uv3,_Layer2Map);
                // o.uv1.zw = TRANSFORM_TEX(v.uv,_Layer4Map);
                // o.uv0AndLightmapUV.xy = TRANSFORM_TEX(v.uv,_dotMap);
                o.uv0AndLightmapUV.zw = v.staticLightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                //Bake GI
                // OUTPUT_LIGHTMAP_UV(v.staticLightmapUV, unity_LightmapST, o.staticLightmapUV);
                // OUTPUT_SH(o.normalWS, o.vertexSH);
                return o;
            }
            half4 frag(v2f i) : SV_TARGET
            {

                //Mix Maps--------------------
                half4 maskMap = 0;
                maskMap.r = i.vertexColor.x;
                maskMap.g = i.vertexColor.y;
                // maskMap.b = i.vertexColor.z;
                //Textures
                // half4 dotMap = SAMPLE_TEXTURE2D(_dotMap, smp, i.uv0AndLightmapUV.xy);
                half4 layer1Map = SAMPLE_TEXTURE2D(_Layer1Map, smp, i.uv0.xy);     
                half4 layer2Map = SAMPLE_TEXTURE2D(_Layer2Map, smp, i.uv0.zw);
                // half4 layer3Map = SAMPLE_TEXTURE2D(_Layer3Map, smp, i.uv1.xy);
                //BlendWeight
                half heighAddL1 = maskMap.r + CheapContrast(layer1Map.a, _HeightContract.x);
                half heighAddL2 = maskMap.g + CheapContrast(layer2Map.a, _HeightContract.y);
                // half heighAddL3 = maskMap.b + CheapContrast(layer3Map.a, _HeightContract.z);
                half heighMax =max(heighAddL1, heighAddL2) - _HeightContract.w;
                half4 BlendWeight = 0;
                BlendWeight.x = max((heighAddL1 - heighMax), 0);
                BlendWeight.y = max((heighAddL2 - heighMax), 0);
                // BlendWeight.z = max((heighAddL3 - heighMax), 0);
                half BlendWeightAdd = BlendWeight.x + BlendWeight.y;
                BlendWeight = BlendWeight/BlendWeightAdd;
                //Color
                half4 colorMix = half4(layer1Map.rgb*BlendWeight.x + layer2Map.rgb*BlendWeight.y, 1);
                half4 finalColor = colorMix;
                //GI----------------------------------
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.uv0AndLightmapUV.zw, i.normalWS.xyz);
                    finalColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    finalColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif


                //Fog
                #ifdef _KLFogOfWar
                    finalColor.rgb = CalcFogOfWar(finalColor.rgb, i.positionWS, i.positionCS.y / _ScaledScreenParams.y);
                #endif
                return finalColor;                 
            }
            ENDHLSL
        }  
    }
}



//BakeGI_Mix2_VertexColorGUI

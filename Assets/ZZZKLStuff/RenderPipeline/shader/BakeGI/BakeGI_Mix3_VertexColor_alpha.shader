Shader "Jeremy/BakeGI/BakeGI_Mix3_VertexColor_alpha"
{
    Properties
    {
        // [Toggle]_MiddleQuality("Middle & High Quality",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcFactor("SrcFactor",int) = 1
        [Enum(UnityEngine.Rendering.BlendMode)]_DstFactor("DstFactor",int) = 0
        // _dotMask("dotMap Maask)",2D) = "black"{}
        [Header(Layer1(X)  Layer2(y)  Layer3(z)  Global(w))]
        [Space(10)]
        _HeightContract("Range:0-1,HeightContract",vector)=(0.1,0.1,0.1,0.1)
        [Header(VertexColor R(Layer1) G(Layer2) B(Layer3) A(alpha))]
        [Space(10)]
        _Layer1Map("Layer1Map RGB(color) A(height)",2D) = "white"{}
        _Layer2Map("Layer2Map RGB(color) A(height)",2D) = "white"{}
        _Layer3Map("Layer3Map RGB(color) A(height)",2D) = "white"{}
        // _dotVector("x-repeat,y-space,z-bright,w-null)",vector) = (3, 0.5, 0.5, 0)
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "../template/ZanyaHLSL.hlsl"
    CBUFFER_START(UnityPerMaterial)
        // int SHADERQUALITY;
        float4 _Layer1Map_ST;
        float4 _Layer2Map_ST;
        float4 _Layer3Map_ST;
        half4 _HeightContract;
        // half4 _dotVector;
    CBUFFER_END
    #define smp _linear_repeat
    SAMPLER(smp);
    TEXTURE2D(_Layer1Map); //SAMPLER(sampler_Layer1Map);
    TEXTURE2D(_Layer2Map); //SAMPLER(sampler_Layer2Map);
    TEXTURE2D(_Layer3Map); //SAMPLER(sampler_Layer3Map);
    // TEXTURE2D(_dotMask);
    ENDHLSL

    SubShader//lod 200
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent-10"}
        Blend [_SrcFactor] [_DstFactor]
        Cull Back
        ZWrite Off
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #pragma multi_compile _ LIGHTMAP_ON

            TEXTURE2D(_dotMap);
            struct appdata
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
                float4 vertexColor : COLOR;

            };

            struct v2f
            {
                float4 uv0 : TEXCOORD0;
                float4 uv1 : TEXCOORD1;//uv1.z: fogCoord
                float4 vertexColor : COLOR;
                float4 positionCS : SV_POSITION;
                half3 normalWS : TEXCOORD4;
                // #if _MIDDLEQUALITY_ON
                // float3 positionWS : TEXCOORD5;
                // float2 uv2 : TEXCOORD2;//uv1.z: fogCoord
                // #endif
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                //Mix Maps
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                // #if _MIDDLEQUALITY_ON
                // o.uv2.xy = v.uv;
                // o.positionWS = positionWS;
                // #endif
                o.positionCS = TransformWorldToHClip(positionWS.xyz);
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
                half4 texColor =0;
                //Mix Maps--------------------
                half4 maskMap = 0;
                maskMap.r = i.vertexColor.x;
                maskMap.g = i.vertexColor.y;
                maskMap.b = i.vertexColor.z;
                maskMap.a = i.vertexColor.w;
                half maskMapAx2 = maskMap.a*2 - 1;
                half maskMapAdd = max(maskMapAx2, 0);
                half maskMapSub = max(-maskMapAx2, 0);

                //Textures
                half4 layer1Map = SAMPLE_TEXTURE2D(_Layer1Map, smp, i.uv0.xy);     
                half4 layer2Map = SAMPLE_TEXTURE2D(_Layer2Map, smp, i.uv0.zw);
                half4 layer3Map = SAMPLE_TEXTURE2D(_Layer3Map, smp, i.uv1.xy); 

                //BlendWeight
                half heighAddL1 = maskMap.r + CheapContrast(layer1Map.a, _HeightContract.x);
                half heighAddL2 = maskMap.g + CheapContrast(layer2Map.a, _HeightContract.y);
                half heighAddL3 = maskMap.b + CheapContrast(layer3Map.a, _HeightContract.z);

                half heighMax = max(max(heighAddL1, heighAddL2), heighAddL3 ) - _HeightContract.w;
                half3 BlendWeight = 0;
                BlendWeight.x = max((heighAddL1 - heighMax), 0);
                BlendWeight.y = max((heighAddL2 - heighMax), 0);
                BlendWeight.z = max((heighAddL3 - heighMax), 0);
                half BlendWeightAdd = BlendWeight.x + BlendWeight.y + BlendWeight.z;
                BlendWeight = BlendWeight/BlendWeightAdd;
                //Color
                half4 colorMix = half4(layer1Map.rgba*BlendWeight.x + layer2Map.rgba*BlendWeight.y + 
                layer3Map.rgba*BlendWeight.z);

                //Alpha
                half ChannelA = saturate(colorMix.w + maskMapAdd - maskMapSub);
                texColor = half4(colorMix.rgb, ChannelA);

                // #if _MIDDLEQUALITY_ON
                // ////Dot Map---------------------------------------
                // half PosWStime = _dotVector.x;
                // half PosWScale = _dotVector.y;
                // half dotBright = _dotVector.z;
                // half dotMaskMap = SAMPLE_TEXTURE2D(_dotMask, smp, i.uv2.xy).r;
                // half3 dotColor = dotMap(PosWStime, PosWScale, dotBright, i.positionWS.x, i.positionWS.z, texColor.rgb);
                // texColor.rgb = lerp( texColor.rgb,   saturate(dotColor),   dotMaskMap);
                // #endif

                //GI----------------------------------
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.uv1.zw, i.normalWS.xyz);
                    texColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    texColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif
                //Dot Mix---------------------------------------
                // texColor.rgb = saturate(texColor.rgb - dotMap.r *(saturate(1-bakedGI)*_ShadowVector.w));
                return texColor;
            }
            ENDHLSL
        }
    }
    Fallback "Hidden/Shader Graph/FallbackError"
}

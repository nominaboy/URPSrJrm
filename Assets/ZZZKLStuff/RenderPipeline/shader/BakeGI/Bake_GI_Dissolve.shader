Shader "Jeremy/BakeGI/Bake_GI_Dissolve"
{
    Properties
    {
        _MainTex ("BaseMap(RGB)", 2D) = "white" {}
        _Zwrite("Zwrite",int)=0 //[Enum(off,0,on,1)]
        _Alpha("Alpha (dissolve)",Range(0,1)) = 0.5
        _Vec4("dot-x,fresnal-y,2dPow-z,2dIntesity-w", Vector) =(0,5,5,10)
        [Toggle]_Transparent("Transparent ON",int)=0 //[Enum(off,0,on,1)]
    }
    
    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "../template/ZanyaHLSL.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Vec4;
            half _Alpha;
        CBUFFER_END
        TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
    ENDHLSL
    
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent"}
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite [_Zwrite]
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile  _ _TRANSPARENT_ON
            
            #pragma multi_compile _ LIGHTMAP_ON

            struct appdata
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
            };
            
            struct v2f
            {
                float4 positionCS : SV_POSITION;
                #if _TRANSPARENT_ON
                    float3 positionWS : TEXCOORD2;
                #endif
                float4 uv0AndLightmapUV : TEXCOORD0; // xy: uv0, zw: LightmapUV
                half3 normalWS : TEXCOORD4;
                float4 screenUV : TEXCOORD1; // xy: uv0, z: fogCoord
            };        
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                #if _TRANSPARENT_ON
                    o.positionWS = positionWS;
                #endif
                o.positionCS = TransformWorldToHClip(positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv0AndLightmapUV.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv0AndLightmapUV.zw = v.staticLightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                // o.dissolveUV.xy = TRANSFORM_TEX(v.uv2, _DissolveTex);
                o.screenUV = ComputeScreenPos(o.positionCS);
                // o.screenUV.y = o.screenUV.y * 2 + (-22);
                return o;
            } 
            
            half4 frag(v2f i) : SV_TARGET
            {

                half4 finalColor;
                //固有色
                half2 uv = i.uv0AndLightmapUV.xy;
                half4 baseMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);//固有色采样
                finalColor = baseMap;
                
                //烘焙GI采样
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SampleLightmap(i.uv0AndLightmapUV.zw, i.normalWS.xyz);
                    finalColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    finalColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif

                // //遮罩图屏幕坐标
                #if _TRANSPARENT_ON
                    //ScreenUV
                    half2 ScreenUV = i.screenUV.xy/i.screenUV.w;
                    ScreenUV.y = ScreenUV.y * 2 + (-0.55);
                    half2 centerPoint = half2(0.5, 0.56);
                    //half circl = circle(ScreenUV, centerPoint); 
                    half circl = length(ScreenUV - centerPoint); 
                    circl = pow(circl,_Vec4.y);              
                
                    //Fresnel
                    half3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                    half dotNV = dot(i.normalWS, V);
                    half fresnel = 1 - dotNV;
                    finalColor.a = saturate( _Vec4.x + pow(fresnel, _Vec4.z)* _Vec4.w + circl + _Alpha); 
                #endif
                           
                return finalColor;
            }
            ENDHLSL
        }
    }
}

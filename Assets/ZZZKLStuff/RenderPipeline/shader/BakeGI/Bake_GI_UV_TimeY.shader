Shader "Jeremy/Deprecated/BakeGI/BakeGI_UV_TimeY"
{
    Properties
    {
        [HDR]_Color("Color",Color) = (1,1,1,1)
        _MainTex ("BaseMap", 2D) = "white" {}
        [Header(U(X)  V(Y)  mask_U(Z)  Mask_V(W))]
        [Space(10)]
        _Sequence("",vector)=(0,0.25,0,0.25)
    }
    
    HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _Color,_Sequence;
        CBUFFER_END
    ENDHLSL
    
    SubShader
    {
        Tags { "Queue" = "Geometry+15" }
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma multi_compile _ LIGHTMAP_ON
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float2 staticLightmapUV : TEXCOORD1;
                float3 normalOS         : NORMAL;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uv0AndLightmapUV : TEXCOORD0; // xy: uv0, zw: staticLightmapUV
                float3 normalWS : TEXCOORD1;
                float4 vertexColor : TEXCOORD2;
            };
            
            Varyings vert(Attributes i)
            {
                Varyings o = (Varyings)0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                
                o.uv0AndLightmapUV.xy = i.uv * _MainTex_ST.xy + frac(_Sequence.xy*_Time.y);
                o.uv0AndLightmapUV.zw = i.staticLightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
                o.vertexColor = i.color;
                return o;
            }           
            
            half4 frag(Varyings i) : SV_TARGET
            {
                half3 finalColor;
                //固有色
                half3 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0AndLightmapUV.xy);//固有色采样
                finalColor = lerp( _Color.rgb, baseColor* _Color.rgb, i.vertexColor.a)+ i.vertexColor.rgb;
                //烘焙GI采样
                #if defined(LIGHTMAP_ON)
                    half3 bakedGI = SAMPLE_GI(i.uv0AndLightmapUV.zw, 1, i.normalWS.xyz);
                    finalColor.rgb *= bakedGI;
                #else
                    float3 L = _MainLightPosition.xyz;
                    float NDotL = max(0.5, dot(i.normalWS.xyz, L));
                    finalColor.rgb *= NDotL.rrr+ unity_AmbientSky.rgb;
                #endif
                return half4(finalColor,1);
            }
            ENDHLSL
        }
        // UsePass "URP/Template/ShadowCast/ShadowCast"
    }
    
    Fallback "Hidden/Shader Graph/FallbackError"
}

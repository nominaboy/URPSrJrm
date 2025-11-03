Shader "Jeremy/Boss/BossChangeTex"
{
    Properties
    {
        _Tint("Tint", Color) = (0,0,0,0.2)
        [HideInInspector]_ToonMap("Toon Map", 2D) = "white"{}
        _MainTex("MainTex", 2D) = "grey"{}
        _ChangeTex("ChangeTex", 2D) = "grey"{}
        // _FresnelColor("Fresnel Color",Color)=(1,0.5,0,1)
        _vect2("dif-x,fre-y,pow-z,Ill-w",Vector)=(2,2,2,4)
        _lerpNum("Lerp Maps", Range(0,1)) = 0
        // [MatierialToggle(_ILLUM_ON)]_Illum("Illum Enable",int)=0
        [Toggle]_Illum("Illum Enable",int)=0
    }
    
    SubShader
    {
        
        Tags {"Renderpipeline"="UniveralRenderPipeline" "RenderType"="Opaqua" "Queue"="Geometry"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST, _ChangeTex_ST;
        half4 _vect2;
        half4 _Tint; //_FresnelColor,
        half _lerpNum;
        int _Illum;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            // #pragma shader_feature _ _ILLUM_ON
            #pragma shader_feature _ _ILLUM_ON

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal :NORMAL;
            };
            
            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            TEXTURE2D(_ChangeTex);SAMPLER(sampler_ChangeTex);
            TEXTURE2D(_ToonMap);SAMPLER(sampler_ToonMap);
            
            v2f vert (appdata v)
            {
                v2f o;
                half3 L = _MainLightPosition.xyz;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(o.worldPos);
                o.worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex); 
                o.uv.zw = saturate(dot(o.worldNormal, L));
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                half3 N = i.worldNormal;
                half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                half NdotV = pow(1 - saturate(dot(N,V)), _vect2.y )*_vect2.z;
                // half3 H = normalize(L + V);
                // half3 L = _MainLightPosition.xyz;
                // half NdotL = max(0, dot(N,L));
                // i.uv.zw = NdotL * _uvScale.xy ;
                
                half4 col = 1;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half4 changeTex = SAMPLE_TEXTURE2D(_ChangeTex, sampler_ChangeTex, i.uv.xy);
                half4 mixTex = lerp(mainTex, changeTex,  _lerpNum);
                half4 toonMap = SAMPLE_TEXTURE2D(_ToonMap, sampler_ToonMap, i.uv.zw);
                
                half4 diffuse = mixTex * (  toonMap * _MainLightColor + unity_AmbientSky) ;
                col.rgb = diffuse.rgb * _vect2.x;//_LightColor0 unity_AmbientSky
                
                // //Shadow
                // float shadow = 1;
                // half4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                // half3 bakedGI = half3(1, 1, 1);
                // ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                // half4 shadowParams = GetMainLightShadowParams();
                // #ifdef _SHADOWS_SOFT
                // shadow = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData);
                // #else
                // //// 1-tap hardware comparison
                // shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz);
                // #endif
                // col.rgb += NdotV * _vect2.w * _FresnelColor.rgb;
                #if _ILLUM_ON
                col.rgb +=  mainTex.rgb * mainTex.a * _vect2.w;
                #endif
                col.rgb += NdotV * ( _Tint.a * 10) * _Tint.rgb;
                return col;
                
            }
            ENDHLSL
        }
        
        // UsePass "URP/Template/ShadowCast/ShadowCast"
    }
}

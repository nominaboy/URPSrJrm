// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Jeremy/Boss/Boss_rim"
{
    Properties
    {
        _Tint("Tint ",Color)=(0, 0, 0, 0)
        _MainTex("MainTex",2D) = "white"{}
        _SpacularColor("Specular Color",Color)=(0.75,0.9,1,1)
        [Header(Diffuse(X)  Specular(y)  Shininess(z)  DarkIntensity(w))]
        [Space]
        _number("dif-X dark-Y spe-Z glos-W",vector)=(0.1,0.1,0.1,5)
        _vect("self-X fresPow-Y Intes-Z FreUse-W",vector)=(0.1,1.5,2,0)
        _FresnelColor("Fresnel Color",Color)=(1,0.5,0,1)
        _FresnelColorSelf("Fresnel Color(self)",Color)=(1,0.5,0,1)
        [MatierialToggle(_ILLUM_ON)]_Illum("Illum Enable",int)=0
        _Illumindex("Illum Index", Range(0,10)) = 4
        // _dotMap("Dot Map", 2D) = "black"{}
        // [Enum(Right,1,Left,-1)]_RimSide("Rim Side",int) = 1
        _RimSide("Rim Side(Right:1, Left:-1)",vector) = (-1,0.55,0,0)

    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
    // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    CBUFFER_START(UnityPerMaterial)
        half4 _Tint;
        half4 _number,_RimSide;
        float4 _MainTex_ST;
        // float4 _dotMap_ST;
        half4 _SpacularColor,_FresnelColor,_FresnelColorSelf;
        half4 _vect;
        int _Illum;
        half _Illumindex;
    CBUFFER_END
    ENDHLSL

    SubShader
    {
        LOD 600
        Tags {"RenderType"="Opaqua" "Queue"="Geometry"}
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature _ _ILLUM_ON
            // #pragma multi_compile_fog//-------------------------------------------------------fog(0)
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal :NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;//-------------------------------------------------------fog(1)
                // float2 dotUV :TEXCOORD3;
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            
            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(o.worldPos);
                o.worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex);
                // o.uv.z = ComputeFogFactor(o.pos.z);//-------------------------------------------------------fog(2)
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = 0;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half3 N = normalize(i.worldNormal);
                half3 L = _MainLightPosition.xyz;
                half NdotL = max(0, dot(N,L));
                half4 diffuse =    mainTex  ;
                half4 lambert = (  saturate( NdotL / _number.x  + _number.y ) ) * diffuse  * _MainLightColor;
                col.rgb = saturate(lambert).rgb;

                half ks = _number.z;
                half Shininess = _number.w;

                half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 H = L + V;
                // half dotNH = max(0,dot(N,H));
                // dotNH = pow(dotNH-0.2,Shininess);
                // return dotNH;
                half4 SpecBlinPhong = _SpacularColor * ks * pow(saturate(dot(N,H)-_RimSide.y), Shininess);
                // SpecBlinPhong = saturate(SpecBlinPhong);
                // SpecBlinPhong.rgb = SpecBlinPhong.rgb * SpecBlinPhong.a;

                half NdotV = pow(1 - saturate(dot(N,V)), _vect.y )*_vect.z;
                half4 Fresnel = _FresnelColor * NdotV * _vect.w ;
                half4 FresnelSelf = saturate((_FresnelColorSelf * NdotV * _vect.x * saturate(N.x * _RimSide.x )));
                // return N.x;

                // //Shadow
                // half shadow = 1;
                // half4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
                // half3 bakedGI = half3(1, 1, 1);
                // ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
                // half4 shadowParams = GetMainLightShadowParams();
                // #ifdef _SHADOWS_SOFT
                //     shadow = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData);
                // #else
                //     shadow = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz);
                // #endif
                // shadow = max(shadow, 0.5);
                // col *= half4(shadow,shadow,shadow,1);

                col += SpecBlinPhong*mainTex;
                
                #if _ILLUM_ON
                col += half4( mainTex.rgb * mainTex.a * _Illumindex, 0 );
                #endif

                // col.rgb = MixFog(col.rgb, i.uv.z);//-------------------------------------------------------fog(3)
                col.rgb += FresnelSelf.rgb;
                col.rgb += Fresnel.rgb;
                col += _Tint*NdotV;

                return col;
            }
            ENDHLSL
        }
    }


    // SubShader
    // {
    //     LOD 400
    //     Tags {"RenderType"="Opaqua" "Queue"="Geometry"}
    //     Pass
    //     {
    //         Tags {"LightMode"="UniversalForward"}
    //         HLSLPROGRAM
    //         #pragma vertex vert
    //         #pragma fragment frag
    //         #pragma multi_compile _ _ILLUM_ON
    //         // #pragma multi_compile_fog//-------------------------------------------------------fog(0)
    //         struct appdata
    //         {
    //             float4 vertex : POSITION;
    //             float2 uv : TEXCOORD0;
    //             float4 normal :NORMAL;
    //         };

    //         struct v2f
    //         {
    //             float2 uv : TEXCOORD0;//-------------------------------------------------------fog(1)
    //             // float2 dotUV :TEXCOORD3;
    //             float4 pos : SV_POSITION;
    //             float3 worldNormal : TEXCOORD1;
    //             float3 worldPos : TEXCOORD2;
    //         };
    //         TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            
    //         v2f vert (appdata v)
    //         {
    //             v2f o;
    //             o.worldPos = TransformObjectToWorld(v.vertex.xyz);
    //             o.pos = TransformWorldToHClip(o.worldPos);
    //             o.worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
    //             o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex);
    //             // o.uv.z = ComputeFogFactor(o.pos.z);//-------------------------------------------------------fog(2)
    //             return o;
    //         }

    //         half4 frag (v2f i) : SV_Target
    //         {
    //             half4 col = 0;
    //             half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
    //             half3 N = (i.worldNormal);
    //             half3 L = _MainLightPosition.xyz;
    //             half NdotL =saturate(dot(N,L));
    //             half4 diffuse =  saturate(  mainTex  );
    //             half4 lambert = ( 0.35  + saturate( NdotL / _number.x  + _number.y ) ) * diffuse * _MainLightColor;
    //             col.rgb = saturate(lambert).rgb;

    //             // half ks = _number.z;
    //             // half Shininess = _number.w;

    //             half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
    //             // half3 H = normalize(L + V);
    //             // half4 SpecBlinPhong = _SpacularColor * ks * pow( max ( 0, dot(N,H)), Shininess);

    //             half NdotV = pow(1 - saturate(dot(N,V)), _vect.y )*_vect.z;
    //             half4 Fresnel = _FresnelColor*NdotV*_vect.w;
    //             half4 FresnelSelf = _FresnelColorSelf * NdotV * _vect.x;

    //             // col += SpecBlinPhong;
                
    //             #if _ILLUM_ON
    //             col += half4( mainTex.rgb * mainTex.a * _Illumindex, 0 );
    //             #endif

    //             // col.rgb = MixFog(col.rgb, i.uv.z);//-------------------------------------------------------fog(3)
    //             col.rgb += FresnelSelf.rgb;
    //             col.rgb += Fresnel.rgb;
    //             col += _Tint*NdotV;

    //             return col;
    //         }
    //         ENDHLSL
    //     }
    // }

    // SubShader
    // {
    //     LOD 200
    //     Tags {"RenderType"="Opaqua" "Queue"="Geometry"}
    //     Pass
    //     {
    //         Tags {"LightMode"="UniversalForward"}
    //         HLSLPROGRAM
    //         #pragma vertex vert
    //         #pragma fragment frag
    //         #pragma multi_compile _ _ILLUM_ON
    //         // #pragma multi_compile_fog//-------------------------------------------------------fog(0)
    //         struct appdata
    //         {
    //             float4 vertex : POSITION;
    //             float2 uv : TEXCOORD0;
    //             float4 normal :NORMAL;
    //         };

    //         struct v2f
    //         {
    //             float2 uv : TEXCOORD0;//-------------------------------------------------------fog(1)
    //             // float2 dotUV :TEXCOORD3;
    //             float4 pos : SV_POSITION;
    //             float3 worldNormal : TEXCOORD1;
    //             float3 worldPos : TEXCOORD2;
    //         };
    //         TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            
    //         v2f vert (appdata v)
    //         {
    //             v2f o;
    //             o.worldPos = TransformObjectToWorld(v.vertex.xyz);
    //             o.pos = TransformWorldToHClip(o.worldPos);
    //             o.worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
    //             o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex);
    //             // o.uv.z = ComputeFogFactor(o.pos.z);//-------------------------------------------------------fog(2)
    //             return o;
    //         }

    //         half4 frag (v2f i) : SV_Target
    //         {
    //             half4 col = 0;
    //             half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
    //             half3 N = (i.worldNormal);
    //             half3 L = _MainLightPosition.xyz;
    //             half NdotL = saturate( dot(N,L));
    //             half4 diffuse =  saturate(  mainTex  );
    //             half4 lambert = ( 0.35  + saturate( NdotL / _number.x  + _number.y ) ) * diffuse * _MainLightColor;
    //             col.rgb = saturate(lambert).rgb;

    //             // half ks = _number.z;
    //             // half Shininess = _number.w;

    //             // half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
    //             // half3 H = normalize(L + V);
    //             // half4 SpecBlinPhong = _SpacularColor * ks * pow( max ( 0, dot(N,H)), Shininess);

    //             // half NdotV = pow(1 - saturate(dot(N,V)), _vect.y )*_vect.z;
    //             half4 Fresnel = _FresnelColor*_vect.w;
    //             half4 FresnelSelf = _FresnelColorSelf * _vect.x;
                
    //             #if _ILLUM_ON
    //             col += half4( mainTex.rgb * mainTex.a * _Illumindex, 0 );
    //             #endif

    //             // col.rgb = MixFog(col.rgb, i.uv.z);//-------------------------------------------------------fog(3)
    //             col.rgb += FresnelSelf.rgb;
    //             col.rgb += Fresnel.rgb;
    //             col += _Tint;

    //             return col;
    //         }
    //         ENDHLSL
    //     }
    // }

    CustomEditor "BossRimGUI"
}

Shader "Jeremy/Boss/BossAlpha"
{
    Properties
    {
        _Tint("Tint ",Color)=(0, 0, 0, 0)
        _Color("Color",Color) = (1,1,1,1)
        _MainTex("MainTex",2D) = "white"{}
        _SpacularColor("Specular Color",Color)=(0.75,0.9,1,1)
        [Header(Diffuse(X)  Specular(y)  Shininess(z)  DarkIntensity(w))]
        [Space]
        _number("ramp-X dark+-Y spe-Z glos-W",vector)=(0.1, 0.1, 0, 5)
        _vect("self-X fresPow-Y Intes-Z FreUse-W",vector)=(0, 2, 2, 0)
        _FresnelColor("Fresnel Color",Color)=(1,0.5,0,1)
        _FresnelColorSelf("Fresnel Color(self)",Color)=(1, 0.47, 0.33, 1)
        [MatierialToggle(_ILLUM_ON)]_Illum("Illum Enable",int)=0
        _Illumindex("Illum Ill-x, dif-y", Vector) = (4, 1, 0, 0)
    }

    SubShader // lod 400
    {  
        Tags {"RenderType"="Transparent" "Queue"="Transparent"}
        LOD 400
        ZWrite On
        Blend SrcAlpha OneMinusSrcAlpha
        // ZTest Lequal
        Cull back
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #pragma shader_feature _ _ILLUM_ON
        // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        CBUFFER_START(UnityPerMaterial)
            half4 _Tint;
            half4 _number;
            float4 _MainTex_ST;
            half4 _SpacularColor,_FresnelColor,_FresnelColorSelf,_Color;
            half4 _vect;
            int _Illum;
            half4 _Illumindex;
        CBUFFER_END
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal :NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;//-------------------------------------------------------fog(1)
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
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 col = 0;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv) * _Color;
                half3 N = i.worldNormal;
                half3 L = _MainLightPosition.xyz;
                half NdotL = saturate(dot(N,L));
                half4 lambert = ( 0.35  + saturate( NdotL / _number.x  + _number.y ) ) * mainTex * _MainLightColor;
                col.rgb = saturate(lambert.rgb ) * _Illumindex.y;

                half ks = _number.z;
                half Shininess = _number.w;

                half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);
                half3 H = normalize(L + V);
                half4 SpecBlinPhong = _SpacularColor * ks * pow( saturate(dot(N,H)), Shininess);

                half NdotV = pow(1 - saturate(dot(N,V)), _vect.y )*_vect.z;
                half4 Fresnel = _FresnelColor * NdotV * _vect.w;
                half4 FresnelSelf = _FresnelColorSelf * NdotV * _vect.x;

                col += SpecBlinPhong;
                
                #if _ILLUM_ON
                col += half4( mainTex.rgb * mainTex.a * _Illumindex.x, 0 );
                #endif
                col.rgb += FresnelSelf.rgb;
                col.rgb += Fresnel.rgb;
                col += _Tint * NdotV;
                col.a = _Color.a;
                return col;

            }
            ENDHLSL
        }

    }

    // SubShader // lod 200
    // {  
    //     Tags {"RenderType"="Opaqua" "Queue"="Geometry"}
    //     LOD 200
    //     ZWrite On
    //     Cull back
    //     Pass
    //     {
    //         Tags {"LightMode"="UniversalForward"}
    //         HLSLPROGRAM
    //         #pragma vertex vert
    //         #pragma fragment frag
    //         #pragma multi_compile _ _ILLUM_ON
    //         #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    //         #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    //         CBUFFER_START(UnityPerMaterial)
    //             half4 _Tint;
    //             half4 _number;
    //             float4 _MainTex_ST;
    //             half4 _FresnelColor,_FresnelColorSelf;
    //             half4 _vect;
    //             int _Illum;
    //             half4 _Illumindex;
    //         CBUFFER_END

    //         struct appdata
    //         {
    //             float4 vertex : POSITION;
    //             float2 uv : TEXCOORD0;
    //             float4 normal :NORMAL;
    //         };

    //         struct v2f
    //         {
    //             float2 uv : TEXCOORD0;//-------------------------------------------------------fog(1)
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
    //             return o;
    //         }

    //         half4 frag (v2f i) : SV_Target
    //         {
    //             half4 col = 0;
    //             half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
    //             half3 N = i.worldNormal;
    //             half3 L = _MainLightPosition.xyz;
    //              half3 V = normalize(_WorldSpaceCameraPos - i.worldPos);

    //             half3 H = normalize(L + V);

    //             half NdotL = saturate(dot(H,L));
    //             half4 lambert = ( 0.35  + saturate( NdotL / _number.x  + _number.y ) ) * mainTex * _MainLightColor;
    //             col.rgb = saturate(lambert.rgb ) * _Illumindex.y;

    //             // half ks = _number.z;
    //             // half Shininess = _number.w;
               
                
    //             // half4 SpecBlinPhong = _SpacularColor * ks * pow( max ( 0, dot(N,H)), Shininess);

    //             half NdotV = pow(1 - saturate(dot(N,V)), _vect.y )*_vect.z;
    //             half4 Fresnel = _FresnelColor * NdotV * _vect.w;
    //             half4 FresnelSelf = _FresnelColorSelf * NdotV * _vect.x;

    //             // col += SpecBlinPhong;
    //             #if _ILLUM_ON
    //             col += half4( mainTex.rgb * mainTex.a * _Illumindex.x, 0 );
    //             #endif
    //             col.rgb += FresnelSelf.rgb;
    //             col.rgb += Fresnel.rgb;
    //             col += _Tint * NdotV;
    //             return col;
    //         }
    //         ENDHLSL
    //     }
    // }
   CustomEditor "BossAlphaGUI"
}

Shader "Jeremy/CustomPBR/Custom_AddLights_blinPhong"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "grey"{}
        _vect("dif-x,MainLight-y,null-z,spec-w", Vector)=(1,2,2,1)
        // [Header(r_ref g_spec b_rou)]
        _MaskTex ("Mask R:ref G:spec B:smoothness A:rimMask", 2D) = "white" {}
        [Toggle]_ReflectionCube("ReflectCube Enable", int)=0
        _vect3("Addlight-x,ref-y,Ill-z,glos-w", Vector)=(1,2,4,4)
        [Toggle]_Illu("Illu Enable", int) = 0
    }
    
    SubShader
    {  
        Tags {"Renderpipeline"="UniveralRenderPipeline" "RenderType"="Transparent" "Queue"="Transparent"}
        Stencil
        {
            Ref 2
            Comp GEqual
            Pass Replace
        }
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "../template/ZanyaHLSL.hlsl"
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half4 _vect,_vect3;
            int _ReflectionCube, _Illu;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            // Tags {"LightMode"="AfterTrans2"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag         
            #pragma target 3.0
            #pragma shader_feature _REFLECTIONCUBE_ON
            #pragma shader_feature _ILLU_ON
            
            #define CUBEMAP_LOD_STEPS 6

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal :NORMAL;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };
            
            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
            // #if _REFLECTIONCUBE_ON
            TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);
            // #endif
            
            v2f vert (appdata v)
            {
                v2f o;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionCS = TransformWorldToHClip(o.positionWS);
                o.normalWS =TransformObjectToWorldNormal(v.normal.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex); 
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                float3 positionWS = i.positionWS;//世界坐标
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos - positionWS);
                half4 col = 1;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.xy);






                //r-金属反射度，g-高光强度，b-光滑度，a-null
                //第一个_vect: x-diff, y-dotNV-pow, z-dotNV-x, w-null
                //第二个_vect3：x-, y-反射强度, z-自发光强度, w-
                
                //灯光分层剔除获取***********************************************************************start
                // uint meshRenderingLayers = (uint)0;//Light Render Culling Mask: Everything,Default,Water,UI...
                // #ifdef _LIGHT_LAYERS
                // meshRenderingLayers = (asuint(unity_RenderingLayer.x) & RENDERING_LIGHT_LAYERS_MASK) >> RENDERING_LIGHT_LAYERS_MASK_SHIFT;
                // #else
                // // Always in this branch
                // meshRenderingLayers = RENDERING_LIGHT_LAYERS_MASK >> RENDERING_LIGHT_LAYERS_MASK_SHIFT; // 1111 1111
                // #endif
                //灯光分层剔除*************************************************************************end
                
                //主光diffuse
                Light mainLight = GetMainLight();
                half3 lightColor = LightingCustum(N, mainLight)* _vect.y * maskTex.a;
                
                //二光specular
                Light light2 = GetAdditionalLight(1, positionWS);
                half3 L2 = light2.direction;
                half ks = _vect.w ;

                half shininess = _vect3.w ;
                half3 H = normalize(L2 + V);
                half4 SpecBlinPhong2 =  ks * pow(max(0, dot(N,H)), shininess);
                
                //额外光diffuse
                int pixelLightCount = GetAdditionalLightsCount();
                for (int index = 0; index < pixelLightCount; index++)
                {
                    Light light = GetAdditionalLight(index, positionWS);
                    lightColor += LightingCustum(N, light) * _vect3.x;
                }
                
                half4 diffuse = mainTex * (half4(lightColor, 1) + unity_AmbientSky);
                col = diffuse * _vect.x;
                

                #if _REFLECTIONCUBE_ON
                    float3 reflectVec = reflect(-V, N);
                    half roughness = 1 - maskTex.b;
                    half mip = roughness * (1.7 - 0.7 * roughness) * CUBEMAP_LOD_STEPS;
                    half4 rgbm = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVec, mip);
                    float3 iblSpecular = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);
                    col.rgb += iblSpecular * maskTex.r * _vect3.y;
                #endif 
                
                #if _ILLU_ON
                    col.rgb +=  mainTex.rgb * maskTex.b * _vect3.z ;
                #endif
                
                col.rgb +=  SpecBlinPhong2.rgb * maskTex.g * mainTex.rgb;
                // col.rgb += NdotV * ( _Tint.a * 10) * _Tint.rgb;
                return col;
                
            }
            ENDHLSL
        }
    }
}
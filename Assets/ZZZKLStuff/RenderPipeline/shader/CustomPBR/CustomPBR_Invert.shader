Shader "Jeremy/CustomPBR/Custom_AddLight_InvertY"
{
    Properties
    {
        // _Tint("Tint", Color) = (0,0,0,0)
        [HDR]_SelfColor("Self Color", Color) = (1.5, 1.5, 1.5, 1)
        _FloorColor("Floor Color", Color) = (0.71, 0.72, 0.7, 1)
        _MainTex("MainTex", 2D) = "grey"{}
        _vect("dif-x,Tranx-y,pow-z,null-w",Vector)=(1,2,2,1)
        _MaskTex ("Mask R:Metallic G:Roughness B:AO A:Emission", 2D) = "white" {}
        [Toggle]_ReflectionCube("ReflectCube Enable",int)=0
        _vect3("Addlight-x,ref-y,Ill-z,0-w",Vector)=(1,2,4,4)
        [Toggle]_Illu("Illu Enable",int)=0
        _InvertVec("Invert-XYZ,InvPow-W", Vector) = (1,-1,1,2.2)
        _InvertTranform("InvertPos-XYZ,InvIndex-W", Vector) = (0,0,0,3.5)
    }
    
    SubShader
    {  
        Tags {"Renderpipeline"="UniveralRenderPipeline" "RenderType"="Opaqua" "Queue"="Geometry"}
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "../template/ZanyaHLSL.hlsl"
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_ST;
        half4 _vect,_vect3,_InvertVec,_InvertTranform;
        half4 _FloorColor, _SelfColor;//_Tint; 
        int _ReflectionCube, _Illu;
        CBUFFER_END
        ENDHLSL
        
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            Cull Front
            // ZTest Greater
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag         
            #pragma target 3.0
            #pragma multi_compile _ _REFLECTIONCUBE_ON
            #pragma multi_compile _ _ILLU_ON

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
            #if _REFLECTIONCUBE_ON
            TEXTURE2D(_MaskTex);SAMPLER(sampler_MaskTex);
            #endif
            
            v2f vert (appdata v)
            {
                v2f o;
                float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
                // positionWS.y = positionWS.y*_InvertVec.y+_InvertTranform.y;
                positionWS.xyz = positionWS.xyz*_InvertVec.xyz+_InvertTranform.xyz;//- _InvertVec.w;
                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(positionWS);
                o.normalWS = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex); 
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                float screenV = i.positionCS.y/_ScreenParams.y;
                float screenMask =  1 - screenV;
                screenMask = pow(abs(screenMask), _InvertVec.w) * _InvertTranform.w;

                float3  positionWS = i.positionWS;//世界坐标

                half3 N = i.normalWS;
                half3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                // half NdotV = pow(1 - saturate(dot(N,V)), _vect.y )*_vect.z;
                
                half4 col = 1;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
            
                //灯光分层剔除获取***********************************************************************start
                // uint meshRenderingLayers = (uint)0;//Light Render Culling Mask: Everything,Default,Water,UI...
                // #ifdef _LIGHT_LAYERS
                // meshRenderingLayers = (asuint(unity_RenderingLayer.x) & RENDERING_LIGHT_LAYERS_MASK) >> RENDERING_LIGHT_LAYERS_MASK_SHIFT;
                // #else
                // meshRenderingLayers = RENDERING_LIGHT_LAYERS_MASK >> RENDERING_LIGHT_LAYERS_MASK_SHIFT;
                // #endif
                //灯光分层剔除*************************************************************************end
                
                ////主灯光运算
                Light mainLight = GetMainLight();
                half3 L = mainLight.direction;
                half3 lightColor = 0;

                lightColor = LightingCustum(N, mainLight);

                //额外灯光运算@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                int pixelLightCount = GetAdditionalLightsCount();//获取副光源个数，整数类型
                for (int index = 2; index < pixelLightCount; index++)//更改index 0---》2}}}}}}}
                {
                    Light light = GetAdditionalLight(index, positionWS);//获取其他的福光源世界位置
                    lightColor += LightingCustum(N, light) * _vect3.x;
                }

                half4 diffuse = mainTex * (half4(lightColor,1)+ unity_AmbientSky) ;
                col = diffuse * _vect.x;

                #if _REFLECTIONCUBE_ON
                half4 maskTex = SAMPLE_TEXTURE2D(_MaskTex, sampler_MaskTex, i.uv.xy);
                float3 reflectVec = reflect(-V, N);
                half4 rgbm=SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,samplerunity_SpecCube0,reflectVec,0);
                float3 iblSpecular = DecodeHDREnvironment(rgbm, unity_SpecCube0_HDR);
                col.rgb += iblSpecular * maskTex.r * _vect3.y;
                #if _ILLU_ON
                col.rgb +=  mainTex.rgb * maskTex.b * _vect3.z;
                #endif
                #endif 

                col *= _SelfColor;
                col.rgb = lerp(col.rgb, _FloorColor.rgb, saturate(screenMask));
                
                // col.rgb += NdotV * ( _Tint.a * 10) * _Tint.rgb;
                return col;
                
            }
            ENDHLSL
        }
        // UsePass "URP/Template/DepthOnly/DepthOnly"
        // UsePass "URP/Template/ShadowCast/ShadowCast"
    }
}

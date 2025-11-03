Shader "Jeremy/Effect/EffectOpaque"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", float) = 2
        [Toggle] _CustomData1XY("CustomData1XY", float) = 0
        [Toggle] _CustomData1ZW("CustomData1ZW", float) = 0
        [Toggle] _CustomData2X("CustomData2XY", float) = 0
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color("Color", Color) = (1,1,1,1)

        _MainTex_Uspeed("MainTex_Uspeed", float) = 0
        _MainTex_Vspeed("MainTex_Vspeed", float) = 0
        [Toggle] _BackColor_ON("����������ɫ", float) = 0
        [HDR] _BackColor("������ɫ", Color) = (1,1,1,1)
        [Toggle(_ADDTEX_ON)] _AddTexOn("AddTexOn", float) = 0
        _AddTex("AddTex", 2D) = "white"{}
        [HDR] _AddTex_Color("Color", Color) = (1,1,1,1)
        _AddTex_Uspeed("AddTex_Uspeed", float) = 0
        _AddTex_Vspeed("AddTex_Vspeed", float) = 0

        [Toggle(_MASKTEX_ON)] _MaskTexOn("MaskTexOn", float) = 0
        _MaskTex("MaskTex", 2D) = "white"{}
        [Toggle] _MaskTex_RA("MaskTex_RA", float) = 0
        _Mask_Uspeed("Mask_Uspeed", float) = 0
        _Mask_Vspeed("Mask_Vspeed", float) = 0

        [Toggle(_DISSOLVETEX_ON)] _DissolveTexOn("DissolveTexOn", float) = 0
        _DissolveTex("DissolveTex", 2D) = "white"{}
        _DissolveValue("DissolveValue", Range(0,1.2)) = 0
        _Dissolve_Uspeed("Dissolve_Uspeed", float) = 0
        _Dissolve_Vspeed("Dissolve_Vspeed", float) = 0


        [Toggle(_FRESNE_ON)] _FresnelOn("FRESNE_ON", float) = 0
        _FresnelBase("fresnelBase", Range(0, 1)) = 0
        _FresnelScale("fresnelScale", Range(0, 1)) = 1
        _FresnelIndensity("fresnelIndensity", Range(0, 10)) = 1
        [HDR] _FresnelCol("_fresnelCol", Color) = (1,1,1,1)

        _MainTexAngle("MainTexAngle", float) = 0
        _AddTexAngle("AddTexAngle", float) = 0
        _MaskTexAngle("MaskTexAngle", float) = 0


        [Toggle(_NOISETEX_ON)] _Noise_On("_Noise_On", float) = 0
        _NoiseTexture("NoiseTexture", 2D) = "white" {}
        _NoiseTex_Uspeed("NoiseTex_Uspeed", float) = 0
        _NoiseTex_Vspeed("NoiseTex_Vspeed", float) = 0
        _Noise_Intensity("Noise_Intensity", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry"}
        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Blend Off
            Cull [_CullMode]
            ZTest LEqual
            ZWrite On
            HLSLPROGRAM
            // #pragma enable_d3d11_debug_symbols
            #pragma shader_feature_local _ _ADDTEX_ON
            #pragma shader_feature_local _ _MASKTEX_ON
            #pragma shader_feature_local _ _DISSOLVETEX_ON
            #pragma shader_feature_local _ _FRESNE_ON
            #pragma shader_feature_local _ _NOISETEX_ON
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #pragma target 3.0
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                half4 vertexColor : COLOR;
                float2 uv : TEXCOORD0;
                float4 customData1 : TEXCOORD1;
                float4 customData2 : TEXCOORD2;
            };

            struct Varyings
            {
                float4 basePlusRotatedUV1 : VAR_BASE_ROTATED_UV1;
                float4 rotatedUV2 : VAR_ROTATED_UV2;
                float3 normalWS : VAR_NORMALWS;
                float3 positionWS : VAR_POSITIONWS;
                half4 vertexColor : VAR_COLOR;
                float4 customData1 : VAR_CUSTOMDATA1;
                float4 customData2 : VAR_CUSTOMDATA2;
                float4 positionCS : SV_POSITION;
            };
                
            
            sampler2D _MainTex;
            sampler2D _AddTex;
            sampler2D _MaskTex;
            sampler2D _DissolveTex;
            sampler2D _NoiseTexture;

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                half4 _Color;
                float _MainTex_Uspeed;
                float _MainTex_Vspeed;
                float4 _AddTex_ST;
                half4 _AddTex_Color;
                float _AddTex_Uspeed;
                float _AddTex_Vspeed;
                float _MaskTex_RA;
                float _Mask_Uspeed;
                float4 _MaskTex_ST;
                float4 _DissolveTex_ST;
                float _Mask_Vspeed;
                float _DissolveValue;
                float _Dissolve_Uspeed;
                float _Dissolve_Vspeed;
                float _FresnelBase;
                float _FresnelScale;
                float _FresnelIndensity;
                half4 _FresnelCol;
                float _CustomData1XY;
                float _CustomData1ZW;
                float _CustomData2X;
          
                float _MainTexAngle;
                half4 _BackColor;
                float _AddTexAngle;
                float _MaskTexAngle;

                float _Noise_On;
                float _NoiseTex_Uspeed;
                float4 _NoiseTexture_ST;
                float _NoiseTex_Vspeed;
                float _Noise_Intensity;
                float _BackColor_ON;
            CBUFFER_END

            

            float2 RotateUV(float2 uv, float uvRotate)
            {
                float2 outUV;
                float s = sin(uvRotate / 57.2958);
                float c = cos(uvRotate / 57.2958);

                outUV = uv - float2(0.5, 0.5);
                outUV = float2(outUV.x * c - outUV.y * s, outUV.x * s + outUV.y * c);
                outUV += float2(0.5, 0.5);
                return outUV;
            }

            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.basePlusRotatedUV1.xy = i.uv;
                o.basePlusRotatedUV1.zw = RotateUV(i.uv, _MainTexAngle);
                o.rotatedUV2.xy = RotateUV(i.uv, _AddTexAngle);
                o.rotatedUV2.zw = RotateUV(i.uv, _MaskTexAngle);

                
                o.normalWS = TransformObjectToWorldDir(i.normalOS.xyz);
                o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
                o.vertexColor = i.vertexColor;
                o.customData1 = i.customData1.xyzw;
                o.customData2 = i.customData2.xyzw;
                o.positionCS = TransformWorldToHClip(o.positionWS);
                return o;
            }

            

            half4 frag (Varyings i) : SV_Target
            {
                float NDotV = dot(normalize(i.normalWS), normalize(_WorldSpaceCameraPos - i.positionWS));
                half isFrontFace = step(0, NDotV);

                float2 noise = float2(0, 0);

                #ifdef _NOISETEX_ON
                    float2 noiseOffset = float2(_NoiseTex_Uspeed, _NoiseTex_Vspeed) * _Time.y;
                    noise = tex2D(_NoiseTexture, TRANSFORM_TEX(i.basePlusRotatedUV1.xy, _NoiseTexture) + noiseOffset).xy * _Noise_Intensity;
                #endif

                _MainTex_Uspeed = _CustomData1XY ? i.customData1.x : _MainTex_Uspeed * _Time.y;
                _MainTex_Vspeed = _CustomData1XY ? i.customData1.y : _MainTex_Vspeed * _Time.y;
              
                half4 col = tex2D(_MainTex, TRANSFORM_TEX(i.basePlusRotatedUV1.zw, _MainTex) + float2(_MainTex_Uspeed, _MainTex_Vspeed) + noise);
                col.rgb *= _Color.rgb * i.vertexColor.rgb;

                #ifdef _ADDTEX_ON
                    _AddTex_Uspeed =  _CustomData1XY ? i.customData1.x : _AddTex_Uspeed * _Time.y;
                    _AddTex_Vspeed =  _CustomData1XY ? i.customData1.y : _AddTex_Vspeed * _Time.y;
                    float4 addMap = tex2D(_AddTex, TRANSFORM_TEX(i.rotatedUV2.xy, _AddTex) + float2(_AddTex_Uspeed, _AddTex_Vspeed) + noise);
                    addMap *= _AddTex_Color;
                    col *= addMap;
                #endif
              
                
                if(_BackColor_ON)
                {
                    col.rgb = isFrontFace ? col.rgb : _BackColor.rgb;
                }
               
                #ifdef _MASKTEX_ON
                    _Mask_Uspeed = _CustomData1ZW ? i.customData1.z : _Mask_Uspeed * _Time.y;
                    _Mask_Vspeed = _CustomData1ZW ? i.customData1.w : _Mask_Vspeed * _Time.y;
                    float4 maskMap = tex2D(_MaskTex, TRANSFORM_TEX(i.rotatedUV2.zw, _MaskTex) + float2(_Mask_Uspeed, _Mask_Vspeed));
                    col = col * (_MaskTex_RA ? maskMap.a : maskMap.r);
                #endif

                #ifdef _DISSOLVETEX_ON
                    _Dissolve_Uspeed =  _Dissolve_Uspeed * _Time.y;
                    _Dissolve_Vspeed =  _Dissolve_Vspeed * _Time.y;
                    float dissolveClip = tex2D(_DissolveTex, TRANSFORM_TEX(i.basePlusRotatedUV1.xy, _DissolveTex) + float2(_Dissolve_Uspeed, _Dissolve_Vspeed)).r;
                    _DissolveValue = _CustomData2X ? i.customData2.x : _DissolveValue;
                    clip(dissolveClip - _DissolveValue);
                #endif
                
                #ifdef _FRESNE_ON
                    float fresnel = pow(1 - saturate(NDotV), _FresnelIndensity) * _FresnelScale + _FresnelBase;
                    col = lerp(col, _FresnelCol, fresnel * _FresnelCol.a * isFrontFace);
                #endif
               
                return half4(col.rgb, 1); 
            }
            ENDHLSL
        }
    }
    CustomEditor "EffectOpaqueGUI"
}

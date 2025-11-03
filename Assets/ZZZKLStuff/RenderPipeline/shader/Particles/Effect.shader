Shader "Jeremy/Effect/Effect"
{
    Properties
    {
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("SrcBlend", float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("DstBlend", float) = 1

        [Enum(UnityEngine.Rendering.CullMode)] _CullMode ("CullMode", float) = 2
        [Enum(Off, 0, On, 1)] _ZWriteMode ("ZWriteMode", float) = 0
        [Toggle] _CustomData1XY("CustomData1XY", float) = 0
        [Toggle] _CustomData1ZW("CustomData1ZW", float) = 0
        [Toggle] _CustomData2X("CustomData2XY", float) = 0
        _BlendType("blendType", float) = 0
        _ZTestMode("ZTestMode", float) = 4
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _Color("Color", Color) = (1,1,1,1)

        // [IntRange] _Stencil("Stencil ID", Range(0, 255)) = 0
        // [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", int) = 8
        // [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp("Stencil Operation", float) = 0
        // _StencilReadMask("Stencil Read Mask", Float) = 255
        // _StencilWriteMask("Stencil Write Mask", Float) = 255
        // _ColorMask("Color Mask", Float) = 15
       
        _MainTex_Uspeed("MainTex_Uspeed", float) = 0
        _MainTex_Vspeed("MainTex_Vspeed", float) = 0
        [Toggle] _MainTex_Alpha_R("MainTex_Alpha_R", float) = 0
        [Toggle] _BackColor_ON("开启背面颜色", float) = 0
        [HDR] _BackColor("背面颜色", Color) = (1,1,1,1)
        [Toggle(_ADDTEX_ON)] _AddTexOn("AddTexOn", float) = 0
        _AddTex("AddTex", 2D) = "white"{}
        [HDR] _AddTex_Color("Color", Color) = (1,1,1,1)
        _AddTex_Uspeed("AddTex_Uspeed", float) = 0
        _AddTex_Vspeed("AddTex_Vspeed", float) = 0
        // _AddLerpValue("AddLerpValue", Range(0,1)) = 0



        [Toggle(_MASKTEX_ON)] _MaskTexOn("MaskTexOn", float) = 1
        _MaskTex("MaskTex", 2D) = "white"{}
        [Toggle] _MaskTex_RA("MaskTex_RA", float) = 0
        _Mask_Uspeed("Mask_Uspeed", float) = 0
        _Mask_Vspeed("Mask_Vspeed", float) = 0

        
        [Toggle(_DISSOLVETEX_ON)] _DissolveTexOn("DissolveTexOn", float) = 1
		[KeywordEnum(OFF, SUB, POW, SMOOTH, EDGE_RADIAL, EDGE)] _DISSOLVE("_DISSOLVE", Int) = 0  
        _DissolveTex("DissolveTex", 2D) = "white"{}
        _DissolveValue("DissolveValue", Range(0,1.2)) = 0
        _Dissolve_Uspeed("Dissolve_Uspeed", float) = 0
        _Dissolve_Vspeed("Dissolve_Vspeed", float) = 0
        _Dissolve_Path("Dissolve_Path", Range(0, 1)) = 0
		_Dissolve_EdgeWidth("Dissolve_EdgeWidth", Range(0, 1)) = 0
		[HDR] _Dissolve_EdgeColor("Dissolve_EdgeColor", Color) = (1, 1, 1, 1)
		_Dissolve_Pow("Dissolve_Pow", Range(0, 1)) = 0
		_Dissolve_Smooth("Dissolve_Smooth", Range(0, 1)) = 0

        // [Toggle(_SOFT_PARTICLE_ON)] _SoftParticleOn("SOFT_PARTICLE_ON",float) = 0
        // _Soft_Particle("Soft_Particle",Range(0,1)) = 1
        [Toggle(_WSSOFTPARTICLES)] _WSSoftParticlesOn("World Space SP On", float) = 0
        _SPIntensity ("Soft Particles Intensity", Range(0, 1)) = 1
        [Toggle(_FRESNE_ON)] _FresnelOn("FRESNE_ON", float) = 0
        _FresnelBase("fresnelBase", Range(0, 1)) = 0
        _FresnelScale("fresnelScale", Range(0, 1)) = 1
        _FresnelIndensity("fresnelIndensity", Range(0, 10)) = 1
        [HDR] _FresnelCol("_fresnelCol", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0,1)) = 1 
        // _BloomFactor("BloomFactor", Range(0,1)) = 1

        // _NoiseTex("Noise Texture (RG)", 2D) = "white" {} //屏幕扭曲
        // _HeatTime("Heat Time", Range(0,1.5)) = 1
        // _HeatForce("Heat Force", Range(0,6)) = 0.1

        _MainTexAngle("MainTexAngle", float) = 0
        _AddTexAngle("AddTexAngle", float) = 0
        _MaskTexAngle("MaskTexAngle", float) = 0


        [Toggle(_NOISETEX_ON)] _Noise_On("_Noise_On", float) = 0
        _NoiseTexture("NoiseTexture", 2D) = "white" {}
        _NoiseTex_Uspeed("NoiseTex_Uspeed", float) = 0
        _NoiseTex_Vspeed("NoiseTex_Vspeed", float) = 0
        _Noise_Intensity("Noise_Intensity", Range(0,1)) = 0
        _Alpha_Intensity("Alpha_Intensity", float) = 1
        // [Toggle(_BILLBOARD_ON)] _BillboardOn("BillboardOn", float) = 0
        // _VerticalBillborading("VerticalBillborading", Range(0,1))=0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Transparent"}

        // Stencil
        // {
        //     Ref[_Stencil]
        //     Comp[_StencilComp]
        //     Pass[_StencilOp]
        //     ReadMask[_StencilReadMask]
        //     WriteMask[_StencilWriteMask]
        // }
        
        // ColorMask [_ColorMask]


        Pass
        {
            Tags{"LightMode" = "UniversalForward"}
            Blend [_SrcBlend] [_DstBlend]
            Cull [_CullMode]
            ZTest [_ZTestMode]
            ZWrite [_ZWriteMode]
            HLSLPROGRAM
            // #pragma enable_d3d11_debug_symbols
            // #pragma shader_feature _ _SOFT_PARTICLE_ON
            #pragma shader_feature_local _ _ADDTEX_ON
            #pragma shader_feature_local _ _MASKTEX_ON
            #pragma shader_feature_local _ _DISSOLVETEX_ON
			#pragma shader_feature_local _DISSOLVE_OFF _DISSOLVE_EDGE _DISSOLVE_EDGE_RADIAL _DISSOLVE_SUB _DISSOLVE_POW _DISSOLVE_SMOOTH
            #pragma shader_feature_local _ _FRESNE_ON
            #pragma shader_feature_local _ _NOISETEX_ON
            #pragma shader_feature_local _ _WSSOFTPARTICLES
            // #pragma shader_feature _ _BILLBOARD_ON
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
                // float4 projPos : TEXCOORD1;
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
                // uniform sampler2D _CameraDepthTexture;
                float4 _MainTex_ST;
                half4 _Color;
                float _BlendType;
                float _MainTex_Uspeed;
                float _MainTex_Vspeed;
                float _MainTex_Alpha_R;
                float4 _AddTex_ST;
                half4 _AddTex_Color;
                float _AddTex_Uspeed;
                float _AddTex_Vspeed;
                // float _AddLerpValue;
                float _MaskTex_RA;
                float _Mask_Uspeed;
                float4 _MaskTex_ST;
                float4 _DissolveTex_ST;
                float _Mask_Vspeed;
                float _DissolveValue;
                float _Dissolve_Uspeed;
                float _Dissolve_Vspeed;
                float _Dissolve_Path;
				float _Dissolve_EdgeWidth;
				half4 _Dissolve_EdgeColor;
				float _Dissolve_Pow;
				float _Dissolve_Smooth;

                // float _Soft_Particle;
                float _SPIntensity;
                float _FresnelBase;
                float _FresnelScale;
                float _FresnelIndensity;
                float _Alpha;
                half4 _FresnelCol;
                // float _BloomFactor;
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
                float _Alpha_Intensity;
                // float _VerticalBillborading;
            CBUFFER_END

            // float _UnscaledTime, _UseUnscaledTime;

            // float4 GetTime() {
            //     float4 utime = float4(_UnscaledTime / 20, _UnscaledTime, _UnscaledTime * 2, _UnscaledTime * 3);
            //     return lerp(_Time, utime, _UseUnscaledTime);
            // }


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

                // float3 positionOS = i.positionOS.xyz;
                //广告牌效果
                // #if defined(_BILLBOARD_ON) 
                //     //选择模型空间的原点作为广告牌的锚点
                //     float3 center = float3(0,0,0);
                //     //计算模型空间中的视线方向
                //     float3 objViewDir = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                //     //根据观察方向和锚点计算目标法线向量
                //     float3 normalDir = objViewDir - center;
                //     /*
                //     更具 _VerticalBillborading来控制垂直方向的约束
                //     当 _VerticalBillborading 为 1 时,法线方向固定，为视角方向
                //     当 _VerticalBillborading 为 0 时,向上方向固定，为(0,1,0)
                //     */
                //     normalDir.y *= _VerticalBillborading;
                //     normalDir = normalize(normalDir);

                //     float3 upDir = abs(normalDir.y)>0.999?float3(0, 0, 1):float3(0, 1, 0);
                //     float3 rightDir = normalize(cross(normalDir, upDir))*-1;
                //     upDir = normalize(cross(normalDir, rightDir));
 
                //     //用旋转矩阵对顶点进行偏移
                //     float3 centerOffs = i.vertex.xyz - center;
                //     positionOS =center +  rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
 
                // #endif
                // o.positionCS = TransformObjectToHClip(positionOS);


                o.basePlusRotatedUV1.xy = i.uv;
                o.basePlusRotatedUV1.zw = RotateUV(i.uv, _MainTexAngle);
                o.rotatedUV2.xy = RotateUV(i.uv, _AddTexAngle);
                o.rotatedUV2.zw = RotateUV(i.uv, _MaskTexAngle);

                //o.projPos = ComputeScreenPos (o.vertex);
                // COMPUTE_EYEDEPTH(o.projPos.z);
                //o.projPos.z = - TransformWorldToView(positionWS).z;
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
                // float4 debugColor = 1.0;
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
                col.rgb = _BlendType < 1 ? col.rgb * col.a : col.rgb;
                col.a = _MainTex_Alpha_R ? col.r : col.a;
                col.rgb *= _Color.rgb * i.vertexColor.rgb;

                #ifdef _ADDTEX_ON
                    _AddTex_Uspeed =  _CustomData1XY ? i.customData1.x : _AddTex_Uspeed * _Time.y;
                    _AddTex_Vspeed =  _CustomData1XY ? i.customData1.y : _AddTex_Vspeed * _Time.y;
                    float4 addMap = tex2D(_AddTex, TRANSFORM_TEX(i.rotatedUV2.xy, _AddTex) + float2(_AddTex_Uspeed, _AddTex_Vspeed) + noise);
                    addMap.rgb = _BlendType < 1 ? addMap.rgb * addMap.a : addMap.rgb;
                    addMap *= _AddTex_Color;
                    // col = lerp(col,addMap,_AddLerpValue);
                    col *= addMap;
                    // float stemp = step(0.01,col.r);
                    // col.rgb = col.rgb*col.a+addMap.rgb*(1-col.a);
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


                float dissolveTex = 0;
				#if defined(_DISSOLVETEX_ON) || defined(_DISSOLVE_EDGE) || defined(_DISSOLVE_EDGE_RADIAL) || defined(_DISSOLVE_SUB) || defined(_DISSOLVE_POW) || defined(_DISSOLVE_SMOOTH)
                    _DissolveValue = _CustomData2X ? i.customData2.x : _DissolveValue;
                    _Dissolve_Uspeed =  _Dissolve_Uspeed * _Time.y;
                    _Dissolve_Vspeed =  _Dissolve_Vspeed * _Time.y;
                    dissolveTex = tex2D(_DissolveTex, TRANSFORM_TEX(i.basePlusRotatedUV1.xy, _DissolveTex) + float2(_Dissolve_Uspeed, _Dissolve_Vspeed)).r;
                #endif

                #ifdef _DISSOLVETEX_ON
                    clip(dissolveTex - _DissolveValue);
                #endif

				float dissolve = 1.0;
                half4 edgeColor = half4(0.0, 0.0, 0.0, 0.0);
                #ifdef _DISSOLVE_EDGE
			    {
			    	float ramp = dissolveTex;
			    	float factor = _DissolveValue + _DissolveValue; 
			    	edgeColor.xyz = _Dissolve_EdgeColor.xyz;
			    	float alpha = step(factor, ramp);
			    	float edge = 1.0 - step(factor + _Dissolve_EdgeWidth * _DissolveValue, ramp);
			    	dissolve = alpha;
			    	edgeColor.w = edge * _Dissolve_EdgeColor.w;
			    }
				#endif
			
				#ifdef _DISSOLVE_EDGE_RADIAL
			    {
			    	float distanceRamp = 1.0 -  distance(i.basePlusRotatedUV1.xy, float2(0.5, 0.5)) * 1.4142; // remap to [0, 1]
			    	float ramp = distanceRamp + _Dissolve_Path * dissolveTex;
			    	float factor = _DissolveValue + _DissolveValue * _Dissolve_Path; 
			    	edgeColor.xyz = _Dissolve_EdgeColor.xyz;
			    	float alpha = step(factor, ramp);
			    	float edge = 1.0 - step(factor + _Dissolve_EdgeWidth * _DissolveValue, ramp);
			    	dissolve = alpha;
			    	edgeColor.w = edge * _Dissolve_EdgeColor.w;
			    }
				#endif
			
				#ifdef _DISSOLVE_SUB
			    {
			    	dissolve = pow(1.0 - saturate((dissolveTex + 1.0) * _DissolveValue), _Dissolve_Pow);
			    }
				#endif
				
				#ifdef _DISSOLVE_POW
				{
					dissolve = pow(saturate(dissolveTex - _DissolveValue * 2.0 + 1.0), _Dissolve_Pow);
				}
				#endif
			
				#ifdef _DISSOLVE_SMOOTH
				{
					dissolve = saturate(lerp(0.5, dissolveTex, _Dissolve_Smooth) - _DissolveValue * 2.0 + 1.0);
				}
				#endif



                // #ifdef _TEST
                //  col.rgb = float3(1,0,0);
                // #endif

                //软粒子
                // #ifdef _SOFT_PARTICLE_ON
                //     float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                //     float partZ = max(0,i.projPos.z - _ProjectionParams.g);
                //     col *=saturate((sceneZ-partZ)/_Soft_Particle);
                // #endif
                #ifdef _WSSOFTPARTICLES
                    col.a *= saturate(i.positionWS.y * _SPIntensity);
                #endif


                #ifdef _FRESNE_ON
                    float fresnel = pow(1 - saturate(NDotV), _FresnelIndensity) * _FresnelScale + _FresnelBase;
                    col = lerp(col, _FresnelCol, fresnel * _FresnelCol.a * isFrontFace);
                #endif
                _Alpha *= i.vertexColor.a * _Alpha_Intensity;
               
                half4 _a = _BlendType ? half4(1, 1, 1, _Alpha) : half4(_Alpha, _Alpha, _Alpha, 1);
                col *= _a;
                col.rgb = lerp(col.rgb, edgeColor.rgb, edgeColor.a);
                col.a *= dissolve;
                col.a = saturate(col.a);
                return col; //
            }
            ENDHLSL
        }
    }
    CustomEditor "ShaderEffectEditor"
}

Shader "JRMAdvanced/EffectUber"
{
    Properties
    {
        _MainTex("_MainTex(Custom1.yz)", 2D) = "white" {}

		_NoiseTex1("_NoiseTex1", 2D) = "white" {}
		_NoiseTex2("_NoiseTex2", 2D) = "white" {}
		_ScreenDistortTex("_ScreenDistortTex", 2D) = "bump" {}
		_MaskTex1("_MaskTex1", 2D) = "white" {}
		_MaskTex2("_MaskTex2", 2D) = "white" {}
		_VertexTex("_VertexTex", 2D) = "white" {}
		_VertexMaskTex("_VertexMaskTex", 2D) = "white" {}
		[HDR] _MainColor("_MainColor", Color) = (1, 1, 1, 1)
		[HDR] _OutSideColor("_OutSideColor", Color) = (1, 1, 1, 1)

		_StrengthX("_StrengthX", Range(0, 1)) = 0
		_StrengthY("_StrengthY", Range(0, 1)) = 0
		_Path("_Path", Range(0, 1)) = 0
		_Dissolve("_Dissolve(Custom1.x)", Range(0, 1)) = 0
		_EdgeWidth("_EdgeWidth", Range(0, 1)) = 0
		[HDR] _EdgeColor("_EdgeColor", Color) = (1, 1, 1, 1)
		_Pow("_Pow", Range(0, 1)) = 0
		_Smooth("_Smooth", Range(0, 1)) = 0

		_FloorSmooth("_FloorSmooth", Range(0, 1)) = 0
		_DepthSmoothDistance("Depth Smooth Distance", Range(0.0, 10.0)) = 0
		_DepthSmoothRange("Depth Smooth Range", Range(0.01, 10.0)) = 1

		_VertexScale("_VertexScale", Vector) = (0, 0, 0, 1)
		
		_ScreenDistortionIntensity("Screen Distortion Intensity", Range(0.0, 1.0)) = 0.1
		_ScreenDistortionBlend("Screen Distortion Blend", Range(0.0, 1.0)) = 1

		_MainTexSpeedX("_MainTexSpeedX", Float) = 0
		_MainTexSpeedY("_MainTexSpeedY", Float) = 0

		_NoiseTex1SpeedX("_NoiseTex1SpeedX", Float) = 0
		_NoiseTex1SpeedY("_NoiseTex1SpeedY", Float) = 0
		_NoiseTex2SpeedX("_NoiseTex2SpeedX", Float) = 0
		_NoiseTex2SpeedY("_NoiseTex2SpeedY", Float) = 0
		
		_MaskTex1SpeedX("_MaskTex1SpeedX", Float) = 0
		_MaskTex1SpeedY("_MaskTex1SpeedY", Float) = 0
		_MaskTex2SpeedX("_MaskTex2SpeedX", Float) = 0
		_MaskTex2SpeedY("_MaskTex2SpeedY", Float) = 0

		_VertexTexSpeedX("_VertexTexSpeedX", Float) = 0
		_VertexTexSpeedY("_VertexTexSpeedY", Float) = 0
		_VertexMaskTexSpeedX("_VertexMaskTexSpeedX", Float) = 0
		_VertexMaskTexSpeedY("_VertexMaskTexSpeedY", Float) = 0

		_NearFadeDistance("_NearFadeDistance", Range(0.0, 10.0)) = 1
		_NearFadeRange("_NearFadeRange", Range(0.01, 10.0)) = 1



		[Toggle(_CUSTOM_DATA)] _CUSTOM_DATA("_CUSTOM_DATA", Float) = 0

		[Toggle(_DISTORTION_MAINTEX)] _DISTORTION_MAINTEX("_DISTORTION_MAINTEX", Float) = 0
		[Toggle(_DISTORTION_SCREEN)] _DISTORTION_SCREEN("_DISTORTION_SCREEN", Float) = 0

		[KeywordEnum(OFF, SINGLE, DOUBLE)] _MASK("_MASK", Int) = 0  
		[KeywordEnum(OFF, SUB, POW, SMOOTH, EDGE_RADIAL, EDGE)] _DISSOLVE("_DISSOLVE", Int) = 0  
		[Toggle(_VERTEX_OFFSET)] _VERTEX_OFFSET("_VERTEX_OFFSET", Float) = 0
		[Toggle(_FLOOR_SMOOTH)] _FLOOR_SMOOTH("_FLOOR_SMOOTH", Float) = 0
		[Toggle(_DEPTH_SMOOTH)] _DEPTH_SMOOTH("_DEPTH_SMOOTH", Float) = 0
		[Toggle(_OUTSIDE_COLOR)] _OUTSIDE_COLOR("_OUTSIDE_COLOR", Float) = 0
		[Toggle(_NEAR_FADE)] _NEAR_FADE("_NEAR_FADE", Float) = 0

		
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 10
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
    }
    SubShader
    {
		Tags { "Queue"="Transparent" }
		Pass 
		{
			Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
			ZTest [_ZTest]
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature_local _DISSOLVE_OFF _DISSOLVE_EDGE _DISSOLVE_EDGE_RADIAL _DISSOLVE_SUB _DISSOLVE_POW _DISSOLVE_SMOOTH
			#pragma shader_feature_local _MASK_OFF _MASK_SINGLE _MASK_DOUBLE
			#pragma shader_feature_local _DISTORTION_MAINTEX
			#pragma shader_feature_local _DISTORTION_SCREEN
			#pragma shader_feature_local _FLOOR_SMOOTH
			#pragma shader_feature_local _DEPTH_SMOOTH
			#pragma shader_feature_local _VERTEX_OFFSET
			#pragma shader_feature_local _OUTSIDE_COLOR
			#pragma shader_feature_local _NEAR_FADE

			#pragma enable_d3d11_debug_symbols
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			#define texture(Tex, UV) SAMPLE_TEXTURE2D(Tex, sampler##Tex, UV)
			#define textureLod(Tex, UV, Lod) SAMPLE_TEXTURE2D_LOD(Tex, sampler##Tex, UV, Lod)
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_NoiseTex1);
			SAMPLER(sampler_NoiseTex1);
			TEXTURE2D(_NoiseTex2);
			SAMPLER(sampler_NoiseTex2);
			TEXTURE2D(_ScreenDistortTex);
			SAMPLER(sampler_ScreenDistortTex);
			TEXTURE2D(_MaskTex1);
			SAMPLER(sampler_MaskTex1);
			TEXTURE2D(_MaskTex2);
			SAMPLER(sampler_MaskTex2);
			TEXTURE2D(_VertexTex);
			SAMPLER(sampler_VertexTex);
			TEXTURE2D(_VertexMaskTex);
			SAMPLER(sampler_VertexMaskTex);

			TEXTURE2D(_CameraDepthTexture);
			SAMPLER(sampler_point_clamp);
			TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_linear_clamp);

			CBUFFER_START(UnityPerMaterial)
				float _CUSTOM_DATA;

				half4 _MainColor;
				half4 _OutSideColor;
				float _StrengthX;
				float _StrengthY;
				float _Path;
				float _EdgeWidth;
				half4 _EdgeColor;
				float _Pow;
				float _Smooth;
				float _Dissolve;

				float _FloorSmooth;
				float _DepthSmoothDistance;
				float _DepthSmoothRange;

				float4 _VertexScale;
			
				float _ScreenDistortionIntensity;
				float _ScreenDistortionBlend;

				float _MainTexSpeedX;
				float _MainTexSpeedY;
			
				float _NoiseTex1SpeedX;
				float _NoiseTex1SpeedY;
				float _NoiseTex2SpeedX;
				float _NoiseTex2SpeedY;
			
				float _MaskTex1SpeedX;
				float _MaskTex1SpeedY;
				float _MaskTex2SpeedX;
				float _MaskTex2SpeedY;
			
				float _VertexTexSpeedX;
				float _VertexTexSpeedY;
				float _VertexMaskTexSpeedX;
				float _VertexMaskTexSpeedY;

				float _NearFadeDistance;
				float _NearFadeRange;
			
				float4 _MainTex_ST;
				float4 _NoiseTex1_ST;
				float4 _NoiseTex2_ST;
				float4 _MaskTex1_ST;
				float4 _MaskTex2_ST;
				float4 _VertexTex_ST;
				float4 _VertexMaskTex_ST;
			CBUFFER_END

			struct Attributes 
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 color : COLOR;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
			};

			struct Varyings 
			{
				float4 color : VAR_COLOR;
				float4 texcoord0 : VAR_TEXCOORD0;
				float4 texcoord1 : VAR_TEXCOORD1;
				float3 positionWS : VAR_POSITIONWS;
				float4 positionSS : VAR_POSITIONSS;
				float4 positionCS : SV_POSITION;
			};

			/* Utility Functions */
			bool IsOrthographicCamera()
			{
				return unity_OrthoParams.w;
			}

			float OrthographicDepthBufferToLinear(float rawDepth)
			{
				#if UNITY_REVERSED_Z
					rawDepth = 1.0 - rawDepth;
				#endif
				return (_ProjectionParams.z - _ProjectionParams.y) * rawDepth + _ProjectionParams.y;
			}

			float2 GetScreenUV(float2 positionCSXY)
			{
				return positionCSXY / _ScaledScreenParams.xy;
			}

			float GetViewDepth(float2 positionCSZW)
			{
				return IsOrthographicCamera() ? OrthographicDepthBufferToLinear(positionCSZW.x) : positionCSZW.y;
			}

			float GetEyeDepth(float2 positionCSXY)
			{
				float2 screenUV = GetScreenUV(positionCSXY);
				float depth = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_point_clamp, screenUV, 0).r;
				depth = IsOrthographicCamera() ? OrthographicDepthBufferToLinear(depth) : LinearEyeDepth(depth, _ZBufferParams);
				return depth;
			}

			half4 GetScreenColor(float2 positionCSXY, float2 uvOffset = float2(0.0, 0.0))
			{
				float2 uv = GetScreenUV(positionCSXY) + uvOffset;
				return SAMPLE_TEXTURE2D_LOD(_CameraOpaqueTexture, sampler_linear_clamp, uv, 0);
			}





			Varyings vert (Attributes i)
			{
			    Varyings o = (Varyings)0;
				float3 vertexOffset = float3(0.0, 0.0, 0.0);
				#ifdef _VERTEX_OFFSET
				{
					float3 vertexTex = textureLod(_VertexTex, i.texcoord0.xy * _VertexTex_ST.xy + _VertexTex_ST.zw + 
						float2(_VertexTexSpeedX, _VertexTexSpeedY) * _Time.y, 0).xyz;
					float3 vertexMaskTex = textureLod(_VertexMaskTex, i.texcoord0.xy * _VertexMaskTex_ST.xy + _VertexMaskTex_ST.zw + 
						float2(_VertexMaskTexSpeedX, _VertexMaskTexSpeedY) * _Time.y, 0).xyz;
					vertexOffset = i.normalOS.xyz * vertexMaskTex * vertexTex * _VertexScale.xyz;
				}
				#endif
				o.positionWS = TransformObjectToWorld(i.positionOS.xyz + vertexOffset);
			    o.positionCS = TransformWorldToHClip(o.positionWS);
				o.positionSS = ComputeScreenPos(o.positionCS);
				o.texcoord0 = i.texcoord0;
				o.texcoord1 = i.texcoord1;
				o.color = i.color;
			    return o;
			}
			float4 frag (Varyings i) : SV_TARGET 
			{
				float dissolveByParticle = _Dissolve;
				float2 uvOffsetByParticle = float2(0.0, 0.0);
				if (_CUSTOM_DATA)
				{
					dissolveByParticle += i.texcoord0.z;
					uvOffsetByParticle = float2(i.texcoord0.w, i.texcoord1.x);
				}
			
				float2 distortion = float2(0.0, 0.0);
				half4 edgeColor = half4(0.0, 0.0, 0.0, 0.0);
				float dissolve = 1.0;
				float mask = 1.0;
				float floorSmooth = 1.0;
				float attenuation = 1.0;

			
				#if defined(_DISTORTION_MAINTEX) || defined(_DISSOLVE_EDGE) || defined(_DISSOLVE_EDGE_RADIAL) || defined(_DISSOLVE_SUB) || defined(_DISSOLVE_POW) || defined(_DISSOLVE_SMOOTH)
					float noise1 = texture(_NoiseTex1, i.texcoord0.xy * _NoiseTex1_ST.xy + _NoiseTex1_ST.zw + 
						float2(_NoiseTex1SpeedX, _NoiseTex1SpeedY) * _Time.y).r;
				#endif
				
				#if defined(_DISTORTION_MAINTEX)
					float noise2 = texture(_NoiseTex2, i.texcoord0.xy * _NoiseTex2_ST.xy + _NoiseTex2_ST.zw + 
						float2(_NoiseTex2SpeedX, _NoiseTex2SpeedY) * _Time.y).r;
				#endif
			
				#ifdef _DISTORTION_MAINTEX
			    {
					float distortionNoise = noise1 + noise2 - 1.0;
			    	distortion = float2(_StrengthX, _StrengthY) * distortionNoise;
			    }
				#endif
			
					
				


				#ifdef _DISSOLVE_EDGE
			    {
			    	float ramp = noise1;
			    	float factor = dissolveByParticle + dissolveByParticle; 
			    	edgeColor.xyz = _EdgeColor.xyz;
			    	float alpha = step(factor, ramp);
			    	float edge = 1.0 - step(factor + _EdgeWidth * _Dissolve, ramp);
			    	dissolve = alpha;
			    	edgeColor.a = edge * _EdgeColor.a;
			    }
				#endif
			
				#ifdef _DISSOLVE_EDGE_RADIAL
			    {
			    	float distanceRamp = 1.0 -  distance(i.texcoord0.xy, float2(0.5, 0.5)) * 1.4142; // remap to [0, 1]
			    	float ramp = distanceRamp + _Path * noise1;
			    	float factor = dissolveByParticle + dissolveByParticle * _Path; 
			    	edgeColor.xyz = _EdgeColor.xyz;
			    	float alpha = step(factor, ramp);
			    	float edge = 1.0 - step(factor + _EdgeWidth * _Dissolve, ramp);
			    	dissolve = alpha;
			    	edgeColor.a = edge * _EdgeColor.a;
			    }
				#endif
			
				#ifdef _DISSOLVE_SUB
			    {
			    	dissolve = pow(1.0 - saturate((noise1 + 1.0) * dissolveByParticle), _Pow);
			    }
				#endif
				
				#ifdef _DISSOLVE_POW
				{
					dissolve = pow(saturate(noise1 - dissolveByParticle * 2.0 + 1.0), _Pow);
				}
				#endif
			
				#ifdef _DISSOLVE_SMOOTH
				{
					dissolve = saturate(lerp(0.5, noise1, _Smooth) - dissolveByParticle * 2.0 + 1.0);
				}
				#endif
			
				#ifdef _MASK_SINGLE
				{
					mask = texture(_MaskTex1, i.texcoord0.xy * _MaskTex1_ST.xy + _MaskTex1_ST.zw + 
						float2(_MaskTex1SpeedX, _MaskTex1SpeedY) * _Time.y).r;
				}
			    #endif
			
			    #ifdef _MASK_DOUBLE
				{
					mask = texture(_MaskTex1, i.texcoord0.xy * _MaskTex1_ST.xy + _MaskTex1_ST.zw + 
						float2(_MaskTex1SpeedX, _MaskTex1SpeedY) * _Time.y).r;
					mask *= texture(_MaskTex2, i.texcoord0.xy * _MaskTex2_ST.xy + _MaskTex2_ST.zw + 
						float2(_MaskTex2SpeedX, _MaskTex2SpeedY) * _Time.y).r;
				}
				#endif
				
				#ifdef _FLOOR_SMOOTH
				{
					floorSmooth = smoothstep(0.0, _FloorSmooth, i.positionWS.y);
				}
				#endif

				#ifdef _DEPTH_SMOOTH
				{
					float depthSub = GetEyeDepth(i.positionCS.xy) - GetViewDepth(i.positionCS.zw);
					attenuation *= (depthSub - _DepthSmoothDistance) / _DepthSmoothRange;
					attenuation = saturate(attenuation);
				}
				#endif
			
				float4 mainTex = texture(_MainTex, i.texcoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw + 
					float2(_MainTexSpeedX, _MainTexSpeedY) * _Time.y + distortion + uvOffsetByParticle);
				
				#ifdef _OUTSIDE_COLOR
			    {
			    	float luminance = dot(mainTex.xyz, float3(0.2126729, 0.7151522, 0.072175004));
			    	mainTex = lerp(_OutSideColor, _MainColor, luminance * mainTex.a) * mainTex.a;
			    }
				#else
				{
					mainTex *= _MainColor;
				}
				#endif
				
				#ifdef _NEAR_FADE
				{
					float viewDepth = GetViewDepth(i.positionCS.zw);
					attenuation *= (viewDepth - _NearFadeDistance) / _NearFadeRange;
					attenuation = saturate(attenuation);
				}
				#endif

				float4 finalColor = mainTex;
				finalColor *= i.color;
				finalColor *= mask;
				finalColor.xyz = lerp(finalColor.xyz, edgeColor.xyz, edgeColor.a);
				finalColor.a *= dissolve;
				finalColor.a *= floorSmooth;
				finalColor.a *= attenuation;
				finalColor.a = saturate(finalColor.a);
			
				#ifdef _DISTORTION_SCREEN
			    {
					float4 distortNormal = SAMPLE_TEXTURE2D(_ScreenDistortTex, sampler_ScreenDistortTex, i.texcoord0.xy);
					float2 screenDistortion =  finalColor.a * UnpackNormalScale(distortNormal, _ScreenDistortionIntensity).xy;
					finalColor.rgb = lerp(GetScreenColor(i.positionCS.xy, screenDistortion).rgb, finalColor.rgb, 
						saturate(finalColor.a - _ScreenDistortionBlend));
			    }
				#endif

				return finalColor;
			}
			ENDHLSL
		}
    }
	CustomEditor "JRMVFX.JRMEffectGUI"
}

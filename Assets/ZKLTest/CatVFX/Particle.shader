Shader "CatVFX/Particle" {
	
	Properties 
	{
		_MainTex("_MainTex(Custom1.yz)", 2D) = "white" {}

		_NoiseTex1("_NoiseTex1", 2D) = "white" {}
		_NoiseTex2("_NoiseTex2", 2D) = "white" {}
		_MaskTex1("_MaskTex1", 2D) = "white" {}
		_MaskTex2("_MaskTex2", 2D) = "white" {}
		_DepthOffsetTex("_DepthOffsetTex", 2D) = "white" {}
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
		_VertexScale("_VertexScale", Vector) = (0, 0, 0, 1)
		
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

		[Toggle(_CUSTOM_DATA)] _CUSTOM_DATA("_CUSTOM_DATA", Float) = 0

		[Toggle(_DISTORTION)] _DISTORTION("_DISTORTION", Float) = 0
		[KeywordEnum(OFF, SINGLE, DOUBLE)] _MASK("_MASK", Int) = 0  
		[KeywordEnum(OFF, SUB, POW, SMOOTH, EDGE_RADIAL, EDGE)] _DISSOLVE("_DISSOLVE", Int) = 0  
		[Toggle(_VERTEX_OFFSET)] _VERTEX_OFFSET("_VERTEX_OFFSET", Float) = 0
		[Toggle(_FLOOR_SMOOTH)] _FLOOR_SMOOTH("_FLOOR_SMOOTH", Float) = 0
		[Toggle(_OUTSIDE_COLOR)] _OUTSIDE_COLOR("_OUTSIDE_COLOR", Float) = 0
		
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
			#pragma vertex VS
			#pragma fragment FS
			#pragma shader_feature_local _DISSOLVE_OFF _DISSOLVE_EDGE _DISSOLVE_EDGE_RADIAL _DISSOLVE_SUB _DISSOLVE_POW _DISSOLVE_SMOOTH
			#pragma shader_feature_local _MASK_OFF _MASK_SINGLE _MASK_DOUBLE
			#pragma shader_feature_local _DISTORTION
			#pragma shader_feature_local _FLOOR_SMOOTH
			#pragma shader_feature_local _VERTEX_OFFSET
			#pragma shader_feature_local _OUTSIDE_COLOR

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			#define vec2 float2
			#define vec3 float3
			#define vec4 float4
			#define texture(Tex, UV) SAMPLE_TEXTURE2D(Tex, sampler##Tex, UV)
			#define textureLod(Tex, UV, Lod) SAMPLE_TEXTURE2D_LOD(Tex, sampler##Tex, UV, Lod)
			#define mix(a, b, t) lerp(a, b, t)
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);
			TEXTURE2D(_NoiseTex1);
			SAMPLER(sampler_NoiseTex1);
			TEXTURE2D(_NoiseTex2);
			SAMPLER(sampler_NoiseTex2);
			TEXTURE2D(_MaskTex1);
			SAMPLER(sampler_MaskTex1);
			TEXTURE2D(_MaskTex2);
			SAMPLER(sampler_MaskTex2);
			TEXTURE2D(_VertexTex);
			SAMPLER(sampler_VertexTex);
			TEXTURE2D(_VertexMaskTex);
			SAMPLER(sampler_VertexMaskTex);

			CBUFFER_START(UnityPerMaterial)
				float _CUSTOM_DATA;

				float4 _MainColor;
				float4 _OutSideColor;
				float _StrengthX;
				float _StrengthY;
				float _Path;
				float _EdgeWidth;
				float4 _EdgeColor;
				float _Pow;
				float _Smooth;
				float _Dissolve;
				float _FloorSmooth;
				float4 _VertexScale;
			
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
			
				float4 _MainTex_ST;
				float4 _NoiseTex1_ST;
				float4 _NoiseTex2_ST;
				float4 _MaskTex1_ST;
				float4 _MaskTex2_ST;
				float4 _VertexTex_ST;
				float4 _VertexMaskTex_ST;
			CBUFFER_END

			struct App {
				float4 pos : POSITION;
				float3 normal : NORMAL;
				float4 color : COLOR;
				float4 texcoord0 : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
			};
			struct V2F {
				float4 color : VAR_COLOR;
				float4 texcoord0 : VAR_TEXCOORD0;
				float4 texcoord1 : VAR_TEXCOORD1;
				float3 worldPos : VAR_WORLDPOS;
				float4 screenPos : VAR_SCREENPOS;
				float4 clipPos : SV_POSITION;
			};
			V2F VS (App i)
			{
				vec3 vertexOffset = vec3(0.f, 0.f, 0.f);
				#ifdef _VERTEX_OFFSET
				{
					const vec3 vertexTex = textureLod(_VertexTex, i.texcoord0.xy * _VertexTex_ST.xy + _VertexTex_ST.zw + vec2(_VertexTexSpeedX, _VertexTexSpeedY) * _Time.y, 0).xyz;
					const vec3 vertexMaskTex = textureLod(_VertexMaskTex, i.texcoord0.xy * _VertexMaskTex_ST.xy + _VertexMaskTex_ST.zw + vec2(_VertexMaskTexSpeedX, _VertexMaskTexSpeedY) * _Time.y, 0).xyz;
					vertexOffset = i.normal.xyz * vertexMaskTex * vertexTex * _VertexScale.xyz;
				}
				#endif
			    V2F o;
			    const float3 worldPos = TransformObjectToWorld(i.pos.xyz + vertexOffset);
				o.worldPos = worldPos;
			    const float4 clipPos = TransformWorldToHClip(worldPos);
			    o.clipPos = clipPos;
				o.screenPos = ComputeScreenPos(clipPos);
				o.texcoord0 = i.texcoord0;
				o.texcoord1 = i.texcoord1;
				o.color = i.color;
			    return o;
			}
			float4 FS (V2F i) : SV_TARGET 
			{
			
				float dissolveByParticle = _Dissolve;
				vec2 uvOffsetByParticle = vec2(0.f, 0.f);
				if (_CUSTOM_DATA) // _CUSTOM_DATA isn't worth the variants, just if else
				{
					dissolveByParticle += i.texcoord0.z;
					uvOffsetByParticle = vec2(i.texcoord0.w, i.texcoord1.x);
				}
			
				vec2 distortion = vec2(0.f, 0.f);
				vec4 edgeColor = vec4(0.f, 0.f, 0.f, 0.f);
				float dissolve = 1.f;
				float mask = 1.f;
				float floorSmooth = 1.f;
			
				#if defined(_DISTORTION) || defined(_DISSOLVE_EDGE) || defined(_DISSOLVE_EDGE_RADIAL) || defined(_DISSOLVE_SUB) || defined(_DISSOLVE_POW) || defined(_DISSOLVE_SMOOTH)
					vec4 noiseTex1 = texture(_NoiseTex1, i.texcoord0.xy * _NoiseTex1_ST.xy + _NoiseTex1_ST.zw + vec2(_NoiseTex1SpeedX, _NoiseTex1SpeedY) * _Time.y);
					float noise1 = noiseTex1.x * noiseTex1.w;
				#endif
				
				#if defined(_DISTORTION)
					vec4 noiseTex2 = texture(_NoiseTex2, i.texcoord0.xy * _NoiseTex2_ST.xy + _NoiseTex2_ST.zw + vec2(_NoiseTex2SpeedX, _NoiseTex2SpeedY) * _Time.y);
					float noise2 = noiseTex2.x * noiseTex2.w;
				#endif
			
				#ifdef _DISTORTION
			    {
					float distortionNoise = noise1 + noise2 - 1.f;
			    	distortion = vec2(distortionNoise * _StrengthX, distortionNoise * _StrengthY) * 0.5f;;
			    }
				#endif
			
				#ifdef _DISSOLVE_EDGE
			    {
			    	const float ramp = noise1;
			    	const float fractor = dissolveByParticle + dissolveByParticle; 
			    	edgeColor.xyz = _EdgeColor.xyz;
			    	const float alpha = step(fractor, ramp);
			    	const float edge = 1.f - step(fractor + _EdgeWidth * _Dissolve, ramp);
			    	dissolve = alpha * (dissolveByParticle != 1.f);
			    	edgeColor.w = edge * _EdgeColor.w * (dissolveByParticle != 0.f);
			    }
				#endif
			
				#ifdef _DISSOLVE_EDGE_RADIAL
			    {
			    	float distanceRamp = 1.f -  distance(i.texcoord0.xy, .5f) * 1.4142; // 1.4142 = (1.f / length(vec2(.5f))) 
			    	const float ramp = distanceRamp + _Path * noise1;
			    	const float fractor = dissolveByParticle + dissolveByParticle * _Path; 
			    	edgeColor.xyz = _EdgeColor.xyz;
			    	const float alpha = step(fractor, ramp);
			    	const float edge = 1.f - step(fractor + _EdgeWidth * _Dissolve, ramp);
			    	dissolve = alpha * (dissolveByParticle != 1.f);
			    	edgeColor.w = edge * _EdgeColor.w * (dissolveByParticle != 0.f);
			    }
				#endif
			
				#ifdef _DISSOLVE_SUB
			    {
			    	dissolve = pow(1.f - clamp((noise1 + 1.f) * dissolveByParticle, 0.f, 1.f), _Pow);
			    }
				#endif
				
				#ifdef _DISSOLVE_POW
				{
					const float powDissolveNoise = noise1;
					dissolve = pow(clamp(noise1 - dissolveByParticle * 2.f + 1.f, 0.f, 1.f), _Pow);
				}
				#endif
			
				#ifdef _DISSOLVE_SMOOTH
				{
					dissolve = clamp(mix(.5f, noise1, _Smooth) - dissolveByParticle * 2.f + 1.f, 0.f, 1.f);
				}
				#endif
			
				#ifdef _MASK_SINGLE
				{
					vec4 maskTex1 = texture(_MaskTex1, i.texcoord0.xy * _MaskTex1_ST.xy + _MaskTex1_ST.zw + vec2(_MaskTex1SpeedX, _MaskTex1SpeedY) * _Time.y);
					mask = maskTex1.x * maskTex1.w;
				}
			    #endif
			
			    #ifdef _MASK_DOUBLE
				{
					vec4 maskTex1 = texture(_MaskTex1, i.texcoord0.xy * _MaskTex1_ST.xy + _MaskTex1_ST.zw + vec2(_MaskTex1SpeedX, _MaskTex1SpeedY) * _Time.y);
					vec4 maskTex2 = texture(_MaskTex2, i.texcoord0.xy * _MaskTex2_ST.xy + _MaskTex2_ST.zw + vec2(_MaskTex2SpeedX, _MaskTex2SpeedY) * _Time.y);
					mask = maskTex1.x * maskTex1.w * maskTex2.x * maskTex2.w;
				}
				#endif
				
				#ifdef _FLOOR_SMOOTH
				{
					floorSmooth = smoothstep(0.f, _FloorSmooth, i.worldPos.y);
				}
				#endif
			
				vec4 mainTex = texture(_MainTex, i.texcoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw + vec2(_MainTexSpeedX, _MainTexSpeedY) * _Time.y + distortion + uvOffsetByParticle);
				
				#ifdef _OUTSIDE_COLOR
			    {
			    	const float luminance = dot(mainTex.xyz, vec3(0.2126729, 0.7151522, 0.072175004));
			    	mainTex = mix(_OutSideColor, _MainColor, luminance * mainTex.w) * mainTex.w;
			    }
				#else
				{
					mainTex *= _MainColor;
				}
				#endif
				
				vec4 fragColor = mainTex;
				fragColor *= i.color;
				fragColor *= mask;
				fragColor.xyz = mix(fragColor.xyz, edgeColor.xyz, edgeColor.w);
				fragColor.w *= dissolve;
				fragColor.w *= floorSmooth;
				fragColor.w = clamp(fragColor.w, 0.f, 1.f);
			
				return fragColor;
			}
			ENDHLSL
		}
	}
	CustomEditor "CatVFX.ParticleGUI"
}
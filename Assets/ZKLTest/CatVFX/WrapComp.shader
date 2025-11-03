Shader "Comp/Wrap" {
	
	Properties 
	{
		[Header(__________Base__________)]
		_MainTex("_MainTex", 2D) = "white" {}
		_Intensity("_Intensity", Range(0, 1)) = 0.3

		
		[Header(__________PassSetting__________)]
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 10
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 4
	}
	
	SubShader 
	{
		Tags { "Queue"="Transparent"  }
		Pass 
		{
			Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
			ZTest [_ZTest]
			HLSLPROGRAM
			#pragma vertex VS
			#pragma fragment FS
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			#define vec2 float2
			#define vec3 float3
			#define vec4 float4
			#define texture(Tex, UV) SAMPLE_TEXTURE2D(Tex, sampler##Tex, UV)
			#define textureLod(Tex, UV, Lod) SAMPLE_TEXTURE2D_LOD(Tex, sampler##Tex, UV, Lod)
			#define mix(a, b, t) lerp(a, b, t)
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			TEXTURE2D(_CameraOpaqueTexture);
			SAMPLER(sampler_CameraOpaqueTexture);
			
			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
				float _Intensity;
			CBUFFER_END

			struct App {
				float4 pos : POSITION;
				float4 texcoord0 : TEXCOORD0;
				float4 color : COLOR;
			};
			struct V2F {
				float4 texcoord0 : VAR_TEXCOORD0;
				float4 clipPos : SV_POSITION;
				float4 screenPos : VAR_SCREEN_POS;
				float4 color: VAR_COLOR;
			};
			V2F VS (App i)
			{
			    V2F o;
			    o.clipPos = TransformObjectToHClip(i.pos.xyz);
				o.texcoord0 = i.texcoord0;
				o.color = i.color;
				o.screenPos = ComputeScreenPos(o.clipPos);
			    return o;
			}
			float4 FS (V2F i) : SV_TARGET 
			{
				vec4 mainTex = texture(_MainTex, i.texcoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				float dis = mainTex.x * mainTex.w;
				dis *= i.color.x * i.color.w;
				dis *= _Intensity;
				vec4 colorTex = texture(_CameraOpaqueTexture, (i.screenPos.xy / i.screenPos.w) + vec2(dis, 0.f));

				return colorTex;
			}
			
			ENDHLSL
		}
	}
}
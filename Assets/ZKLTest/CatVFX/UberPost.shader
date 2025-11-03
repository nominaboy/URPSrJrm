Shader "CatVFX/Post-process/UberPost" {
	
	Properties 
	{
		_MainTex("_MainTex", 2D) = "white" {}
		
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull", Float) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 0
	}
	
	SubShader 
	{
		Pass 
		{
			Blend SrcAlpha OneMinusSrcAlpha
			Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull [_Cull]
			ZTest [_ZTest]
			HLSLPROGRAM
			#pragma vertex VS
			#pragma fragment FS

			#pragma multi_compile_local_fragment _ _CHROMATIC_ABERRATION



			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
			#define vec2 float2
			#define vec3 float3
			#define vec4 float4
			#define texture(Tex, UV) SAMPLE_TEXTURE2D(Tex, sampler##Tex, UV)
			#define textureLod(Tex, UV, Lod) SAMPLE_TEXTURE2D_LOD(Tex, sampler##Tex, UV, Lod)
			#define mix(a, b, t) lerp(a, b, t)
			
			TEXTURE2D(_MainTex);
			SAMPLER(sampler_MainTex);

			CBUFFER_START(UnityPerMaterial)
				float4 _MainTex_ST;
			CBUFFER_END

			uniform float4 _ChromaticAberration_Split;
			uniform float _ChromaticAberration_Blur;
			uniform float _ChromaticAberration_Radial;

			struct App {
				float4 pos : POSITION;
				float4 texcoord0 : TEXCOORD0;
			};
			struct V2F {
				float4 clipPos : SV_POSITION;
				float4 texcoord0 : VAR_TEXCOORD0;
			};
			V2F VS (App i)
			{
			    V2F o;
			    o.clipPos = TransformObjectToHClip(i.pos.xyz);
				o.texcoord0 = i.texcoord0;
			    return o;
			}
			float4 FS (V2F i) : SV_TARGET 
			{
				vec2 uv = i.texcoord0.xy;

				vec4 fragColor;

				#if _CHROMATIC_ABERRATION
					float mask = min(length(uv - 0.5f) * 4.f + .3f, 1.f);
					float tex1 = texture(_MainTex, uv).y;
					tex1 *= mix(1.f, _ChromaticAberration_Radial, mask);
					vec3 tex2 = texture(_MainTex, uv - (uv - 0.5f) * _ChromaticAberration_Blur).xyz;
					vec3 tex3 = texture(_MainTex, uv + (uv - 0.5f) * _ChromaticAberration_Blur).xyz;
					vec3 col = vec3(tex2.x * _ChromaticAberration_Split.y + tex3.x * _ChromaticAberration_Split.x,
					                tex2.y * _ChromaticAberration_Split.z + tex3.y * _ChromaticAberration_Split.z + tex1 * _ChromaticAberration_Split.w,
					                tex2.z * _ChromaticAberration_Split.x + tex3.z * _ChromaticAberration_Split.y);
					fragColor = vec4(col, 1.f);
				#else

				fragColor = texture(_MainTex, uv);

				#endif
    
				return fragColor;
			}
			ENDHLSL
		}

	}
}
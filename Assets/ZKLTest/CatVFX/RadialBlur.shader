Shader "CatVFX/Post-process/RadialBlur" {
	
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

			uniform int _SampleCount;
			uniform float _Blur; 


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
    
				vec2 velocity = uv - 0.5f;
				velocity *= length(velocity);
				
				float detal = _Blur / float(_SampleCount);
				float offset = detal;

				vec4 sum = 0;
				for (int i = 0; i < _SampleCount; i++)
				{
				    sum += texture(_MainTex, uv - velocity * offset);
				    offset += detal;
				}
				return sum / _SampleCount;
			}
			ENDHLSL
		}

	}
}
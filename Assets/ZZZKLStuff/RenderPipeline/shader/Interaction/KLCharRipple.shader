Shader "Jeremy/Interaction/KLCharRipple"
{
	Properties
	{
        _NormalMap ("Normal Map", 2D) = "bump" { }
	}
	
	SubShader
	{
		Tags { "RenderType" = "Opaque"}

		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
		ZWrite Off
		ZTest Off
		
		Pass
		{
            Tags { "LightMode" = "KLCharRipple" }
			HLSLPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			//#pragma multi_compile_instancing
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			//#pragma enable_d3d11_debug_symbols

			TEXTURE2D(_NormalMap);
            SamplerState kl_linear_clamp_sampler;

			struct Attributes
			{
				float4 positionOS : POSITION;
				half4 vertexColor : COLOR;
                float2 uv : TEXCOORD0;
			};
			
			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				half4 vertexColor : COLOR;
                float2 uv : TEXCOORD0;
			};

			Varyings vert(Attributes i)
			{
                Varyings o = (Varyings) 0;
				o.uv = i.uv;
				o.vertexColor = i.vertexColor;
				o.positionCS = TransformObjectToHClip(i.positionOS);
				return o;
			}

			half4 frag(Varyings i) : SV_Target
			{
				half3 normalTS = SAMPLE_TEXTURE2D(_NormalMap, kl_linear_clamp_sampler, i.uv).rgb;
				return half4(normalTS.rg, normalTS.b, i.vertexColor.a * normalTS.b);
			}
			ENDHLSL

		}
	}
}
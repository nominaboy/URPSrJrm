Shader "Jeremy/Unlit/Gem"
{
	Properties
	{
		[HDR]_Color("Color", Color) = (0.1505874,0.5510882,0.6792453,0)
		_MainTex("MainTex", 2D) = "white" {}
		// _RefractIndex("RefractIndex", Float) = 2
		// _Rotation("Rotation", float) = 0.1
		[Toggle]_YFloat("YFloat Enable", int) = 0
		_Trans("x-Rot,y-posRange,z-posSpeed,w-pos+", Vector) = (36, 1, 0.2, 0.3)
	}
	
	SubShader
	{
		Tags { "RenderType"="Opaque"  "Queue"="Geometry" }
		LOD 200

		Pass
		{
			Tags {"LightMode"="UniversalForward" }
			// Blend SrcAlpha OneMinusSrcAlpha
			// Blend One One
			ZWrite On
			// Cull Back
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _YFLOAT_ON
            #pragma target 3.0
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD2;
			};

			CBUFFER_START(UnityPerMaterial)
				half4 _Color;
				// half _RefractIndex;
				// half _Rotation;
				half4 _Trans;
			CBUFFER_END
			TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
			
			Varyings vert (Attributes i)
			{
				Varyings o;

				o.uv = i.uv;
				float rotation = _Trans.x * frac(_Time.x) + unity_DeltaTime.x ;
				// float4x4 RotationY = float4x4(
				// cos(rotation),0,sin(rotation),0,
				// 0,1,0,0,
				// -sin(rotation),0,cos(rotation),0,
				// 0,0,0,1
				// );
				// i.vertex = mul(RotationY,i.vertex);
				
				float s = sin(rotation);
				float c = cos(rotation);

				float3x3 rotationY = float3x3(
						c, 0, s,
						0, 1, 0,
						-s ,0 ,c
					);
				i.positionOS.xyz = mul(rotationY, i.positionOS.xyz);
				#ifdef _YFLOAT_ON
					i.positionOS.y += sin(_Time.w * _Trans.y) * _Trans.z + _Trans.w;
				#endif
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				return o;
			}
			
			half4 frag (Varyings i ) : SV_Target
			{
				half4 finalColor= 1;
				half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);		
				
				finalColor.rgb =  mainTex.rgb * _Color.rgb;
				// finalColor.a = _Color.a * mainTex.a;
				return finalColor;
			}
			ENDHLSL
		}
		//UsePass "URP/Template/ShadowCast/ShadowCast"
	}
	
}
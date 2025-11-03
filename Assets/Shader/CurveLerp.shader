Shader "Jeremy/CurveLerp" 
{
	Properties {
        _BaseColor("Base Color", Color) = (0, 0, 0, 0)
        _CurveLerp("Curve Lerp", Range(0, 1)) = 0
		_UVOffset("UV Offset", Vector) = (0, 0, 0, 0)
	}
    SubShader {
        Tags { 
            "RenderType" = "Opaque"
			"RenderPipeline" = "UniversalRenderPipeline"
            "Queue" = "Transparent"
		}
		HLSLINCLUDE
		#pragma vertex vert
		#pragma fragment frag
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
		struct Attributes {
			float4 positionOS : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct Varyings {
			float2 uv : TEXCOORD0;
			float4 positionCS : SV_POSITION;
		};
		ENDHLSL
   
		Pass {
            HLSLPROGRAM

			half4 _BaseColor;
			float _CurveLerp;
			float4 _UVOffset;

			float CurveFunc(float x)
			{
				return (abs(cos(x) + cos(2 * x)) + 1) / 6.0;
			}

			Varyings vert(Attributes i) {
				Varyings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				return o;
			}

			half4 frag(Varyings i) : SV_Target {
                half4 color;
				clip(_UVOffset.z - abs(i.uv.x - 0.5));

				float uvx = floor((i.uv.x + _UVOffset.x) * 20);
				float uvy = lerp(0, CurveFunc(uvx), _CurveLerp);

				clip(uvy - abs(i.uv.y - 0.5));

				color = (abs(i.uv.y - 0.5) + 0.5) * _BaseColor;


                return color;
			}
            ENDHLSL
        }
        
   
   
   }
}

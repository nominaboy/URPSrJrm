Shader "Jeremy/Translucent/Diamond"
{
	Properties
	{
		_Cubemap("Cubemap", CUBE) = "white" {}
		_CubeNormal("Cube Normal", CUBE) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" }

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			samplerCUBE _Cubemap;
			samplerCUBE _CubeNormal;

			#define REFRACT_INDEX float3(2.407, 2.426, 2.451)
			#define REFRACT_SPREAD float3 (0.0, 0.02, 0.05)
			#define MAX_BOUNCE 5
			// Total internal reflection => cos(arcsin(1.0/2.4)) = 0.91
			#define COS_CRITICAL_ANGLE 0.91

			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normalOS : NORMAL;
			};

			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normalOS : TEXCOORD1;
				float3 viewDirOS : TEXCOORD2;
			};

			
			Varyings vert (Attributes i)
			{
				Varyings o = (Varyings)0;
				float3 viewPosOS = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
				o.viewDirOS = normalize(i.positionOS.xyz - viewPosOS);
				o.normalOS = i.normalOS;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
				o.uv = i.uv;
				return o;
			}

			

			float4 frag (Varyings i) : SV_Target
			{
				float3 viewDirOS = normalize(i.viewDirOS);
				float3 normalOS = normalize(i.normalOS);
				float3 reflectDirOS = reflect(viewDirOS, normalOS);
				float fresnel = pow(1 - abs(dot(viewDirOS, normalOS)), 2);
				
				float3 reflectDirWS = TransformObjectToWorldDir(reflectDirOS);
				half3 finalColor = texCUBE(_Cubemap, reflectDirWS).rgb * fresnel;

				// Divide 1 by refraction index, since we entering to diamond from air 
				float3 inDirOS = refract(viewDirOS, normalOS, 1.0 / REFRACT_INDEX.r);
				// Direction to sample environment cubemap for different colors
				float3 inDirR, inDirG, inDirB;
				[unroll]
				for (int bounce = 0; bounce < MAX_BOUNCE; bounce++)
				{
					// Convert normalOS to -1, 1 range
					float3 inN = texCUBE(_CubeNormal, inDirOS).rgb * 2.0 - 1.0;
					if (abs(dot(-inDirOS, inN)) > COS_CRITICAL_ANGLE)
					{
						// The more bounces we have the heavier dispersion should be
						inDirR = refract(inDirOS, inN, REFRACT_INDEX.r);
						inDirG = refract(inDirOS, inN, REFRACT_INDEX.g + bounce * REFRACT_SPREAD.g);
						inDirB = refract(inDirOS, inN, REFRACT_INDEX.b + bounce * REFRACT_SPREAD.b);
						break;
					}

					// We didn't manage to exit diamond in MAX_BOUNCE
					// To be able exit from diamond to air we need fake our refraction 
					// index other way we'll get float3(0,0,0) as return
					if (bounce == MAX_BOUNCE-1)
					{
						inDirR = refract(inDirOS, inN, 1.0 / REFRACT_INDEX.r);
						inDirG = refract(inDirOS, inN, 1.0 / (REFRACT_INDEX.g + bounce * REFRACT_SPREAD.g));
						inDirB = refract(inDirOS, inN, 1.0 / (REFRACT_INDEX.b + bounce * REFRACT_SPREAD.b));
						break;
					}
					inDirOS = reflect(inDirOS, inN);
				}

				inDirR = TransformObjectToWorldDir(inDirR);
				inDirG = TransformObjectToWorldDir(inDirG);
				inDirB = TransformObjectToWorldDir(inDirB);
				finalColor.r += texCUBE(_Cubemap, inDirR).r;
				finalColor.g += texCUBE(_Cubemap, inDirG).g;
				finalColor.b += texCUBE(_Cubemap, inDirB).b;
				return half4(finalColor, 1);
			}
			ENDHLSL
		}
	}
}

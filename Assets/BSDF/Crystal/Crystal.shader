Shader "Jeremy/Translucent/Crystal"
{
    Properties
    {
		[Header(_______Base_______)]
        [Space]
		_BaseSpeed("Base Speed", Range(0, 1)) = 0.5
		_BaseColor("Base Color", Color) = (0.2, 0.2, 0.5, 1)

		[Header(_______Height_______)]
        [Space]
		_HeightTex("Height Texture", 2D) = "white"{}
		_HeightIntensity("Height Intensity", Range(0, 1)) = 0.2

		[Header(_______Sparkle_______)]
        [Space]
		_SparkleTex1("Sparkle Texture1", 2D) = "white"{}
		_SparkleTex2("Sparkle Texture2", 2D) = "white"{}
		_SparkleAmplitude1("Sparkle Amplitude1", Float) = 1.8
		_SparkleAmplitude2("Sparkle Amplitude2", Float) = 1.7	
		[HDR]_SparkleColor("Sparkle Color", Color) = (1, 1, 1, 1)
		_SparklePow("Sparkle Pow", Float) = 0.7
		_SparkleIntensity("Sparkle Intensity", Float) = 20

		[Header(_______Substance_______)]
        [Space]
		_SubstanceTex1("Substance Texture 1", 2D) = "white"{}
		_SubstanceTex2("Substance Texture 2", 2D) = "white"{}
		_SubstanceAmplitude1("Substance Amplitude1", Float) = 2.0
		_SubstanceAmplitude2("Substance Amplitude2", Float) = 1.6
		_SubstanceColor("Substance Color", Color) = (1, 1, 1, 1)
		_SubstancePow("Substance Pow", Float) = 0.8
		_SubstanceIntensity("Substance Intensity", Float) = 5

        [Header(_______Wrap Diffuse_______)]
        [Space]
		_NormalTex("Normal Texture", 2D) = "bump"{}
		_NormalScale("Normal Scale", Range(0, 2.0)) = 1.0
		_WrapValue("Wrap Value", Range(0, 1)) = 0

		[Header(_______Reflection_______)]
        [Space]
		_ReflectionIntensity("Reflection Intensity", Range(0, 5)) = 0.1
		_MatcapTex("Matcap Textuire", 2D) = "white"{}
		_FresnelPow("Fresnel Pow", Range(1, 10)) = 5
		_FresnelMin("Fresnel Min", Range(0, 1)) = 0.3
		_FresnelMax("Fresnel Max", Range(0, 1)) = 0.9
    }

    SubShader
    {
		Tags { "Queue" = "Geometry" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

			TEXTURE2D(_HeightTex);
			TEXTURE2D(_NormalTex);
			TEXTURE2D(_MatcapTex);
			TEXTURE2D(_SparkleTex1);
			TEXTURE2D(_SparkleTex2);
			TEXTURE2D(_SubstanceTex1);
			TEXTURE2D(_SubstanceTex2);

			//SamplerState kl_linear_clamp_sampler;
			SamplerState kl_linear_repeat_sampler;
			
            CBUFFER_START(UnityPerMaterial)
				float4 _NormalTex_ST;
				float4 _HeightTex_ST;
				float4 _SparkleTex1_ST;
				float4 _SparkleTex2_ST;
				float4 _SubstanceTex1_ST;
				float4 _SubstanceTex2_ST;

				float _BaseSpeed;
				half3 _BaseColor;

				float _HeightIntensity;

				float _SparkleAmplitude1;
				float _SparkleAmplitude2;
				half3 _SparkleColor;
				float _SparklePow;
				float _SparkleIntensity;

				float _SubstanceAmplitude1;
				float _SubstanceAmplitude2;
				half3 _SubstanceColor;
				float _SubstancePow;
				float _SubstanceIntensity;

				float _NormalScale;
				float _WrapValue;
				
				float _ReflectionIntensity;
				float _FresnelPow;
				float _FresnelMin;
				float _FresnelMax;
            CBUFFER_END


            struct Attributes
            {
                float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normalOS : NORMAL;
				float4 tangentOS : TANGENT;
            };

            struct Varyings
			{
				float4 positionCS : SV_POSITION;	
				float4 uv : VAR_UV;
				float4 T2W0 : VAR_T2W0;
				float4 T2W1 : VAR_T2W1;
				float4 T2W2 : VAR_T2W2;
			};


            Varyings vert (Attributes i)
            {
				Varyings o;
				float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
				float3 positionVS = TransformWorldToView(positionWS);

				o.positionCS = TransformWViewToHClip(positionVS);

                float crossSign = i.tangentOS.w * GetOddNegativeScale();
				float3 normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
				float3 tangentWS = TransformObjectToWorldDir(i.tangentOS.xyz);
				float3 bitangentWS = cross(normalWS, tangentWS) * crossSign;

				o.T2W0 = float4(tangentWS.x, bitangentWS.x, normalWS.x, positionWS.x);
				o.T2W1 = float4(tangentWS.y, bitangentWS.y, normalWS.y, positionWS.y);
				o.T2W2 = float4(tangentWS.z, bitangentWS.z, normalWS.z, positionWS.z);

				// Matcap
				positionVS = normalize(positionVS);
				float3 normalVS = TransformWorldToViewNormal(normalWS);
				float2 matcapUV = cross(positionVS, normalVS).xy;
				matcapUV = float2(-matcapUV.y, matcapUV.x) * 0.5 + 0.5;

				o.uv.xy = i.uv;
				o.uv.zw = matcapUV;
				return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
				float2 baseUV = i.uv.xy;
				Light mainLight = GetMainLight();
				// Row Major Matrix
				float3x3 tanToWorld = float3x3(normalize(i.T2W0.xyz), normalize(i.T2W1.xyz), normalize(i.T2W2.xyz));
				float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, kl_linear_repeat_sampler, baseUV * _NormalTex_ST.xy + _NormalTex_ST.zw));
				normalTS.xy *= _NormalScale;
				normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
				float3 normalWS = normalize(mul(tanToWorld, normalTS));
				
				float3 positionWS = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
				float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
				float3 lightDirWS = normalize(mainLight.direction);
				float NDotV = saturate(dot(normalWS, viewDirWS));

				// Parallax
				float baseSpeed = _BaseSpeed * _Time.y;
				//float3 viewDirTS = normalize(mul(transpose(tanToWorld), viewDirWS));
				float3 viewDirTS = normalize(mul(viewDirWS, tanToWorld));
				float height = SAMPLE_TEXTURE2D(_HeightTex, kl_linear_repeat_sampler, 
					baseUV * _HeightTex_ST.xy + _HeightTex_ST.zw * baseSpeed).r * _HeightIntensity;

				// Sparkle
				float2 uvOffset = ParallaxOffset1Step(height, _SparkleAmplitude1, viewDirTS);
				float2 sparkleUV1 = (baseUV + uvOffset) * _SparkleTex1_ST.xy + _SparkleTex1_ST.zw * baseSpeed;
				float sparkle1 = SAMPLE_TEXTURE2D(_SparkleTex1, kl_linear_repeat_sampler, sparkleUV1).r;
				uvOffset = ParallaxOffset1Step(height, _SparkleAmplitude2, viewDirTS);
				float2 sparkleUV2 = (baseUV + uvOffset) * _SparkleTex2_ST.xy + _SparkleTex2_ST.zw * baseSpeed;
				float sparkle2 = SAMPLE_TEXTURE2D(_SparkleTex2, kl_linear_repeat_sampler, sparkleUV2).r;
				float sparkle = saturate(pow(sparkle1 * sparkle2, _SparklePow) * _SparkleIntensity);
				half3 sparkleColor = lerp(_BaseColor.rgb, _SparkleColor.rgb, sparkle);
				
				// Substance
				uvOffset = ParallaxOffset1Step(height, _SubstanceAmplitude1, viewDirTS);
				float2 substanceUV1 = (baseUV + uvOffset) * _SubstanceTex1_ST.xy + _SubstanceTex1_ST.zw * baseSpeed;
				half3 substance1 = SAMPLE_TEXTURE2D(_SubstanceTex1, kl_linear_repeat_sampler, substanceUV1).rgb;
				uvOffset = ParallaxOffset1Step(height, _SubstanceAmplitude2, viewDirTS);
				float2 substanceUV2 = (baseUV + uvOffset) * _SubstanceTex2_ST.xy + _SubstanceTex2_ST.zw * baseSpeed;
				half3 substance2 = SAMPLE_TEXTURE2D(_SubstanceTex2, kl_linear_repeat_sampler, substanceUV2).rgb;
				half3 substanceColor = pow(substance1 * substance2, _SubstancePow) * _SubstanceIntensity * _SubstanceColor;

				// wrap diffuse
				float wrapDiffuse = max(0, dot(normalWS, lightDirWS) + _WrapValue) / (1 + _WrapValue);
				half3 diffuse = wrapDiffuse * (sparkleColor.rgb + substanceColor.rgb) * mainLight.color.rgb * mainLight.distanceAttenuation;

				// Reflection
				float2 mapcapUV = i.uv.zw;
				half3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, kl_linear_repeat_sampler, mapcapUV).rgb;
				half fresnel = saturate(pow(1 - smoothstep(_FresnelMin, _FresnelMax, NDotV), _FresnelPow));
				half3 reflection = matcap * _ReflectionIntensity * fresnel;

				half4 finalColor = half4(0, 0, 0, 1);
				finalColor.rgb = diffuse + reflection;
				return finalColor;
            }
            ENDHLSL
        }
    }
}

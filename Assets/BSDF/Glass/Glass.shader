Shader "Jeremy/Translucent/Glass"
{
    Properties
    {
        [Header(_______Diffuse_______)]
        [Space]
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_RampTex("Ramp Texture", 2D) = "white"{}
		[HDR]_RampColor("Ramp Color", Color) = (1, 1, 1, 1)

        [Header(_______Specular_______)]
        [Space]
		_SpecularPow("Specular Pow", Range(0.001, 1)) = 0.2
		_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)

        [Header(_______Rim Light_______)]
        [Space]
		_RimColor("Rim Color", Color) = (1, 1, 1, 1)
		_FresnelPow("Fresnel Pow", Range(1, 10)) = 5
		_FresnelMin("Fresnel Min", Range(0, 1)) = 0.3
		_FresnelMax("Fresnel Max", Range(0, 1)) = 0.9

		[Header(_______Reflection_______)]
        [Space]
		_ReflectionIntensity("Reflection Intensity",  Range(0, 2)) = 0.1
		_MatcapTex("Matcap Textuire", 2D) = "white"{}

        [Header(_______Refraction_______)]
        [Space]
		_RefractionIntensity("Refraction Rate", Range(-1, 1)) = 0.2
		_NormalTex("Normal Texture", 2D) = "bump"{}
		_NormalScale("Normal Scale", Range(0, 2.0)) = 1.0
    }

    SubShader
    {
		Tags { "Queue" = "Transparent" }

        Pass
        {
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite On

            Tags { "LightMode" = "Translucent" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			TEXTURE2D(_NormalTex);
			TEXTURE2D(_RampTex);
			TEXTURE2D(_MatcapTex);

			TEXTURE2D(_CustomColorTexture0);
			SamplerState kl_linear_clamp_sampler;
			SamplerState kl_linear_repeat_sampler;
			
            CBUFFER_START(UnityPerMaterial)
				half4 _BaseColor;
				half3 _RampColor;

				float _SpecularPow;
				half3 _SpecularColor;

				half3 _RimColor;
				float _FresnelPow;
				float _FresnelMin;
				float _FresnelMax;

				float _ReflectionIntensity;

				float _RefractionIntensity;
				float4 _NormalTex_ST;
				float _NormalScale;
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

				o.uv.xy = TRANSFORM_TEX(i.uv, _NormalTex);
				o.uv.zw = matcapUV;

				return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
				// Row Major Matrix
				float3x3 tanToWorld = float3x3(normalize(i.T2W0.xyz), normalize(i.T2W1.xyz), normalize(i.T2W2.xyz));
				float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, kl_linear_repeat_sampler, i.uv.xy));
				normalTS.xy *= _NormalScale;
				normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
				float3 normalWS = normalize(mul(tanToWorld, normalTS));
				float3 normalVS = TransformWorldToViewNormal(normalWS, true);
				
				float3 positionWS = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
				float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
				float3 lightDirWS = _MainLightPosition.xyz;

				float NDotV = saturate(dot(normalWS, viewDirWS));
				float3 reflectLightDir = reflect(-lightDirWS, normalWS);
				float3 reflectViewDir = reflect(-viewDirWS, normalWS);		
				
				// Specular - Phong VDotR
				half3 specular = pow(saturate(dot(reflectLightDir, viewDirWS)), 100 * _SpecularPow) * _SpecularColor.rgb;

				// Rim Light
				float fresnel = saturate(pow(1 - smoothstep(_FresnelMin, _FresnelMax, NDotV), _FresnelPow));
				half3 rimColor = fresnel * _RimColor.rgb;

				// Ramp Color
				float2 mapcapUV = i.uv.zw;
				half3 rampColor = SAMPLE_TEXTURE2D(_RampTex, kl_linear_clamp_sampler, mapcapUV + fresnel).rgb * _RampColor;

				// Reflection
				half3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, kl_linear_repeat_sampler, mapcapUV).rgb;
				half3 reflection = matcap * _ReflectionIntensity;

				// Refraction
				float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;
				half3 refraction = SAMPLE_TEXTURE2D(_CustomColorTexture0, kl_linear_repeat_sampler, 
					screenUV + normalVS.xy * NDotV * _RefractionIntensity).rgb;
				
				half4 finalColor = half4(0, 0, 0, 1);
				//finalColor.rgb = lerp(rimColor + refraction + rampColor + reflection, reflection, fresnel) + specular;
				finalColor.rgb = specular + rimColor + refraction + rampColor + reflection;
				finalColor.rgba *=  _BaseColor;
				return finalColor;
            }
            ENDHLSL
        }
    }
}

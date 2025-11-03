Shader "Jeremy/Translucent/Jade"
{
    Properties
    {
        [Header(_______Wrap Diffuse_______)]
        [Space]
		_NormalTex("Normal Texture", 2D) = "bump"{}
		_NormalScale("Normal Scale", Range(0, 2.0)) = 1.0
		_BaseColor("Base Color", Color) = (1, 1, 1, 1)
		_WrapValue("Wrap Value", Range(0, 1)) = 0

		[Header(_______SSS_______)]
        [Space]
		_ThicknessTex("Thickness Texture", 2D) = "white"{}
		_SSSColor("SSS Color", Color) = (1, 1, 1, 1)
		_SSSDistortion("SSS Distortion", Range(0, 1)) = 1.0
		_SSSPower("SSS Power", Range(0.1, 10)) = 1.0
		_SSSScale("SSS Scale", Range(0, 10)) = 1.0
		_AddSSSColor("Additional SSS Color", Color) = (1, 1, 1, 1)
		_AddSSSDistortion("Additional SSS Distortion", Range(0, 1)) = 1.0
		_AddSSSPower("Additional SSS Power", Range(0.1, 10)) = 1.0
		_AddSSSScale("Additional SSS Scale", Range(0, 10)) = 1.0


		[Header(_______Reflection_______)]
        [Space]
		_ReflectionIntensity("Reflection Intensity",  Range(0, 2)) = 0.1
		_MatcapTex("Matcap Textuire", 2D) = "white"{}
		_FresnelPow("Fresnel Pow", Range(1, 10)) = 5
		_FresnelMin("Fresnel Min", Range(0, 1)) = 0.3
		_FresnelMax("Fresnel Max", Range(0, 1)) = 0.9
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
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_NormalTex);
			TEXTURE2D(_ThicknessTex);
			TEXTURE2D(_MatcapTex);

			//SamplerState kl_linear_clamp_sampler;
			SamplerState kl_linear_repeat_sampler;
			
            CBUFFER_START(UnityPerMaterial)
				half3 _BaseColor;
				float _NormalScale;
				float _WrapValue;
				
				half3 _SSSColor;
				float _SSSDistortion;
				float _SSSPower;
				float _SSSScale;
				half3 _AddSSSColor;
				float _AddSSSDistortion;
				float _AddSSSPower;
				float _AddSSSScale;

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

			inline float FastSSS (float3 V, float3 L, float3 N, float distortion, float power, float scale)
            {
                float3 H = normalize(L + N * distortion);
                //float3 H = L + N * distortion;
                float I = pow(saturate(dot(V, -H)), power) * scale;
                return I;
            }

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
				Light mainLight = GetMainLight();
				// Row Major Matrix
				float3x3 tanToWorld = float3x3(normalize(i.T2W0.xyz), normalize(i.T2W1.xyz), normalize(i.T2W2.xyz));
				float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, kl_linear_repeat_sampler, i.uv.xy));
				normalTS.xy *= _NormalScale;
				normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
				float3 normalWS = normalize(mul(tanToWorld, normalTS));
				float3 normalVS = TransformWorldToViewNormal(normalWS, true);
				
				float3 positionWS = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);
				float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
				float3 lightDirWS = normalize(mainLight.direction);
				float3 reflectDirWS = reflect(-viewDirWS, normalWS);
				float NDotV = saturate(dot(normalWS, viewDirWS));

				// wrap diffuse
				float wrapDiffuse = max(0, dot(normalWS, lightDirWS) + _WrapValue) / (1 + _WrapValue);
				half3 diffuse = wrapDiffuse * _BaseColor.rgb *  mainLight.color.rgb * mainLight.distanceAttenuation;

				// SSS
				half thickness = SAMPLE_TEXTURE2D(_ThicknessTex, kl_linear_repeat_sampler, i.uv.xy).r;
				float sss = FastSSS(viewDirWS, lightDirWS, normalWS, _SSSDistortion, _SSSPower, _SSSScale);
				half3 sssColor = sss * (1 - thickness) * _SSSColor.rgb * mainLight.color.rgb * mainLight.distanceAttenuation;
				
				// Add SSS
				half3 addsssColor = 0;
				uint pixelLightCount = GetAdditionalLightsCount();
				LIGHT_LOOP_BEGIN(pixelLightCount)
    
					Light light = GetAdditionalLight(lightIndex, positionWS);
					sss = FastSSS(viewDirWS, lightDirWS, normalWS, _AddSSSDistortion, _AddSSSPower, _AddSSSScale);
					addsssColor += sss * (1 - thickness) * _AddSSSColor.rgb * light.color.rgb * light.distanceAttenuation;
    
				LIGHT_LOOP_END


				// Reflection
				float2 mapcapUV = i.uv.zw;
				half3 matcap = SAMPLE_TEXTURE2D(_MatcapTex, kl_linear_repeat_sampler, mapcapUV).rgb;
				half fresnel = saturate(pow(1 - smoothstep(_FresnelMin, _FresnelMax, NDotV), _FresnelPow));
				half3 reflection = matcap * _ReflectionIntensity * fresnel;

				half4 finalColor = half4(0, 0, 0, 1);
				finalColor.rgb = diffuse + sssColor + addsssColor + reflection;
				return finalColor;
            }
            ENDHLSL
        }
    }
}

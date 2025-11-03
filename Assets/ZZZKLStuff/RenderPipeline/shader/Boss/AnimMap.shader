Shader "Jeremy/Boss/AnimMap"
{
	Properties
	{
		_Tint("Tint", Color) = (0, 0, 0, 0)
		_MainTex("Texture", 2D) = "white" {}
		[Header(AnimMap)]
		_AnimMap("AnimMap", 2D) = "white" {}
		_AnimLen("Anim Length", Float) = 0
		_AnimNowRate("anim NowRate", Float) = -1
		[Header(Diffuse(X1)  line(y0.1)  ShadowAdd(z0.1)  Illum(w5))]	
		[Space(10)]
		_number("Diffuse(X) del-line(y) del-Shadow+(z)x Illum(w)",vector)=(1,0.006,0.1,5)
		[Toggle]_Illum("Illum Enable",int)=0
	}
	
	HLSLINCLUDE
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#pragma vertex vert
	#pragma fragment frag
    #pragma target 3.0
    #pragma multi_compile_instancing

	UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_DEFINE_INSTANCED_PROP(float, _AnimLen)
		UNITY_DEFINE_INSTANCED_PROP(float, _AnimNowRate)
		UNITY_DEFINE_INSTANCED_PROP(half4, _number)
		UNITY_DEFINE_INSTANCED_PROP(half4, _Tint)
    UNITY_INSTANCING_BUFFER_END(Props)

	TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
	TEXTURE2D(_AnimMap); SAMPLER(sampler_AnimMap);
	float4 _AnimMap_TexelSize;
	
	ENDHLSL
	
	SubShader
	{
		Pass
		{
			Tags { "RenderType"="Opaque" "Queue"="Geometry" "LightMode"="UniversalForward" }
			
			Stencil
			{
				Ref 3
				Comp GEqual
				Pass Replace
				Fail Keep
				ZFail Keep
			}

			HLSLPROGRAM
			#pragma shader_feature _ _ILLUM_ON
			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct Varyings
			{
				float2 uv : TEXCOORD0;
				float3 positionWS : VAR_POSITIONWS;
				float3 normalWS : VAR_NORMALWS;
				float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			Varyings vert(Attributes i, uint vid : SV_VertexID)
			{
				Varyings o = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_TRANSFER_INSTANCE_ID(i, o);
				
				float2 uv = float2((vid + 0.5) * _AnimMap_TexelSize.x, UNITY_ACCESS_INSTANCED_PROP(Props, _AnimNowRate));
				float3 positionOS = SAMPLE_TEXTURE2D_LOD(_AnimMap, sampler_AnimMap, uv, 0).xyz;
				o.uv = i.uv;
				o.normalWS = TransformObjectToWorldNormal(i.normalOS);
				o.positionWS = TransformObjectToWorld(positionOS);
				o.positionCS = TransformWorldToHClip(o.positionWS);
				return o;
			}
			
			half4 frag(Varyings i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
				half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				mainTex.rgb *= _MainLightColor.rgb;
				half4 numberVal = UNITY_ACCESS_INSTANCED_PROP(Props, _number);
				half3 finalColor = mainTex.rgb * numberVal.x;
				#if _ILLUM_ON
					finalColor += mainTex.rgb * mainTex.a * numberVal.w;
				#endif
				half4 tintColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Tint);
				//finalColor = lerp(finalColor, tintColor.rgb, tintColor.a);
				half3 viewDirWS = GetWorldSpaceNormalizeViewDir(i.positionWS);
				half NDotVC = 1 - saturate(dot(i.normalWS, viewDirWS));
				finalColor += NDotVC * (tintColor.a * 10) * tintColor.rgb;

				return half4(finalColor, 1);
			}
			ENDHLSL
		}
		
		Pass //outline
		{
			Tags { "RenderType"="Opaque" "Queue"="Geometry" "LightMode"="Outline" }
			Cull Front
			
			HLSLPROGRAM
			struct Attributes
			{
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
				float4 normalOS :NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct Varyings
			{
				float2 uv : TEXCOORD0;
				float4 positionCS : SV_POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			Varyings vert(Attributes i, uint vid : SV_VertexID)
			{
				Varyings o = (Varyings)0;
				UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
				
				float2 uv = float2((vid + 0.5) * _AnimMap_TexelSize.x, UNITY_ACCESS_INSTANCED_PROP(Props, _AnimNowRate));
				float3 positionOS = SAMPLE_TEXTURE2D_LOD(_AnimMap, sampler_AnimMap, uv, 0).xyz;
				half _OutlineLen = UNITY_ACCESS_INSTANCED_PROP(Props, _number).y;
				o.positionCS = TransformObjectToHClip(positionOS);
				float3 normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
				float3 normalCS = TransformWorldToHClipDir(normalWS);
				float2 offset = normalize(normalCS.xy) / _ScreenParams.xy * _OutlineLen * o.positionCS.w;
				o.positionCS.xy += offset;
				o.uv = i.uv;
				return o;
			}
			
			half4 frag(Varyings i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
				half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
				half3 finalColor = mainTex.rgb * 0.5;
				half4 tintColor = UNITY_ACCESS_INSTANCED_PROP(Props, _Tint);
				finalColor = lerp(finalColor, tintColor.rgb, saturate(tintColor.a * 10));
				return half4(finalColor, 1);
			}
			
			ENDHLSL
		}
	}
}
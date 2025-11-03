Shader "Jeremy/Fur/Fur"
{
    Properties 
	{
        [Header(_______Diffuse_______)]
		[Space]
		_BaseMap("Main Texture", 2D) = "white"{}
		_UVOffset("UV Offset", Vector) = (0.0, 0.0, 0.2, 0.2)
		_BottomColor("Bottom Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_TopColor("Top Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_LightFilter("Light Filter", Range(-0.5,0.5)) = 0.0
		_FurLength("Fur Length", Float) = 1.0
		_FurThickness("Fur Thickness", Range(0,1)) = 0.5
		_FurDirection("Fur Direction", Vector) = (0.0, -1.0, 0.0, 0.0)
		_GravityStrength("Gravity Strength", Range(0,1)) = 0.25
		_NormalTex("Normal Texture", 2D) = "bump"{}
		_NormalScale("Normal Scale", Range(0, 2.0)) = 1.0

		[Header(_______Alpha_______)]
		[Space]
		_NoiseTex("Noise Texure", 2D) = "bump" {}
		_FurMask("Fur Mask", 2D) = "white"{}
		_EdgeAlpha("Edge Alpha", Range(0, 1)) = 0.5

		[Header(_______Indirect_______)]
		[Space]
		_OcclusionColor("Occlusion Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_FresnelLV("Fresnel LV", Float) = 1.0

		[Header(_______Specular_______)]
		[Space]
        [Toggle(_SPECULAR_ON)] _SPECULAR_ON("_SPECULAR_ON", Float) = 0
		_SpecularVec("Specular Vec", Vector) = (30, 50, -0.33, -0.71)
		_SpecularColor1("Specular Color1", Color) = (1.0, 1.0, 1.0, 1.0)
		_SpecularColor2("Specular Color2", Color) = (1.0, 1.0, 1.0, 1.0)
		_SpecularLightDir("Specular Light Dir", Vector) = (1, 1, 1, 1)
	}

    HLSLINCLUDE
        #pragma shader_feature _ _SPECULAR_ON
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

		float _FUR_LAYER;  
		CBUFFER_START(UnityPerMaterial) 
			float2 _UVOffset;
			half3 _BottomColor;          
			half3 _TopColor;    
			half _LightFilter;
			half _FurLength;       
			half _FurThickness;    
			half4 _FurDirection;   
			half _GravityStrength; 
			half _NormalScale;         
			
			half _EdgeAlpha;   

			half3 _OcclusionColor;
			half _FresnelLV;

			float4 _SpecularVec;
			half3 _SpecularColor1;    
			half3 _SpecularColor2;   
			float3 _SpecularLightDir;
			
			float4 _BaseMap_ST;
			float4 _NormalTex_ST;   
			float4 _NoiseTex_ST;    
		CBUFFER_END
		TEXTURE2D(_BaseMap);
		TEXTURE2D(_NormalTex);
		TEXTURE2D(_NoiseTex);
		TEXTURE2D(_FurMask);
		SamplerState kl_linear_repeat_sampler;

	ENDHLSL

    SubShader
    {
		Pass 
		{  
			Name "PBRBase"                      
			Tags { "LightMode" = "PBRBase" "Queue"="Geometry"}    
        
			HLSLPROGRAM  
			#pragma vertex vertSimple  
			#pragma fragment fragSimple   
			#include "FurUtils.hlsl" 
			ENDHLSL 
		}



		Pass 
		{  
			Name "Fur"                      
			Tags { "LightMode" = "Fur" "Queue"="Transparent"}    
			Cull Off                            
			ZWrite Off                          
			Blend SrcAlpha OneMinusSrcAlpha     
        
			HLSLPROGRAM  
			#pragma vertex vert     
			#pragma fragment frag   
			#include "FurUtils.hlsl" 
			ENDHLSL 
		}

        
    }
}

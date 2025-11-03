/*****************************************************************
(直接Diffuse specular && 间接/环境Diffuse(Light Probe + SH) specular(IBL))
*****************************************************************/
Shader "Jeremy/PBRFinal" {
	Properties {
        [Header(____________Albedo____________)]
        [Space(10)]
        _MainTex("Main Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1 ,1 ,1 ,1)
        [Header(____________Metallic____________)]
        [Space(10)]
        [Toggle(USE_METALLIC_TEX)] _UseMatallicTex("Use Matallic Texture", Float) = 0
        _Metallic("Metallic Map", 2D) = "black" {}
        _MetallicCoe("Metallic Coefficient", Range(0,1)) = 1
        [Header(____________Roughness____________)]
        [Space(10)]
        [Toggle(USE_ROUGHNESS_TEX)] _UseRoughnessTex("Use Roughness Texture", Float) = 0
		_Roughness("Roughness Map", 2D) = "white" {}
        _RoughnessCoe("Roughness Coefficient", Range(0,1)) = 1
        [Header(____________AO____________)]
        [Space(10)]
        _Ao("Ambient Occlusion Map", 2D) = "white" {}
        [Header(____________Normal____________)]
        [Space(10)]
        [Toggle(USE_NORMAL_TEX)] _UseNormalTex("Use Normal Texture", Float) = 0
        [Normal] _Normal("Normal Map", 2D) = "bump" {}
        _NormalScale("Normal Scale", float) = 1.0
        [Header(____________Emission____________)]
        [Space(10)]
        [Toggle(USE_EMISSION_TEX)] _UseEmissionTex("Use Emission Texture", Float) = 0
        [NoScaleOffset] _EmissionMap("Emission Texture", 2D) = "white"{}
        [HDR] _EmissionColor("Emission Color", Color) = (0.0,0.0,0.0,0.0)
	}
    SubShader {
        Tags { 
            "RenderType" = "Opaque"
			"RenderPipeline" = "UniversalRenderPipeline" 
		}
		HLSLINCLUDE
        #include "./HLSL/PBRFunctions.hlsl"
        
        #pragma enable_d3d11_debug_symbols
		#pragma vertex vert
		#pragma fragment frag
        #pragma shader_feature USE_METALLIC_TEX
        #pragma shader_feature USE_ROUGHNESS_TEX
        #pragma shader_feature USE_NORMAL_TEX
        #pragma shader_feature USE_EMISSION_TEX
			
		struct Attributes {
			float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
			float2 uv : TEXCOORD0;
		};

		struct Varyings {
			float4 positionCS : SV_POSITION;
			float2 uv : TEXCOORD0;
			float3 positionWS : TEXCOORD1;
            float3 normalWS : TEXCOORD2;
            float3 tangentWS : TEXCOORD3;
            float3 bitangentWS : TEXCOORD4;
		};
		ENDHLSL
   
		Pass {

            HLSLPROGRAM
            float4 _Tint;
            float4 _EmissionColor;
            float _NormalScale;
            float _MetallicCoe;
            float _RoughnessCoe;
            float4 _MainTex_ST;

            Texture2D _PBREnvironmentMap;
			SamplerState sampler_PBREnvironmentMap;
            Texture2D _PBRBrdfLUTMap;
			SamplerState sampler_PBRBrdfLUTMap; 

            Texture2D _MainTex;
            Texture2D _Metallic;
			Texture2D _Roughness;
            Texture2D _Ao;
            Texture2D _Normal;
            Texture2D _EmissionMap;
            SamplerState texture2d_linear_repeat_sampler;// 上述Texture2D均为Bilinear + repeat


            // 获取自发光
            float3 GetEmission(float2 uv, float3 emissionColor) {
                float4 emissionMap = SAMPLE_TEXTURE2D(_EmissionMap, texture2d_linear_repeat_sampler, uv);
                // 获取自发光颜色值
                return emissionMap.rgb * emissionColor.rgb;
            }

			Varyings vert(Attributes i) {
				Varyings o;
				o.positionWS = TransformObjectToWorld(i.positionOS.xyz);
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

                VertexNormalInputs normalInputs = GetVertexNormalInputs(i.normalOS.xyz, i.tangentOS);
                //o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                //获取世界空间法线
				o.normalWS = normalInputs.normalWS;
				//获取世界空间顶点
				o.tangentWS = normalInputs.tangentWS;
				//获取世界空间顶点
				o.bitangentWS = normalInputs.bitangentWS;

				o.uv = TRANSFORM_TEX(i.uv, _MainTex);
				return o;
			}

			float4 frag(Varyings i) : SV_Target {
                float metallic, roughness, emis;
                float3 normalWS, albedo;
#ifdef USE_METALLIC_TEX
                metallic = SAMPLE_TEXTURE2D(_Metallic, texture2d_linear_repeat_sampler, i.uv).r;
#else
                metallic = _MetallicCoe;
#endif

#ifdef USE_ROUGHNESS_TEX
                roughness = SAMPLE_TEXTURE2D(_Roughness, texture2d_linear_repeat_sampler, i.uv).r;
#else
                roughness = _RoughnessCoe;
#endif
                roughness = max(0.02, roughness);
#ifdef USE_NORMAL_TEX
				// 采样法线贴图（切线空间）
				float4 normalTXS = SAMPLE_TEXTURE2D(_Normal, texture2d_linear_repeat_sampler, i.uv);
				// 贴图颜色 0~1 转 -1~1 (*2-1)并且缩放法线强度
				float3 normalTS = UnpackNormalScale(normalTXS, _NormalScale);
                normalWS = normalize(TransformTangentToWorld(normalTS, real3x3(i.tangentWS, i.bitangentWS, i.normalWS)));
#else
                normalWS = normalize(i.normalWS);
#endif

#ifdef USE_EMISSION_TEX
                emis = GetEmission(i.uv, _EmissionColor);
#else
                emis = float3(0,0,0);
#endif

                albedo = SAMPLE_TEXTURE2D(_MainTex, texture2d_linear_repeat_sampler, i.uv).rgb;
                albedo *= _Tint.rgb;
                float ao = SAMPLE_TEXTURE2D(_Ao, texture2d_linear_repeat_sampler, i.uv).r;
				// 计算WorldSpace下NormalDir Viewdir ReflectionDir
				float3 N = normalWS;
                float3 V = normalize(GetCameraPositionWS() - i.positionWS);
                float3 R = reflect(-V, N);   
                // 绝缘体基础反射率定为0.04，绝缘体直接取基础反射率F0作为表面颜色，金属没有漫反射直接使用纹理颜色作为F0
                float3 F0 = float3(0.04, 0.04, 0.04); 
                F0 = lerp(F0, albedo, metallic);
                // reflectance equation
                float3 Lo = float3(0.0, 0.0, 0.0);

                float3 L, H, clight, F;
                float3 specular, kS, kD;
                float NdotL;
                /***********主光源*************/
                Light mainLight = GetMainLight();
                L = normalize(mainLight.direction);
                H = normalize(V + L);
                // directional Light L项 即为c_light
                clight = mainLight.distanceAttenuation * mainLight.color.rgb;
                // Cook-Torrance BRDF
                //specular = URPLitSpecularBRDF(roughness, N, H, V, L, F0, F);
                specular = CTSpecBRDF(roughness, N, H, V, L, F0, F);
                // 菲涅尔方程结果为反射光线所占百分比，即为kS
                kS = F;
                // 能量守恒，kS和kD和为1
                kD = float3(1.0, 1.0, 1.0) - kS;
                // 金属只反射光线不折射光线，不会有漫反射，metallic为1时kD为0
                kD *= (1.0 - metallic);	                
                NdotL = max(dot(N, L), 0.0);
                // kS用于计算kD，不进入specular BRDF计算
                Lo += (kD * LambertianDiffBRDF(albedo) + specular) * PI * clight * NdotL;
                /***********其它光源*************/

				int pixelLightCount = GetAdditionalLightsCount();
                for(int lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex) {

                    Light light = GetAdditionalLight(lightIndex, i.positionWS);
                    
                    // calculate per-light radiance
                    L = normalize(light.direction);
                    H = normalize(V + L);
                    clight = light.distanceAttenuation * light.color.rgb;

                    specular = CTSpecBRDF(roughness, N, H, V, L, F0, F);
                    //specular = URPLitSpecularBRDF(roughness, N, H, V, L, F0, F);

                    kS = F;
                    kD = float3(1.0, 1.0, 1.0) - kS;
                    kD *= (1.0 - metallic);	                
                    NdotL = max(dot(N, L), 0.0);        

                    Lo += (kD * LambertianDiffBRDF(albedo) + specular) * PI * clight * NdotL;
                }   
                // ambient lighting (we now use IBL as the ambient term)
                F = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);
                kS = F;
                kD = 1.0 - kS;
                kD *= 1.0 - metallic;	  
                // Light Probe采样
                float3 diffuse = SampleSH(N) * albedo;
				float mipLv = roughness * _mipMapMaxLevel;
                float3 prefilteredColor = SAMPLE_TEXTURE2D_LOD(_PBREnvironmentMap, sampler_PBREnvironmentMap, GetPhiThetaFromPos(normalize(R)), mipLv).rgb;
                float2 uv = float2(max(dot(N, V), 0.0), roughness);
                float2 brdf = SAMPLE_TEXTURE2D(_PBRBrdfLUTMap, sampler_PBRBrdfLUTMap, uv).rg;
                // split sum两项相乘 得到高光IBL
                specular = prefilteredColor * (F0 * brdf.x + brdf.y);


                //specular = MonteCarloCalc(roughness, N, V, F0);
                //return (diffuse * kD * ao).xyzz;
                // 环境间接光照 
                float3 ambient = (kD * diffuse + specular) * ao;
                float3 color = ambient + Lo + emis;
                return float4(color, 1.0);
			}
            ENDHLSL
        }
        
   
   
   }
}

Shader "Jeremy/Unlit/Pet"
{
    Properties
    {
        _MainTex("MainTex",2D) = "white"{}
        // _DarkColor("Dark Color",Color)=(0.75,0.9,1,1)
        [Header(Diffuse(X)  Specular(y)  Shininess(z)  DarkIntensity(w))]
        [Space]
        _number("dif-X dark-Y spe-Z glos-W",vector)=(1.5, 2, 0.2, 0.9)
        // [Toggle]_Illum("Illum Enable",int)=0
        _Illumindex("Illum Index", Range(0,10)) = 4
        [Header(Outline)]
        _OutlineColor("OutlineColor", Color) = (0.0853, 0.1565, 0.1792, 1)
        _OutlineLen("OutlineWidth", Range(0, 20)) = 8
        [Header(MeshShadow)]
        _BaseColor("Shadow Color",Color)=(0.8039, 0.4549, 0.2196, 0.745)
        _ShadowOffsest ("ShadowOffset-x,y,z dotSize-w", vector)=(0.4,0,-0.7,0.75)
        _dotMap("dot Map", 2D) = "white"{}
        
    }
    
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #pragma target 3.0
    CBUFFER_START(UnityPerMaterial)
    half4 _number;
    float4 _MainTex_ST;
    int _Illum;
    half _Illumindex;
    half3 _OutlineColor;
    half _OutlineLen;
    half4 _BaseColor;
    half4 _ShadowOffsest;
    float4 _dotMap_ST;
    CBUFFER_END
    ENDHLSL
    
    SubShader
    {
        Tags {"RenderType"="Opaqua" "Queue"="Geometry"}
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            Stencil
            {
                Ref 3
                Comp GEqual
                Pass Replace
            }
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma multi_compile _ _ILLUM_ON

            half3 SimpleLambert( float3 normalWS, Light mainLight, half4 _number, half3 mainTex)
            { 
                half3 lightColor1 = 0;
                //灯光剔除判断
                // if (IsMatchingLightLayer(mainLight.layerMask, meshRenderingLayers))
                // {
                    half NdotL = (dot(normalWS, mainLight.direction));
                    half3 lambert = ( saturate( saturate(NdotL) / _number.y  + lerp(_number.z, _number.z*mainTex, _number.w) ) )  * mainLight.color.rgb;
                    lightColor1.rgb = saturate(lambert).rgb;
                // }
                return lightColor1;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal :NORMAL;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;//-------------------------------------------------------fog(1)
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };
            TEXTURE2D(_MainTex);   SAMPLER(sampler_MainTex);
            
            v2f vert (appdata v)
            {
                v2f o;
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.pos = TransformWorldToHClip(o.worldPos);
                o.worldNormal = TransformObjectToWorldNormal(v.normal.xyz);
                o.uv.xy = TRANSFORM_TEX(v.uv,_MainTex);
                return o;
            }
            
            half4 frag (v2f i) : SV_Target
            {
                // //灯光分层剔除获取***********************************************************************start
                // uint meshRenderingLayers = (uint)0;//Light Render Culling Mask: Everything,Default,Water,UI...
                // #ifdef _LIGHT_LAYERS
                // meshRenderingLayers = (asuint(unity_RenderingLayer.x) & RENDERING_LIGHT_LAYERS_MASK) >> RENDERING_LIGHT_LAYERS_MASK_SHIFT;
                // #else
                // meshRenderingLayers = RENDERING_LIGHT_LAYERS_MASK >> RENDERING_LIGHT_LAYERS_MASK_SHIFT;
                // #endif
                //灯光分层剔除*************************************************************************end
                float3 positionWS = i.worldPos;
                half4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy);
                half3 mainTexHalf3 = mainTex.xyz;
                half3 N = normalize(i.worldNormal);

                Light mainLight = GetMainLight();
                half3 L = mainLight.direction;//_MainLightPosition.xyz;

                half3 lightColor = SimpleLambert(N, mainLight,_number,mainTexHalf3);
                //additional Lights
                int pixelLightCount = GetAdditionalLightsCount();//获取副光源个数，整数类型
                for (int index = 0; index < pixelLightCount; index++)
                {
                    Light light = GetAdditionalLight(index, positionWS);//获取其他的福光源世界位置
                    lightColor += SimpleLambert(N, light,_number, mainTexHalf3);
                }
                lightColor *= mainTexHalf3 * _number.x;
                
                // #if _ILLUM_ON
                // lightColor += half4( mainTexHalf3 * mainTex.a * _Illumindex, 0 );
                // #endif
                
                return half4(lightColor,1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "OUTLINEBOSS"
            Tags {"LightMode"="Outline"}
            Cull Front
            //Stencil
            //{
            //    Ref 3
            //    Comp NotEqual
            //    Pass Replace
            //}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag 

            float3 OctahedronToUnitVector(float2 oct)
            {
                float3 unitVec = float3(oct, 1 - dot(float2(1, 1), abs(oct)));
                if (unitVec.z < 0)
                {
                    unitVec.xy = (1 - abs(unitVec.yx)) * float2(unitVec.x >= 0 ? 1 : -1, unitVec.y >= 0 ? 1 : -1);
                }
                return normalize(unitVec);
            }
    
            struct appdata
            {
                float3 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                
                float2 smoothNormal : TEXCOORD3;
                float4 color : COLOR0;
            };
                
            struct v2f
            {
                float4 positionCS : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o = (v2f)0;

                o.positionCS = TransformObjectToHClip(v.positionOS);
                
                float3 normalTS = OctahedronToUnitVector(v.smoothNormal);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                float3x3 tangentToWorld = float3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS);
                float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld);

                // float3 normalWS = TransformObjectToWorldNormal(v.normalOS.xyz);
                float3 normalCS = TransformWorldToHClipDir(normalWS);

                float2 offset = normalize(normalCS.xy) / _ScreenParams.xy * _OutlineLen * o.positionCS.w * v.color.w;
                // half2 offset = normalize(normalCS.xy)  * _OutlineLen * o.positionCS.w * v.color.w;
                o.positionCS.xy += offset;
                return o;
            }
    
            half4 frag(v2f i) : SV_Target
            {
                return half4(_OutlineColor, 1);
            }
            ENDHLSL
        }
    }
}


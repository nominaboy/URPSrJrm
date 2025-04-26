Shader "JRMAdvanced/MCCloudShaderLab"
{
    Properties
    {
        [Header(_________Base_________)]
        _PositionWSOffset("PositionWS Offset", Vector) = (-352.35156, 279.41406, -8328.48535)
        _UVFlowSpeedOffset("UV Flow Speed And Offset", Vector) = (0.5, 0, 1, 0)
        _UVSwitch("UV Switch", Int) = 0
        _MovedUVScale("MovedUV Scale", Vector) = (1, 1, 1, 1)

        [Header(_________Vertex Color Lerp_________)]
        _VertexScatterColor1("Vertex Scatter Color1", Color) = (0.3451, 0.43137, 0.46667, 1.00)
        _VertexScatterColor2("Vertex Scatter Color2", Color) = (0.43137, 0.53725, 0.61569, 1.00)
        _VertexScatterColor3("Vertex Scatter Color3", Color) = (0.0902, 0.10588, 0.11765, 1.00)
        _VertexScatterColor4("Vertex Scatter Color4", Color) = (0.44762, 0.41667, 0.34349, 0.00)
        
        [Header(_________Cloud Textures_________)]
        _RedMask("Red Mask", 2D) = "white" {}
        _NoiseMap("Noise Map", 2D) = "white" {}
        _CloudTex("Cloud Tex", 2D) = "white" {}
        _ThunderTex("Thunder Tex", 2D) = "white" {}
        
        [Header(_________Cloud Color_________)]
        _DarkPartColor("Dark Part Color", Color) = (0.04373, 0.16022, 0.34201, 1.00)
        //_CloudColor2("Cloud Color2", Color) = (0.10866, 0.22145, 0.34201, 1.00)
        _BrightPartColor("Bright Part Color", Color) = (1.00, 0.86888, 0.55996, 1.00)
        _LitPartColor("Lit Part Color", Color) = (1.00, 0.73579, 0.19444, 1.00)
        _LowPartColor("Low Part Color", Color) = (0.38524, 0.52956, 0.70, 1.00)
        _AdditionalCloudColor("Additional Cloud Color", Color) = (0.5, 0.5, 0.5, 1.00)

        [Header(_________Thunder_________)]
        _ThunderMaskThreshold("Thunder Mask Threshold", Range(0, 1)) = 0
        _ThunderVecScaleOffset("ThunderVec Scale And Offset", Vector) = (0, 0, 0, 0)
        _ThunderUVYMinMax("Thunder UVY Min And Max", Vector) = (0, 0, 0, 0)
        _ThunderColor("Thunder Color", Color) = (0, 0, 0, 0)
        _ThunderLerp("Thunder Lerp", Range(0, 1)) = 1
        _ThunderMaskPath("Thunder Mask Path", Vector) = (1, 0, 0, 0)

        [Header(_________Rim_________)]
        _RimZoneNormal("Rim Zone Normal", Vector) = (2.97717, 0.57143, 2, 1)
        _RimMinIntensity("Rim Min Intensity", Float) = 0
        _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimZoneControl("Rim Zone Control", Vector) = (0.01, 1, 1, 1)

        [Header(_________Height Brightness_________)]
        _HeightScale("Height Scale", Range(0, 1)) = 1
        _BrightnessScale("Brightness Scale", Float) = 1.28
        _LowPartScale("Low Part Scale", Range(0, 1)) = 1
        _GreyScale("Grey Scale", Range(0, 1)) = 0


    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                //float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 uvGroup : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
                float4 additionalColor : TEXCOORD3;
            };

            
            sampler2D _RedMask;
            sampler2D _NoiseMap;
            sampler2D _CloudTex;
            sampler2D _ThunderTex;

            CBUFFER_START(UnityPerMaterial)
                float3 _PositionWSOffset;
                float4 _UVFlowSpeedOffset;
                int _UVSwitch;
                float2 _MovedUVScale;

                half4 _VertexScatterColor1;
                half4 _VertexScatterColor2;
                half4 _VertexScatterColor3;
                half4 _VertexScatterColor4;

                half4 _DarkPartColor;
                half4 _BrightPartColor;
                half4 _LitPartColor;
                half4 _LowPartColor;
                half4 _AdditionalCloudColor;

                

                float _ThunderMaskThreshold;
                float4 _ThunderVecScaleOffset;
                float2 _ThunderUVYMinMax;
                float4 _ThunderColor;
                float _ThunderLerp;
                float4 _ThunderMaskPath;

                float3 _RimZoneNormal;
                float4 _RimZoneControl;
                float _RimMinIntensity;
                float3 _RimColor;
                
                float _HeightScale;
                float _BrightnessScale;
                float _LowPartScale;
                float _GreyScale;
            CBUFFER_END


            float pow3(float x) {
                return x * x * x;
            }

            float pow5(float x) {
                return x * x * x * x * x;
            }

            Varyings vert (Attributes i)
            {
                Varyings o;
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);

                float3 positionWS = TransformObjectToWorld(i.positionOS.xyz) + _PositionWSOffset;
                o.positionWS = positionWS;
                o.positionCS = TransformWorldToHClip(positionWS);

                o.uvGroup.xy = i.uv.xy;
                o.uvGroup.zw = i.uv2.xy;
 

                float4 additionalColor = half4(0.0, 0.0, 0.0, 1.0);
                //_child0[7]	0.00, 0.00, 10.00, 0.00
                float boolVal1/*_25._m0[7u].x*/ = 0.0;
                if (/*_131*/ boolVal1 > 0.0) {
                    float3 posWSVec/*_323 _330*/ = positionWS - float3(0.0, 0.0, 0.0);
                    //float zOffset/*_331*/ = /*_138.z*/-_PositionWSOffset.z;
                    //posWSVec.z += (-_PositionWSOffset.z - zOffset);
                    float posWSLength/*_358*/ = length(posWSVec);
                    float InvPosWSLength/*_355*/ = 1 / max(0.01, posWSLength);

                    float4 finalScatter/*_329*/;
                    if (posWSLength < 0.01/*_70*/) {
                        finalScatter = float4(0.0, 0.0, 0.0, 1.0);
                    } else {
                        float3 posWSDir/*_368*/ = normalize(posWSVec);
                        float isPosWSFarClip/*_377*/ = step(posWSLength, 6000000.0);
                        float lerpRes1/*_381*/ = lerp(/*_107*/0.28 / 1000, /*_110*/0.8 / 1000, saturate((posWSLength - 2000000.0) / (-800000.0)));
                        float InvPosWSVecZ/*_400*/ = max(0/*_104*/, 0.01) * InvPosWSLength * posWSVec.z;
                        //float OneMinusInvPosWSLength/*_405*/  = 1.0 - max(0, 0.01) * InvPosWSLength;
                        float powVal1/*_409*/ = pow3(1.0 - max(0, 0.01) * InvPosWSLength) * posWSLength;

                        //float _417 = posWSLength - 10000.0/*_122*/;

                        float zCoe1/*_422*/ = (0.1/*_114*/ * exp2(-max(-127.0, lerpRes1 * ((/*_331*/InvPosWSVecZ/*- _138.z*/))))) / 1000.0;
                        float lerpPosWSVecZ/*_440*/ = max(-127.0, lerpRes1 * (posWSVec.z - InvPosWSVecZ));
                        //float _449 = (1.0 + (-exp2(-lerpPosWSVecZ))) / lerpPosWSVecZ;
                        //float _457 = abs(lerpPosWSVecZ);
                        float zCoe2/*_460*/ = (abs(lerpPosWSVecZ)/*_457*/ > 0.01) ? /*_449*/(1.0 + (-exp2(-lerpPosWSVecZ))) / lerpPosWSVecZ : 0.693147;

                        float zMulti1/*_439*/ = zCoe1 * zCoe2;

                        float LDotPosWSDir/*_469*/ = (dot(_MainLightPosition.xyz/*_64*/, posWSDir) * 0.5) + 0.5;//_64 _child2[20]	-0.00119, -0.73807, 0.67472, -7.06947  lightdir?

                        float lightCoe1/*_476*/ = (min(pow(exp((LDotPosWSDir - 1) * 37.51020050048828125), 
                            lerp(0.5/*_125*/, abs(dot(posWSDir, float3(0.0, 0.0, 1.0))) * 0.5/*_125*/, 0.0/*_118*/)), 1.0) * 
                            saturate(pow5(LDotPosWSDir))) * 
                            max(1.0 - saturate(exp2(-zMulti1 * (posWSLength - 10000.0)/*_417*/)), 
                            saturate((powVal1 - 500000.0) / 500000.0));

                        float multiplier1/*_521*/ = max(saturate(exp2(-zMulti1 * powVal1)), 0/*_373 = 1.0 + (-_100);//1.0 - 1.0*/);
                        float scatterAlpha/*_530*/ = min(multiplier1 * lerp(1.0, 1.0 - min(0.80, lightCoe1), saturate(0/*_128*/)), 
                            max(0.0, 1.0 + (-((isPosWSFarClip * saturate((posWSLength - 35000/*_84*/) / 80000/*_80*/)) * 0.50119/*_76*/))));

                        // Color Lerp
                        //_child2[10]	0.3451, 0.43137, 0.46667, 1.00
                        //_child2[11]	0.43137, 0.53725, 0.61569, 1.00
                        //_child2[12]	0.0902, 0.10588, 0.11765, 1.00
                        //_child2[0]	0.44762, 0.41667, 0.34349, 0.00
                        float3 scatterColor/*_607*/ = 
                            lerp(
                                lerp(
                                    lerp(
                                        _VertexScatterColor1/*_25._m2[10u].xyz*/, _VertexScatterColor2/*_25._m2[11u].xyz*/, 
                                        pow(saturate((posWSLength - 50000/*_96*/) / (200000/*_92*/ - 50000/*_96*/)), 1/*_88*/)
                                        ), 
                                    _VertexScatterColor3/*_25._m2[12u].xyz*/, multiplier1
                                    ), 
                                _VertexScatterColor4/*_25._m2[0u].xyz*/ * 0/*_128*/, saturate(lightCoe1 * 0/*_128*/)
                                )
                            * (1.0 - scatterAlpha);

                        finalScatter/*_329*/ = float4(scatterColor, scatterAlpha);
                    }


                    additionalColor/*_144*/ = lerp(float4(0.0, 0.0, 0.0, 1.0), finalScatter, boolVal1);
                }

                
                o.additionalColor = additionalColor;
                return o;
            }



            half4 frag (Varyings i) : SV_Target
            {
                


                //float sampleLod/*_50*/ = 0/*_27._m0[2u].x*/; // lod             0.00, 1.00, 1.00, 1.00

                float zOffset /*_61*/ = i.positionWS.z/*_16.xyz*/ - _PositionWSOffset.z/*_27._m0[0u].xyz*/;
                float3 posWSNorm/*_70*/ = normalize(-i.positionWS.xyz);

                float3 thunderVec1/*_76*/ = cross(float3(-2.97717, -0.57143, 2.00)/*_27._m2[10u].xyz*/, float3(0.0, 0.0, 1.0));//-2.97717, -0.57143, 2.00, 0.00
                //float _86 = length(_76);
                thunderVec1/*_85*/ = normalize(thunderVec1);// / vec3(_86);//normallize vector on xy-plane
                //_m2[10]	-2.97717, -0.57143, 2.00, 0.00
                float2 thunderVec2/*_95*/ = float2(dot(thunderVec1, posWSNorm), dot(cross(thunderVec1, float3(-2.97717, -0.57143, 2.00)/*_27._m2[10u].xyz*/), posWSNorm));
                float2 thunderVec3/*_108*/ = saturate((float2(1.0, 1.0) + ((thunderVec2 * _ThunderVecScaleOffset.xy/*_27._m2[11u].xy*//*0.00, 0.00, 0.00, 0.00*/) + 
                    _ThunderVecScaleOffset.zw/*_27._m2[11u].zw*/)) * float2(0.5, 0.5));
                        
                float2 thunderTexUV/*_126*/;
                thunderTexUV.x = thunderVec3.x;
                //_m2[12]	0.00, 0.00, 0.00, 0.00
                thunderTexUV.y = min(max(thunderVec3.y, _ThunderUVYMinMax.x/*_27._m2[12u].x*/), _ThunderUVYMinMax.y/*_27._m2[12u].y*/);
                float4 thunder/*_140*/ = tex2D(_ThunderTex, thunderTexUV);//, sampleLod/*_50*/);
                float2 thunderMask/*_145*/ = thunder.yw;
                float2 thunderPath/*_153*/ = thunder.zx;

                //_m3[2]	4.00, 0.50, 0.00, 1.00
                //_m2[2]	1.00, 1.00, 0.00, 2.00
                //_m2[4]	0.00, 1.00, 1.00, 0.00
                // uv流动，参数控制，360度比例
                float uvFlowVal/*_160*/ = ((frac(_Time.y/*_53 142.64896  _Time???*/ * _UVFlowSpeedOffset.x/*_27._m3[2u].y*/ * 0.001) 
                    + _UVFlowSpeedOffset.y/*_27._m3[2u].z*/) * _UVFlowSpeedOffset.z/*_27._m2[2u].y*/) + _UVFlowSpeedOffset.w/*_27._m2[4u].w*/;
                //vec2 _177;
                //_177.y = 0.0;
                //_177.x = uvFlowVal;


                //vec2 _181 = vec2(-0.5) + uvGroup.zw;// -0.5 0.5
                float flowAngle/*_187*/ = uvFlowVal * 2 * PI/*6.28318500518798828125*/;
                float cosFlowAngle/*_191*/ = cos(flowAngle);
                float sinFlowAngle/*_194*/ = sin(flowAngle);
                //vec2 _197;
                //_197.x = cosFlowAngle;
                //_197.y = sinFlowAngle * (-1.0);
                //vec2 _204;
                //_204.x = sinFlowAngle;
                //_204.y = cosFlowAngle;
                float2 rotateValue/*_209*/;
                // 旋转矩阵变换
                rotateValue.x = dot(i.uvGroup.zw - float2(0.5, 0.5)/*_181*/, float2(cosFlowAngle, -sinFlowAngle)/*_197*/);
                rotateValue.y = dot(i.uvGroup.zw - float2(0.5, 0.5)/*_181*/, float2(sinFlowAngle, cosFlowAngle)/*_204*/);


                //_m3[2]	4.00, 0.50, 0.00, 1.00
                //_m3[1]	1.00, 1.00, 1.00, 1.00
                float2 movedUV/*_218*/ = lerp(i.uvGroup.xy + float2(uvFlowVal, 0)/*_177*/, float2(0.5, 0.5) + rotateValue, _UVSwitch/*_27._m3[2u].ww*/) * _MovedUVScale/*_27._m3[1u].xy*/;
                // 两种不同映射插值？
                float4 cloudTex = tex2D(_CloudTex, movedUV);//, sampleLod/*_50*/);// _233


                //_m2[15]	0.00, 0.00, 0.00, 0.00
                //_m2[3]	0.00, 0.00, 0.00, 0.00
                //_m3[2]	4.00, 0.50, 0.00, 1.00
                //_m2[13]	1.00, 0.00, 0.00, 0.00      控制thunder贴图通道
                //_m3[0]	2.508, 2.9016, 3.00, 0.00
                //_m3[3]	1.00, 0.10, 0.60, 0.50
                //_m2[14]	0.00, 0.00, 0.00, 0.00
                // Thunder Calculation
                float3 thunderColor /*_238*/ = /*0 _27._m2[15u].zzz * */ (
                                (
                                    (
                                        (
                                            (step(1.0 - _ThunderMaskThreshold/*0 _27._m2[3u].y * 4 _27._m3[2u].x*/, dot(_ThunderMaskPath.xy/*_27._m2[13u].xy*/, thunderMask.xy)) * 
                                            dot(_ThunderMaskPath.xy/*_27._m2[13u].xy*/, thunderPath.xy)).xxx
                                            
                                            * float3(2.508, 2.9016, 3.00)/*_27._m3[0u].xyz*/
                                        ) * 
                                        (saturate((cloudTex.x - 0.1/*_27._m3[3u].y*/) / 0.5/*_27._m3[3u].w*/)).xxx
                                    )
                            * _ThunderColor.xyz/*_27._m2[14u].xyz*/) * _ThunderColor.w/*_27._m2[3u].xxx*/);
                

                //_m2[6]	0.40278, 0.72345, 1.00, 1.00
                //_m2[9]	0.10866, 0.22145, 0.34201, 1.00
                //float3 cloudColor1/*_290*/ = _CloudColor1.xyz;//_27._m2[6u].xyz * _27._m2[9u].xyz;//云的颜色


                //float _300 = 1.0 - uvGroup.y;//vertexColor.y: 1为地平线，0为球顶
                //float _306 = pow(1.0 - uvGroup.y/*_300*/, 0.3);// 地0 天1
                float height/*_310*/ = (i.uvGroup.y/*_300*/ <= 0.0) ? 0.0 : pow(i.uvGroup.y/*_300*/, 0.3)/*_306*/;

                //_m3[4]	1.00, 3.00, 0.30, 0.30
                height/*float _317*/ = height * _HeightScale/*_27._m3[4u].x*/;
                //_m2[0]	0.00, 0.60, 0.885, 1.28
                //float _322 = pow(cloudTex.x, max(_27._m2[0u].w, 0.5));//云亮部暗部
                float brightness/*_329*/ = (cloudTex.x <= 0.0) ? 0.0 : pow(cloudTex.x, max(_BrightnessScale/*_27._m2[0u].w*/, 0.5))/*_322*/;
                float heightBrightness/*_335*/ = height * brightness;// 高度 * 亮暗

                //_m2[5]	1.00, 0.86888, 0.55996, 1.00
                float3 mixedCloudColor/*_339*/ = lerp(_DarkPartColor.xyz, _BrightPartColor.xyz/*_27._m2[5u].xyz*/, heightBrightness);//根据高度*亮暗，插值云朵颜色





                //_m2[8]	1.00, 0.73579, 0.19444, 1.00
                //_m0[6]	-0.00119, -0.73807, 0.67472, 1.00     lightDir
                //float3 cloudColor4/*_347*/ = _LitPartColor.xyz/*_27._m2[8u].xyz*/ * 2.0;// color
                float3 lightDir/*_355*/ = -_MainLightPosition.xyz/*_27._m0[6u].xyz*/;// lightDir
                float LDotPosWS/*_361*/ = (1.0 + dot(lightDir, posWSNorm)) * 0.5; // LDotPosWS
                //_m3[4]	1.00, 3.00, 0.30, 0.30
                //float _367 = pow(LDotPosWS, 3/*_27._m3[4u].y*/);
                float LDotPosWSPow/*_372*/ = (LDotPosWS <= 0.0) ? 0.0 : pow(LDotPosWS, 3/*_27._m3[4u].y*/)/*_367*/;
                //_m2[0]	0.00, 0.60, 0.885, 1.28
                mixedCloudColor/*vec3 _377*/ = mixedCloudColor + (_LitPartColor.xyz * heightBrightness * 0.6/*_27._m2[0u].y*/ * LDotPosWSPow);// ... + LDotPosWS * 高度 * 亮暗 * color
                //_m1[1]	0.38524, 0.52956, 0.70, 1.00
                //_m1[0]	0.00, 150000.00, 1.00, 0.00
                mixedCloudColor/*vec3 _389*/ = lerp(lerp(mixedCloudColor, _LowPartColor.rgb/*_27._m1[1u].xyz*/, _LowPartScale/*_27._m1[0u].zzz*/), mixedCloudColor, height/*vec3(_317)*/);// 高度lerp
                //_m2[1]	1.00, 0.50, 1.00, 1.00
                //_m2[7]	1.00, 1.00, 1.00, 1.00
                float3 brightMixedCC/*_402*/ = mixedCloudColor + _AdditionalCloudColor.rgb * _AdditionalCloudColor.a;//(_27._m2[1u].yyy * _27._m2[7u].xyz);// 云增亮？
                




                float2 noiseUV/*_412*/ = posWSNorm.xy / posWSNorm.zz;//positionWS作为NOISEMAP UV
                // _m3[4]	1.00, 3.00, 0.30, 0.30    白天晚上都不变   
                // _m2[10]	-2.97717, -0.57143, 2.00, 0.00       白天晚上都不变
                float rimZone/*_419*/ = length(((tex2D(_NoiseMap, noiseUV * 0.30/*_27._m3[4u].zz*//*, sampleLod _50*/).xy * 0.3/*_27._m3[4u].ww*/) + noiseUV) + 
                    (_RimZoneNormal.xy/*_27._m2[10u].xy*/ / _RimZoneNormal.zz/*_27._m2[10u].zz*/));
                //_m2[15]	0.00, 0.00, 0.00, 0.00
                rimZone/*float _418*/ = 1.0 - saturate(rimZone / _RimZoneControl.x/*_27._m2[15u].x*/);
                //float _452 = pow(_418, 0/*_27._m2[15u].y*/);
                rimZone/*float _457*/ = (rimZone <= 0.0) ? 0.0 : pow(rimZone, _RimZoneControl.y/*_27._m2[15u].y*/)/*_452*/;
                //_m2[15]	0.00, 0.00, 0.00, 0.00
                //_m2[3]	0.00, 0.00, 0.00, 0.00
                //_m2[2]	1.00, 1.00, 0.00, 2.00
                //_m2[14]	0.00, 0.00, 0.00, 0.00
                float3 rimColor/*vec3 _462*/ = max(brightMixedCC, _RimZoneControl.z/*_27._m2[15u].w*/ * max(rimZone * _RimZoneControl.w/*_27._m2[3u].x*/, _RimMinIntensity/*_27._m2[2u].z*/) * _RimColor.xyz/*_27._m2[14u].xyz*/);
                float NDotL/*_480*/ = dot(lightDir, i.normalWS.xyz/*_13.xyz*/);//NDotL
                //float _485 = pow(NDotL, 2.0);// 0 - 1
                float NDotLSquare/*_488*/ = (NDotL <= 0.0) ? 0.0 : pow(NDotL, 2.0)/*_485*/;
                //float _493 = pow(cloudTex.y, _27._m3[5u].x);//云边缘光
                //_m3[5]	2.00, 1.00, 0.00, 1.00
                float cloudRim/*_499*/ = (cloudTex.y <= 0.0) ? 0.0 : pow(cloudTex.y, 2/*_27._m3[5u].x*/)/*_493*/;
                float3 cloudRimColor/*_505*/ = lerp(mixedCloudColor/*_389*/, rimColor, NDotLSquare * cloudRim/*_499*/);// NDOTL*CloudY  lerp两个颜色？




                





                //_m2[4]	0.00, 1.00, 1.00, 0.00
                float3 thunderCloudMixedColor/*_513*/ = thunderColor/*_238*/ + cloudRimColor * 1 /*_27._m2[4u].yyy*/;//第一部分CloudX亮暗相关颜色 + 第二部分CloudY边缘相关颜色

                //_m2[3]	0.00, 0.00, 0.00, 0.00
                //float _521 = abs(0/*_27._m2[3u].x*/ + (-0.01));
                //vec3 _527 = lerp(_505, _513, 0/*bvec3(_27._m2[3u].x >= 0.01)*/);// = _505
                thunderCloudMixedColor/*vec3 _537*/ = lerp(thunderCloudMixedColor, cloudRimColor/*_527*/, _ThunderLerp/*bvec3(_521 > 0.0)*/);// = _527
                float3 TCGrey/*_551 _545*/ = (dot(thunderCloudMixedColor, float3(0.3, 0.59, 0.11))).xxx;// Luminance
                //vec3 _551;// Luminance
                //_551.x = _545;
                //_551.y = _545;
                //_551.z = _545;


                
                //_m2[2]	1.00, 1.00, 0.00, 2.00
                //_m3[5]	2.00, 1.00, 0.00, 1.00
                float ssCoe1/*_558*/ = lerp(min(max(2/*_27._m2[2u].w*/ - 0.5, -0.5), 1.0), 1.0, 0/*_27._m3[5u].z*/);//1
                float ssCoe2/*_567*/ = 1.0 + (-ssCoe1);//0
                float4 finalOriginalColor/*_584 _571*/ = float4(0, 0, 0, 0);
                finalOriginalColor.xyz /*_584*/ = (max(lerp(thunderCloudMixedColor, TCGrey, float3(0, 0, 0)/*vec3(_40)*/), 0.0) * i.additionalColor.www /*_15.www*/) + i.additionalColor.xyz;
                //vec4 _571;
                //_571 = vec4(_584.x, _584.y, _584.z, _571.w);

                //_m2[1]	1.00, 0.50, 1.00, 1.00
                //_m3[6]	2.00, 1.00, 0.00, 0.00
                // finalColor透明度计算
                finalOriginalColor.w = saturate(
                            (
                                (
                                    //smoothstep(0.0, 200000.0, zOffset/*_61.z*/) *  //世界坐标消隐偏移
                                    saturate(lerp(cloudTex.w, lerp(cloudTex.z * 
                                    smoothstep(saturate(ssCoe2 - 0.5), clamp(ssCoe2, 0.01, 1.0), 
                                    tex2D(_RedMask, movedUV/*, sampleLod _50*/).x), cloudTex.z, smoothstep(0.95, 1.0, ssCoe1)), 
                                    smoothstep(-0.5, -0.3, ssCoe1)))
                                ) * 1/*_27._m2[1u].z*/
                            ) * 
                            saturate(
                                    smoothstep(0.0, 1.0, cloudTex.x + 1/*_27._m3[6u].y*/)
                                )
                        );
                

                
                //vec4 _58 = _571;
                //vec3 _645 = mix(_571.xyz, vec3(dot(_571.xyz, vec3(0.299, 0.587, 0.114))), vec3(0/*_46*/));// 原始颜色 灰度 插值
                //_58 = vec4(_645.x, _645.y, _645.z, _58.w);
                //vec3 _656 = mix(_58.xyz, vec3(dot(_58.xyz, vec3(0.299, 0.587, 0.114))), vec3(0/*_40*/));// 原始颜色 灰度 插值
                //_58 = vec4(_656.x, _656.y, _656.z, _58.w);
                finalOriginalColor.xyz/*_58*/ = lerp(finalOriginalColor.xyz, (dot(finalOriginalColor.xyz, float3(0.299, 0.587, 0.114))).xxx, _GreyScale/*_46*/);




                //_m0[3]	1.00, 1.00, 1.00, 1.00
                finalOriginalColor.xyz/*vec3 _664*/ = finalOriginalColor.xyz * 1/*_27._m0[3u].xyz*/;
                //_58 = vec4(_664.x, _664.y, _664.z, _58.w);
                finalOriginalColor.xyz/*vec3 _671*/ = -min(-finalOriginalColor.xyz, (0).xxx);
                //return (1).xxxx;
                return finalOriginalColor;
                //_58 = vec4(_671.x, _671.y, _671.z, _58.w);
                //_18 = _58;
            }

            ENDHLSL
        }
        
    }
}

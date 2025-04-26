Shader "JRMFOWCloud/FOWRayMarchingShaderLab"
{
    Properties
    {
        [Header(_________Base_________)]
		_CloudBottom("Cloud Bottom", Float) = 5
		_CloudTop("Cloud Top", Float) = 25

		_CloudTopScaleOffset("Cloud Top Scale Offset", Vector) = (0.00389, 0.00389, 1.36221, -0.89758)

		[HDR]_InsideStartColor("Inside Start Color", Color) = (3.33314, 3.18989, 2.68852, 1.00)
		[HDR]_OutsideStartColor("Outside Start Color", Color) = (2.23462, 2.89121, 3.50918, 1.00)
		_InsideCloudColor("Inside Cloud Color", Color) = (0.05514, 0.2857, 0.5566, 1.00)
		_OutsideCloudColor("Outside Cloud Color", Color) = (0.03348, 0.13749, 0.248, 1.00)

		_CloudIntensity("Cloud Intensity", Float) = 5.53
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" }
        //Cull Off
        //Blend SrcAlpha OneMinusSrcAlpha
        //ZWrite Off

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
                //float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 positionSS : TEXCOORD0;
            };
            
            sampler2D _FOWHeightRenderTexture;
            sampler2D _CameraDepthTexture;
			
			
            CBUFFER_START(UnityPerMaterial)
				float _CloudBottom;
				float _CloudTop;

				float4 _CloudTopScaleOffset;

				half4 _InsideStartColor;
				half4 _OutsideStartColor;
				half4 _InsideCloudColor;
				half4 _OutsideCloudColor;

				float _CloudIntensity;
            CBUFFER_END

            Varyings vert (Attributes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                //cb0_v21 -1.00, 10.00, 1100.00, 0.00091    _ProjectionParams
			    //positionCS.y = -positionCS.y /*cb0[21].x*/;

			    //r1.xzw = positionCS.xwy * float3(0.5, 0.5, 0.5);

			    ////o1.zw = r0.zw;
       //         o.posVec.zw = o.positionCS.zw;
			    ////o1.xy = r1.zz + r1.xw;
       //         o.posVec.x = 0.5 * (o.positionCS.w + o.positionCS.x);
       //         o.posVec.y = 0.5 * (o.positionCS.w - o.positionCS.y);
				o.positionSS = ComputeScreenPos(o.positionCS);
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
				/* cb0_v122前为unity内置变量    cb0_v122后为用户定义变量 */

					//r0.xy = v1.xy/v1.ww;
					float2 screenUV = i.positionSS.xy / i.positionSS.ww;

					//r0.xy = r0.xy*float2(2.0, 2.0) + float2(-1.0, -1.0);
					float2 posNDCXY = screenUV * 2 - 1;

					//float4 r0 = float4(screenUV.x, screenUV.y, 0, 0);
					float4 r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12;

					// cb0_v38 0.00, 0.26795, 0.00, 0.00 
					//r0.yzw = r0.yyy * float3(0.00, 0.26795, 0.00);//cb0[38].xyz;
					// cb0_v37 0.47635, 0.00, 0.00, 0.00 
					//float4 viewPos;
					//// Matrix Transform  2D -> 3D    posNDCXY映射
					//viewPos.xyz/*r0.xyz*/ = /*cb0[37].xyz*/ posNDCXY.xxx * float3(_ScreenUVXScale, 0.00, 0.00) + posNDCXY.yyy * float3(0.00, _ScreenUVYScale, 0.00);
					//// cb0_v40 0.00, 0.00, -1.00, 0.05045
					//viewPos.xyz = viewPos.xyz/*r0.xyz*/-/*cb0[40].xyz*/float3(0.00, 0.00, -1.00);


					float4 viewPos;
					float4x4 transCamInvProj = transpose(unity_CameraInvProjection);
					viewPos.xyz = transCamInvProj[0].xyz * posNDCXY.x + transCamInvProj[1] * posNDCXY.y - transCamInvProj[3].xyz;







					//// Matrix Transform Rotate 40 degrees around X
					//// cb0_v46 0.00, 0.76604, 0.64279, 0.00
					//r1.xyz = viewPos.yyy * float3(0.00, 0.76604, 0.64279)/*cb0[46].xyz*/;
					//// cb0_v45 1.00, 0.00, 0.00, 0.00
					//viewPos.xyw = /*cb0[45].xyz*/  float3(1.00, 0.00, 0.00)*viewPos.xxx + r1.xyz;
					//// cb0_v47 0.00, -0.64279, 0.76604, 0.00
					//viewPos.xyz = /*cb0[47].xyz*/float3(0.00, -0.64279, 0.76604)*viewPos.zzz + viewPos.xyw;

					//float rotateAngle = _RotateAngle;
					//rotateAngle = rotateAngle / 180 * PI;
					//float cosR = cos(rotateAngle);
					//float sinR = sin(rotateAngle);
					//float3x3 matrixRotate = float3x3(float3(1, 0, 0), float3(0, cosR, -sinR), float3(0, sinR, cosR));//按行写
					//viewPos.xyz = mul(matrixRotate, viewPos.xyz);



					float4 positionWS;
					float3x3 cam2WorldRotate = float3x3(unity_CameraToWorld[0].xyz, unity_CameraToWorld[1].xyz, unity_CameraToWorld[2].xyz);
					positionWS.xyz = mul(cam2WorldRotate, viewPos.xyz);












					// normalize
					////r0.w = dot(r0.xyzx, r0.xyzx);
					float posLengthWS /*positionWS.w*/ = length(positionWS.xyz);
					//r1.x = rsqrt(positionWS.w);
					//positionWS.xyz = positionWS.xyz * r1.xxx;
					//positionWS.xyz = normalize(positionWS.xyz);
					float3 posDirWS = normalize(positionWS.xyz);

					// pixel coordinates
					float2 pixelCoords /*r1.xy*/ = i.positionCS/*v0*/.xy + float2(0.5, 0.5);
					//cb0_v128 5.00, 25.00, 0.00104, 0.00185      zw 1/TexelSize 1/960  1/540
					float2 pixelUV /*r1.xy*/ = float2(pixelCoords.x / 1920, pixelCoords.y / 1080);//float2(0.00104, 0.00185);//cb0[128].zw;

					//Linear Depth
					//r1.xyzw = tex2D(_CameraDepthTexture, pixelUV).xyzw; //_CameraDepthTexture;
					//cb0_v23 109.00, 1.00, 0.09909, 0.00091  zBufferParam
					//r1.x = /*cb0[23].z*/ 0.09909 *r1.x + 0.00091 /*cb0[23].w*/;
					//r1.x = 1.0/r1.x;
					float linearDepth /*r1.x*/ = LinearEyeDepth(tex2D(_CameraDepthTexture, pixelUV).x, _ZBufferParams);


					//positionWS.w = sqrt(positionWS.w);
					//positionWS.w = posLengthWS * linearDepth;
					// cb0_v20 -221.75, 112.48785, 199.44223, 0.00
					// O + tD
					float3 focusPoint/*r1.xyz*/ = posDirWS.xyz * posLengthWS * linearDepth + _WorldSpaceCameraPos.xyz;//float3(-221.75, 112.48785, 199.44223)/*cb0[20].xyz*/;
					// cb0_v128 5.00, 25.00, 0.00104, 0.00185 
					//positionWS.w = /*cb0[128].y*/_CloudHeight - 0.03;
					int isBeyondCloud = focusPoint.y >= _CloudTop - 0.03;

					float4 finalColor;

					
					if (isBeyondCloud != 0) {
						finalColor.xyzw = float4(0, 0, 0, 0);
						return finalColor;
					}
					float2 camCloudDistY /*r2.xy*/ = float2(_CloudTop - _WorldSpaceCameraPos.y, _CloudBottom - _WorldSpaceCameraPos.y);// -cb0[20].yy + cb0[128].yx;
					float2 camCloudDist = camCloudDistY.xy / posDirWS.yy;//相似三角形,cam距离Cloud上下层
					//视线与云上下层交点
					float3 cloudTopPoint /*r2.xzw*/ = posDirWS.xyz * camCloudDist.x + _WorldSpaceCameraPos.xyz;//float3(-221.75, 112.48785, 199.44223);//cb0[20].xyz;
					float3 cloudBottomPoint /*positionWS.xzw*/ = posDirWS.xyz * camCloudDist.y + _WorldSpaceCameraPos.xyz;//float3(-221.75, 112.48785, 199.44223);//cb0[20].xyz;
					//r1.w = positionWS.z < r1.y;
					//突破云下层clamp
					focusPoint.xyz /*positionWS.xzw*/ = cloudBottomPoint.y < focusPoint.y ? focusPoint.xyz : cloudBottomPoint.xyz;



					float posDirWSY /*positionWS.y*/ = abs(posDirWS.y) * 0.8 + 0.8;


					//进入云层
					float3 enterCloudVec = focusPoint.xyz - cloudTopPoint.xyz;



					//步进方向
					//r1.x = dot(r0.xzwx, r0.xzwx);
					float marchingDist /*r1.x*/ = min(length(enterCloudVec.xyz) * 0.02, 5.0);
					//r1.x = dot(enterCloudVec.xyz, enterCloudVec.xyz);
					//r1.x = sqrt(r1.x);
					//r1.y = 1.0/r1.x;
					//enterCloudVec.xyz = enterCloudVec.xyz * r1.yyy;
					enterCloudVec.xyz = normalize(enterCloudVec.xyz);
					//r1.x = r1.x * 0.02;
					//r1.x = min(r1.x, 5.0);
					enterCloudVec.xyz = enterCloudVec.xyz * marchingDist;


					// cb0_v129 0.00389, 0.00389, 1.36221, -0.89758
					cloudTopPoint.xy/*r2.xz*/ = /*r2.xw*/cloudTopPoint.xz * _CloudTopScaleOffset.xy + _CloudTopScaleOffset.zw;//float2(0.00389, 0.00389) /*cb0[129].xy*/ + float2(1.36221, -0.89758)/*cb0[129].zw*/;
					// cb0_v128 5.00, 25.00, 0.00104, 0.00185 
					//r1.y = _CloudTop - _CloudBottom;/*-cb0[128].x + cb0[128].y*/
					//r3.y = 1.0 / _CloudTop - _CloudBottom;
					//r3.xz = _CloudTopScaleOffset.xy;// cb0[129].xy;
					float3 scaledCloud = float3(_CloudTopScaleOffset.x, 1.0 / (_CloudTop - _CloudBottom), _CloudTopScaleOffset.y);
					//r1.yzw = enterCloudVec.xyz * scaledCloud.xyz;
					//r2.y = 1.0;
					//r1.yzw = r1.yzw*float3(0.5, 0.5, 0.5) + float3(cloudTopPoint.x, 1, cloudTopPoint.y) /*r2.xyz*/;
					// cb0_v132 3.33314, 3.18989, 2.68852, 1.00 
					//cb0_v133 0.05514, 0.2857, 0.5566, 1.00 
					//cb0_v134 2.23462, 2.89121, 3.50918, 1.00 
					//cb0_v135 0.03348, 0.13749, 0.248, 1.00 

					half4 outsideColor /*r2*/ = _OutsideStartColor.rgba - _OutsideCloudColor.rgba;  //cb0[134].xyzw-cb0[135].xyzw;
					half4 insideColor /*r4*/ = _InsideStartColor.rgba - _InsideCloudColor.rgba;  //cb0[132].xyzw-cb0[133].xyzw;
					//r5.w = 1.0;
					//r6.xyzw = float4(0, 0, 0, 0);
					float4 finalColor1 = float4(0, 0, 0, 0);
					//r5.xyz = float3(0, 0, 0);
					float4 tempColor = float4(0, 0, 0, 1);
					//r8.w = 0;
					float4 finalColor2 = float4(0, 0, 0, 0);
					//占比/缩放  步进点
					float3 marchingPoint /*r7.xyz*/ = enterCloudVec.xyz * scaledCloud.xyz * float3(0.5, 0.5, 0.5) + float3(cloudTopPoint.x, 1, cloudTopPoint.y); //r1.yzw;
					int counter /*r3.w*/ = 0;
					//r7.w = 0;
					float colorSign = 0;
					float4 fowHeight/*r9*/;
					float4 currentColor/*r10*/;
					[loop]
					while(true) {
						//r9.x = r3.w >= 50;
						colorSign = 0;
						if (counter >= 50) break;
						fowHeight.xyz = tex2D(_FOWHeightRenderTexture, marchingPoint.xz).xyz; //Fog Camera Height;
						fowHeight.w = saturate(marchingPoint.y);//步进点Y分量占云层厚度比例 0.5-1
						fowHeight.x = saturate(fowHeight.x - fowHeight.w);
						//r10.x = 0.0 < r9.x;
						if (fowHeight.x > 0.0) {
							fowHeight.y = fowHeight.y * 0.75 + 0.25;
							//r10.x = fowHeight.w + 0.03;
							//r10.x = 2 * (fowHeight.w + 0.03);//r10.x + r10.x;
							//r10.x = min(fowHeight.x, 2 * (fowHeight.w + 0.03));
							// cb0_v131 5.53, 257.1871, -350.34351, 230.84621
							//r10.x = min(fowHeight.x, 2 * (fowHeight.w + 0.03)) * _CloudIntensity;//5.53/*cb0[131].x*/;
							currentColor.x = fowHeight.y * min(fowHeight.x, 2 * (fowHeight.w + 0.03)) * _CloudIntensity;//5.53/*cb0[131].x*/;
							//fowHeight.y = fowHeight.y * 0.5 + 0.5;
							//fowHeight.y = saturate((fowHeight.y * 0.5 + 0.5) * r10.x);
							fowHeight.y = 1.0 - saturate((fowHeight.y * 0.5 + 0.5) * currentColor.x);
							currentColor.x = 1.0 - finalColor2.w;
							fowHeight.z = 1.0 - fowHeight.z;
							fowHeight.y = fowHeight.y * fowHeight.y;
							fowHeight.w = -fowHeight.w*0.5 + 1.0;
							fowHeight.y = fowHeight.w * fowHeight.y;
							//cb0_v135 0.03348, 0.13749, 0.248, 1.00 
							float4 currentOutColor/*r11.xyzw*/ = fowHeight.y * outsideColor.xyzw + _OutsideCloudColor.rgba;// float4(0.03348, 0.13749, 0.248, 1.00);//cb0[135].xyzw;
							//cb0_v133 0.05514, 0.2857, 0.5566, 1.00 
							float4 currentInColor/*r12.xyzw*/ = fowHeight.y * insideColor.xyzw + _InsideCloudColor.rgba;//float4(0.05514, 0.2857, 0.5566, 1.00);//cb0[133].xyzw;
							currentOutColor.xyzw = currentOutColor.xyzw - currentInColor.xyzw;
							currentOutColor.xyzw = fowHeight.z * currentOutColor.xyzw + currentInColor.xyzw;
							currentColor.xyzw = currentColor.x * currentOutColor.xyzw;
							currentColor.xyzw = marchingDist * currentColor.xyzw;
							fowHeight.xyzw = fowHeight.x * currentColor.xyzw;
							finalColor2.xyz = tempColor.xyz;
							finalColor2.xyzw += fowHeight.xyzw * posDirWSY/*positionWS.yyyy*/;
							//fowHeight.x = 0.99 < r8.w;
							if (finalColor2.w > 0.99) {
								fowHeight.y = 1.0/finalColor2.w;
								tempColor.xyz = finalColor2.xyz * fowHeight.y;
								finalColor1.xyzw = tempColor.xyzw;
								finalColor2.w = 1.0;
								colorSign = -1;
								break;
							}
							tempColor.xyz = finalColor2.xyz;
							colorSign = fowHeight.x;
						} else {
							colorSign = 0;
						}
						marchingPoint.xyz += enterCloudVec.xyz * scaledCloud.xyz;
						counter += 1;
						finalColor1.xyzw = float4(0, 0, 0, 0);
					}




					//enterCloudVec.x = -r8.w + 2.0;
					finalColor2.xyz = (2.0 - finalColor2.w) * tempColor.xyz;

					finalColor.xyzw = colorSign ? finalColor1.xyzw : finalColor2.xyzw;
					return finalColor;
            }
            ENDHLSL
        }
        
    }
}

Shader "JRMFOWCloud/FOWCompositeShaderLab"
{
    Properties
    {
        

    
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
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };
            
            sampler2D _FOWCloudRenderTexture;
            

            Varyings vert (Attributes i)
            {
                Varyings o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                //r0.xyzw = v0.xyxy + float4(1.0, 1.0, -1.0, 1.0);
			    //// cb0_v4 1920.00, 1080.00, 1.00052, 1.00093     _ScreenParams
			    //r1.xyzw = float4(1.0, 1.0, 1.0, 1.0)/cb0[4].xyxy;
			    //r0.xyzw = r0.xyzw * r1.xyzw;
                float4 screenUVGroup /*r0*/ = (i.positionCS.xyxy + float4(1.0, 1.0, -1.0, 1.0)) / _ScreenParams.xyxy;

			    float4 fowCloudColor1 /*r2.xyzw*/ = tex2D(_FOWCloudRenderTexture, screenUVGroup.zw).xyzw;
			    float4 fowCloudColor2 /*r0.xyzw*/ = tex2D(_FOWCloudRenderTexture, screenUVGroup.xy).xyzw;

			    //r2.xyz = r2.www * r2.xyz;
			    //r0.xyz = r0.xyz*r0.www + r2.xyz;
                float3 fowCloudColor/*r0.xyz*/ = fowCloudColor1.xyz * fowCloudColor1.w + fowCloudColor2.xyz * fowCloudColor2.w;


			    //r3.xyzw = v0.xyxy + float4(1.0, -1.0, -1.0, -1.0);
			    //r3.xyzw = r1.xyzw * r3.xyzw;
                screenUVGroup /*r3*/ = (i.positionCS.xyxy + float4(1.0, -1.0, -1.0, -1.0)) / _ScreenParams.xyxy;
			    //r1.xy = r1.zw * v0.xy;
                float2 baseUV /*r1.xy*/ = i.positionCS.xy / _ScreenParams.xy;


			    float4 fowCloudColor3/*r1.xyzw*/ = tex2D(_FOWCloudRenderTexture, baseUV).xyzw;
			    float4 fowCloudColor4/*r4.xyzw*/ = tex2D(_FOWCloudRenderTexture, screenUVGroup.xy).xyzw;
			    float4 fowCloudColor5/*r3.xyzw*/ = tex2D(_FOWCloudRenderTexture, screenUVGroup.zw).xyzw;
			    //r0.xyz = r4.xyz*r4.www + r0.xyz;
			    //r0.xyz = r3.xyz*r3.www + r0.xyz;
                fowCloudColor /*r0.xyz*/ += fowCloudColor4.xyz * fowCloudColor4.w + fowCloudColor5.xyz * fowCloudColor5.w;

			    //r2.x = r2.w + r0.w;
                float alphaAdd = fowCloudColor1.w + fowCloudColor2.w;

			    //r0.w = max(r2.w, r0.w);
                float maxAlpha1 = max(fowCloudColor1.w, fowCloudColor2.w);

			    //r2.x = r4.w + r2.x;
                alphaAdd += fowCloudColor4.w;

			    //r2.y = max(r3.w, r4.w);
                float maxAlpha2 = max(fowCloudColor5.w, fowCloudColor4.w);

			    //r2.x = r3.w + r2.x;
                alphaAdd += fowCloudColor5.w;

			    //r0.w = max(r0.w, r2.y);
                float maxAlpha = max(maxAlpha1, maxAlpha2);

			    //r0.w = -r1.w + r0.w;
                maxAlpha -= fowCloudColor3.w;

			    //r0.w = 0.3 < abs(r0.w);
                maxAlpha = step(0.3, abs(maxAlpha));



			    //r2.y = 1.0/r2.x;
                float alphaReverse = 1 / max(alphaAdd, 0.001);
			    //r2.x = r2.x * 0.25;
                alphaAdd *= 0.25;
			    //r3.w = max(fowCloudColor3.w/*r1.w*/, alphaAdd/*r2.x*/);
			    //r3.xyz = /*r0.xyz*/fowCloudColor * alphaReverse;//r2.yyy;
                float4 otherCloudColor = float4(fowCloudColor.xyz * alphaReverse, max(fowCloudColor3.w, alphaAdd));

			    //o0.xyzw = r0.wwww;
                float4 finalColor;
                finalColor = (maxAlpha != 0) ? otherCloudColor : fowCloudColor3;
			    return finalColor;
            }
            ENDHLSL
        }
        
    }
}

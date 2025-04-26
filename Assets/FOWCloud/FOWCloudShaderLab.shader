Shader "JRMFOWCloud/FOWCloudShaderLab"
{
    Properties
    {
        [Header(_________Base_________)]
        _UVScaleOffset("UV Scale Offset", Vector) = (257.1871, 257.1871, -350.34351, 230.84621)
        _FowMaskScaleOffset("Fow Mask Scale Offset", Vector) = (0.00195, 0.00195, 1.04883, -0.49023)
        _ModifiedUVOffset("Modified UV Offset", Vector) = (0, -5, 0, 0)
        _CloudNoiseDoubleScale("Cloud Noise Double Scale", Vector) = (0.0039, 0.0041, 0.0058, 0.0057)
        _CloudNoiseDoubleOffset("Cloud Noise Double Offset", Vector) = (-0.0014, 0.00, -0.016, -0.0045)
        _CloudFogFactor("Cloud Fog Factor", Vector) = (0.645, 0.313, 0, 0)
        _FinalCloudNoiseFactor("Final Cloud Noise Factor", Vector) = (0.172, 0.136, 0.343, 0.868)

        [Header(_________Texture_________)]
        [NoScaleOffset]_FowMask("Fow Mask", 2D) = "white" {}
        [NoScaleOffset]_CloudNoise("Cloud Noise", 2D) = "white" {}
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
                float2 uv : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            
            sampler2D _FowMask;
            sampler2D _CloudNoise;

            CBUFFER_START(UnityPerMaterial)
                float4 _UVScaleOffset;
                float4 _FowMaskScaleOffset;
                float2 _ModifiedUVOffset;
                float2 _CloudFogFactor;
                float4 _CloudNoiseDoubleScale;
                float4 _CloudNoiseDoubleOffset;
                float4 _FinalCloudNoiseFactor;
            CBUFFER_END

            Varyings vert (Attributes i)
            {
                Varyings o;
                o.uv = i.uv * _UVScaleOffset.xy + _UVScaleOffset.zw;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                //float4 r0 = float4(1, 1, 0, 0);
                float4 defaultVec0 = float4(1, 1, 0, 0);
			    //cb0_v127 0.00195, 0.00195, 1.04883, -0.49023
			    //r1.xy = i.uv.xy*float2(0.00195, 0.00195)/*cb0[127].xy*/ + float2(1.04883, -0.49023)/*cb0[127].zw*/;
			    float2 fowMaskUV/*r1.xy*/ = i.uv.xy * _FowMaskScaleOffset.xy * 0.001 + _FowMaskScaleOffset.zw;

                
			    //r1.z = min(r1.y, r1.x);
			    //r1.z = step(0.0, r1.z);//r1.z = r1.z >= 0.0; // step
			    //r1.w = max(r1.y, r1.x);

                float fowMaskUVMin = min(fowMaskUV.x, fowMaskUV.y);
                fowMaskUVMin = step(0, fowMaskUVMin);
                float fowMaskUVMax = max(fowMaskUV.x, fowMaskUV.y);


			    float4 fowMask /*r2.xyzw*/ = tex2D(_FowMask, fowMaskUV).xyzw; //fow mask;
			    //假如所有均为未解锁区域 fowmask : 1, 1, 0, 1/0?
			    //r2.xyzw = r2.xyzw + float4(-1.0, -1.0, -0.0, -0.0);
			    fowMask -= float4(1.0, 1.0, 0.0, 0.0);


			    float fowMaskUVMaxMin /*r1.x*/ = step(fowMaskUVMax, 1.0);//r1.x = 1.0 >= r1.w; // step
			    //r1.xz = r1.xz & float2(0x3f800000, 0x3f800000) // 0x3f800000=1.0, maybe means: if (r1.xz==0xFFFFFFFF) r1.xz=1.0;
			    fowMaskUVMaxMin/*r1.x*/ = fowMaskUVMaxMin/*r1.x*/ * fowMaskUVMin;
			    //cb0_v128 1.00, 10.93, -0.03, -0.005
			    fowMaskUVMaxMin *= 1/*cb0[128].x*/;


			    float4 tempVec /*r1.xyzw*/ = /*r1.xxxx*/  fowMaskUVMaxMin * fowMask /*r2.xyzw*/ + float4(1.0, 1.0, 0.0, 0.0);
			    defaultVec0.xyzw = defaultVec0.xyzw - tempVec.xyzw;

			    float uvXStep /*r2.x*/ = step(0.0, i.uv.x);//r2.x = i.uv.x >= 0.0;
			    //r2.x = r2.x & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r2.x==0xFFFFFFFF) r2.x=1.0;
			    defaultVec0 /*r0.xyzw*/ = uvXStep * defaultVec0.xyzw + tempVec.xyzw;


			    //cb0_v135 0.645, 0.313, -5.00, 1.00
			    //r1.y = i.uv.y-(-5)/*cb0[135].z*/;
			    //r1.x = i.uv.x;
                float2 modifiedUV = float2(i.uv.x + _ModifiedUVOffset.x, i.uv.y + _ModifiedUVOffset.y);

			    //cb0_v132 0.0039, 0.0041, 0.0058, 0.0057
			    //r1.xyzw = /*r1.xyxy*/ modifiedUV.xyxy * _CloudNoiseDoubleScale.xyzw;//cb0[132].xyzw;
			    //cb0_v133 -0.0014, 0.00, -0.016, -0.0045
                //cb0_v15 1.8049, 36.09803, 72.19606, 108.29409     _Time
			    float4 cloudNoiseUV /*r1.xyzw*/ = _Time.y * _CloudNoiseDoubleOffset.xyzw /*cb0[15].yyyy*cb0[133].xyzw*/ + modifiedUV.xyxy * _CloudNoiseDoubleScale.xyzw;
			    float2 cloudNoise1 /*r2.xyzw*/ = tex2D(_CloudNoise, cloudNoiseUV.zw).xy; //cloud noise;
			    float2 cloudNoise2 /*r1.xyzw*/ = tex2D(_CloudNoise, cloudNoiseUV.xy).xy; //cloud noise;
			    //r1.zw = -r1.yx + r2.yx;
                float2 cloudNoise = cloudNoise1.yx - cloudNoise2.yx;

			    //cb0_v135 0.645, 0.313, -5.00, 1.00
			    //r1.xy = saturate(float2(0.645, 0.313)/*cb0[135].xy*/*r1.zw + r1.yx);
			    cloudNoise /*r1.xy*/ = saturate(_CloudFogFactor.xy * cloudNoise /*r1.zw*/ + cloudNoise2.yx /*r1.yx*/);


                
                float4 finalCloudNoise;
			    //cb0_v134 0.343, 0.172, 0.868, 0.136       defaultVec0 1 1 0 0 
			    finalCloudNoise.yz /*r1.yz*/ = /*r1.yy*/ cloudNoise.yy * _FinalCloudNoiseFactor.xy;// float2(0.172, 0.136)/*cb0[134].yw*/;
			    //r1.x = r1.x-1.0;
                cloudNoise.x -= 1.0;
			    finalCloudNoise.xw /*r1.xw*/ = /*r1.xx*/ cloudNoise.xx * _FinalCloudNoiseFactor.zw;// float2(0.343, 0.868)/*cb0[134].xz*/;
			    finalCloudNoise.y = defaultVec0.z * finalCloudNoise.y;
			    finalCloudNoise.x = finalCloudNoise.x * defaultVec0.y + finalCloudNoise.y;

			    float2 tempVec2 /*r2.xy*/ = -defaultVec0.wx + float2(1.0, 1.0);
			    finalCloudNoise.y = tempVec2.x * 0.15;
			    defaultVec0.y = -finalCloudNoise.w * defaultVec0.y + tempVec2.y;

                float4 finalColor;
			    finalColor.y = -finalCloudNoise.z * defaultVec0.z + defaultVec0.y;
			    defaultVec0.x = defaultVec0.x * 0.85 + finalCloudNoise.y;
			    finalColor.z = defaultVec0.w;
			    finalColor.x = finalCloudNoise.x + defaultVec0.x;
			    finalColor.w = 0;
			    return finalColor;
            }
            ENDHLSL
        }
        
    }
}

Shader "Jeremy/Effect/Billboard"
{
    Properties
    {
        [HDR]_Color("Color",Color) = (1,1,1,1)
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
        [Header(Row(X)  Cloum(Y)  Frame(Z)  null(W))]
        [Space(10)]
        [Enum(Billboard,1,VerticalBillboard,0)]_BillboardType("BillboardType",int)=1
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "LightMode"="UniversalForward" "Queue"="Geometry" "IgnoreProject"="True"}

        Pass
        {
            Cull Back
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //pragmas

            #pragma target 3.0
            // #pragma target 2.0
            // #pragma multi_compile_instancing

            //Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            
            CBUFFER_START(UnityPerMaterial)
                half4 _Color;
                int _BillboardType;
            CBUFFER_END

            TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD;
            };

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                //目的是为了构建旋转后的基向量在模型本地空间下的坐标
                    //viewDir相当于是我们自己定义了Z基向量，把相机从世界空间转换到本地空间，而本地空间就是以我们馍丁的原点为中心点的坐标，此时相机转换后的位置就是我们要的向量了
                    float3 viewDir = mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos,1)).xyz;
                    //对向量归一化，求出基
                    viewDir = normalize(viewDir);
                    viewDir.y *= _BillboardType;
                    //假设向上的向量为世界坐标系下的上向量
                    float3 upDir = float3(0,1,0);
                    //利用叉积（左手法则）计算出向右的向量
                    float3 rightDir = normalize(cross(viewDir,upDir));
                    upDir = cross(rightDir,viewDir);

                    //矩阵写法
                    // float4x4 M = float4x4(
                    // rightDir.x, upDir.x, viewDir.x, 0,
                    // rightDir.y, upDir.y, viewDir.y, 0,
                    // rightDir.z, upDir.z, viewDir.z, 0,
                    // 0,0,0,1
                    // );
                    // float3 newVertex = mul(M, v.positionOS);

                    //向量乘法写法
                float3 newPositionOS = rightDir*v.positionOS.x + upDir*v.positionOS.y + viewDir*v.positionOS.z;

                o.positionCS = TransformObjectToHClip(newPositionOS);
                o.uv = v.uv;
                return o;
            }

            half4 frag(Varyings i) : SV_TARGET
            {
                half3 c = _Color.rgb;
                half3 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb;
                c *= mainTex;
                return half4(c,1);
            }

            ENDHLSL

        }
    }
    Fallback "Hidden/Shader Graph/FallbackError"
}

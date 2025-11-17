Shader "Jeremy/SDF/SDF2DInteraction"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVScale("UV Scale", Range(0,100)) = 1
        _Smooth("Smooth", Range(0,1)) = 1
        _Ball_A_Center("Ball A Center", Vector) =(0,0,0,0)
        _Ball_A_Radius("Ball A Radius", Range(0,1)) = 0 

        _Ball_B_Center("Ball B Center", Vector) = (0,0,0,0)
        _Ball_B_Radius("Ball B Radius", Range(0,1)) = 0

        [Toggle(_CONTOURLINE)] _ContourLine("ContourLine", float) = 0
        _ContourLineFactor("ContourLine Factor", Range(2,30)) = 10

        _CircleColor("Circle Color", Color) = (1,1,1,1)
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _EdgeWidth("Edge Width", Range(0,1)) = 0.1
        

        _RectMain("Rect Main", Vector) = (0, 0, 0, 0)
        _RectA("Rect A", Vector) = (0, 0, 0, 0)
        _RectB("Rect B", Vector) = (0, 0, 0, 0)
        _RectC("Rect C", Vector) = (0, 0, 0, 0)
        _RectD("Rect D", Vector) = (0, 0, 0, 0)
        _RoundRectRatio("Round Rect Ratio", Range(0.0, 1.0)) = 1.0
        _RectALerp("RectA Lerp", Range(0.0, 1.0)) = 0.0
        _RectMainLerp("RectMain Lerp", Range(0.0, 1.0)) = 0.0

    }
    SubShader
    {
        Tags{
            "Queue" = "Transparent"
        }
        Pass
        {
            Blend One OneMinusSrcAlpha
            ZTest Always
            ZWrite Off
            Cull Off
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            #pragma shader_feature _CONTOURLINE

            #pragma vertex vert
            #pragma fragment frag

            float4 _Ball_A_Center;
            float _Ball_A_Radius;
            float4 _Ball_B_Center;
            float _Ball_B_Radius;

            float _UVScale;
            half _Smooth;
            half _ContourLineFactor;

            half4 _CircleColor;
            half4 _EdgeColor;
            half _EdgeWidth;

            float4 _RectMain;
            float4 _RectA;
            float4 _RectB;
            float4 _RectC;
            float4 _RectD;
            float _RoundRectRatio;
            float _RectALerp;
            float _RectMainLerp;

            struct Attributes {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varings {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varings vert(Attributes input) {
                Varings o;
                float3 position = input.positionOS.xyz;
                o.positionCS = TransformObjectToHClip(position);
                o.uv = input.uv;
                return o;
            }

            float sdfCircle(float2 coord, float2 center, float radius)
            {
	            float2 offset = coord - center;
	            return sqrt((offset.x * offset.x) + (offset.y * offset.y)) - radius;
            }

            float sdfRoundRect(float2 coord,  float2 center, float width, float height, float r)
            {
                float2 d = abs(coord - center) - float2(width, height);
                return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - r;
            }


            float sdfTestMin( float a, float b )
            {
                return (a<b) ? a : b;
            }

            float smin( float a, float b, float k )
            {
                k *= 2.0;
                float x = b-a;
                return 0.5*( a+b-sqrt(x*x+k*k) );
            }

            half4 DrawContourLine(float sdf_value, float factor){
                float sdf = sdf_value * factor; //扩大取值范围
                float seg = floor(sdf); //离散化
                float lerpValue = seg / 8.0;
                half4 color = lerp(half4(0.7,0.5,0.3,1), half4(0.3,0.4,0.4,1), lerpValue);
                seg = sdf - seg; 
                color = lerp(half4(0,0,0,1), color, smoothstep(0, 0.1, 0.5 - abs(seg - 0.5)));
                color = lerp(half4(1,0,0,1), color, step(0.1, abs(sdf))); //查找边缘
                return color;
            }

            half4 frag(Varings i) : SV_TARGET{
                //float ratio = _ScaledScreenParams.x / _ScaledScreenParams.y;
                //float2 uv = i.positionCS.xy / _ScaledScreenParams.xy;
                ////half2 uv = i.uv - 0.5; //将quad uv 原点从左下角移动到几何中心
                //float dis_A = length((uv - _Ball_A_Center.xy) * float2(ratio, 1) * _UVScale) - _Ball_A_Radius;
                //float dis_B = length((uv - _Ball_B_Center.xy) * float2(ratio, 1) * _UVScale) - _Ball_B_Radius;
                //float sdf_value = smin(dis_A, dis_B, _Smooth);
                //#ifdef _CONTOURLINE
                //    return DrawContourLine(sdf_value, _ContourLineFactor);
                //#else
                //    half circle = 1 - step(0, sdf_value);
                //    half edge = 1 - step(_EdgeWidth, sdf_value);

                //    half4 color = lerp(_EdgeColor  * edge, _CircleColor, circle);
                //    return color;
                //#endif



                float ratio = _ScaledScreenParams.x / _ScaledScreenParams.y;
                float2 uv = i.positionCS.xy / _ScaledScreenParams.xy;
                float2 scale = float2(ratio, 1) * _UVScale;
                uv *= scale;
                float disRectMain = lerp(1, sdfRoundRect(uv, float2(_RectMain.x, 1 - _RectMain.y) * scale, _RectMain.z, _RectMain.w, _RoundRectRatio), _RectMainLerp);
                //float disRectMain = sdfCircle(uv, _RectMain.xy * scale, _RectMain.z);
                
                float disRectA = lerp(1, sdfRoundRect(uv, float2(_RectA.x, 1 - _RectA.y) * scale, _RectA.z, _RectA.w, _RoundRectRatio), _RectALerp);
                //float disRectB = sdfRoundRect(uv, _RectB.xy * scale, _RectB.z, _RectB.w, _RoundRectRatio);
                //float disRectC = sdfRoundRect(uv, _RectC.xy * scale, _RectC.z, _RectC.w, _RoundRectRatio);
                //float disRectD = sdfRoundRect(uv, _RectD.xy * scale, _RectD.z, _RectD.w, _RoundRectRatio);
                //float sdfValue = smin(smin(smin(smin(disRectMain, disRectA, _Smooth), disRectB, _Smooth), disRectC, _Smooth), disRectD, _Smooth);
                float sdfValue = smin(disRectMain, disRectA, _Smooth);

                half circle = 1 - step(0, sdfValue);
                half edge = 1 - step(_EdgeWidth, sdfValue);

                half4 color = lerp(_EdgeColor  * edge, _CircleColor, circle);

                return color;


            }

            ENDHLSL
        }
    }
}
Shader "Jeremy/SDF/SDFTemplate"
{
    Properties
    {
		_MainColor("_MainColor", Color) = (1, 1, 1, 1)
        _BackgroundColor("_BackgroundColor", Color) = (1, 1, 1, 1)
        _DistanceThreshold("_DistanceThreshold", Range(0, 1)) = 0.5
        _DistanceSmoothness("_DistanceSmoothness", Range(0,50)) = 1
        _SDFMix("_SDFMix", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "Queue"="Transparent" }
        Pass
        {
            Tags {"LightMode"="UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            CBUFFER_START(UnityPerMaterial)
                half4 _MainColor;
                half4 _BackgroundColor;
                float _DistanceThreshold;
                float _DistanceSmoothness;
                float4 _SDFMix;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            float sdfCircle(float2 coord, float2 center, float radius)
            {
	            float2 offset = coord - center;
	            return sqrt((offset.x * offset.x) + (offset.y * offset.y)) - radius;
            }

            float sdfTorus(float2 coord, float2 center, float radius1, float radius2)
            {
                float2 offset = coord - center;
                return abs(sqrt((offset.x * offset.x) + (offset.y * offset.y)) - radius1) - radius2;
            }

            float sdfEclipse(float2 coord, float2 center, float a, float b)
            {
                float a2 = a * a;
                float b2 = b * b;
                return (b2 * (coord.x - center.x) * (coord.x - center.x) +
                    a2 * (coord.y - center.y) * (coord.y - center.y) - a2 * b2) / (a2 * b2);
            }

            float sdfRect(float2 coord,  float2 center, float width, float height)
            {
                float2 d = abs(coord - center) - float2(width, height);
                return min(max(d.x,d.y),0.0) + length(max(d,0.0));
            }

            float sdfRoundRect(float2 coord,  float2 center, float width, float height, float r)
            {
                float2 d = abs(coord - center) - float2(width, height);
                return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - r;
            }

            float sdfTriangle(float2 coord, float2 center, float radius)
            {
                const float k = sqrt(3.0);
                
                coord -= center;

                coord.x = abs(coord.x) - radius;
                coord.y = coord.y + radius/k;

                if(coord.x + k * coord.y > 0.0) 
                {
                    coord = float2(coord.x - k * coord.y, -k * coord.x - coord.y) / 2.0;
                }

                coord.x -= clamp(coord.x, -2.0 * radius, 0.0);
                return -length(coord)*sign(coord.y);
            }


            float sdfUnion(float a, float b) 
            {
                return min(a, b);
            }

            float sdfDifference(float a, float b) 
            {
                return max(a, -b);
            }

            float sdfIntersection(float a, float b) 
            {
                return max(a, b);
            }

            float sdfMix(float a, float b, float v) 
            {
                return lerp(a, b, saturate(v));
            }

            float sdfTrans1( float a, float b, float k )
            {
                float h = a-b;
                return 0.5*( (a+b) - sqrt(h*h+k) );
            }


            float4 render(float d, float3 color, float stroke) 
            {
	            float anti = fwidth(d) * 1.0;
	            float4 colorLayer = float4(color, 1.0 - smoothstep(-anti, anti, d));
	            if (stroke < 0.000001) {
		            return colorLayer;
	            }

	            float4 strokeLayer = float4(float3(0.05, 0.05, 0.05), 1.0 - smoothstep(-anti, anti, d - stroke));
	            return float4(lerp(strokeLayer.rgb, colorLayer.rgb, colorLayer.a), strokeLayer.a);
            }





            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float2 posVP = i.positionCS.xy;
                float sdfRectValue = sdfRect(posVP, float2(0.4, 0.5) * _ScaledScreenParams.xy, _DistanceThreshold * _ScaledScreenParams.x, _DistanceThreshold * _ScaledScreenParams.x * 0.6);
                float sdfTriValue = sdfTriangle(posVP, float2(0.7, 0.65) * _ScaledScreenParams.xy, _DistanceThreshold * _ScaledScreenParams.x);
                float sdfCircleValue = sdfCircle(posVP, float2(0.5, 0.4) * _ScaledScreenParams.xy, _DistanceThreshold * _ScaledScreenParams.x);


                //float sdfValue = sdfMix(sdfUnion(sdfRectValue, sdfCircleValue), sdfTriValue, _SDFMix.y);
                float sdfValue = sdfMix(sdfMix(sdfRectValue, sdfCircleValue, _SDFMix.x), sdfTriValue, _SDFMix.y);


                sdfValue /= _ScaledScreenParams.x / 2;
                sdfValue *= 20;
                float segment = floor(sdfValue);
                half4 color = lerp(_MainColor, _BackgroundColor, segment/20.0);
                segment = sdfValue - segment;
                // sdf与seg差异大的地方为分界线
                color = lerp(half4(0,0,0,1), color, smoothstep(0, 0.1, 0.5 - abs(segment - 0.5)));
                color = lerp(half4(1,0,0,1), color, step(0.1, abs(sdfValue))); //查找边缘
                return color;

                
                //float edge = smoothstep(6, 16, abs(sdfValue));
                //float edge = step(10, abs(sdfValue));

	            return lerp(_MainColor, _BackgroundColor, smoothstep(-1 * _DistanceSmoothness, _DistanceSmoothness, sdfValue));

             //   float4 layer1 = render(sdfValue, _MainColor.rgb, fwidth(sdfValue) * 5.0);
	            //return lerp(_BackgroundColor, layer1, layer1.a);





                //float2 pixelPos = i.positionCS.xy;

                //float circle = sdfCircle(pixelPos, float2(0.2, 0.5)* _ScreenParams.xy, 100);
                //float circle2 = sdfCircle(pixelPos, float2(0.5, 0.5)* _ScreenParams.xy, 100);
                //float circle3 = sdfCircle(pixelPos, float2(0.8, 0.5)* _ScreenParams.xy, 100);

                //float box = sdfBox(pixelPos, float2(0.2, 0.5)* _ScreenParams.xy, 120, 70);
                //float box2 = sdfBox(pixelPos, float2(0.5, 0.5)* _ScreenParams.xy, 120, 70);
                //float box3 = sdfBox(pixelPos, float2(0.8, 0.5)* _ScreenParams.xy, 120, 70);

                //float unionResult = sdfUnion(circle, box);
                //float diffResult = sdfDifference(circle2, box2);
                //float intersectResult = sdfIntersection(circle3, box3);

                //float4 unionLayer = render(unionResult, float3(0.91, 0.12, 0.39), fwidth(unionResult)* 2.0);
                //float4 diffLayer = render(diffResult, float3(0.3, 0.69, 0.31), fwidth(diffResult)* 2.0);
                //float4 intersectLayer = render(intersectResult, float3(1, 0.76, 0.03), fwidth(intersectResult)* 2.0);

                //float4 col = lerp(_BackgroundColor, unionLayer, unionLayer.a);
                //col *= lerp(_BackgroundColor, diffLayer, diffLayer.a);
                //col *= lerp(_BackgroundColor, intersectLayer, intersectLayer.a);
                //return col;
            }
            ENDHLSL
        }
    }

}

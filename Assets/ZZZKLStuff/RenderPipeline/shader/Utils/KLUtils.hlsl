#ifndef KL_UTILS_INCLUDED
#define KL_UTILS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityInput.hlsl"

///////////////////////////////////////////////////////////////////////////////
//                         Utils Function                                    //
///////////////////////////////////////////////////////////////////////////////

#define PI8 25.1327
#define INV_PI8 0.039789


half LinearStep(half minValue, half maxValue, half val)
{
    return saturate((val - minValue) / (maxValue - minValue));
}

half OcclusionFade(float4 positionCS, float distanceScale, float distanceSensitivity, float2 roleScreenPos)
{
    float cameraDistance = abs(positionCS.w);
    float cameraDistanceFactor = max(0.0, cameraDistance / distanceScale);
    cameraDistanceFactor = pow(cameraDistanceFactor, distanceSensitivity);
    float2 screenUV = positionCS.xy / _ScaledScreenParams.xy;
    float ratio = _ScaledScreenParams.y / _ScaledScreenParams.x;
    float2 sphere = float2(screenUV.x - roleScreenPos.x, (screenUV.y - roleScreenPos.y) * ratio);
    float distanceSS = length(sphere);
    float sphereRange = 1 - 3.33 * distanceSS;
    float sphereRangePow = 2.33 * sphereRange;
    sphereRangePow = sphereRangePow * sphereRangePow;
    sphereRangePow = pow(2.72, sphereRangePow);
    sphereRangePow = 1 / sphereRangePow;
    float result = sphereRange > 0 ? sphereRangePow : 1.0;
    result = abs(sphereRange) > 0.1 ? result : 1.0;
    result = result * cameraDistanceFactor;
    result = saturate(result);
    float noise = InterleavedGradientNoise(float2(positionCS.x * 0.5, positionCS.y), 0);
    result = noise + result - 1.0;
    return result;
}

float2 PolarCoordinates(float2 uv, float2 center, float radialScale, float lengthScale)
{
    float2 delta = uv - center;
    float radius = length(delta) * 2 * radialScale;
    float angle = atan2(delta.x, delta.y) * 0.16 * lengthScale;
    return float2(radius, angle);
}

///////////////////////////////////////////////////////////////////////////////
//                         Noise Function                                    //
///////////////////////////////////////////////////////////////////////////////
float RandomNoise(float2 vec2)
{
	return frac(sin(dot(vec2, float2(12.9898, 78.233))) * 43758.5453);
}

float RandomNoiseV2(float2 vec2)
{
	return frac(sin(dot(vec2 , float2(17.13, 3.71))) * 43758.5453);
}

float RandomNoise(float val)
{
	return RandomNoise(float2(val, 1.0));
}

float RandomImageBlockNoise(float2 vec2, float speed)
{
    return RandomNoise(vec2 * floor(_Time.y * speed));
}

float RandomImageBlockNoise(float val, float speed)
{
    return RandomImageBlockNoise(float2(val, 1.0), speed);
}

float RandomImageBlockNoiseV2(float2 vec2, float speed)
{
    return RandomNoiseV2(vec2 * floor(_Time.y * speed));
}














///////////////////////////////////////////////////////////////////////////////
//                         Color Function                                    //
///////////////////////////////////////////////////////////////////////////////
half SimpleLum(half3 linearRgb)
{
    return dot(linearRgb, half3(0.2127, 0.7152, 0.0722));
}

#endif
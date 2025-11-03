#ifndef KL_PP_COMMON_INCLUDED
#define KL_PP_COMMON_INCLUDED

#include "KLUtils.hlsl"

half2 _KLRadialCenter;
half _KLBlurRadius;
int _KLIteration;

half _KLHDIntensity;
float4 _KLHDNoiseTillingSpeed;
TEXTURE2D(_KLHDNoiseTex);
SAMPLER(sampler_KLHDNoiseTex);

half _KLPixelSize;
half _KLPixelRatio;

half _KLRGBSplitIntensity;
half _KLRGBSplitSpeed;

half _KLImageBlockSpeed;
half _KLImageBlockSize;
half _KLImageBlockRatio;

half _KLRdImageBlockLayer1U;
half _KLRdImageBlockLayer1V;
half _KLRdImageBlockLayer2U;
half _KLRdImageBlockLayer2V;
half _KLRdImageBlockSpeed;
half _KLRdImageBlockLayer1Intensity;
half _KLRdImageBlockLayer2Intensity;
half _KLRdImageBlockRGBIntensity;
half _KLRdImageBlockFade;
half _KLRdImageBlockOffset;

float2 _KLBWFCenter;
float _KLBWFRadialScale;
float _KLBWFLengthScale;
float2 _KLBWFSpeed;
TEXTURE2D(_KLBWFTex);
SAMPLER(sampler_KLBWFTex);
half _KLBWFThreshold;
half _KLBWFMix;
half3 _KLBWFColor;

half _KLSLRange;
half _KLSLSmoothIntensity;
half _KLSLSmoothWidth;
half3 _KLSLSmoothColor;
half _KLSLOutlineWidth;
half3 _KLSLOutlineColor;
float4 _KLSLNoiseTillingSpeed;
TEXTURE2D(_KLSLNoiseTex);
SAMPLER(sampler_KLSLNoiseTex);









/*****************Common Textures*****************/
TEXTURE2D_FLOAT(_CustomDepthTexture0);
SAMPLER(sampler_CustomDepthTexture0);

TEXTURE2D(_CustomColorTexture1);
SamplerState rt_linear_clamp_sampler;

/*****************Common Params*****************/
uniform float3 _RoleWorldPos;





///////////////////////////////////////////////////////////////////////////////
//                     Post Processing Functions                             //
///////////////////////////////////////////////////////////////////////////////
half3 ApplyRadialBlur(float2 uv, TEXTURE2D_PARAM(sourceTex, sourceSampler))
{
    half3 color = 0.0f;
    half2 blurVector = (_KLRadialCenter - uv) * _KLBlurRadius;
    [unroll(30)]
    for (int i = 0; i <_KLIteration; i++)
    {
        color += SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv).xyz;
        uv += blurVector;//* (1 + i / _KLIteration);
    }
    color /= _KLIteration;
    return color;
}

half3 ApplyHeatDistortion(float2 uv, TEXTURE2D_PARAM(sourceTex, sourceSampler))
{
    half3 color = 0.0f;
    half distort = SAMPLE_TEXTURE2D(_KLHDNoiseTex, sampler_KLHDNoiseTex, uv * _KLHDNoiseTillingSpeed.xy + _Time.y * _KLHDNoiseTillingSpeed.zw).x;
    distort = distort * 2 - 1 ;
    distort = lerp(0, distort, _KLHDIntensity);
    color = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv + distort.xx).xyz;
    return color;
}

half3 ApplyPixelizeQuad(float2 uv, TEXTURE2D_PARAM(sourceTex, sourceSampler))
{
    half3 color = 0.0f;
	uv = float2(floor(uv.x * _KLPixelSize) * 1.0f / _KLPixelSize, 
        floor(uv.y * _KLPixelSize * _KLPixelRatio) * 1.0f / (_KLPixelSize * _KLPixelRatio));
    color = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv).xyz;
    return color;
}

half3 ApplyRGBSplit(half3 input, float2 uv, TEXTURE2D_PARAM(sourceTex, sourceSampler))
{
    half3 color = 0.0f;
    float splitAmount = _KLRGBSplitIntensity * RandomNoise(floor(frac(_Time.y) * _KLRGBSplitSpeed));
	color.r = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, float2(uv.x + splitAmount, uv.y)).r;
    color.g = input.g;
	color.b = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, float2(uv.x - splitAmount, uv.y)).b;
    return color;
}

half3 ApplyImageBlock(half3 input, float2 uv, TEXTURE2D_PARAM(sourceTex, sourceSampler))
{
    half3 color = 0.0f;
    half block = RandomImageBlockNoiseV2(floor(uv * _KLImageBlockSize * float2(1, _KLImageBlockRatio)), _KLImageBlockSpeed);
    block = block * block;
    block = block * block;
    block = block * block;
	color.r = input.r;
	color.g = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv + float2(block * 0.05 * RandomImageBlockNoise(7.0, _KLImageBlockSpeed), 0.0)).g;
	color.b = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv - float2(block * 0.05 * RandomImageBlockNoise(13.0, _KLImageBlockSpeed), 0.0)).b;
    return color;
}

half3 ApplyAdvancedImageBlock(half3 input, float2 uv, TEXTURE2D_PARAM(sourceTex, sourceSampler))
{
    half3 color = 0.0f;
	float2 blockLayer1 = floor(uv * float2(_KLRdImageBlockLayer1U, _KLRdImageBlockLayer1V));
	float2 blockLayer2 = floor(uv * float2(_KLRdImageBlockLayer2U, _KLRdImageBlockLayer2V));
	float lineNoise1 = pow(RandomImageBlockNoise(blockLayer1, _KLRdImageBlockSpeed), _KLRdImageBlockLayer1Intensity);
	float lineNoise2 = pow(RandomImageBlockNoise(blockLayer2, _KLRdImageBlockSpeed), _KLRdImageBlockLayer2Intensity);
	float RGBSplitNoise = RandomImageBlockNoise(5.1379, _KLRdImageBlockSpeed) * _KLRdImageBlockRGBIntensity;
	float lineNoise = lineNoise1 * lineNoise2 * _KLRdImageBlockOffset  - RGBSplitNoise;
	color.r = input.r;
	color.g = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv + float2(lineNoise * 0.05 * RandomImageBlockNoise(7.0, _KLRdImageBlockSpeed), 0.0)).g;
	color.b = SAMPLE_TEXTURE2D(sourceTex, sourceSampler, uv - float2(lineNoise * 0.05 * RandomImageBlockNoise(23.0, _KLRdImageBlockSpeed), 0.0)).b;
	color = lerp(input, color, _KLRdImageBlockFade);
    return color;
}

half3 ApplyBlackWhiteFlash(half3 input, float2 uv)
{
    half3 color = 0.0f;
    half luminance = SimpleLum(input);
    float2 polarCoord = PolarCoordinates(uv, _KLBWFCenter.xy, _KLBWFRadialScale * 0.05, _KLBWFLengthScale);
    polarCoord += _Time.y * _KLBWFSpeed;
    half mainR = SAMPLE_TEXTURE2D(_KLBWFTex, sampler_KLBWFTex, polarCoord).r;
    luminance += luminance * mainR;
    luminance = step(_KLBWFThreshold, luminance);
    luminance = lerp(luminance, 1 - luminance, _KLBWFMix);
    color = luminance * _KLBWFColor.rgb;
    return color;
}

half3 ApplyScanline(half3 input, float2 uv)
{
    half3 color = 0.0f;
    float depth = SAMPLE_DEPTH_TEXTURE(_CustomDepthTexture0, sampler_CustomDepthTexture0, uv);
    #if UNITY_REVERSED_Z
        depth = depth;
    #else
        // Adjust Z to match NDC for OpenGL ([-1, 1])
        depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, depth);
    #endif
    float3 positionWS = ComputeWorldSpacePosition(uv, depth, UNITY_MATRIX_I_VP);
    half noise = SAMPLE_TEXTURE2D(_KLSLNoiseTex, sampler_KLSLNoiseTex, 
        positionWS.xz * _KLSLNoiseTillingSpeed.xy + _KLSLNoiseTillingSpeed.zw * _Time.y).r;
    float distance = length(positionWS.xz - _RoleWorldPos.xz);
    float insideArea = smoothstep(distance - _KLSLSmoothIntensity, distance + _KLSLSmoothIntensity,  _KLSLRange + 0.8 * noise);
    float smoothArea = step(distance, _KLSLRange + _KLSLSmoothWidth + noise);
    float outlineArea = step(distance, _KLSLRange + _KLSLSmoothWidth + _KLSLOutlineWidth + 1.2 * noise);
    //half luminance = SimpleLum(input);
    half3 nextSceneColor = SAMPLE_TEXTURE2D(_CustomColorTexture1, rt_linear_clamp_sampler, uv).rgb;
    //color = lerp(input, luminance.xxx, insideArea);
    color = lerp(input, nextSceneColor, insideArea);
    color = lerp(color, _KLSLSmoothColor.rgb, smoothArea - insideArea);
    color = lerp(color, _KLSLOutlineColor.rgb, outlineArea - smoothArea);
    return color;
}




#endif
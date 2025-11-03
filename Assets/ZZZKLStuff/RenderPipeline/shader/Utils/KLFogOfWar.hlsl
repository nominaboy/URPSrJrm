#ifndef KL_FOG_OF_WAR_INCLUDED
#define KL_FOG_OF_WAR_INCLUDED

#pragma multi_compile _ _KLFogOfWar

uniform TEXTURE2D(_FOWMaskTexture);
uniform SAMPLER(sampler_FOWMaskTexture);
uniform half _FOWMaskWorldScale;
uniform TEXTURE2D(_FOWTexture);
uniform SAMPLER(sampler_FOWTexture);
uniform half4 _FOWTilling;
uniform half4 _FOWSpeed;
uniform half4 _FOWColor;
uniform half _FOWIntensity;
uniform half _FOWMaxHeight;
uniform half _FOWMinHeight;

uniform half _FOWScreenStart;
uniform half _FOWScreenEnd;



half3 CalcFogOfWar(half3 originalColor, float3 positionWS, float screenUVY)
{
    half3 finalColor;
    half fogMask = SAMPLE_TEXTURE2D(_FOWMaskTexture, sampler_FOWMaskTexture,
                        (positionWS.xz / _FOWMaskWorldScale) + float2(0.5, 0.5)).r;
    half fogNoise1 = SAMPLE_TEXTURE2D(_FOWTexture, sampler_FOWTexture,
                        positionWS.xz * _FOWTilling.xy * 0.01 + _Time.y * _FOWSpeed.xy * 0.01).r;
    half fogNoise2 = SAMPLE_TEXTURE2D(_FOWTexture, sampler_FOWTexture,
                        positionWS.xz * _FOWTilling.zw * 0.01 + _Time.y * _FOWSpeed.zw * 0.01).r;
    half fogNoise = 0.5 * (fogNoise1 + fogNoise2);
    float fogFactor = saturate((_FOWMaxHeight - positionWS.y) / (_FOWMaxHeight - _FOWMinHeight));
    finalColor.rgb = lerp(originalColor.rgb, _FOWColor.rgb * _FOWIntensity, fogFactor * fogNoise * fogMask);
    
    finalColor.rgb = lerp(finalColor.rgb, _FOWColor.rgb * _FOWIntensity, smoothstep(_FOWScreenStart, _FOWScreenEnd, screenUVY) * fogMask);
    
    return finalColor;
}


#endif
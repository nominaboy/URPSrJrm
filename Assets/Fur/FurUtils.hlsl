#ifndef FUR_UTILS_INCLUDED
#define FUR_UTILS_INCLUDED

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 uv01 : VAR_UV01;
    float2 uv2 : VAR_UV2;
    float4 T2W0 : VAR_T2W0;
	float4 T2W1 : VAR_T2W1;
	float4 T2W2 : VAR_T2W2;
};

float StrandSpecular(float3 T, float3 V, float3 L, float exponent)
{
    float3 H = normalize(L + V);
    float dotTH = dot(T, H);
    float sinTH = sqrt(1- dotTH * dotTH);
    float dirAtten = smoothstep(-1, 0, dotTH);    
    return dirAtten * pow(sinTH, exponent);
}





Varyings vertSimple(Attributes i)
{
    Varyings o = (Varyings) 0;

    o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
    
    o.uv01.xy = i.uv;
    o.T2W0.xyz = TransformObjectToWorldNormal(i.normalOS.xyz);
    return o;
}

half4 fragSimple(Varyings i) : SV_TARGET
{
    half3 albedo = SAMPLE_TEXTURE2D(_BaseMap, kl_linear_repeat_sampler, i.uv01.xy).rgb;
    Light mainLight = GetMainLight();
    float3 lightDirWS = normalize(mainLight.direction);
    float NDotL = dot(i.T2W0.xyz, lightDirWS);
    half3 diffuse = (0.5 * NDotL + 0.5) * mainLight.color.rgb * albedo;
    return half4(diffuse, 1);
}







Varyings vert(Attributes i)
{
    Varyings o = (Varyings) 0;

    float2 uvOffset = _UVOffset.xy * _FUR_LAYER * 0.1;
    o.uv01.xy = TRANSFORM_TEX(i.uv, _BaseMap) + uvOffset;
    o.uv01.zw = TRANSFORM_TEX(i.uv, _NormalTex) + uvOffset;
    o.uv2 = TRANSFORM_TEX(i.uv, _NoiseTex) + uvOffset;  

    half3 direction = normalize(lerp(i.normalOS, normalize(lerp(i.normalOS, _FurDirection.xyz, _GravityStrength)), _FUR_LAYER));
    i.positionOS.xyz += direction * _FurLength * _FUR_LAYER; // higher layer -> longer fur
	float3 positionWS = TransformObjectToWorld(i.positionOS.xyz);
    o.positionCS = TransformWorldToHClip(positionWS);
    
    float crossSign = i.tangentOS.w * GetOddNegativeScale();
	float3 normalWS = TransformObjectToWorldNormal(i.normalOS.xyz);
	float3 tangentWS = TransformObjectToWorldDir(i.tangentOS.xyz);
	float3 bitangentWS = cross(normalWS, tangentWS) * crossSign;

	o.T2W0 = float4(tangentWS.x, bitangentWS.x, normalWS.x, positionWS.x);
	o.T2W1 = float4(tangentWS.y, bitangentWS.y, normalWS.y, positionWS.y);
	o.T2W2 = float4(tangentWS.z, bitangentWS.z, normalWS.z, positionWS.z);

    return o;
}

half4 frag(Varyings i) : SV_TARGET
{
    float3x3 tanToWorld = float3x3(normalize(i.T2W0.xyz), normalize(i.T2W1.xyz), normalize(i.T2W2.xyz));
	float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, kl_linear_repeat_sampler, i.uv01.zw));
	normalTS.xy *= _NormalScale;
	normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
	float3 normalWS = normalize(mul(tanToWorld, normalTS));
    float3 normalVS = TransformWorldToViewNormal(normalWS);
	float3 positionWS = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);

    Light mainLight = GetMainLight();
    float3 lightDirWS = normalize(mainLight.direction);
    float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - positionWS);
    float NDotV = dot(normalWS, viewDirWS);
    float NDotL = dot(normalWS, lightDirWS);

    // Diffuse
    half3 baseColor = lerp(_BottomColor, _TopColor, _FUR_LAYER);
    half3 albedo = baseColor * SAMPLE_TEXTURE2D(_BaseMap, kl_linear_repeat_sampler, i.uv01.xy).rgb;
    half lambertDiffuse = saturate(NDotL + _LightFilter + _FUR_LAYER);
    half3 finalColor = albedo.rgb * lambertDiffuse * mainLight.color.rgb * mainLight.distanceAttenuation;

    // Alpha
    half alpha = 1 - _FUR_LAYER * _FUR_LAYER;
    alpha += (NDotV - _EdgeAlpha);
    half furMask = SAMPLE_TEXTURE2D(_FurMask, kl_linear_repeat_sampler, i.uv01.xy).r;
    half FurThickness = SAMPLE_TEXTURE2D(_NoiseTex, kl_linear_repeat_sampler, i.uv2) * furMask;
    FurThickness = step(lerp(0, _FurThickness, _FUR_LAYER), FurThickness);
    alpha = saturate(alpha * FurThickness);

    // Indirect Light
    half3 SH = saturate(normalVS.y * 0.25 + 0.35);
    half occlusion = saturate(_FUR_LAYER * _FUR_LAYER + 0.04);
    half3 SHL = lerp(_OcclusionColor * SH, SH, occlusion);
    half fresnel = 1 - max(0, NDotV);
    half rimLight = fresnel * occlusion;
    rimLight *= rimLight;
    rimLight *= _FresnelLV * SH;
    SHL += rimLight;

    // Anisotropic Specular 
    half3 specular = 0;
    #if defined(_SPECULAR_ON)
        lightDirWS = normalize(_SpecularLightDir); 
	    float3 bitangentWS = float3(i.T2W0.y, i.T2W1.y, i.T2W2.y);
        float3 T1 = normalize(_SpecularVec.z * normalWS + bitangentWS);
        float3 T2 = normalize(_SpecularVec.w * normalWS + bitangentWS);
        float spec1 = StrandSpecular(T1, viewDirWS, lightDirWS, _SpecularVec.x) * _FUR_LAYER;
        float spec2 = StrandSpecular(T2, viewDirWS, lightDirWS, _SpecularVec.y) * _FUR_LAYER;
        specular  = (spec1 * _SpecularColor1  + spec2 * _SpecularColor2);// * max(0, NDotL);
    #endif

    return half4(finalColor + SHL + specular, alpha);
}
#endif
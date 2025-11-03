#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



uniform int _mipMapMaxLevel;

TextureCube _EnvironmentMap;
SamplerState sampler_EnvironmentMap; 

// ----------------------------------------------------------------------------
// 由直角坐标系position转换到球坐标系phi theta
// ----------------------------------------------------------------------------
float2 GetPhiThetaFromPos(float3 pos) {
    float x = pos.x;
    float y = pos.y;
    float z = pos.z;
    float x2 = x * x;
    float y2 = y * y;
    float z2 = z * z;
    // 注意acos定义域
    float theta = acos(clamp(y, -1, 1));
    float phi = acos(clamp(x / sin(theta), -1, 1));
    theta = 1 - theta / PI;
    //float phi = atan(z / x);
    // arccos 值域 [0,PI]。夹角phi大于PI时(X轴正方向为起点，绕Y轴逆时针旋转大于180度，Z为负值),取[0,2PI]关于PI对称的值
    if(z < 0) {
	    phi = (2 * PI) - phi;
    }
    phi = phi / (2 * PI);
    return float2(phi, theta);
}

// ----------------------------------------------------------------------------
// Trowbridge-Reitz GGX. 
// ----------------------------------------------------------------------------
float DistributionGGX(float3 N, float3 H, float roughness) {
	// 使用平方粗糙度以获得更好的视觉效果
    float a = roughness*roughness;
    float a2 = a*a;
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH*NdotH;

    float nom = a2;
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    denom = PI * denom * denom;

    return nom / denom;
}
// ----------------------------------------------------------------------------
// Van Der Corput 序列
// ----------------------------------------------------------------------------
float RadicalInverse_VdC(uint bits) {
     bits = (bits << 16u) | (bits >> 16u);
     bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
     bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
     bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
     bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
     return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}
// ----------------------------------------------------------------------------
// 基于Van Der Corput 序列生成Hammersley 序列
// ----------------------------------------------------------------------------
float2 Hammersley(uint i, uint N) {
	return float2(float(i)/float(N), RadicalInverse_VdC(i));
}
// ----------------------------------------------------------------------------
// GGX重要性采样
// ----------------------------------------------------------------------------
float3 ImportanceSampleGGX(float2 Xi, float3 N, float roughness) {
	float a = roughness*roughness;
	
	float phi = 2.0 * PI * Xi.x;
	float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
	float sinTheta = sqrt(1.0 - cosTheta*cosTheta);
	
	// 球坐标系变换到直角坐标系，模长为1，halfvector
	float3 H;
	H.x = cos(phi) * sinTheta;
	H.y = sin(phi) * sinTheta;
	H.z = cosTheta;
	
	// from tangent-space H vector to world-space sample vector
	float3 up = abs(N.z) < 0.999 ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
	float3 tangent = normalize(cross(up, N));
	float3 bitangent = cross(N, tangent);
	
	float3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
	return normalize(sampleVec);
}
// ----------------------------------------------------------------------------
// Schlick-GGX
// ----------------------------------------------------------------------------
float GeometrySchlickGGX(float NdotV, float roughness) {
    // note that we use a different k for IBL
    float a = roughness;
    float k = (a * a) / 2.0;

    float nom = saturate(NdotV);
    float denom = NdotV * (1.0 - k) + k;

    return nom / max(denom, 0.0001);
}
// ----------------------------------------------------------------------------
// 史密斯法(Smith’s method)
// 考虑观察方向（几何遮蔽(Geometry Obstruction)）和光线方向向量（几何阴影(Geometry Shadowing)）
// ----------------------------------------------------------------------------
float GeometrySmith(float3 N, float3 V, float3 L, float roughness) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}

// ----------------------------------------------------------------------------
// Fresnel-Schlick近似(Fresnel-Schlick Approximation)
// ----------------------------------------------------------------------------
float3 fresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (float3(1.0, 1.0, 1.0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}
// ----------------------------------------------------------------------------
// 粗糙的表面在边缘反射较弱
// ----------------------------------------------------------------------------
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness) {
    return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
} 

// ----------------------------------------------------------------------------
// Lambertian Diffuse BRDF
// ----------------------------------------------------------------------------
float3 LambertianDiffBRDF(float3 albedo) {
    return albedo / PI;
}

// ----------------------------------------------------------------------------
// CT Specular BRDF
// ----------------------------------------------------------------------------
float3 CTSpecBRDF(float roughness, float3 N, float3 H, float3 V, float3 L, float3 F0, out float3 F) {
    // Cook-Torrance BRDF
    float NDF = DistributionGGX(N, H, roughness);   
    float G = GeometrySmith(N, V, L, roughness);    
    F = fresnelSchlick(max(dot(H, V), 0.0), F0);    
    // 分子项 D*F*G
    float3 numerator = NDF * G * F;
    // 分母项 ，+ 0.0001防止分母为0
    float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0); 
  
    return numerator / max(denominator, 0.0001);
}

// ----------------------------------------------------------------------------
// Monte Carlo Calc
// ----------------------------------------------------------------------------
float3 MonteCarloCalc(float roughness, float3 N, float3 V, float3 F0) {
    float mipLevel;
    const uint SAMPLE_COUNT = 128u;
    float3 innerVal = float3(0, 0, 0);
    float totalWeight = 0.0;
    for(uint i = 0u; i < SAMPLE_COUNT; ++i) {
        // generates a sample vector that's biased towards the preferred alignment direction (importance sampling).
        float2 Xi = Hammersley(i, SAMPLE_COUNT);
        float3 H = ImportanceSampleGGX(Xi, N, roughness);
        float3 L  = normalize(2.0 * dot(V, H) * H - V);
        float NdotL = max(dot(N, L), 0.0);
        if(NdotL > 0.0) {
            float NdotH = max(dot(N, H), 0.0);
            float NdotV = max(dot(N, V), 0.0);
            float VdotH = max(dot(V, H), 0.0);
            // Cook-Torrance BRDF
            float G = GeometrySmith(N, V, L, roughness);    
            float3 F = fresnelSchlick(VdotH, F0);    
            // sample from the environment's mip level based on roughness/pdf
            float D   = DistributionGGX(N, H, roughness);
            float pdf = max(D * NdotH / (4.0 * VdotH), 0.0001); 
            float resolution = 2048.0; // resolution of source cubemap (per face)
            float saTexel  = 4.0 * PI / (6.0 * resolution * resolution);
            float saSample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);
            mipLevel = roughness == 0.0 ? 0.0 : max(0.5 * log2(saSample / saTexel), 0); 
            // 分子项 F*G*VdotH*Li
            float3 numerator = G * F * VdotH * SAMPLE_TEXTURECUBE_LOD(_EnvironmentMap, sampler_EnvironmentMap, L, mipLevel).rgb;
            // 分母项
            float denominator = NdotV * NdotH; 
            innerVal += numerator / max(denominator, 0.0001);
            // NdotL大小作为权重
            totalWeight += NdotL;
        }
    }
    innerVal = innerVal / totalWeight;
    return innerVal;
}


// ----------------------------------------------------------------------------
// URPLit Specular BRDF
// ----------------------------------------------------------------------------
float3 URPLitSpecularBRDF(float roughness, float3 N, float3 H, float3 V, float3 L, float3 F0, out float3 F) {
    float roughness2 = roughness * roughness;
    float NoH = saturate(dot(N, H));
    float LoH = saturate(dot(L, H));
    float d = NoH * NoH * (roughness2 - 1.0) + 1.00001;
    F = fresnelSchlick(max(dot(H, V), 0.0), F0);

    float LoH2 = LoH * LoH;
    float3 specularTerm = (roughness2 / ((d * d) * max(0.1, LoH2) * (roughness * 4.0 + 2.0))).xxx;
    return specularTerm;
}


// ----------------------------------------------------------------------------
// Specular 1st stage: Pre-filtered color calculation
// ----------------------------------------------------------------------------
float4 CalculatePrefilteredColor(float3 posDir, float mipmapLevel) {		
    float roughness = (float)mipmapLevel * (1.0 / (float)_mipMapMaxLevel);
    float3 N = normalize(posDir);// N = posDir
    // make the simplifying assumption that V equals R equals N 
    float3 R = N;
    float3 V = R;
    const uint SAMPLE_COUNT = 1024u;
    float3 prefilteredColor = float3(0, 0, 0);
    float totalWeight = 0.0;
    for(uint i = 0u; i < SAMPLE_COUNT; ++i) {
        // generates a sample vector that's biased towards the preferred alignment direction (importance sampling).
        float2 Xi = Hammersley(i, SAMPLE_COUNT);
        float3 H = ImportanceSampleGGX(Xi, N, roughness);
        float3 L  = normalize(2.0 * dot(V, H) * H - V);
        float NdotL = max(dot(N, L), 0.0);
        if(NdotL > 0.0) {
            // sample from the environment's mip level based on roughness/pdf
            float D   = DistributionGGX(N, H, roughness);
            float NdotH = max(dot(N, H), 0.0);
            float HdotV = max(dot(H, V), 0.0);
            float pdf = max(D * NdotH / (4.0 * HdotV), 0.0001); 

            float resolution = 2048.0; // resolution of source cubemap (per face)
            float saTexel  = 4.0 * PI / (6.0 * resolution * resolution);
            float saSample = 1.0 / (float(SAMPLE_COUNT) * pdf + 0.0001);

            float mipLevel = roughness == 0.0 ? 0.0 : 0.5 * log2(saSample / saTexel); 
            prefilteredColor += SAMPLE_TEXTURECUBE_LOD(_EnvironmentMap, sampler_EnvironmentMap, L, mipLevel).rgb * NdotL;
            // NdotL大小作为权重
            totalWeight += NdotL;
        }
    }
    prefilteredColor = prefilteredColor / totalWeight;
    return float4(prefilteredColor, 1.0);
}
// ----------------------------------------------------------------------------
// Specular 2nd stage: BRDF part
// ----------------------------------------------------------------------------
float2 IntegrateBRDF(float NdotV, float roughness) {
    float3 V;
    V.x = sqrt(1.0 - NdotV*NdotV);
    V.y = 0.0;
    V.z = NdotV;

    float A = 0.0;
    float B = 0.0; 
    float3 N = float3(0.0, 0.0, 1.0);
    
    int SAMPLE_COUNT = 1024;
    for(int i = 0; i < SAMPLE_COUNT; i++) {
        // generates a sample vector that's biased towards the
        // preferred alignment direction (importance sampling).
        float2 Xi = Hammersley(i, SAMPLE_COUNT);
        float3 H = ImportanceSampleGGX(Xi, N, roughness);
        float3 L = normalize(2.0 * dot(V, H) * H - V);
        float NdotL = max(L.z, 0.0);
        float NdotH = max(H.z, 0.0);
        float VdotH = max(dot(V, H), 0.0);

        if(NdotL > 0.0) {
            float G = GeometrySmith(N, V, L, roughness);
            float G_Vis = (G * VdotH) / (NdotH * NdotV);
            float Fc = pow(1.0 - VdotH, 5.0);
            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }
    A /= float(SAMPLE_COUNT);
    B /= float(SAMPLE_COUNT);
    return float2(A, B);
}





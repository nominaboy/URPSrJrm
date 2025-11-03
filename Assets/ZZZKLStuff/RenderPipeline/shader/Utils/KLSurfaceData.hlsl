#ifndef KL_SURFACE_DATA_INCLUDED
#define KL_SURFACE_DATA_INCLUDED


struct KLSurfaceData
{
    half3 albedo;
    half alpha;
    half3 specular;
    half3 emission;
    
    half metallic;
    half smoothness;
    half occlusion;
    half clearCoatMask;
    half clearCoatSmoothness;
    half specularIntensity;
    
    half rampMapID;
};

//struct AnisoSpecularData
//{
//    half3 specularColor;
//    half3 specularSecondaryColor;
//    half specularShift;
//    half specularSecondaryShift;
//    half specularStrength;
//    half specularSecondaryStrength;
//    half specularExponent;
//    half specularSecondaryExponent;
//    half spread1;
//    half spread2;
//};

//struct AngleRingSpecularData
//{
//    half3 shadowColor;
//    half3 brightColor;
//    half mask;
//    half width;
//    half softness;
//    half threshold;
//    half intensity;
//};




#endif
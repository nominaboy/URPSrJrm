#ifndef KL_VARYINGS_INCLUDED
#define KL_VARYINGS_INCLUDED


struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float2 texcoord : TEXCOORD0;
    float2 staticLightmapUV : TEXCOORD1;
};

struct Varyings
{
    float2 uv : VAR_UV;
    float3 positionWS : VAR_POSITIONWS;
    float3 normalWS : VAR_NORMALWS;
    float4 positionCS : SV_POSITION;
    DECLARE_LIGHTMAP_OR_SH(staticLightmapUV, vertexSH, 8);
};




#endif
#ifndef KL_BSDF_INCLUDED
#define KL_BSDF_INCLUDED



BRDFData CreateKLClearCoatBRDFData(KLSurfaceData surfaceData, inout BRDFData brdfData)
{
    BRDFData brdfDataClearCoat = (BRDFData) 0;

    #if _CLEARCOAT
            // base brdfData is modified here, rely on the compiler to eliminate dead computation by InitializeBRDFData()
            InitializeBRDFDataClearCoat(surfaceData.clearCoatMask, surfaceData.clearCoatSmoothness, brdfData, brdfDataClearCoat);
    #endif

    return brdfDataClearCoat;
}



void InitializeKLBRDFData(KLSurfaceData surfaceData, out BRDFData outBRDFData, out BRDFData outClearBRDFData)
{
    // Only for metallic workflow
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, 1 /*surfaceData.specular*/, surfaceData.smoothness, surfaceData.alpha, outBRDFData);
    outClearBRDFData = outBRDFData;
    #if _CLEARCOAT
        outClearBRDFData = CreateKLClearCoatBRDFData(surfaceData, outBRDFData);
    #endif
}

#endif
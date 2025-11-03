using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Pixelize/KL Pixelize Quad", typeof(UniversalRenderPipeline))]
public class KLPixelizeQuad : VolumeComponent, IPostProcessComponent
{
    [Header("KL Pixelize Quad")]
    public ClampedFloatParameter pixelSize = new ClampedFloatParameter(0.5f, 0.5f, 500.0f);

    public ClampedFloatParameter pixelRatio = new ClampedFloatParameter(1.0f, 0.2f, 5.0f);

    public bool IsActive() => pixelSize.value > 0.5f;
    public bool IsTileCompatible() => false;
}

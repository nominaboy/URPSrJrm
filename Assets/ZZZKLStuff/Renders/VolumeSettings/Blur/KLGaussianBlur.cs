using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Blur/KL Radial Blur", typeof(UniversalRenderPipeline))]
public class KLGaussianBlur : VolumeComponent, IPostProcessComponent
{
    [Header("KL Gaussian Blur")]
    public ClampedFloatParameter blurRadius = new ClampedFloatParameter(0.0f, 0.0f, 0.5f);

    public ClampedIntParameter iteration = new ClampedIntParameter(1, 1, 30);

    public ClampedIntParameter rtResolution = new ClampedIntParameter(1, 1, 16);

    public bool IsActive() => iteration.value > 1 && blurRadius.value > 0.0f;
    public bool IsTileCompatible() => false;
}

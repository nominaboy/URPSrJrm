using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Blur/KL Radial Blur", typeof(UniversalRenderPipeline))]
public class KLRadialBlur : VolumeComponent, IPostProcessComponent
{
    [Header("KL Radial Blur")]
    public Vector2Parameter radialCenter = new Vector2Parameter(Vector2.one * 0.5f);

    public ClampedFloatParameter blurRadius = new ClampedFloatParameter(0.0f, 0.0f, 0.5f);

    public ClampedIntParameter iteration = new ClampedIntParameter(1, 1, 30);

    public bool IsActive() => iteration.value > 1;
    public bool IsTileCompatible() => false;
}

using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Glitch/KL Image Block", typeof(UniversalRenderPipeline))]
public class KLImageBlock : VolumeComponent, IPostProcessComponent
{
    [Header("KL Image Block")]
    public ClampedFloatParameter speed = new ClampedFloatParameter(10.0f, 0.0f, 50.0f);

    public ClampedFloatParameter size = new ClampedFloatParameter(1.0f, 1.0f, 10.0f);

    public ClampedFloatParameter ratio = new ClampedFloatParameter(4.0f, 1.0f, 10.0f);

    public bool IsActive() => size.value > 1.0f;
    public bool IsTileCompatible() => false;


}

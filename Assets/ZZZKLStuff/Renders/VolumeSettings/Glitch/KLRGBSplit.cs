using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Glitch/KL RGB Split", typeof(UniversalRenderPipeline))]
public class KLRGBSplit : VolumeComponent, IPostProcessComponent
{
    [Header("KL RGB Split")]
    public ClampedFloatParameter intensity = new ClampedFloatParameter(0.0f, -0.3f, 0.3f);

    public ClampedFloatParameter speed = new ClampedFloatParameter(10.0f, 0.0f, 50.0f);

    public bool IsActive() => intensity.value != 0.0f;
    public bool IsTileCompatible() => false;
}

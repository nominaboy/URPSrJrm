using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Glitch/KL Advanced Image Block", typeof(UniversalRenderPipeline))]
public class KLAdvancedImageBlock : VolumeComponent, IPostProcessComponent
{
    [Header("KL Advanced Image Block")]
    public ClampedFloatParameter blockLayer1U = new ClampedFloatParameter(4.0f, 0.0f, 20.0f);

    public ClampedFloatParameter blockLayer1V = new ClampedFloatParameter(12.0f, 0.0f, 20.0f);

    public ClampedFloatParameter blockLayer2U = new ClampedFloatParameter(5.0f, 0.0f, 20.0f);

    public ClampedFloatParameter blockLayer2V = new ClampedFloatParameter(5.0f, 0.0f, 20.0f);

    public ClampedFloatParameter speed = new ClampedFloatParameter(10.0f, 0.0f, 50.0f);

    public ClampedFloatParameter blockLayer1Intensity = new ClampedFloatParameter(4.0f, 0.0f, 50.0f);

    public ClampedFloatParameter blockLayer2Intensity = new ClampedFloatParameter(4.0f, 0.0f, 50.0f);

    public ClampedFloatParameter blockRGBIntensity = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);

    public ClampedFloatParameter fade = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

    public ClampedFloatParameter offset = new ClampedFloatParameter(0.0f, 1.0f, 10.0f);


    public bool IsActive() => fade.value > 0.0f;
    public bool IsTileCompatible() => false;
}

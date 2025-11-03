using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Distortion/KL Heat Distortion", typeof(UniversalRenderPipeline))]
public class KLHeatDistortion : VolumeComponent, IPostProcessComponent
{
    [Header("KL Heat Distortion")]
    public TextureParameter noiseTexture = new TextureParameter(null);

    public ClampedFloatParameter intensity = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

    public Vector4Parameter noiseTillingSpeed  = new Vector4Parameter(new Vector4(1.0f, 1.0f, 0.04f, 0.05f));

    public bool IsActive() => intensity.value > 0.0f && noiseTexture != null;
    public bool IsTileCompatible() => false;
}

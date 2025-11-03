using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Comic/KL Scanline", typeof(UniversalRenderPipeline))]
public class KLScanline : VolumeComponent, IPostProcessComponent
{
    [Header("KL Scanline")]
    public ClampedFloatParameter range = new ClampedFloatParameter(0.0f, 0.0f, 80.0f);

    public ClampedFloatParameter smoothIntensity = new ClampedFloatParameter(3.5f, 0.0f, 10.0f);

    public ClampedFloatParameter smoothWidth = new ClampedFloatParameter(5.0f, 0.0f, 8.0f);

    public ColorParameter smoothColor = new ColorParameter(Color.yellow);

    public ClampedFloatParameter outlineWidth = new ClampedFloatParameter(1.0f, 0.0f, 2.0f);

    public ColorParameter outlineColor = new ColorParameter(Color.cyan);

    public Texture2DParameter noiseTex = new Texture2DParameter(null);

    public Vector4Parameter noiseTillingSpeed  = new Vector4Parameter(new Vector4(0.02f, 0.02f, 0.01f, 0.01f));

    public bool IsActive() => range.value > 0.0f && noiseTex.value != null;
    public bool IsTileCompatible() => false;
}

using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Fog Of War", typeof(UniversalRenderPipeline))]
public class KLFogOfWar : VolumeComponent, IPostProcessComponent
{
    [Header("KL Fog Of War")]
    public TextureParameter maskTexture = new TextureParameter(null);

    public FloatParameter maskWorldScale = new FloatParameter(1f);

    public TextureParameter fogTexture = new TextureParameter(null);

    public Vector4Parameter fogTilling = new Vector4Parameter(Vector4.one);

    public Vector4Parameter fogSpeed = new Vector4Parameter(Vector4.zero);

    public ColorParameter fogColor = new ColorParameter(Color.white);

    public ClampedFloatParameter fogIntensity = new ClampedFloatParameter(1.0f, 0.0f, 5.0f);

    public ClampedFloatParameter fogMaxHeight = new ClampedFloatParameter(0.0f, 0.0f, 100.0f);

    public ClampedFloatParameter fogMinHeight = new ClampedFloatParameter(0.0f, 0.0f, 100.0f);

    public ClampedFloatParameter fogScreenStart = new ClampedFloatParameter(0.6f, 0.0f, 1.0f);

    public ClampedFloatParameter fogScreenEnd = new ClampedFloatParameter(1.0f, 0.0f, 2.0f);

    public bool IsActive() => maskTexture.value != null && fogTexture.value != null;
    public bool IsTileCompatible() => false;
}

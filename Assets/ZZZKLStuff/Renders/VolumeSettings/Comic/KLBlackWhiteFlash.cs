using System;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;

[Serializable, VolumeComponentMenuForRenderPipeline("KLPostProcessing/Comic/KL Black White Flash", typeof(UniversalRenderPipeline))]
public class KLBlackWhiteFlash : VolumeComponent, IPostProcessComponent
{
    [Header("KL Black White Flash")]
    public TextureParameter radialTexture = new TextureParameter(null);

    public Vector2Parameter center = new Vector2Parameter(Vector2.one * 0.5f);

    public ClampedFloatParameter radialScale = new ClampedFloatParameter(0.45f, 0.0f, 1.0f);

    public ClampedFloatParameter lengthScale = new ClampedFloatParameter(5.0f, 0.0f, 10.0f);

    public Vector2Parameter speed = new Vector2Parameter(Vector2.zero);

    public ClampedFloatParameter threshold = new ClampedFloatParameter(0.2f, 0.0f, 1.0f);

    public ClampedFloatParameter mix = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

    public ColorParameter color = new ColorParameter(Color.white);

    public bool IsActive() => radialTexture.value != null;
    public bool IsTileCompatible() => false;
}

using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CatVFX
{
    [Serializable, VolumeComponentMenu("Cat VFX/ScreenDistortion")]
    public class ScreenDistortion : VolumeComponent, IPostProcessComponent
    {

        [Tooltip("Strength of the wrap.")]
        public ClampedFloatParameter intensity = new ClampedFloatParameter(0.0f, 0f, 1f);

        public bool IsActive() => intensity.value > 0f;

        public bool IsTileCompatible() => false;
    }

}

using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CatVFX
{
    [Serializable, VolumeComponentMenu("Cat VFX/RadialBlur")]
    public class RadialBlur : VolumeComponent, IPostProcessComponent
    {

        [Tooltip("Sample count")]
        public ClampedIntParameter sampleCount = new ClampedIntParameter(4, 1, 10);


        [Tooltip("Blur")]
        public ClampedFloatParameter blur = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

        public bool IsActive() => blur.value > 0f;

        public bool IsTileCompatible() => false;
    }

}
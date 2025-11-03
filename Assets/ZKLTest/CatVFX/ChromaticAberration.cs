using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace CatVFX
{
    [Serializable, VolumeComponentMenu("Cat VFX/ChromaticAberration")]
    public class ChromaticAberration : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Split")]
        public Vector4Parameter split = new Vector4Parameter(new Vector4(1, 0, 0.5f, 1));

        [Tooltip("Blur")]
        public ClampedFloatParameter blur = new ClampedFloatParameter(0.0f, 0.0f, 1.0f);

        [Tooltip("Radial")]
        public ClampedFloatParameter radial = new ClampedFloatParameter(0.5f, 0.0f, 1.0f);

        public bool IsActive() => blur.value > 0f;

        public bool IsTileCompatible() => false;
    }
}
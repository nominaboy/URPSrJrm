using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class KLRenderUtils
{
    [System.Flags]
    public enum CustomRenderingLayerMask
    {
        None = 0,
        Default = 1 << 0,
        BlackOutline = 1 << 1,
        RedOutline = 1 << 2,
        WhiteOutline = 1 << 3,
        BlackOutlineNoStencil = 1 << 4,
        DotMeshShadow = 1 << 5,
        BlackOutlineClip = 1 << 6
    }
}

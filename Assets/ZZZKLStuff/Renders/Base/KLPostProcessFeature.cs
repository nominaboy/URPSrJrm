using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLPostProcessFeature : ScriptableRendererFeature
{
    KLPostProcessPass _KLPostProcessPass;
    public override void Create()
    {
        _KLPostProcessPass = new KLPostProcessPass();
        _KLPostProcessPass.renderPassEvent = RenderPassEvent.BeforeRendering;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLPostProcessPass);
    }

    class KLPostProcessPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        public KLPostProcessPass()
        {
            _ProfilingSampler = new ProfilingSampler("KL Post Processing");
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var stack = VolumeManager.instance.stack;
            if (stack == null) return;
            ref CameraData cameraData = ref renderingData.cameraData;
            bool isSceneViewCamera = cameraData.isSceneViewCamera;


            var _KLFogOfWar = stack.GetComponent<KLFogOfWar>();
            var _KLBlackWhiteFlash = stack.GetComponent<KLBlackWhiteFlash>();

            bool useKLFogOfWar = _KLFogOfWar.IsActive();
            bool useKLBlackWhiteFlash = _KLBlackWhiteFlash.IsActive() && !isSceneViewCamera;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                DisableAllKeywords(cmd);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                if (useKLFogOfWar)
                {
                    SetupKLFogOfWar(cmd, _KLFogOfWar);
                }
                

                if (useKLBlackWhiteFlash)
                {
                    SetupKLBlackWhiteFlash(cmd, _KLBlackWhiteFlash);
                }
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }


        // Disable global keywords because we can't get uber material
        private void DisableAllKeywords(CommandBuffer cmd)
        {
            cmd.DisableShaderKeyword(ShaderConstants.kwFogOfWar);
            cmd.DisableShaderKeyword(ShaderConstants.kwBlackWhiteFlash);
        }
        private void SetupKLFogOfWar(CommandBuffer cmd, KLFogOfWar pp)
        {
            cmd.EnableShaderKeyword(ShaderConstants.kwFogOfWar);
            cmd.SetGlobalTexture(ShaderConstants._FOWMaskTexture, pp.maskTexture.value);
            cmd.SetGlobalFloat(ShaderConstants._FOWMaskWorldScale, pp.maskWorldScale.value);
            cmd.SetGlobalTexture(ShaderConstants._FOWTexture, pp.fogTexture.value);
            cmd.SetGlobalVector(ShaderConstants._FOWTilling, pp.fogTilling.value);
            cmd.SetGlobalVector(ShaderConstants._FOWSpeed, pp.fogSpeed.value);
            cmd.SetGlobalColor(ShaderConstants._FOWColor, pp.fogColor.value);
            cmd.SetGlobalFloat(ShaderConstants._FOWIntensity, pp.fogIntensity.value);
            cmd.SetGlobalFloat(ShaderConstants._FOWMaxHeight, pp.fogMaxHeight.value);
            cmd.SetGlobalFloat(ShaderConstants._FOWMinHeight, pp.fogMinHeight.value);
            cmd.SetGlobalFloat(ShaderConstants._FOWScreenStart, pp.fogScreenStart.value);
            cmd.SetGlobalFloat(ShaderConstants._FOWScreenEnd, pp.fogScreenEnd.value);
        }

        private void SetupKLBlackWhiteFlash(CommandBuffer cmd, KLBlackWhiteFlash pp)
        {
            cmd.EnableShaderKeyword(ShaderConstants.kwBlackWhiteFlash);
            cmd.SetGlobalTexture(ShaderConstants._KLBWFTex, pp.radialTexture.value);
            cmd.SetGlobalVector(ShaderConstants._KLBWFCenter, pp.center.value);
            cmd.SetGlobalFloat(ShaderConstants._KLBWFRadialScale, pp.radialScale.value);
            cmd.SetGlobalFloat(ShaderConstants._KLBWFLengthScale, pp.lengthScale.value);
            cmd.SetGlobalVector(ShaderConstants._KLBWFSpeed, pp.speed.value);
            cmd.SetGlobalFloat(ShaderConstants._KLBWFThreshold, pp.threshold.value);
            cmd.SetGlobalFloat(ShaderConstants._KLBWFMix, pp.mix.value);
            cmd.SetGlobalColor(ShaderConstants._KLBWFColor, pp.color.value);
        }




        #region Internal Utilities

        private static class ShaderConstants
        {
            // Global Keywords
            public static readonly string kwFogOfWar = "_KLFogOfWar";
            public static readonly string kwBlackWhiteFlash = "_KL_BLACK_WHITE_FLASH";



            // Shader Params
            public static readonly int _FOWMaskTexture = Shader.PropertyToID("_FOWMaskTexture");
            public static readonly int _FOWMaskWorldScale = Shader.PropertyToID("_FOWMaskWorldScale");
            public static readonly int _FOWTexture = Shader.PropertyToID("_FOWTexture");
            public static readonly int _FOWTilling = Shader.PropertyToID("_FOWTilling");
            public static readonly int _FOWSpeed = Shader.PropertyToID("_FOWSpeed");
            public static readonly int _FOWColor = Shader.PropertyToID("_FOWColor");
            public static readonly int _FOWIntensity = Shader.PropertyToID("_FOWIntensity");
            public static readonly int _FOWMaxHeight = Shader.PropertyToID("_FOWMaxHeight");
            public static readonly int _FOWMinHeight = Shader.PropertyToID("_FOWMinHeight");
            public static readonly int _FOWScreenStart = Shader.PropertyToID("_FOWScreenStart");
            public static readonly int _FOWScreenEnd = Shader.PropertyToID("_FOWScreenEnd");

            public static readonly int _KLBWFCenter = Shader.PropertyToID("_KLBWFCenter");
            public static readonly int _KLBWFRadialScale = Shader.PropertyToID("_KLBWFRadialScale");
            public static readonly int _KLBWFLengthScale = Shader.PropertyToID("_KLBWFLengthScale");
            public static readonly int _KLBWFSpeed = Shader.PropertyToID("_KLBWFSpeed");
            public static readonly int _KLBWFTex = Shader.PropertyToID("_KLBWFTex");
            public static readonly int _KLBWFThreshold = Shader.PropertyToID("_KLBWFThreshold");
            public static readonly int _KLBWFMix = Shader.PropertyToID("_KLBWFMix");
            public static readonly int _KLBWFColor = Shader.PropertyToID("_KLBWFColor");


        }

        #endregion

    }



}



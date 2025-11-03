using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLCopyColorFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class KLCopyColorRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public int rtResolution = 1;
        public Material copyColorMaterial;
    }

    class KLCopyColorPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        //private RenderTargetHandle _CameraColorAttachment;
        private RenderTargetHandle _CustomColorTexture0;

        private int _RtResolution;
        private Material _CopyColorMaterial;
        public KLCopyColorPass(int rtResolution, Material mat)
        {
            _ProfilingSampler = new ProfilingSampler("KL Copy Color");
            _RtResolution = rtResolution;

            //_CameraColorAttachment.Init("_CameraColorAttachment");
            _CustomColorTexture0.Init("_CustomColorTexture0");
            _CopyColorMaterial = mat;
        }


        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            descriptor.width = Mathf.FloorToInt(descriptor.width / _RtResolution);
            descriptor.height = Mathf.FloorToInt(descriptor.height / _RtResolution);

            cmd.GetTemporaryRT(_CustomColorTexture0.id, descriptor, _RtResolution == 1 ? FilterMode.Point : FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (_CopyColorMaterial == null)
            {
                return;
            }
            ref CameraData cameraData = ref renderingData.cameraData;
            ScriptableRenderer renderer = cameraData.renderer;
            var colorAttachment = renderer.cameraColorTarget;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                //cmd.SetGlobalTexture("_SourceTex", colorAttachment);
                //cmd.SetRenderTarget(_CustomColorTexture0.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
                //    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
                cmd.Blit(colorAttachment, _CustomColorTexture0.Identifier(), _CopyColorMaterial, 0);
                cmd.SetGlobalTexture("_CustomColorTexture0", _CustomColorTexture0.Identifier());
                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_CustomColorTexture0.id);
        }
    }

    public KLCopyColorRenderSettings settings = new KLCopyColorRenderSettings();
    KLCopyColorPass _KLCopyColorPass;

    public override void Create()
    {
        _KLCopyColorPass = new KLCopyColorPass(settings.rtResolution, settings.copyColorMaterial);
        _KLCopyColorPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLCopyColorPass);
    }
}



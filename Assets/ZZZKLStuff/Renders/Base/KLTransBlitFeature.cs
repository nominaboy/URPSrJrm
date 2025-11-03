using SpaceWar;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLTransBlitFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class KLTransBlitRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Shader copyColorShader;
    }

    class KLTransBlitPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;

        private Material _CopyColorMaterial;

        private RenderTargetHandle _CustomColorTexture0;
        private RenderTargetHandle _CustomDepthTexture0;
        public KLTransBlitPass(Shader shader)
        {
            _ProfilingSampler = new ProfilingSampler("KL TransBlit");
            _CustomColorTexture0.Init("_CustomColorTexture0");
            _CustomDepthTexture0.Init("_CustomDepthTexture0");
            _CopyColorMaterial = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            ref CameraData cameraData = ref renderingData.cameraData;
            ScriptableRenderer renderer = cameraData.renderer;
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                // Revert to default Render Targets
                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);
                //cmd.SetRenderTarget(renderer.cameraColorTarget);

                // Blit VFX RT to main colorAttachment
                cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                cmd.SetGlobalTexture("_CustomColorTexture0", _CustomColorTexture0.Identifier());
                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, _CopyColorMaterial, 0, 0);

                cmd.SetViewProjectionMatrices(cameraData.GetViewMatrix(), cameraData.GetProjectionMatrix());


            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);

        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_CustomColorTexture0.id);
            cmd.ReleaseTemporaryRT(_CustomDepthTexture0.id);
        }
    }

    public KLTransBlitRenderSettings settings = new KLTransBlitRenderSettings();
    KLTransBlitPass _KLTransBlitPass;

    public override void Create()
    {
        _KLTransBlitPass = new KLTransBlitPass(settings.copyColorShader);

        _KLTransBlitPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLTransBlitPass);
    }
}



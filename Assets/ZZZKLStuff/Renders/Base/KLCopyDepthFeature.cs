using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
public class KLCopyDepthFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class KLCopyDepthRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public bool clearRT = true;
        public Material copyDepthMaterial;
    }
    class KLCopyDepthPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        //private RenderTargetHandle _CameraDepthAttachment;
        private RenderTargetHandle _CustomDepthTexture0;
        private Material _CopyDepthMaterial;
        private bool _ClearRT;

        public KLCopyDepthPass(bool clearRT, Material mat)
        {
            _ProfilingSampler = new ProfilingSampler("KL Copy Depth");
            _ClearRT = clearRT;

            //_CameraDepthAttachment.Init("_CameraDepthAttachment");
            _CustomDepthTexture0.Init("_CustomDepthTexture0");
            _CopyDepthMaterial = mat;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
#if UNITY_EDITOR
            bool isSceneViewOrPreviewCamera = cameraData.isSceneViewCamera || cameraData.cameraType == CameraType.Preview;
            if (isSceneViewOrPreviewCamera) return;
#endif
            if (_CopyDepthMaterial == null)
            {
                return;
            }
            ScriptableRenderer renderer = cameraData.renderer;
            RenderTextureDescriptor depthDescriptor = cameraData.cameraTargetDescriptor;
            depthDescriptor.colorFormat = RenderTextureFormat.Depth;
            depthDescriptor.depthBufferBits = 32;
            depthDescriptor.width = depthDescriptor.width;
            depthDescriptor.height = depthDescriptor.height;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                cmd.GetTemporaryRT(_CustomDepthTexture0.id, depthDescriptor, FilterMode.Point);
                cmd.SetRenderTarget(_CustomDepthTexture0.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare,
                    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store); 
                if (_ClearRT)
                {
                    cmd.ClearRenderTarget(true, true, Color.black);
                }
                //cmd.SetGlobalTexture("_CameraDepthAttachment", _CameraDepthAttachment.Identifier());
                cmd.SetGlobalTexture("_CameraDepthAttachment", renderer.cameraDepthTarget);

                bool yflip = cameraData.IsCameraProjectionMatrixFlipped();
                float flipSign = yflip ? -1.0f : 1.0f;
                cmd.SetGlobalFloat("_ScaleBiasDepthRT", flipSign);
                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, _CopyDepthMaterial);
                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);

//#if UNITY_EDITOR
//                bool isSceneViewOrPreviewCamera = cameraData.isSceneViewCamera || cameraData.cameraType == CameraType.Preview;
//                if (isSceneViewOrPreviewCamera)
//                {
//                    cmd.SetRenderTarget(renderer.cameraColorTarget);
//                }
//                else
//                {
//                    cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);
//                }
//#else
//                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);
//#endif
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_CustomDepthTexture0.id);
        }
    }

    public KLCopyDepthRenderSettings settings = new KLCopyDepthRenderSettings();
    KLCopyDepthPass _KLCopyDepthPass;

    public override void Create()
    {
        _KLCopyDepthPass = new KLCopyDepthPass(settings.clearRT, settings.copyDepthMaterial);
        _KLCopyDepthPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLCopyDepthPass);
    }
}



using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLGaussianBlurFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class KLGaussianBlurRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public int rtResolution = 2;
        public int iteration = 5;
        public float blurSize = 3.0f;
        public Material copyColorMaterial;
        public Material blurMaterial;
    }
    class KLGaussianBlurPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        //private RenderTargetHandle _CameraColorAttachment;
        private RenderTargetHandle _GaussianBlurBuffer0;
        private RenderTargetHandle _GaussianBlurBuffer1;

        private int _RtResolution;
        private int _Iteration;
        private float _BlurSize;
        private Material _CopyColorMaterial;
        private Material _BlurMaterial;
        private static readonly int _BlurSizeId = Shader.PropertyToID("_BlurSize");

        public KLGaussianBlurPass(int rtResolution, int iteration, float blurSize, Material copyColorMat, Material blurMat)
        {
            _ProfilingSampler = new ProfilingSampler("KL Gaussian Blur");
            _RtResolution = rtResolution;
            _Iteration = iteration;
            _BlurSize = blurSize;

            _GaussianBlurBuffer0.Init("_GaussianBlurBuffer0");
            _GaussianBlurBuffer1.Init("_GaussianBlurBuffer1");
            _CopyColorMaterial = copyColorMat;
            _BlurMaterial = blurMat;
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            descriptor.width = Mathf.FloorToInt(descriptor.width / _RtResolution);
            descriptor.height = Mathf.FloorToInt(descriptor.height / _RtResolution);

            cmd.GetTemporaryRT(_GaussianBlurBuffer0.id, descriptor, _RtResolution == 1 ? FilterMode.Point : FilterMode.Bilinear);
            cmd.GetTemporaryRT(_GaussianBlurBuffer1.id, descriptor, _RtResolution == 1 ? FilterMode.Point : FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (_CopyColorMaterial == null || _BlurMaterial == null)
            {
                return;
            }
            ref CameraData cameraData = ref renderingData.cameraData;
            //RenderTextureDescriptor descriptor = cameraData.cameraTargetDescriptor;
            ScriptableRenderer renderer = cameraData.renderer;
            var colorAttachment = renderer.cameraColorTarget;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                cmd.Blit(colorAttachment, _GaussianBlurBuffer0.Identifier(), _CopyColorMaterial, 0);

                //Vector4 horizontal = new Vector4(_BlurSize / descriptor.width, 0, 0, 0);
                //Vector4 vertical = new Vector4(0, _BlurSize / descriptor.height, 0, 0);
                _BlurMaterial.SetFloat(_BlurSizeId, _BlurSize);
                for (int i = 0; i < _Iteration; i++)
                {
                    //cmd.SetGlobalVector(_BlurSizeId, horizontal);
                    //_BlurMaterial.SetVector(_BlurSizeId, horizontal);
                    cmd.Blit(_GaussianBlurBuffer0.Identifier(), _GaussianBlurBuffer1.Identifier(), _BlurMaterial, 0);

                    //cmd.SetGlobalVector(_BlurSizeId, vertical);
                    //_BlurMaterial.SetVector(_BlurSizeId, vertical);
                    cmd.Blit(_GaussianBlurBuffer1.Identifier(), _GaussianBlurBuffer0.Identifier(), _BlurMaterial, 1);
                }

                cmd.SetGlobalTexture("_GaussianBlurBuffer0", _GaussianBlurBuffer0.Identifier());
                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_GaussianBlurBuffer0.id);
            cmd.ReleaseTemporaryRT(_GaussianBlurBuffer1.id);
        }
    }

    public KLGaussianBlurRenderSettings settings = new KLGaussianBlurRenderSettings();
    KLGaussianBlurPass m_KLGaussianBlurPass;

    public override void Create()
    {
        m_KLGaussianBlurPass = new KLGaussianBlurPass(settings.rtResolution, settings.iteration, settings.blurSize, 
            settings.copyColorMaterial, settings.blurMaterial);
        m_KLGaussianBlurPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_KLGaussianBlurPass);
    }
}



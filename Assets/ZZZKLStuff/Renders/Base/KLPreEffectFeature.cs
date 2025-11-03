using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLPreEffectFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class KLPreEffectRenderSettings
    {
        public int rtResolution = 1;
        public Material copyColorMaterial;
        public Material preEffectMaterial;
    }
    class KLPreEffectPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        //private RenderTargetHandle _CameraColorAttachment;
        private RenderTargetHandle _CustomColorTexture0;

        private int _RtResolution;
        private Material _CopyColorMaterial;
        private Material _PreEffectMaterial;
        public KLPreEffectPass(int rtResolution, Material copyColorMat, Material preEffectMat)
        {
            _ProfilingSampler = new ProfilingSampler("KL Pre Effect");
            _RtResolution = rtResolution;

            //_CameraColorAttachment.Init("_CameraColorAttachment");
            _CustomColorTexture0.Init("_CustomColorTexture0");
            _CopyColorMaterial = copyColorMat;
            _PreEffectMaterial = preEffectMat;
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
            if (_CopyColorMaterial == null || _PreEffectMaterial == null) return;
            var stack = VolumeManager.instance.stack;
            if (stack == null) return;
            ref CameraData cameraData = ref renderingData.cameraData;
            if (!cameraData.postProcessEnabled) return; // same as unity PP
            ScriptableRenderer renderer = cameraData.renderer;
            var colorAttachment = renderer.cameraColorTarget;
            bool isSceneViewCamera = cameraData.isSceneViewCamera;

            var _KLGaussianBlur = stack.GetComponent<KLGaussianBlur>();
            var _KLRadialBlur = stack.GetComponent<KLRadialBlur>();
            var _KLHeatDistortion = stack.GetComponent<KLHeatDistortion>();
            var _KLPixelizeQuad = stack.GetComponent<KLPixelizeQuad>();
            var _KLRGBSplit = stack.GetComponent<KLRGBSplit>();
            var _KLImageBlock = stack.GetComponent<KLImageBlock>();
            var _KLAdvancedImageBlock = stack.GetComponent<KLAdvancedImageBlock>();
            var _KLScanline = stack.GetComponent<KLScanline>();


            bool useKLGaussianBlur = _KLGaussianBlur.IsActive() && !isSceneViewCamera;
            bool useKLRadialBlur = _KLRadialBlur.IsActive() && !isSceneViewCamera;
            bool useKLHeatDistortion = _KLHeatDistortion.IsActive() && !isSceneViewCamera;
            bool useKLPixelizeQuad = _KLPixelizeQuad.IsActive() && !isSceneViewCamera;
            bool useKLRGBSplit = _KLRGBSplit.IsActive() && !isSceneViewCamera;
            bool useKLImageBlock = _KLImageBlock.IsActive() && !isSceneViewCamera;
            bool useKLAdvancedImageBlock = _KLAdvancedImageBlock.IsActive() && !isSceneViewCamera;
            bool useKLScanline = _KLScanline.IsActive() && !isSceneViewCamera;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                DisableAllKeywords(_PreEffectMaterial);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                if (useKLGaussianBlur)
                {
                    SetupKLGaussianBlur(_PreEffectMaterial, _KLGaussianBlur);
                }

                if (useKLRadialBlur)
                {
                    SetupKLRadialBlur(_PreEffectMaterial, _KLRadialBlur);
                }

                if (useKLHeatDistortion)
                {
                    SetupKLHeatDistortion(_PreEffectMaterial, _KLHeatDistortion);
                }

                if (useKLPixelizeQuad)
                {
                    SetupKLPixelizeQuad(_PreEffectMaterial, _KLPixelizeQuad);
                }

                if (useKLRGBSplit)
                {
                    SetupKLRGBSplit(_PreEffectMaterial, _KLRGBSplit);
                }
                else if (useKLImageBlock)
                {
                    SetupKLImageBlock(_PreEffectMaterial, _KLImageBlock);
                }
                else if (useKLAdvancedImageBlock)
                {
                    SetupKLRandomImageBlock(_PreEffectMaterial, _KLAdvancedImageBlock);
                }

                if (useKLScanline)
                {
                    SetupKLScanline(_PreEffectMaterial, _KLScanline);
                }

                //cmd.SetGlobalTexture("_SourceTex", colorAttachment);
                //cmd.SetRenderTarget(_CustomColorTexture0.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
                //    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
                cmd.Blit(colorAttachment, _CustomColorTexture0.Identifier(), _CopyColorMaterial, 0);
                cmd.SetGlobalTexture("_CustomColorTexture0", _CustomColorTexture0.Identifier());

                cmd.SetRenderTarget(renderer.cameraColorTarget, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
                    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
                cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, _PreEffectMaterial);
                cmd.SetViewProjectionMatrices(cameraData.GetViewMatrix(), cameraData.GetProjectionMatrix());
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);

        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_CustomColorTexture0.id);
        }


        // Disable material keywords
        private void DisableAllKeywords(Material mat)
        {
            mat.shaderKeywords = null;
        }

        

        private void SetupKLGaussianBlur(Material mat, KLGaussianBlur pp)
        {
            mat.EnableKeyword(ShaderConstants.kwRadialBlur);
            mat.SetFloat(ShaderConstants._KLBlurRadius, pp.blurRadius.value * 0.01f);
            mat.SetInteger(ShaderConstants._KLIteration, pp.iteration.value);
        }


        private void SetupKLRadialBlur(Material mat, KLRadialBlur pp)
        {
            mat.EnableKeyword(ShaderConstants.kwRadialBlur);
            mat.SetVector(ShaderConstants._KLRadialCenter, pp.radialCenter.value);
            mat.SetFloat(ShaderConstants._KLBlurRadius, pp.blurRadius.value * 0.01f);
            mat.SetInteger(ShaderConstants._KLIteration, pp.iteration.value);
        }
        private void SetupKLHeatDistortion(Material mat, KLHeatDistortion pp)
        {
            mat.EnableKeyword(ShaderConstants.kwHeatDistortion);
            mat.SetFloat(ShaderConstants._KLHDIntensity, pp.intensity.value * 0.05f);
            mat.SetVector(ShaderConstants._KLHDNoiseTillingSpeed, pp.noiseTillingSpeed.value);
            mat.SetTexture(ShaderConstants._KLHDNoiseTex, pp.noiseTexture.value);
        }

        private void SetupKLPixelizeQuad(Material mat, KLPixelizeQuad pp)
        {
            mat.EnableKeyword(ShaderConstants.kwPixelizeQuad);
            mat.SetFloat(ShaderConstants._KLPixelSize, pp.pixelSize.value);
            mat.SetFloat(ShaderConstants._KLPixelRatio, pp.pixelRatio.value);
        }

        private void SetupKLRGBSplit(Material mat, KLRGBSplit pp)
        {
            mat.EnableKeyword(ShaderConstants.kwRGBSplit);
            mat.SetFloat(ShaderConstants._KLRGBSplitIntensity, pp.intensity.value * 0.1f);
            mat.SetFloat(ShaderConstants._KLRGBSplitSpeed, pp.speed.value);
        }

        private void SetupKLImageBlock(Material mat, KLImageBlock pp)
        {
            mat.EnableKeyword(ShaderConstants.kwImageBlock);
            mat.SetFloat(ShaderConstants._KLImageBlockSpeed, pp.speed.value);
            mat.SetFloat(ShaderConstants._KLImageBlockSize, pp.size.value);
            mat.SetFloat(ShaderConstants._KLImageBlockRatio, pp.ratio.value);
        }

        private void SetupKLRandomImageBlock(Material mat, KLAdvancedImageBlock pp)
        {
            mat.EnableKeyword(ShaderConstants.kwAdvancedImageBlock);
            mat.SetFloat(ShaderConstants._KLRdImageBlockLayer1U, pp.blockLayer1U.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockLayer1V, pp.blockLayer1V.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockLayer2U, pp.blockLayer2U.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockLayer2V, pp.blockLayer2V.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockSpeed, pp.speed.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockLayer1Intensity, pp.blockLayer1Intensity.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockLayer2Intensity, pp.blockLayer2Intensity.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockRGBIntensity, pp.blockRGBIntensity.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockFade, pp.fade.value);
            mat.SetFloat(ShaderConstants._KLRdImageBlockOffset, pp.offset.value);
        }

        private void SetupKLScanline(Material mat, KLScanline pp)
        {
            mat.EnableKeyword(ShaderConstants.kwScanline);
            mat.SetFloat(ShaderConstants._KLSLRange, pp.range.value);
            mat.SetFloat(ShaderConstants._KLSLSmoothIntensity, pp.smoothIntensity.value);
            mat.SetFloat(ShaderConstants._KLSLSmoothWidth, pp.smoothWidth.value);
            mat.SetColor(ShaderConstants._KLSLSmoothColor, pp.smoothColor.value);
            mat.SetFloat(ShaderConstants._KLSLOutlineWidth, pp.outlineWidth.value);
            mat.SetColor(ShaderConstants._KLSLOutlineColor, pp.outlineColor.value);
            mat.SetVector(ShaderConstants._KLSLNoiseTillingSpeed, pp.noiseTillingSpeed.value);
            mat.SetTexture(ShaderConstants._KLSLNoiseTex, pp.noiseTex.value);
        }


        #region Internal Utilities

        private static class ShaderConstants
        {
            // Global Keywords
            public static readonly string kwGaussianBlur = "_KL_GAUSSIAN_BLUR";
            public static readonly string kwRadialBlur = "_KL_RADIAL_BLUR";
            public static readonly string kwHeatDistortion = "_KL_HEAT_DISTORTION";
            public static readonly string kwPixelizeQuad = "_KL_PIXELIZE_QUAD";
            public static readonly string kwRGBSplit = "_KL_RGB_SPLIT";
            public static readonly string kwImageBlock = "_KL_IMAGE_BLOCK";
            public static readonly string kwAdvancedImageBlock = "_KL_ADVANCED_IMAGE_BLOCK";
            public static readonly string kwScanline = "_KL_SCANLINE";


            // Shader Params
            public static readonly int _KLBlurRadius = Shader.PropertyToID("_KLBlurRadius");
            public static readonly int _KLIteration = Shader.PropertyToID("_KLIteration");
            public static readonly int _KLRadialCenter = Shader.PropertyToID("_KLRadialCenter");

            public static readonly int _KLHDIntensity = Shader.PropertyToID("_KLHDIntensity");
            public static readonly int _KLHDNoiseTillingSpeed = Shader.PropertyToID("_KLHDNoiseTillingSpeed");
            public static readonly int _KLHDNoiseTex = Shader.PropertyToID("_KLHDNoiseTex");

            public static readonly int _KLPixelSize = Shader.PropertyToID("_KLPixelSize");
            public static readonly int _KLPixelRatio = Shader.PropertyToID("_KLPixelRatio");

            public static readonly int _KLRGBSplitIntensity = Shader.PropertyToID("_KLRGBSplitIntensity");
            public static readonly int _KLRGBSplitSpeed = Shader.PropertyToID("_KLRGBSplitSpeed");

            public static readonly int _KLImageBlockSpeed = Shader.PropertyToID("_KLImageBlockSpeed");
            public static readonly int _KLImageBlockSize = Shader.PropertyToID("_KLImageBlockSize");
            public static readonly int _KLImageBlockRatio = Shader.PropertyToID("_KLImageBlockRatio");

            public static readonly int _KLRdImageBlockLayer1U = Shader.PropertyToID("_KLRdImageBlockLayer1U");
            public static readonly int _KLRdImageBlockLayer1V = Shader.PropertyToID("_KLRdImageBlockLayer1V");
            public static readonly int _KLRdImageBlockLayer2U = Shader.PropertyToID("_KLRdImageBlockLayer2U");
            public static readonly int _KLRdImageBlockLayer2V = Shader.PropertyToID("_KLRdImageBlockLayer2V");
            public static readonly int _KLRdImageBlockSpeed = Shader.PropertyToID("_KLRdImageBlockSpeed");
            public static readonly int _KLRdImageBlockLayer1Intensity = Shader.PropertyToID("_KLRdImageBlockLayer1Intensity");
            public static readonly int _KLRdImageBlockLayer2Intensity = Shader.PropertyToID("_KLRdImageBlockLayer2Intensity");
            public static readonly int _KLRdImageBlockRGBIntensity = Shader.PropertyToID("_KLRdImageBlockRGBIntensity");
            public static readonly int _KLRdImageBlockFade = Shader.PropertyToID("_KLRdImageBlockFade");
            public static readonly int _KLRdImageBlockOffset = Shader.PropertyToID("_KLRdImageBlockOffset");

            public static readonly int _KLSLRange = Shader.PropertyToID("_KLSLRange");
            public static readonly int _KLSLSmoothIntensity = Shader.PropertyToID("_KLSLSmoothIntensity");
            public static readonly int _KLSLSmoothWidth = Shader.PropertyToID("_KLSLSmoothWidth");
            public static readonly int _KLSLSmoothColor = Shader.PropertyToID("_KLSLSmoothColor");
            public static readonly int _KLSLOutlineWidth = Shader.PropertyToID("_KLSLOutlineWidth");
            public static readonly int _KLSLOutlineColor = Shader.PropertyToID("_KLSLOutlineColor");
            public static readonly int _KLSLNoiseTillingSpeed = Shader.PropertyToID("_KLSLNoiseTillingSpeed");
            public static readonly int _KLSLNoiseTex = Shader.PropertyToID("_KLSLNoiseTex");
        }

        #endregion
    }

    public KLPreEffectRenderSettings settings = new KLPreEffectRenderSettings();
    KLPreEffectPass _KLPreEffectPass;

    public override void Create()
    {
        _KLPreEffectPass = new KLPreEffectPass(settings.rtResolution, settings.copyColorMaterial, settings.preEffectMaterial);
        _KLPreEffectPass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLPreEffectPass);
    }
}



using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static KLRenderUtils;

public class KLScanlineSceneFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FilterSettings
    {
        public int lowerBound;
        public int upperBound;
        public LayerMask layerMask;
        public string[] shaderTagStrArray;

        public FilterSettings()
        {
            lowerBound = 0;
            upperBound = 5000;
            layerMask = 0;
        }
    }

    [System.Serializable]
    public class KLScanlineSceneRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public bool clearRT;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonOpaque;
        public FilterSettings filterSettings = new FilterSettings();
        public Material overrideMaterial = null; // Dot Mesh Shadow
    }



    class KLScanlineScenePass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        private LayerMask _LayerMask;
        private SortingCriteria _SortingCriteria;
        private FilteringSettings _FilteringSettings;
        private FilteringSettings _DMFilteringSettings;
        private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();
        private Material _OverrideMaterial;
        private bool _ClearRT;

        private RenderTargetHandle _CustomColorTexture1;
        private RenderTargetHandle _CustomDepthTexture1;
        public KLScanlineScenePass(LayerMask lm, SortingCriteria sc, int lb, int ub, string[] stsArray,
            bool clearRT, Material mat)
        {
            _ProfilingSampler = new ProfilingSampler("KL ScanlineScene");
            _LayerMask = lm;
            _SortingCriteria = sc;
            var renderQueueRange = new RenderQueueRange(lb, ub);
            _FilteringSettings = new FilteringSettings(renderQueueRange, _LayerMask);
            _DMFilteringSettings = new FilteringSettings(renderQueueRange, _LayerMask);
            _DMFilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.DotMeshShadow;
            _OverrideMaterial = mat;
            if (stsArray != null && stsArray.Length > 0)
            {
                foreach (string sts in stsArray)
                {
                    _ShaderTagIdList.Add(new ShaderTagId(sts));
                }
            }
            else
            {
                _ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
                _ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
                _ShaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
            }
            _ClearRT = clearRT;
            _CustomColorTexture1.Init("_CustomColorTexture1");
            _CustomDepthTexture1.Init("_CustomDepthTexture1");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
#if UNITY_EDITOR
            bool isSceneViewOrPreviewCamera = cameraData.isSceneViewCamera || cameraData.cameraType == CameraType.Preview;
            if (isSceneViewOrPreviewCamera) return;
#endif
            ScriptableRenderer renderer = cameraData.renderer;
            RenderTextureDescriptor colorDescriptor = cameraData.cameraTargetDescriptor;
            RenderTextureDescriptor depthDescriptor = cameraData.cameraTargetDescriptor;
            depthDescriptor.colorFormat = RenderTextureFormat.Depth;
            depthDescriptor.depthBufferBits = 32;
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                cmd.GetTemporaryRT(_CustomColorTexture1.id, colorDescriptor, FilterMode.Bilinear);
                cmd.GetTemporaryRT(_CustomDepthTexture1.id, depthDescriptor, FilterMode.Point);
                cmd.SetGlobalTexture("_CustomColorTexture1", _CustomColorTexture1.Identifier());
                cmd.SetRenderTarget(_CustomColorTexture1.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
                    _CustomDepthTexture1.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
                if (_ClearRT)
                {
                    cmd.ClearRenderTarget(true, true, Color.black);
                }
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                DrawingSettings drawingSettings = CreateDrawingSettings(_ShaderTagIdList, ref renderingData, _SortingCriteria);
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);

                DrawingSettings dotMeshDrawingSettings = CreateDrawingSettings(_ShaderTagIdList, ref renderingData, SortingCriteria.CommonTransparent);
                dotMeshDrawingSettings.overrideMaterial = _OverrideMaterial;
                dotMeshDrawingSettings.overrideMaterialPassIndex = 0;
                context.DrawRenderers(renderingData.cullResults, ref dotMeshDrawingSettings, ref _DMFilteringSettings);

                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_CustomColorTexture1.id);
            cmd.ReleaseTemporaryRT(_CustomDepthTexture1.id);
        }
    }

    public KLScanlineSceneRenderSettings settings = new KLScanlineSceneRenderSettings();
    KLScanlineScenePass _KLScanlineScenePass;

    public override void Create()
    {
        FilterSettings filteringSettings = settings.filterSettings;
        _KLScanlineScenePass = new KLScanlineScenePass(filteringSettings.layerMask, settings.sortingCriteria,
            filteringSettings.lowerBound, filteringSettings.upperBound, filteringSettings.shaderTagStrArray,
            settings.clearRT, settings.overrideMaterial);
        _KLScanlineScenePass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLScanlineScenePass);
    }
}



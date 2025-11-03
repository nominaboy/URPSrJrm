using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLMapFogFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FilterSettings
    {
        public int lowerBound;
        public int upperBound;
        public LayerMask layerMask;
        public FilterSettings()
        {
            lowerBound = 0;
            upperBound = 5000;
            layerMask = 0;
        }
    }

    [System.Serializable]
    public class KLMapFogRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
        public int rtResolution = 4;
        public FilterSettings filterSettings = new FilterSettings();
    }

    class KLMapFogPass : ScriptableRenderPass
    {
        private bool _SupportsR8RenderTextureFormat = SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.R8);

        private ProfilingSampler _ProfilingSampler;
        private LayerMask _LayerMask;
        private SortingCriteria _SortingCriteria;
        private FilteringSettings _FilteringSettings;
        private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();

        private int _RtResolution;
        private RenderTargetHandle _MapFogRenderTexture;
        public KLMapFogPass(int rtResolution, LayerMask lm, SortingCriteria sc, int lb, int ub)
        {
            _ProfilingSampler = new ProfilingSampler("KL Map Fog");
            _RtResolution = rtResolution;
            _MapFogRenderTexture.Init("_MapFogRenderTexture");
            _LayerMask = lm;
            _SortingCriteria = sc;
            _FilteringSettings = new FilteringSettings(new RenderQueueRange(lb, ub), _LayerMask);
            _ShaderTagIdList.Add(new ShaderTagId("ChapterMapFog"));
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            descriptor.colorFormat = _SupportsR8RenderTextureFormat ? RenderTextureFormat.R8 : RenderTextureFormat.ARGB32;
            descriptor.width = Mathf.FloorToInt(descriptor.width / _RtResolution);
            descriptor.height = Mathf.FloorToInt(descriptor.height / _RtResolution);
            cmd.GetTemporaryRT(_MapFogRenderTexture.id, descriptor, _RtResolution == 1 ? FilterMode.Point : FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
            ScriptableRenderer renderer = cameraData.renderer;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                cmd.SetGlobalTexture("_MapFogRenderTexture", _MapFogRenderTexture.Identifier());
                cmd.SetRenderTarget(_MapFogRenderTexture.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
                    RenderBufferLoadAction.DontCare, RenderBufferStoreAction.DontCare);
                cmd.ClearRenderTarget(true, true, Color.white);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                DrawingSettings drawingSettings = CreateDrawingSettings(_ShaderTagIdList, ref renderingData, _SortingCriteria);
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);
                cmd.SetRenderTarget(renderer.cameraColorTarget, renderer.cameraDepthTarget);

            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(_MapFogRenderTexture.id);
        }
    }

    public KLMapFogRenderSettings settings = new KLMapFogRenderSettings();
    KLMapFogPass _KLMapFogPass;
    public override void Create()
    {
        var filterSettings = settings.filterSettings;
        _KLMapFogPass = new KLMapFogPass(settings.rtResolution, filterSettings.layerMask, settings.sortingCriteria,
            filterSettings.lowerBound, filterSettings.upperBound);
        _KLMapFogPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLMapFogPass);
    }
}



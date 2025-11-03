using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLTransVfxFeature : ScriptableRendererFeature
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
    public class KLTransVfxRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public int rtResolution = 2;
        public bool clearRT;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
        public FilterSettings filterSettings = new FilterSettings();
    }



    class KLTransVfxPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        private LayerMask _LayerMask;
        private SortingCriteria _SortingCriteria;
        private FilteringSettings _FilteringSettings;
        private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();

        private int _RtResolution;
        private bool _ClearRT;
        private RenderTargetHandle _CustomColorTexture0;
        private RenderTargetHandle _CustomDepthTexture0;

        public KLTransVfxPass(LayerMask lm, SortingCriteria sc, int lb, int ub, string[] stsArray,
            int rtResolution, bool clearRT)
        {
            _ProfilingSampler = new ProfilingSampler("KL TransVfx");
            _LayerMask = lm;
            _SortingCriteria = sc;
            _FilteringSettings = new FilteringSettings(new RenderQueueRange(lb, ub), _LayerMask);

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

            _RtResolution = rtResolution;
            _ClearRT = clearRT;
            _CustomColorTexture0.Init("_CustomColorTexture0");
            _CustomDepthTexture0.Init("_CustomDepthTexture0");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
//#if UNITY_EDITOR
//            bool isSceneViewOrPreviewCamera = cameraData.isSceneViewCamera || cameraData.cameraType == CameraType.Preview;
//            if (isSceneViewOrPreviewCamera) return;
//#endif
            ScriptableRenderer renderer = cameraData.renderer;
            RenderTextureDescriptor colorDescriptor = cameraData.cameraTargetDescriptor;
            colorDescriptor.colorFormat = RenderTextureFormat.ARGBHalf; // HDR and Alpha channel
            colorDescriptor.width /= _RtResolution;
            colorDescriptor.height /= _RtResolution;


            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();


                cmd.GetTemporaryRT(_CustomColorTexture0.id, colorDescriptor, FilterMode.Bilinear);
                cmd.SetRenderTarget(_CustomColorTexture0.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store, 
                    _CustomDepthTexture0.Identifier(), RenderBufferLoadAction.Load, RenderBufferStoreAction.DontCare);
                if (_ClearRT)
                {
                    cmd.ClearRenderTarget(false, true, Color.black); // Default Alpha is 1
                }

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                // Draw Transparent Objects
                DrawingSettings drawingSettings = CreateDrawingSettings(_ShaderTagIdList, ref renderingData, _SortingCriteria);

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    public KLTransVfxRenderSettings settings = new KLTransVfxRenderSettings();
    KLTransVfxPass _KLTransVfxPass;

    public override void Create()
    {
        FilterSettings filteringSettings = settings.filterSettings;
        _KLTransVfxPass = new KLTransVfxPass(filteringSettings.layerMask, settings.sortingCriteria,
            filteringSettings.lowerBound, filteringSettings.upperBound, filteringSettings.shaderTagStrArray,
            settings.rtResolution, settings.clearRT);

        _KLTransVfxPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLTransVfxPass);
    }
}



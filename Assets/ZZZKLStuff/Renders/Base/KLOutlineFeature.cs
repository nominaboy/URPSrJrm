using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static KLRenderUtils;

public class KLOutlineFeature : ScriptableRendererFeature
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
    public class KLOutlineRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonOpaque;
        public FilterSettings filterSettings = new FilterSettings();
        public Material[] overrideMaterial = null;
    }


    class KLOutlinePass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        private LayerMask _LayerMask;
        private SortingCriteria _SortingCriteria;
        private FilteringSettings _FilteringSettings;
        private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();
        public Material[] overrideMaterial { get; set; }

        public KLOutlinePass(LayerMask lm, SortingCriteria sc, int lb, int ub, string[] stsArray)
        {
            _ProfilingSampler = new ProfilingSampler("KL Outline");
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
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
            Camera camera = cameraData.camera;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                DrawingSettings drawingSettings = CreateDrawingSettings(_ShaderTagIdList, ref renderingData, _SortingCriteria);

                #region Battle

                // Black Outline
                _FilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.BlackOutline;
                drawingSettings.overrideMaterial = overrideMaterial[0];
                drawingSettings.overrideMaterialPassIndex = 0;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);

                // Red Outline
                _FilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.RedOutline;
                drawingSettings.overrideMaterial = overrideMaterial[1];
                drawingSettings.overrideMaterialPassIndex = 0;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);

                // White Outline
                _FilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.WhiteOutline;
                drawingSettings.overrideMaterial = overrideMaterial[2];
                drawingSettings.overrideMaterialPassIndex = 1;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);

                // PosWS Clip Black Outline
                _FilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.BlackOutlineClip;
                drawingSettings.overrideMaterial = overrideMaterial[3];
                drawingSettings.overrideMaterialPassIndex = 3;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);

                #endregion


                #region CardMachine

                // Black Outline Without Stencil Test
                _FilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.BlackOutlineNoStencil;
                drawingSettings.overrideMaterial = overrideMaterial[4];
                drawingSettings.overrideMaterialPassIndex = 2;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings); 

                #endregion
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    public KLOutlineRenderSettings settings = new KLOutlineRenderSettings();
    private KLOutlinePass _KLOutlinePass;
    public override void Create()
    {
        FilterSettings filterSettings = settings.filterSettings;
        _KLOutlinePass = new KLOutlinePass(filterSettings.layerMask, settings.sortingCriteria,
            filterSettings.lowerBound, filterSettings.upperBound, filterSettings.shaderTagStrArray);
        _KLOutlinePass.overrideMaterial = settings.overrideMaterial;
        _KLOutlinePass.renderPassEvent = settings.renderPassEvent;
    }
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLOutlinePass);
    }
}



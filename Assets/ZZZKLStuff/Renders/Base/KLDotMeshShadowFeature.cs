using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static KLRenderUtils;

public class KLDotMeshShadowFeature : ScriptableRendererFeature
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
    public class KLDMSRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingSkybox;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
        public FilterSettings filterSettings = new FilterSettings();
        public Material overrideMaterial = null;
    }



    class KLDotMeshShadowPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        private LayerMask _LayerMask;
        private SortingCriteria _SortingCriteria;
        private FilteringSettings _FilteringSettings;
        private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();
        public Material overrideMaterial { get; set; }

        public KLDotMeshShadowPass(LayerMask lm, SortingCriteria sc, int lb, int ub, string[] stsArray)
        {
            _ProfilingSampler = new ProfilingSampler("KL DotMeshShadow");
            _LayerMask = lm;
            _SortingCriteria = sc;
            _FilteringSettings = new FilteringSettings(new RenderQueueRange(lb, ub), _LayerMask);
            _FilteringSettings.renderingLayerMask = (uint)CustomRenderingLayerMask.DotMeshShadow;

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
                drawingSettings.overrideMaterial = overrideMaterial;
                drawingSettings.overrideMaterialPassIndex = 0;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref _FilteringSettings);
            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    public KLDMSRenderSettings settings = new KLDMSRenderSettings();
    private KLDotMeshShadowPass _KLDotMeshShadowPass;
    public override void Create()
    {
        FilterSettings filterSettings = settings.filterSettings;
        _KLDotMeshShadowPass = new KLDotMeshShadowPass(filterSettings.layerMask, settings.sortingCriteria,
            filterSettings.lowerBound, filterSettings.upperBound, filterSettings.shaderTagStrArray);
        _KLDotMeshShadowPass.overrideMaterial = settings.overrideMaterial;
        _KLDotMeshShadowPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLDotMeshShadowPass);
    }

}



using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FurFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class FurFilterSettings
    {
        public int lowerBound;
        public int upperBound;

        public LayerMask layerMask;
        public string[] shaderTagStrArray;

        public FurFilterSettings()
        {
            lowerBound = 0;
            upperBound = 5000;
            layerMask = 0;
        }
    }

    [System.Serializable]
    public class FurRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
        public FurFilterSettings filterSettings = new FurFilterSettings();
        [Range(2, 200)]
        public int furLayerNum = 2;
    }



    class FurPass : ScriptableRenderPass
    {
        private ProfilingSampler m_ProfilingSampler;
        private LayerMask m_LayerMask;
        private SortingCriteria m_SortingCriteria;
        private FilteringSettings m_FilteringSettings;
        private List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
        private int m_FurLayerNum;



        public FurPass(LayerMask lm, SortingCriteria sc, int lb, int ub, string[] stsArray, int fln)
        {
            m_ProfilingSampler = new ProfilingSampler("JRM Fur");
            m_LayerMask = lm;
            m_SortingCriteria = sc;
            m_FilteringSettings = new FilteringSettings(new RenderQueueRange(lb, ub), m_LayerMask);

            if (stsArray != null && stsArray.Length > 0)
            {
                foreach (string sts in stsArray)
                {
                    m_ShaderTagIdList.Add(new ShaderTagId(sts));
                }
            }
            else
            {
                m_ShaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
                m_ShaderTagIdList.Add(new ShaderTagId("UniversalForward"));
                m_ShaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
            }
            m_FurLayerNum = fln;
        }


        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagIdList[0], ref renderingData, SortingCriteria.CommonOpaque);

                cmd.SetGlobalFloat("_FUR_LAYER", 0f);
                context.ExecuteCommandBuffer(cmd);
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);

                drawingSettings = CreateDrawingSettings(m_ShaderTagIdList[1], ref renderingData, m_SortingCriteria);

                for (int i = 1; i < m_FurLayerNum; i++)                                                  
                {
                    cmd.Clear();
                    cmd.SetGlobalFloat("_FUR_LAYER", i / (m_FurLayerNum - 1.0f));
                    context.ExecuteCommandBuffer(cmd);
                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
                }                                                                                       

            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

    }

    public FurRenderSettings settings = new FurRenderSettings();
    FurPass m_FurPass;

    /// <inheritdoc/>
    public override void Create()
    {
        FurFilterSettings filterSettings = settings.filterSettings;
        m_FurPass = new FurPass(filterSettings.layerMask, settings.sortingCriteria,
            filterSettings.lowerBound, filterSettings.upperBound, filterSettings.shaderTagStrArray, 
            settings.furLayerNum);
        m_FurPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_FurPass);
    }
}



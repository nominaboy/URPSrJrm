using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLSceneInteractionFeature : ScriptableRendererFeature
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
    public class KLSceneInteractionRenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
        public int rtResolution = 1;
        public bool clearRT;
        public SortingCriteria sortingCriteria = SortingCriteria.CommonTransparent;
        public FilterSettings filterSettings = new FilterSettings();
    }



    class KLSceneInteractionPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        private LayerMask _LayerMask;
        private SortingCriteria _SortingCriteria;
        private FilteringSettings _FilteringSettings;
        private List<ShaderTagId> _ShaderTagIdList = new List<ShaderTagId>();
        private int _RtResolution;
        private bool _ClearRT;

        private RenderTargetHandle _SceneInteractionColorTexture;
        //private RenderTargetHandle _SceneInteractionDepthTexture;

        public KLSceneInteractionPass(LayerMask lm, SortingCriteria sc, int lb, int ub, string[] stsArray,
            int rtResolution, bool clearRT)
        {
            _ProfilingSampler = new ProfilingSampler("KL SceneInteraction");
            _LayerMask = lm;
            _SortingCriteria = sc;
            var renderQueueRange = new RenderQueueRange(lb, ub);
            _FilteringSettings = new FilteringSettings(renderQueueRange, _LayerMask);
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
            _SceneInteractionColorTexture.Init("_SceneInteractionColorTexture");
            //_SceneInteractionDepthTexture.Init("_SceneInteractionDepthTexture");
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;
            //descriptor.colorFormat = RenderTextureFormat.ARGBHalf; // HDR and Alpha channel
            descriptor.width = Mathf.FloorToInt(descriptor.width / _RtResolution);
            descriptor.height = Mathf.FloorToInt(descriptor.height / _RtResolution);

            cmd.GetTemporaryRT(_SceneInteractionColorTexture.id, descriptor, _RtResolution == 1 ? FilterMode.Point : FilterMode.Bilinear);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
#if UNITY_EDITOR
            bool isSceneViewOrPreviewCamera = cameraData.isSceneViewCamera || cameraData.cameraType == CameraType.Preview;
            if (isSceneViewOrPreviewCamera) return;
#endif
            ScriptableRenderer renderer = cameraData.renderer;
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                cmd.SetGlobalTexture("_SceneInteractionColorTexture", _SceneInteractionColorTexture.Identifier());
                cmd.SetRenderTarget(_SceneInteractionColorTexture.Identifier(), RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
                if (_ClearRT)
                {
                    cmd.ClearRenderTarget(true, true, Color.clear);
                }
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
            cmd.ReleaseTemporaryRT(_SceneInteractionColorTexture.id);
            //cmd.ReleaseTemporaryRT(_SceneInteractionDepthTexture.id);
        }
    }

    public KLSceneInteractionRenderSettings settings = new KLSceneInteractionRenderSettings();
    KLSceneInteractionPass _KLSceneInteractionPass;

    public override void Create()
    {
        FilterSettings filteringSettings = settings.filterSettings;
        _KLSceneInteractionPass = new KLSceneInteractionPass(filteringSettings.layerMask, settings.sortingCriteria,
            filteringSettings.lowerBound, filteringSettings.upperBound, filteringSettings.shaderTagStrArray,
            settings.rtResolution, settings.clearRT);
        _KLSceneInteractionPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLSceneInteractionPass);
    }
}



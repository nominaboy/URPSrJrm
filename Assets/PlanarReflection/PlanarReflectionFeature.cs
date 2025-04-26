using System.Collections.Generic;
using UnityEditor.Build.Content;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class PlanarReflectionFeature : ScriptableRendererFeature {
    [SerializeField]
    public SortingCriteria sortingCriteria = SortingCriteria.BackToFront;
    [SerializeField]
    public LayerMask layerMask = -1;
    [SerializeField]
    public int lowerBound;
    [SerializeField]
    public int upperBound;
    [SerializeField]
    public bool enableExtraCulling;
    [SerializeField]
    public RenderPassEvent renderPassEvent = RenderPassEvent.BeforeRenderingOpaques;
    class PlanarReflectionPass : ScriptableRenderPass {
        private ProfilingSampler m_ProfilingSampler;
        private SortingCriteria m_SortingCriteria;
        private LayerMask m_LayerMask;
        private FilteringSettings m_FilteringSettings;
        private bool m_EnableExtraCulling;

        private int m_PlanarReflectionRTId = Shader.PropertyToID("_PlanarReflectionRT");
        private ShaderTagId m_ShaderTagId = new ShaderTagId("PlanarReflection");

        private PlanarReflectionMgr m_PlanarReflectionMgr;
        public PlanarReflectionPass(SortingCriteria sc, LayerMask lm, int lb, int ub, bool ec) {
            m_ProfilingSampler = new ProfilingSampler("Planar Reflection");
            m_SortingCriteria = sc;
            m_LayerMask = lm;
            m_FilteringSettings = new FilteringSettings(new RenderQueueRange(lb, ub), m_LayerMask);
            m_EnableExtraCulling = ec;
        }


        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData) {
            m_PlanarReflectionMgr = PlanarReflectionMgr.Instance;
            if (m_PlanarReflectionMgr == null) return;

            RenderTextureDescriptor rtSettings = renderingData.cameraData.cameraTargetDescriptor;
            rtSettings.colorFormat = RenderTextureFormat.ARGB32;
            rtSettings.width = 1920;
            rtSettings.height = 1080;
            rtSettings.depthBufferBits = 0;
            rtSettings.sRGB = true;
            rtSettings.useMipMap = true;
            rtSettings.mipCount = 6;

            cmd.GetTemporaryRT(m_PlanarReflectionRTId, rtSettings, FilterMode.Bilinear);
            ConfigureTarget(m_PlanarReflectionRTId);
            ConfigureClear(ClearFlag.Color, Color.clear);
        }


        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
            if (m_PlanarReflectionMgr == null) return;
            ref CameraData cameraData = ref renderingData.cameraData;
            Camera camera = cameraData.camera;

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler)) {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                Vector3 planeNormal = Vector3.up;
                Vector3 pointO = m_PlanarReflectionMgr.plane.position;
                float d = -Vector3.Dot(pointO, planeNormal);
                Vector4 reflPlane = new Vector4(planeNormal.x, planeNormal.y, planeNormal.z, d);

                Matrix4x4 planarReflMat = MathUtils.CalculateReflectionMatrix(reflPlane);
                cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix * planarReflMat, camera.projectionMatrix);
                cmd.SetInvertCulling(true);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                DrawingSettings drawingSettings = CreateDrawingSettings(m_ShaderTagId, ref renderingData, m_SortingCriteria);
#if UNITY_EDITOR
                if (renderingData.cameraData.isPreviewCamera) {
                    m_FilteringSettings.layerMask = -1;
                }
                else {
                    m_FilteringSettings.layerMask = m_LayerMask;
                }
#endif
                if (m_EnableExtraCulling && camera.TryGetCullingParameters(out var cullingParameters)) {
                    Matrix4x4 cullingMatrix = camera.projectionMatrix * camera.worldToCameraMatrix * planarReflMat;
                    Plane[] frustumPlanes = GeometryUtility.CalculateFrustumPlanes(cullingMatrix);
                    for (int i = 0; i < 6; i++) {
                        cullingParameters.SetCullingPlane(i, frustumPlanes[i]);
                    }
                    CullingResults reflCullingResults = context.Cull(ref cullingParameters);
                    context.DrawRenderers(reflCullingResults, ref drawingSettings, ref m_FilteringSettings);
                }
                else {
                    context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref m_FilteringSettings);
                }

                cmd.SetViewProjectionMatrices(cameraData.GetViewMatrix(), cameraData.GetProjectionMatrix());
                cmd.SetInvertCulling(false);
                cmd.EnableShaderKeyword("ENABLE_PR");
                cmd.SetGlobalTexture(RenderTextureNameUtils._PlanarReflectionRenderTexture, m_PlanarReflectionRTId);

            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd) {
            base.OnCameraCleanup(cmd);
            cmd.DisableShaderKeyword("ENABLE_PR");
        }
    }

    PlanarReflectionPass m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create() {
        m_ScriptablePass = new PlanarReflectionPass(sortingCriteria, layerMask, lowerBound, upperBound, enableExtraCulling);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = renderPassEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}



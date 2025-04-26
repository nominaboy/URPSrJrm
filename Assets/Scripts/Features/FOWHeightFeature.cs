using UnityEditor.Build.Content;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FOWHeightFeature : ScriptableRendererFeature {
    public Material FOWHeightMaterial;
    class FOWHeightPass : ScriptableRenderPass {
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        private ProfilingSampler m_ProfilingSampler;
        private Material m_FOWHeightMaterial;

        private int FOWHeightRTId = Shader.PropertyToID("_FOWHeightRT");

        public FOWHeightPass(Material mat) {
            m_ProfilingSampler = new ProfilingSampler("FOWHeight");
            m_FOWHeightMaterial = mat;
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData) {

            RenderTextureDescriptor rtSettings = renderingData.cameraData.cameraTargetDescriptor;
            rtSettings.colorFormat = RenderTextureFormat.ARGB32;
            rtSettings.width = 1024;
            rtSettings.height = 1024;
            rtSettings.depthBufferBits = 0;
            rtSettings.sRGB = true;

            cmd.GetTemporaryRT(FOWHeightRTId, rtSettings, FilterMode.Bilinear);
            ConfigureTarget(FOWHeightRTId);
            ConfigureClear(ClearFlag.Color, Color.clear);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, m_ProfilingSampler)) {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                ref CameraData cameraData = ref renderingData.cameraData;

                cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
                cmd.DrawMesh(RenderingUtils.FullScreenMesh, Matrix4x4.identity, m_FOWHeightMaterial, 0, 0);
                cmd.SetViewProjectionMatrices(cameraData.GetViewMatrix(), cameraData.GetProjectionMatrix());
                cmd.SetGlobalTexture(RenderTextureNameUtils._FOWHeightRenderTexture, FOWHeightRTId);

            }
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }



        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd) {
            cmd.ReleaseTemporaryRT(FOWHeightRTId);
        }
    }

    FOWHeightPass m_FOWHeightPass;

    /// <inheritdoc/>
    public override void Create() {
        m_FOWHeightPass = new FOWHeightPass(FOWHeightMaterial);

        // Configures where the render pass should be injected.
        m_FOWHeightPass.renderPassEvent = RenderPassEvent.BeforeRendering;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        renderer.EnqueuePass(m_FOWHeightPass);
    }
}



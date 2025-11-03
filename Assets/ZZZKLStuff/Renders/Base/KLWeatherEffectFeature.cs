using System.Collections.Generic;
using SpaceWar;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class KLWeatherEffectFeature : ScriptableRendererFeature, IComRenderScript
{
    [System.Serializable]
    public class KLWERenderSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material;
    }

    class KLWeatherEffectPass : ScriptableRenderPass
    {
        private ProfilingSampler _ProfilingSampler;
        private Material _RainMateiral;

        public float globalGameSpeed = 1f;
        public bool isRainy = false;
        public KLWeatherEffectPass(Material mat)
        {
            _ProfilingSampler = new ProfilingSampler("KL Weather Effect");
            _RainMateiral = mat;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            ref CameraData cameraData = ref renderingData.cameraData;
            Camera currentCam = cameraData.camera;
            if (!currentCam.CompareTag("MainCamera"))
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get();
            using (new ProfilingScope(cmd, _ProfilingSampler))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);

                #region Rainy

                cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, _RainMateiral, 0, 0);

                #endregion

                cmd.SetViewProjectionMatrices(cameraData.GetViewMatrix(), cameraData.GetProjectionMatrix());
            }

            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }
    }

    public KLWERenderSettings settings = new KLWERenderSettings();
    private static KLWeatherEffectPass _KLWeatherEffectPass;

    public override void Create()
    {
        _KLWeatherEffectPass = new KLWeatherEffectPass(settings.material);
        _KLWeatherEffectPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(_KLWeatherEffectPass);
    }

    public void setSpeed(float speed)
    {
        _KLWeatherEffectPass.globalGameSpeed = speed;
    }

    public void UpdateData(object param)
    {
        List<int> weather = param as List<int>;
        _KLWeatherEffectPass.isRainy = weather.IndexOf((int)WeatherType.Rainy) != -1;
    }
}
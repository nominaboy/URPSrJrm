using System.Collections.Generic;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine;
using System.Reflection;
using System;



namespace CatVFX
{
    public class CatPostProcess : ScriptableRendererFeature
    {
        public class ScreenDistortionCachePass : ScriptableRenderPass
        {
            RenderTargetHandle cacheFramebuffer;
            RenderTargetIdentifier colorAttachment;
            private static ShaderTagId litShaderTagId = new ShaderTagId("ScreenDistortionCache");
            bool setupResult = false;

            public ScreenDistortionCachePass()
            {
                renderPassEvent = RenderPassEvent.BeforeRenderingTransparents;
                cacheFramebuffer.Init("_ScreenDistortionCache");
            }
            public void Setup(RenderTargetIdentifier colorAttachment)
            {
                setupResult = false;

                this.colorAttachment = colorAttachment;

                var stack = VolumeManager.instance.stack;
                var screenDistortion = stack.GetComponent<ScreenDistortion>();
                if (!screenDistortion.IsActive())
                {
                    return;
                }

                setupResult = true;
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (!setupResult)
                {
                    return;
                }
                CommandBuffer cmd = CommandBufferPool.Get("ScreenDistortionCachePass");

                RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.width /= 2;
                desc.height /= 2;
                cmd.GetTemporaryRT(cacheFramebuffer.id, desc);
                cmd.SetRenderTarget(cacheFramebuffer.Identifier());
                cmd.ClearRenderTarget(true, true, Color.clear);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var sortingSettings = new SortingSettings() { criteria = SortingCriteria.CommonTransparent };
                var drawingSettings = new DrawingSettings(litShaderTagId, sortingSettings);
                int renderingLayerMask = -1;
                var filteringSettings = new FilteringSettings(renderingLayerMask: (uint)renderingLayerMask, renderQueueRange: RenderQueueRange.transparent, layerMask: -1);

                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);
                cmd.SetGlobalTexture(cacheFramebuffer.id, cacheFramebuffer.Identifier());


                cmd.SetRenderTarget(colorAttachment);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                CommandBufferPool.Release(cmd);
            }
            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(cacheFramebuffer.id);
            }
        }
        public class ScreenDistortionPass : ScriptableRenderPass
        {
            public RenderTargetHandle screenDistortionColor;
            public RenderTargetHandle previousColor;
            public ScreenDistortion screenDistortion;
            public Material screenDistortionMaterial;
            bool setupResult = false;

            public ScreenDistortionPass()
            {
                renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
                screenDistortionColor.Init("_ScreenDistortionColor");

            }
            public RenderTargetHandle Setup(RenderTargetHandle previousColor, Material screenDistortionMaterial)
            {
                setupResult = false;
                this.previousColor = previousColor;
                this.screenDistortionMaterial = screenDistortionMaterial;

                if (!screenDistortionMaterial)
                {
                    return previousColor;
                }

                var stack = VolumeManager.instance.stack;
                screenDistortion = stack.GetComponent<ScreenDistortion>();
                if (!screenDistortion.IsActive())
                {
                    return previousColor;
                }
                setupResult = true;
                return screenDistortionColor;
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (!setupResult)
                {
                    return;
                }
                screenDistortionMaterial.SetFloat("_Intensity", screenDistortion.intensity.value);

                CommandBuffer cmd = CommandBufferPool.Get("ScreenDistortionPass");

                RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.width /= 2;
                desc.height /= 2;
                cmd.GetTemporaryRT(screenDistortionColor.id, desc);
                cmd.SetGlobalTexture(screenDistortionColor.id, screenDistortionColor.Identifier());

                Blit(cmd, previousColor.Identifier(), screenDistortionColor.Identifier(), screenDistortionMaterial);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                CommandBufferPool.Release(cmd);
            }
            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(screenDistortionColor.id);
            }
        }

        public class RadialBlurPass : ScriptableRenderPass
        {
            public RenderTargetHandle radialBlurColor;
            public RenderTargetHandle previousColor;
            public RadialBlur radialBlur;
            public Material radialBlurMaterial;
            bool setupResult = false;

            public RadialBlurPass()
            {
                renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
                radialBlurColor.Init("_RadialBlurColor");

            }
            public RenderTargetHandle Setup(RenderTargetHandle previousColor, Material radialBlurMaterial)
            {
                setupResult = false;
                     
                this.previousColor = previousColor;
                this.radialBlurMaterial = radialBlurMaterial;
                if (!radialBlurMaterial) 
                {
                    return previousColor;
                }
                var stack = VolumeManager.instance.stack;
                radialBlur = stack.GetComponent<RadialBlur>();
                if (!radialBlur.IsActive())
                {
                    return previousColor;
                }

                setupResult = true;
                return radialBlurColor;
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (!setupResult)
                {
                    return;
                }

                radialBlurMaterial.SetInt("_SampleCount", radialBlur.sampleCount.value);
                radialBlurMaterial.SetFloat("_Blur", radialBlur.blur.value);

                CommandBuffer cmd = CommandBufferPool.Get("RadialBlurPass");

                RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
                desc.width /= 2;
                desc.height /= 2;
                cmd.GetTemporaryRT(radialBlurColor.id, desc);
                cmd.SetGlobalTexture(radialBlurColor.id, radialBlurColor.Identifier());

                Blit(cmd, previousColor.Identifier(), radialBlurColor.Identifier(), radialBlurMaterial);

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                CommandBufferPool.Release(cmd);
            }
            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(radialBlurColor.id);
            }
        }

        public class PostUberBlitPass : ScriptableRenderPass
        {
            public RenderTargetHandle resultColor;
            public RenderTargetHandle previousColor;
            public RenderTargetHandle tempColor;

            public Material uberMaterial;

            ChromaticAberration chromaticAberration;

            public PostUberBlitPass()
            {
                renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
                tempColor.Init("_PostUberBlitTemp");
            }
            public void Setup(RenderTargetHandle previousColor, RenderTargetHandle resultColor, Material uberMaterial)
            {
                this.previousColor = previousColor;
                this.resultColor = resultColor;
                this.uberMaterial = uberMaterial;
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                CommandBuffer cmd = CommandBufferPool.Get("PostBlitPass");

                if (uberMaterial)
                {
                    bool hasPostProcess = false;

                    var stack = VolumeManager.instance.stack;
                    chromaticAberration = stack.GetComponent<ChromaticAberration>();
                    if (chromaticAberration.IsActive())
                    {
                        uberMaterial.EnableKeyword("_CHROMATIC_ABERRATION");
                        uberMaterial.SetVector("_ChromaticAberration_Split", chromaticAberration.split.value);
                        uberMaterial.SetFloat("_ChromaticAberration_Blur", chromaticAberration.blur.value);
                        uberMaterial.SetFloat("_ChromaticAberration_Radial", chromaticAberration.radial.value);
                        hasPostProcess = true;
                    }
                    else
                    {
                        uberMaterial.DisableKeyword("_CHROMATIC_ABERRATION");
                    }
                    if (previousColor == resultColor) // if only has uber pass
                    {
                        if (hasPostProcess)
                        {
                            RenderTextureDescriptor desc = renderingData.cameraData.cameraTargetDescriptor;
                            cmd.GetTemporaryRT(tempColor.id, desc);
                            Blit(cmd, resultColor.Identifier(), tempColor.Identifier());
                            Blit(cmd, tempColor.Identifier(), resultColor.Identifier(), uberMaterial);
                        }
                    }
                    else
                    {
                        Blit(cmd, previousColor.Identifier(), resultColor.Identifier(), uberMaterial);
                    }

                }
                else
                {
                    if (previousColor != resultColor)
                    {
                        Blit(cmd, previousColor.Identifier(), resultColor.Identifier());
                    }
                }

                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                CommandBufferPool.Release(cmd);
            }
            public override void FrameCleanup(CommandBuffer cmd)
            {
                cmd.ReleaseTemporaryRT(tempColor.id);
            }
        }



        public ScreenDistortionCachePass screenDistortionCachePass;
        public ScreenDistortionPass screenDistortionPass;
        public RadialBlurPass radialBlurPass;
        public PostUberBlitPass postUberBlitPass;
        public Material screenDistortionMaterial;
        public Material radialBlurMaterial;
        public Material uberMaterial;
        public override void Create()
        {
            screenDistortionCachePass = new ScreenDistortionCachePass();
            screenDistortionPass = new ScreenDistortionPass();
            radialBlurPass = new RadialBlurPass();
            postUberBlitPass = new PostUberBlitPass();
        }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (!screenDistortionMaterial || !radialBlurMaterial)
            {
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled)
            {
                return;
            }

            screenDistortionCachePass.Setup(renderer.cameraColorTarget);
            renderer.EnqueuePass(screenDistortionCachePass);

            RenderTargetHandle afterPostProcessColor = (RenderTargetHandle)typeof(UniversalRenderer).GetField("m_AfterPostProcessColor", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(renderer); 
            RenderTargetHandle previousColor = afterPostProcessColor;

            previousColor = screenDistortionPass.Setup(previousColor, screenDistortionMaterial);
            renderer.EnqueuePass(screenDistortionPass);

            previousColor = radialBlurPass.Setup(previousColor, radialBlurMaterial);
            renderer.EnqueuePass(radialBlurPass);

            postUberBlitPass.Setup(previousColor, afterPostProcessColor, uberMaterial);
            renderer.EnqueuePass(postUberBlitPass);
        }

    }

}
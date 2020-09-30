using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FrameCapture : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        public CustomRenderPass()
        {
            m_CameraColorAttachment.Init("_CameraColorTexture");
            m_CameraDepthAttachment.Init("_CameraDepthAttachment");
            m_DepthTexture.Init("_CameraDepthTexture");
            m_OpaqueColor.Init("_CameraOpaqueTexture");
            m_AfterPostProcessColor.Init("_AfterPostProcessTexture");
            m_ColorGradingLut.Init("_InternalGradingLut");
        }

        RenderTargetHandle m_CameraColorAttachment;
        RenderTargetHandle m_CameraDepthAttachment;
        RenderTargetHandle m_DepthTexture;
        RenderTargetHandle m_OpaqueColor;
        RenderTargetHandle m_AfterPostProcessColor;
        RenderTargetHandle m_ColorGradingLut;

        FrameCaptureSetting setting;
        Material blitMat => setting.blitMat.value;
        RenderTargetIdentifier source;
        RenderTargetIdentifier dist;
        CameraData cameraData;
        RenderTextureDescriptor sourceDesc;
        public void Setup(ScriptableRenderer renderer, RenderingData renderingData)
        {
            if (setting == null)
                setting = VolumeManager.instance.stack.GetComponent<FrameCaptureSetting>();
            source = renderer.cameraColorTarget;
            cameraData = renderingData.cameraData;
            renderPassEvent = setting.Event.value;
            dist = new RenderTargetIdentifier(setting.blitTarget.value);
        }

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in an performance manner.
        public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor)
        {
            sourceDesc = cameraTextureDescriptor;
            sourceDesc.msaaSamples = 1;
            sourceDesc.depthBufferBits = 0;
            sourceDesc.colorFormat = RenderTextureFormat.ARGBHalf;
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (setting == null || !setting.IsActive())
                return;

            var cmd = CommandBufferPool.Get("FrameCapture");
            var tmpSource = Shader.PropertyToID("_TmpSource");
            cmd.GetTemporaryRT(tmpSource, sourceDesc);
            Blit(cmd, m_AfterPostProcessColor.id, tmpSource, blitMat);
            Blit(cmd, tmpSource, dist);
            //            Blit(cmd, tmpSource, BuiltinRenderTextureType.CameraTarget);
            cmd.ReleaseTemporaryRT(tmpSource);
            context.ExecuteCommandBuffer(cmd);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }

    CustomRenderPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.Setup(renderer, renderingData);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}


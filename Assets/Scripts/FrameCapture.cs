using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FrameCapture : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {
        Material blitMat;
        RenderTargetIdentifier source;
        CameraData cameraData;
        RenderTextureDescriptor sourceDesc;
        public void Setup(Material mat, ScriptableRenderer renderer, RenderingData renderingData)
        {
            blitMat = mat;
            source = renderer.cameraColorTarget;
            cameraData = renderingData.cameraData;
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
            var cmd = CommandBufferPool.Get("FrameCapture");
            var tmpSource = Shader.PropertyToID("_TmpSource");
            cmd.GetTemporaryRT(tmpSource, sourceDesc);
            Blit(cmd, source, tmpSource, blitMat);
            Blit(cmd, tmpSource, source);
            Blit(cmd, tmpSource, BuiltinRenderTextureType.CameraTarget);
            cmd.ReleaseTemporaryRT(tmpSource);
            context.ExecuteCommandBuffer(cmd);
        }

        /// Cleanup any allocated resources that were created during the execution of this render pass.
        public override void FrameCleanup(CommandBuffer cmd)
        {
        }
    }

    CustomRenderPass m_ScriptablePass;
    public RenderPassEvent Event = RenderPassEvent.AfterRenderingPostProcessing;
    public Material blitMat;

    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = Event;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        Debug.Log(renderingData.cameraData.cameraTargetDescriptor.colorFormat);
        m_ScriptablePass.Setup(blitMat, renderer, renderingData);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}



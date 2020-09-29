using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[ExecuteInEditMode, VolumeComponentMenu("frame capture")]
public sealed class FrameCaptureSetting : VolumeComponent, IPostProcessComponent
{
    //VolumeParameterは初期化宣言しておかないとエラー出る
    public RenderPassEventParameter Event = new RenderPassEventParameter();
    public RenderTextureParameter blitTarget = new RenderTextureParameter(null);
    public MaterialParameter blitMat = new MaterialParameter();

    public bool IsActive() => blitTarget.value != null;
    public bool IsTileCompatible() => false;

    [System.Serializable]
    public sealed class RenderPassEventParameter : VolumeParameter<RenderPassEvent> { }
    [System.Serializable]
    public sealed class MaterialParameter : VolumeParameter<Material> { }
}

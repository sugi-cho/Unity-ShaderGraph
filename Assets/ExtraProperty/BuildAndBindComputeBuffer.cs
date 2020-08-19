using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[ExecuteInEditMode]
public class BuildAndBindComputeBuffer : MonoBehaviour
{
    public Material mat;
    public string propName = "_MyData";
    public Color[] colors = new Color[] { Color.red, Color.green, Color.blue, Color.yellow };
    ComputeBuffer buffer;

    private void Update()
    {
        if (buffer == null)
            Build();
        // Shaderを更新したら外れるから表示用にUpdateでSetDataする
        mat.SetBuffer(propName, buffer);
        mat.SetInt("_BufferCount", buffer.count);
    }
    private void OnDestroy()
    {
        if (buffer != null)
            buffer.Release();
    }

    [ContextMenu("build and bind")]
    void Build()
    {
        if (buffer != null)
            buffer.Release();

        buffer = new ComputeBuffer(colors.Length, sizeof(float) * (3 + 4));
        var data = colors.Select(c => new MyData() { pos = Vector3.zero, color = c }).ToArray();
        buffer.SetData(data);
    }

    struct MyData
    {
        public Vector3 pos;
        public Color color;
    }
}

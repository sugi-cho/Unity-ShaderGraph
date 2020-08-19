using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class BuildAndBindComputeBuffer : MonoBehaviour
{
    public Material mat;
    public string propName = "_MyData";
    public Color[] colors;
    ComputeBuffer buffer;

    [ContextMenu("build and bind")]
    void Build()
    {
        buffer = new ComputeBuffer(colors.Length, sizeof(float) * (3 + 4));
        var data = colors.Select(c => new MyData() { pos = Vector3.zero, color = c }).ToArray();
        buffer.SetData(data);
        mat.SetBuffer(propName, buffer);
    }

    struct MyData
    {
        public Vector3 pos;
        public Color color;
    }
}

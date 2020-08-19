using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[ExecuteInEditMode]
public class FloatArrayBinder : MonoBehaviour
{
    public float[] dataArray = new float[16];
    public Material mat;

    // Start is called before the first frame update
    void Start()
    {
        dataArray = Enumerable.Range(0, 16).Select(i => i / 16f).ToArray();
    }

    private void Update()
    {
        mat.SetFloatArray("_Array", dataArray);
    }
}

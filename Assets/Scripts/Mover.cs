using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Mover : MonoBehaviour
{

    [SerializeField] Vector3 from;
    [SerializeField] Vector3 to;
    [SerializeField] float duration = 5f;

    // Update is called once per frame
    void Update()
    {
        var t = Mathf.PingPong(Time.time / duration, 1f);
        transform.position = Vector3.Lerp(from, to, t);
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Movement : MonoBehaviour
{
    Rigidbody rb;
    public RenderTexture renderTexture;
    public GameObject model;
    void Start()
    {
        rb = this.gameObject.GetComponent<Rigidbody>();
        Shader.SetGlobalTexture("_RenderTexture", renderTexture);
    }

    void Update()
    {
        
        rb.AddForce(new Vector3(Input.GetAxis("Horizontal"), 0, Input.GetAxis("Vertical")));
        model.transform.Rotate(Vector3.up, Time.deltaTime * 500);

        Shader.SetGlobalVector("_PlayerPos", this.gameObject.transform.position);
    }
}

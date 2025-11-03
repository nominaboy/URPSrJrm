using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotation : MonoBehaviour
{
    private float rotateSpeed = 0.05f;
    void Start()
    {
        
    }

    void Update()
    {
        transform.Rotate(0, rotateSpeed, 0);
    }
}

using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class SDF2DInteraction : MonoBehaviour
{
    [Header("材质引用")]
    public Material targetMaterial;

    [Header("阻尼设置")]
    [SerializeField, Range(0.1f, 5f)]
    private float dampingSpeed = 2f;

    private Vector2 resetValueA, resetValueB;
    private Vector2 currentUVA = Vector2.zero;
    private Vector2 currentUVB = Vector2.zero;
    private Vector2 targetUVA = Vector2.zero;
    private Vector2 targetUVB = Vector2.zero;
    private Vector2 velocityA = Vector2.zero;
    private Vector2 velocityB = Vector2.zero;
    private Color circleColor = Color.white;

    private static readonly int BallACenter = Shader.PropertyToID("_Ball_A_Center");
    private static readonly int BallBCenter = Shader.PropertyToID("_Ball_B_Center");
    private static readonly int CircleColor = Shader.PropertyToID("_CircleColor");

    private void Start()
    {
        if (targetMaterial != null)
        {
            resetValueA = targetMaterial.GetVector(BallACenter);
            currentUVA = resetValueA;
            resetValueB = targetMaterial.GetVector(BallBCenter);
            currentUVB = resetValueB;
            circleColor = targetMaterial.GetVector(CircleColor);
        }
    }

    void Update()
    {
        bool leftButton = Input.GetMouseButton(0);
        bool rightButton = Input.GetMouseButton(1);


        if (leftButton)
        {
            Vector2 mousePos = Input.mousePosition;
            targetUVA = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        }
        currentUVA = Vector2.SmoothDamp(currentUVA, targetUVA, ref velocityA, 1f / dampingSpeed);

        if (rightButton)
        {
            Vector2 mousePos = Input.mousePosition;
            targetUVB = new Vector2(mousePos.x / Screen.width, mousePos.y / Screen.height);
        }
        currentUVB = Vector2.SmoothDamp(currentUVB, targetUVB, ref velocityB, 1f / dampingSpeed);

        if (targetMaterial != null)
        {
            Vector4 currentValueA = targetMaterial.GetVector(BallACenter);
                currentValueA.x = currentUVA.x;
                currentValueA.y = currentUVA.y;
                targetMaterial.SetVector(BallACenter, currentValueA);
            Vector4 currentValueB = targetMaterial.GetVector(BallBCenter);
                currentValueB.x = currentUVB.x;
                currentValueB.y = currentUVB.y;
                targetMaterial.SetVector(BallBCenter, currentValueB);
            float distance = Mathf.Clamp01(Vector2.Distance(currentValueA, currentValueB));
            targetMaterial.SetVector(CircleColor, Color.Lerp(circleColor, Color.green, distance));
        }
    }

    void OnDisable()
    {
        // 重置材质属性（可选）
        if (targetMaterial != null)
        {
            targetMaterial.SetVector(BallACenter, resetValueA);
            targetMaterial.SetVector(BallBCenter, resetValueB);
            targetMaterial.SetVector(CircleColor, circleColor);
        }
    }
}

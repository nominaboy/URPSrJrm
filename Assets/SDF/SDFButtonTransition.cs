using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

public class SDFButtonTransition : MonoBehaviour
{
    [Header("材质引用")]
    public Material targetMaterial;

    [Header("过渡设置")]
    [SerializeField, Range(0.1f, 15f)]
    private float dampingSpeed = 2f;

    [SerializeField, Range(0.01f, 1.0f)]
    private float proximityThreshold = 0.1f;

    [SerializeField, Range(0.001f, 0.1f)]
    private float equalityThreshold = 0.01f;

    [SerializeField, Range(0.1f, 15f)]
    private float lerpTransitionSpeed = 2f;

    // 当前状态
    private Vector2 rectMainCurrent = Vector2.zero;
    private Vector2 rectMainTarget = Vector2.zero;
    private Vector2 rectACurrent = Vector2.zero;
    private Vector2 rectATarget = Vector2.zero;
    private float rectALerpCurrent = 0f;
    private float rectMainLerpCurrent = 0f;
    private Vector2 velocity = Vector2.zero;

    // 材质初始值
    private Vector4 initialRectMain;
    private Vector4 initialRectA;
    private float initialRectALerp;
    private float initialRectMainLerp;

    // 材质属性ID（性能优化）
    private static readonly int RectMain = Shader.PropertyToID("_RectMain");
    private static readonly int RectA = Shader.PropertyToID("_RectA");
    private static readonly int RectALerp = Shader.PropertyToID("_RectALerp");
    private static readonly int RectMainLerp = Shader.PropertyToID("_RectMainLerp");

    // 按钮追踪
    private Dictionary<Button, Vector2> buttonUVPositions = new Dictionary<Button, Vector2>();
    private Button currentActiveButton = null;

    void Start()
    {
        // 保存材质的初始值
        if (targetMaterial != null)
        {
            initialRectMain = targetMaterial.GetVector(RectMain);
            initialRectA = targetMaterial.GetVector(RectA);
            initialRectALerp = targetMaterial.GetFloat(RectALerp);
            initialRectMainLerp = targetMaterial.GetFloat(RectMainLerp);

            // 使用材质初始值设置当前状态
            rectMainCurrent = new Vector2(initialRectMain.x, initialRectMain.y);
            rectMainTarget = rectMainCurrent;
            rectACurrent = new Vector2(initialRectA.x, initialRectA.y);
            rectATarget = rectACurrent;
            rectALerpCurrent = initialRectALerp;
            rectMainLerpCurrent = initialRectMainLerp;
        }

        // 自动查找所有按钮并绑定事件
        FindAndBindAllButtons();
    }

    void Update()
    {
        if (targetMaterial == null) return;

        // 平滑过渡 RectMain 到目标位置
        rectMainCurrent = Vector2.SmoothDamp(rectMainCurrent, rectMainTarget, ref velocity, 1f / dampingSpeed);

        // 立即设置 RectA 到目标位置
        rectACurrent = rectATarget;

        // 检查 RectMain 和 RectA 的接近程度
        float xDistance = Mathf.Abs(rectMainCurrent.x - rectACurrent.x);

        // 检查两个矩形是否几乎相等
        if (xDistance < equalityThreshold)
        {
            // 当两个矩形几乎相等时，RectALerp 渐变回0
            rectALerpCurrent = Mathf.Lerp(rectALerpCurrent, 0f, lerpTransitionSpeed * Time.deltaTime);
            rectMainLerpCurrent = 1f;
        }
        // 根据接近程度调整 Lerp 参数
        else if (xDistance < proximityThreshold)
        {
            // 当两个矩形接近时，将 RectALerp 和 RectMainLerp 都从0增加到1
            rectALerpCurrent = Mathf.Lerp(rectALerpCurrent, 1f, lerpTransitionSpeed * Time.deltaTime);
            rectMainLerpCurrent = Mathf.Lerp(rectMainLerpCurrent, 1f, lerpTransitionSpeed * Time.deltaTime);


        }
        else
        {
            // 当两个矩形分开时，保持 RectALerp 和 RectMainLerp 都为0
            rectALerpCurrent = 0f;
            rectMainLerpCurrent = 0f;
        }

        // 更新材质属性
        UpdateMaterialProperties();
    }

    /// <summary>
    /// 查找场景中所有按钮并绑定点击事件
    /// </summary>
    private void FindAndBindAllButtons()
    {
        Button[] allButtons = FindObjectsOfType<Button>();

        foreach (Button button in allButtons)
        {
            // 移除旧的监听器（避免重复）
            button.onClick.RemoveAllListeners();

            // 添加新的点击监听
            button.onClick.AddListener(() => OnButtonClicked(button));

            // 预计算按钮的中心UV位置
            Vector2 buttonUV = CalculateButtonCenterUV(button);
            buttonUVPositions[button] = buttonUV;

            Debug.Log($"绑定按钮: {button.name}, UV位置: {buttonUV}");
        }
    }

    /// <summary>
    /// 计算按钮中心点的屏幕UV坐标
    /// </summary>
    private Vector2 CalculateButtonCenterUV(Button button)
    {
        RectTransform rectTransform = button.GetComponent<RectTransform>();
        Canvas canvas = button.GetComponentInParent<Canvas>();

        if (rectTransform == null || canvas == null)
        {
            Debug.LogWarning($"无法获取 {button.name} 的RectTransform或Canvas");
            return Vector2.zero;
        }

        // 获取按钮在屏幕空间的位置
        Vector3[] worldCorners = new Vector3[4];
        rectTransform.GetWorldCorners(worldCorners);

        // 计算中心点
        Vector2 center = Vector2.zero;
        foreach (Vector3 corner in worldCorners)
        {
            center += (Vector2)corner;
        }
        center /= 4f;

        // 转换为屏幕UV坐标 (0-1)
        Vector2 screenUV;
        if (canvas.renderMode == RenderMode.ScreenSpaceOverlay)
        {
            screenUV = new Vector2(center.x / Screen.width, center.y / Screen.height);
        }
        else
        {
            Camera canvasCamera = canvas.worldCamera ?? Camera.main;
            Vector3 screenPos = canvasCamera.WorldToScreenPoint(center);
            screenUV = new Vector2(screenPos.x / Screen.width, screenPos.y / Screen.height);
        }

        return screenUV;
    }

    /// <summary>
    /// 按钮点击回调
    /// </summary>
    private void OnButtonClicked(Button clickedButton)
    {
        if (!buttonUVPositions.ContainsKey(clickedButton))
        {
            Debug.LogWarning($"未找到按钮 {clickedButton.name} 的UV位置");
            return;
        }

        Vector2 buttonUV = buttonUVPositions[clickedButton];

        // 设置新的目标位置
        rectMainTarget = buttonUV;      // 主矩形平滑移动
        rectATarget = buttonUV;         // 辅助矩形立即出现

        // 重置速度以重新开始阻尼计算
        velocity = Vector2.zero;

        // 点击按钮后，将两个Lerp参数都设为0
        rectALerpCurrent = 0f;
        rectMainLerpCurrent = 0f;

        // 记录当前活动按钮
        currentActiveButton = clickedButton;

        Debug.Log($"按钮点击: {clickedButton.name}, UV: {buttonUV}");
    }

    /// <summary>
    /// 手动添加按钮（用于动态创建的按钮）
    /// </summary>
    public void RegisterButton(Button button)
    {
        if (button == null) return;

        // 移除旧的监听器
        button.onClick.RemoveAllListeners();

        // 添加新的监听器
        button.onClick.AddListener(() => OnButtonClicked(button));

        // 计算并存储UV位置
        Vector2 buttonUV = CalculateButtonCenterUV(button);
        buttonUVPositions[button] = buttonUV;
    }

    /// <summary>
    /// 手动设置目标位置（用于非按钮的交互）
    /// </summary>
    public void SetTargetPosition(Vector2 screenUV)
    {
        rectMainTarget = screenUV;
        rectATarget = screenUV;
        velocity = Vector2.zero;

        // 手动设置位置后，也将两个Lerp参数设为0
        rectALerpCurrent = 0f;
        rectMainLerpCurrent = 0f;
    }

    /// <summary>
    /// 更新材质属性
    /// </summary>
    private void UpdateMaterialProperties()
    {
        if (targetMaterial == null) return;

        // 获取当前材质值，只更新xy分量，保留zw分量
        Vector4 currentRectMain = targetMaterial.GetVector(RectMain);
        currentRectMain.x = rectMainCurrent.x;
        currentRectMain.y = rectMainCurrent.y;
        targetMaterial.SetVector(RectMain, currentRectMain);

        // 获取当前材质值，只更新xy分量，保留zw分量
        Vector4 currentRectA = targetMaterial.GetVector(RectA);
        currentRectA.x = rectACurrent.x;
        currentRectA.y = rectACurrent.y;
        targetMaterial.SetVector(RectA, currentRectA);

        // 更新 _RectALerp
        targetMaterial.SetFloat(RectALerp, rectALerpCurrent);

        // 更新 _RectMainLerp
        targetMaterial.SetFloat(RectMainLerp, rectMainLerpCurrent);
    }

    /// <summary>
    /// 重置材质属性为初始值
    /// </summary>
    public void ResetMaterialToInitial()
    {
        if (targetMaterial != null)
        {
            targetMaterial.SetVector(RectMain, initialRectMain);
            targetMaterial.SetVector(RectA, initialRectA);
            targetMaterial.SetFloat(RectALerp, initialRectALerp);
            targetMaterial.SetFloat(RectMainLerp, initialRectMainLerp);

            // 同时重置内部状态
            rectMainCurrent = new Vector2(initialRectMain.x, initialRectMain.y);
            rectMainTarget = rectMainCurrent;
            rectACurrent = new Vector2(initialRectA.x, initialRectA.y);
            rectATarget = rectACurrent;
            rectALerpCurrent = initialRectALerp;
            rectMainLerpCurrent = initialRectMainLerp;
            velocity = Vector2.zero;
        }
    }

    /// <summary>
    /// 在Inspector中调试当前状态
    /// </summary>
    [ContextMenu("调试状态")]
    private void DebugStatus()
    {
        Debug.Log($"RectMain: {rectMainCurrent}, Target: {rectMainTarget}");
        Debug.Log($"RectA: {rectACurrent}");
        Debug.Log($"RectALerp: {rectALerpCurrent}");
        Debug.Log($"RectMainLerp: {rectMainLerpCurrent}");
        Debug.Log($"当前活动按钮: {(currentActiveButton != null ? currentActiveButton.name : "无")}");
    }

    void OnDisable()
    {
        // 重置为材质球的初始参数
        ResetMaterialToInitial();
    }

    void OnDestroy()
    {
        // 销毁时也重置材质
        ResetMaterialToInitial();
    }
}
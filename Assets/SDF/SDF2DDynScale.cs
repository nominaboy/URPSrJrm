using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.Events;

public class SDF2DDynScale : MonoBehaviour
{
    [Header("材质引用")]
    public Material targetMaterial;

    [Header("边缘宽度参数")]
    [SerializeField, Range(0f, 1f)]
    private float targetEdgeWidth2 = 0.5f;

    [SerializeField, Range(0f, 1f)]
    private float targetEdgeWidth3 = 0.3f;

    [Header("边缘颜色参数")]
    [SerializeField]
    private Color targetEdgeColor2 = new Color(1f, 0.5f, 0.2f, 1f);

    [Header("动画曲线")]
    [SerializeField]
    private AnimationCurve edgeWidth2Curve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    [SerializeField]
    private AnimationCurve edgeWidth3Curve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    [SerializeField]
    private AnimationCurve edgeColorCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    [Header("动画设置")]
    [SerializeField, Range(0.1f, 3f)]
    private float animationDuration = 1f;

    [SerializeField]
    private bool loopAnimation = false;

    [SerializeField, Range(1, 100)]
    private int loopCount = 1;

    [SerializeField]
    private bool pingPongLoop = false;

    // 材质属性ID
    private static readonly int RectMain = Shader.PropertyToID("_RectMain");
    private static readonly int EdgeWidth2 = Shader.PropertyToID("_EdgeWidth2");
    private static readonly int EdgeWidth3 = Shader.PropertyToID("_EdgeWidth3");
    private static readonly int EdgeColor2 = Shader.PropertyToID("_EdgeColor2");

    // 材质初始值
    private Vector4 initialRectMain;
    private float initialEdgeWidth2;
    private float initialEdgeWidth3;
    private Color initialEdgeColor2;

    // 当前动画状态
    private float animationTimer = 0f;
    private bool isAnimating = false;
    private int currentLoop = 0;
    private bool isReversing = false;

    // 按钮追踪
    private Dictionary<Button, Vector2> buttonUVPositions = new Dictionary<Button, Vector2>();
    private Button currentActiveButton = null;

    // 事件系统
    [System.Serializable]
    public class ButtonClickEvent : UnityEvent<Vector2> { }
    public ButtonClickEvent onButtonClicked;

    void Start()
    {
        // 保存材质的初始值
        if (targetMaterial != null)
        {
            initialRectMain = targetMaterial.GetVector(RectMain);
            initialEdgeWidth2 = targetMaterial.GetFloat(EdgeWidth2);
            initialEdgeWidth3 = targetMaterial.GetFloat(EdgeWidth3);
            initialEdgeColor2 = targetMaterial.GetColor(EdgeColor2);
        }

        // 自动查找所有按钮并绑定事件
        FindAndBindAllButtons();

        // 初始化事件
        if (onButtonClicked == null)
            onButtonClicked = new ButtonClickEvent();
    }

    void Update()
    {
        // 处理动画
        if (isAnimating)
        {
            animationTimer += Time.deltaTime;
            float progress = Mathf.Clamp01(animationTimer / animationDuration);

            // 处理循环逻辑
            if (loopAnimation && progress >= 1f)
            {
                if (pingPongLoop)
                {
                    // 乒乓循环模式
                    if (!isReversing && currentLoop < loopCount * 2 - 1)
                    {
                        animationTimer = 0f;
                        isReversing = !isReversing;
                        currentLoop++;
                    }
                    else if (isReversing && currentLoop < loopCount * 2 - 1)
                    {
                        animationTimer = 0f;
                        isReversing = !isReversing;
                        currentLoop++;
                    }
                    else
                    {
                        isAnimating = false;
                    }
                }
                else
                {
                    // 普通循环模式
                    if (currentLoop < loopCount - 1)
                    {
                        animationTimer = 0f;
                        currentLoop++;
                    }
                    else
                    {
                        isAnimating = false;
                    }
                }

                // 更新进度
                progress = Mathf.Clamp01(animationTimer / animationDuration);
            }

            // 计算当前值（考虑乒乓循环）
            float currentProgress = isReversing ? 1f - progress : progress;

            // 使用曲线计算当前值
            float currentEdgeWidth2 = Mathf.Lerp(initialEdgeWidth2, targetEdgeWidth2, edgeWidth2Curve.Evaluate(currentProgress));
            float currentEdgeWidth3 = Mathf.Lerp(initialEdgeWidth3, targetEdgeWidth3, edgeWidth3Curve.Evaluate(currentProgress));
            Color currentEdgeColor2 = Color.Lerp(initialEdgeColor2, targetEdgeColor2, edgeColorCurve.Evaluate(currentProgress));

            // 更新材质参数
            if (targetMaterial != null)
            {
                targetMaterial.SetFloat(EdgeWidth2, currentEdgeWidth2);
                targetMaterial.SetFloat(EdgeWidth3, currentEdgeWidth3);
                targetMaterial.SetColor(EdgeColor2, currentEdgeColor2);
            }

            // 检查动画是否完成（非循环模式）
            if (!loopAnimation && progress >= 1f)
            {
                isAnimating = false;
            }
        }
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
    /// 按钮点击回调 - 确保每次点击都从头开始播放
    /// </summary>
    private void OnButtonClicked(Button clickedButton)
    {
        if (!buttonUVPositions.ContainsKey(clickedButton))
        {
            Debug.LogWarning($"未找到按钮 {clickedButton.name} 的UV位置");
            return;
        }

        Vector2 buttonUV = buttonUVPositions[clickedButton];

        // 立即更新 RectMain 的 UV 坐标
        if (targetMaterial != null)
        {
            Vector4 currentRectMain = targetMaterial.GetVector(RectMain);
            currentRectMain.x = buttonUV.x;
            currentRectMain.y = buttonUV.y;
            targetMaterial.SetVector(RectMain, currentRectMain);
        }

        // 重置边缘参数到初始值，确保从头开始播放
        ResetEdgeParametersToInitial();

        // 开始边缘参数的动画
        StartEdgeAnimation();

        // 记录当前活动按钮
        currentActiveButton = clickedButton;

        // 触发事件
        onButtonClicked?.Invoke(buttonUV);

        Debug.Log($"按钮点击: {clickedButton.name}, UV: {buttonUV}");
    }

    /// <summary>
    /// 开始边缘参数动画
    /// </summary>
    private void StartEdgeAnimation()
    {
        // 重置动画计时器
        animationTimer = 0f;
        currentLoop = 0;
        isReversing = false;
        isAnimating = true;
    }

    /// <summary>
    /// 重置边缘参数到初始值
    /// </summary>
    private void ResetEdgeParametersToInitial()
    {
        if (targetMaterial != null)
        {
            targetMaterial.SetFloat(EdgeWidth2, initialEdgeWidth2);
            targetMaterial.SetFloat(EdgeWidth3, initialEdgeWidth3);
            targetMaterial.SetColor(EdgeColor2, initialEdgeColor2);
        }
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
        // 立即更新 RectMain 的 UV 坐标
        if (targetMaterial != null)
        {
            Vector4 currentRectMain = targetMaterial.GetVector(RectMain);
            currentRectMain.x = screenUV.x;
            currentRectMain.y = screenUV.y;
            targetMaterial.SetVector(RectMain, currentRectMain);
        }

        // 重置边缘参数到初始值，确保从头开始播放
        ResetEdgeParametersToInitial();

        // 开始边缘参数的动画
        StartEdgeAnimation();

        // 触发事件
        onButtonClicked?.Invoke(screenUV);
    }

    /// <summary>
    /// 设置目标边缘宽度2
    /// </summary>
    public void SetTargetEdgeWidth2(float value)
    {
        targetEdgeWidth2 = Mathf.Clamp01(value);
    }

    /// <summary>
    /// 设置目标边缘宽度3
    /// </summary>
    public void SetTargetEdgeWidth3(float value)
    {
        targetEdgeWidth3 = Mathf.Clamp01(value);
    }

    /// <summary>
    /// 设置目标边缘颜色2
    /// </summary>
    public void SetTargetEdgeColor2(Color color)
    {
        targetEdgeColor2 = color;
    }

    /// <summary>
    /// 设置边缘宽度2的动画曲线
    /// </summary>
    public void SetEdgeWidth2Curve(AnimationCurve curve)
    {
        edgeWidth2Curve = curve;
    }

    /// <summary>
    /// 设置边缘宽度3的动画曲线
    /// </summary>
    public void SetEdgeWidth3Curve(AnimationCurve curve)
    {
        edgeWidth3Curve = curve;
    }

    /// <summary>
    /// 设置边缘颜色的动画曲线
    /// </summary>
    public void SetEdgeColorCurve(AnimationCurve curve)
    {
        edgeColorCurve = curve;
    }

    /// <summary>
    /// 设置动画时长
    /// </summary>
    public void SetAnimationDuration(float duration)
    {
        animationDuration = Mathf.Max(0.1f, duration);
    }

    /// <summary>
    /// 设置是否循环播放
    /// </summary>
    public void SetLoopAnimation(bool loop)
    {
        loopAnimation = loop;
    }

    /// <summary>
    /// 设置循环次数
    /// </summary>
    public void SetLoopCount(int count)
    {
        loopCount = Mathf.Max(1, count);
    }

    /// <summary>
    /// 设置是否使用乒乓循环
    /// </summary>
    public void SetPingPongLoop(bool pingPong)
    {
        pingPongLoop = pingPong;
    }

    /// <summary>
    /// 立即完成当前动画
    /// </summary>
    public void CompleteAnimationImmediately()
    {
        if (targetMaterial != null)
        {
            targetMaterial.SetFloat(EdgeWidth2, targetEdgeWidth2);
            targetMaterial.SetFloat(EdgeWidth3, targetEdgeWidth3);
            targetMaterial.SetColor(EdgeColor2, targetEdgeColor2);
        }

        isAnimating = false;
    }

    /// <summary>
    /// 停止当前动画
    /// </summary>
    public void StopAnimation()
    {
        isAnimating = false;
    }

    /// <summary>
    /// 重置所有材质属性为初始值
    /// </summary>
    public void ResetMaterialToInitial()
    {
        if (targetMaterial != null)
        {
            targetMaterial.SetVector(RectMain, initialRectMain);
            targetMaterial.SetFloat(EdgeWidth2, initialEdgeWidth2);
            targetMaterial.SetFloat(EdgeWidth3, initialEdgeWidth3);
            targetMaterial.SetColor(EdgeColor2, initialEdgeColor2);
        }

        // 停止动画
        isAnimating = false;
        animationTimer = 0f;
        currentLoop = 0;
        isReversing = false;
    }

    /// <summary>
    /// 在Inspector中调试当前状态
    /// </summary>
    [ContextMenu("调试状态")]
    private void DebugStatus()
    {
        Debug.Log($"当前活动按钮: {(currentActiveButton != null ? currentActiveButton.name : "无")}");
        Debug.Log($"动画状态: {(isAnimating ? "进行中" : "停止")}");
        Debug.Log($"动画进度: {Mathf.Clamp01(animationTimer / animationDuration) * 100f}%");
        Debug.Log($"当前循环: {currentLoop}/{loopCount}");
        Debug.Log($"乒乓模式: {pingPongLoop}, 反向: {isReversing}");

        if (targetMaterial != null)
        {
            Debug.Log($"当前 EdgeWidth2: {targetMaterial.GetFloat(EdgeWidth2)}");
            Debug.Log($"当前 EdgeWidth3: {targetMaterial.GetFloat(EdgeWidth3)}");
            Debug.Log($"当前 EdgeColor2: {targetMaterial.GetColor(EdgeColor2)}");
        }
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

    void OnApplicationQuit()
    {
        // 应用退出时重置材质
        ResetMaterialToInitial();
    }
}
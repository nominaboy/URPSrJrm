using UnityEngine;
using System.Collections;

[RequireComponent(typeof(Renderer))]
public class FurDragInteraction : MonoBehaviour
{
    [Header("Fur Interaction Settings")]
    public string furDirectionProperty = "_FurDirection";
    public float dragStrengthMultiplier = 2.0f;
    public float maxFurDirectionMagnitude = 5.0f;
    public float smoothDampTime = 0.1f;

    [Header("Drag Settings")]
    public float dragSpeed = 10f;

    [Header("Wind Field Settings")]
    public bool enableWind = true;
    public Vector3 baseWindDirection = Vector3.forward;
    public float baseWindStrength = 0.5f;
    public float windNoiseScale = 0.5f;
    public float windNoiseSpeed = 1.0f;
    public float windTurbulence = 0.3f;
    public float windPulseFrequency = 0.2f;
    public float windPulseAmplitude = 0.5f;

    // 风场属性
    [System.Serializable]
    public class WindZone
    {
        public Transform windZoneTransform;
        public float radius = 5f;
        public float strength = 1f;
        public AnimationCurve falloff = AnimationCurve.EaseInOut(0, 1, 1, 0);
    }

    [Header("Wind Zones")]
    public WindZone[] windZones;

    private Material furMaterial;
    private Vector3 currentFurDirection;
    private Vector3 furDirectionVelocity;
    private bool isDragging = false;
    private Vector3 dragVelocity;
    private Vector3 previousPosition;
    private Vector3 windDirection;
    private float windStrength;
    private float noiseOffset;
    private Vector3 defaultFurDirection; // 存储默认绒毛方向

    void Start()
    {
        // 获取材质
        Renderer renderer = GetComponent<Renderer>();
        if (renderer != null)
        {
            // 使用material实例，避免影响其他使用相同材质的对象
            furMaterial = renderer.material;

            // 获取材质的默认绒毛方向
            if (furMaterial.HasProperty(furDirectionProperty))
            {
                defaultFurDirection = furMaterial.GetVector(furDirectionProperty);
                currentFurDirection = defaultFurDirection;
            }
            else
            {
                Debug.LogWarning("Material does not have property: " + furDirectionProperty);
                defaultFurDirection = Vector3.zero;
                currentFurDirection = Vector3.zero;
            }
        }
        else
        {
            Debug.LogError("No Renderer found on " + gameObject.name);
            enabled = false;
            return;
        }

        // 初始化风场
        noiseOffset = Random.Range(0f, 100f);
        windDirection = baseWindDirection.normalized;
        windStrength = baseWindStrength;
    }

    void Update()
    {
        // 更新风场效果
        if (enableWind)
        {
            UpdateWindField();
        }

        // 在编辑器中实时更新参数（可选）
#if UNITY_EDITOR
        if (!Application.isPlaying && furMaterial != null)
        {
            if (furMaterial.HasProperty(furDirectionProperty))
            {
                furMaterial.SetVector(furDirectionProperty, currentFurDirection);
            }
        }
#endif
    }

    void UpdateWindField()
    {
        // 基础风场噪声
        float time = Time.time * windNoiseSpeed + noiseOffset;
        Vector3 noiseDirection = new Vector3(
            Mathf.PerlinNoise(time, 0) - 0.5f,
            Mathf.PerlinNoise(0, time) - 0.5f,
            Mathf.PerlinNoise(time, time) - 0.5f
        ) * windTurbulence;

        // 风场脉冲效果
        float pulse = Mathf.Sin(Time.time * windPulseFrequency * Mathf.PI * 2f) * windPulseAmplitude + 1f;

        // 计算基础风场
        Vector3 baseWind = baseWindDirection.normalized * baseWindStrength * pulse;
        Vector3 turbulentWind = noiseDirection * windTurbulence;

        // 应用风区域
        Vector3 zoneWind = Vector3.zero;
        if (windZones != null && windZones.Length > 0)
        {
            foreach (WindZone zone in windZones)
            {
                if (zone.windZoneTransform != null)
                {
                    float distance = Vector3.Distance(transform.position, zone.windZoneTransform.position);
                    if (distance <= zone.radius)
                    {
                        float falloff = zone.falloff.Evaluate(distance / zone.radius);
                        Vector3 zoneDirection = zone.windZoneTransform.forward;
                        zoneWind += zoneDirection * zone.strength * falloff;
                    }
                }
            }
        }

        // 合并所有风场效果
        Vector3 totalWind = baseWind + turbulentWind + zoneWind;
        windDirection = totalWind.normalized;
        windStrength = Mathf.Clamp(totalWind.magnitude, 0, maxFurDirectionMagnitude);

        // 如果没有在拖拽，应用风场效果和默认方向
        if (!isDragging)
        {
            // 将风场效果与默认方向结合
            Vector3 targetFurDirection = defaultFurDirection + (windDirection * windStrength);

            // 限制总长度
            targetFurDirection = Vector3.ClampMagnitude(targetFurDirection, maxFurDirectionMagnitude);

            currentFurDirection = Vector3.SmoothDamp(currentFurDirection, targetFurDirection, ref furDirectionVelocity, smoothDampTime);

            // 传递给shader
            if (furMaterial.HasProperty(furDirectionProperty))
            {
                furMaterial.SetVector(furDirectionProperty, currentFurDirection);
            }
        }
    }

    void OnMouseDown()
    {
        isDragging = true;
        previousPosition = transform.position;
        StartCoroutine(DragObject());
    }

    void OnMouseUp()
    {
        isDragging = false;
        // 停止拖动时开始衰减绒毛方向到默认方向+风场
        StartCoroutine(DecayFurDirection());
    }

    IEnumerator DragObject()
    {
        while (isDragging)
        {
            // 将鼠标位置转换为世界坐标
            Vector3 mousePosition = Input.mousePosition;
            Vector3 screenPoint = Camera.main.WorldToScreenPoint(transform.position);
            mousePosition.z = screenPoint.z;
            Vector3 targetPosition = Camera.main.ScreenToWorldPoint(mousePosition);

            // 计算速度
            dragVelocity = (targetPosition - transform.position) / Time.deltaTime;

            // 移动物体
            transform.position = Vector3.Lerp(transform.position, targetPosition, dragSpeed * Time.deltaTime);

            // 计算绒毛方向（拖动方向的反方向）
            Vector3 rawFurDirection = -dragVelocity.normalized;

            // 根据速度大小调整强度
            float speedFactor = Mathf.Clamp(dragVelocity.magnitude * dragStrengthMultiplier, 0, maxFurDirectionMagnitude);

            // 平滑过渡绒毛方向
            Vector3 targetFurDirection = rawFurDirection * speedFactor;

            // 如果启用了风场，将风场效果与拖动效果叠加
            if (enableWind)
            {
                targetFurDirection += windDirection * windStrength * 0.5f; // 风场影响减半，避免完全覆盖拖动效果
            }

            // 限制总长度
            targetFurDirection = Vector3.ClampMagnitude(targetFurDirection, maxFurDirectionMagnitude);

            currentFurDirection = Vector3.SmoothDamp(currentFurDirection, targetFurDirection, ref furDirectionVelocity, smoothDampTime);

            // 传递给shader
            if (furMaterial.HasProperty(furDirectionProperty))
            {
                furMaterial.SetVector(furDirectionProperty, currentFurDirection);
            }

            previousPosition = transform.position;
            yield return null;
        }
    }

    IEnumerator DecayFurDirection()
    {
        float decayTime = 1.0f; // 衰减时间
        float elapsedTime = 0f;
        Vector3 startDirection = currentFurDirection;

        while (elapsedTime < decayTime)
        {
            elapsedTime += Time.deltaTime;
            float t = elapsedTime / decayTime;

            // 使用缓动函数使衰减更自然
            float easeOut = 1f - Mathf.Pow(1f - t, 3);

            // 计算目标方向：默认方向 + 当前风场效果
            Vector3 targetDirection = defaultFurDirection + (windDirection * windStrength);
            targetDirection = Vector3.ClampMagnitude(targetDirection, maxFurDirectionMagnitude);

            currentFurDirection = Vector3.Lerp(startDirection, targetDirection, easeOut);

            if (furMaterial.HasProperty(furDirectionProperty))
            {
                furMaterial.SetVector(furDirectionProperty, currentFurDirection);
            }

            yield return null;
        }

        // 确保最终到达目标方向
        Vector3 finalDirection = defaultFurDirection + (windDirection * windStrength);
        finalDirection = Vector3.ClampMagnitude(finalDirection, maxFurDirectionMagnitude);
        currentFurDirection = finalDirection;

        if (furMaterial.HasProperty(furDirectionProperty))
        {
            furMaterial.SetVector(furDirectionProperty, currentFurDirection);
        }
    }

    // 公共方法，用于外部控制绒毛方向
    public void SetFurDirection(Vector3 direction, float strength = 1.0f)
    {
        if (furMaterial != null && furMaterial.HasProperty(furDirectionProperty))
        {
            Vector3 normalizedDirection = direction.normalized;
            float clampedStrength = Mathf.Clamp(strength, 0, maxFurDirectionMagnitude);
            currentFurDirection = normalizedDirection * clampedStrength;
            furMaterial.SetVector(furDirectionProperty, currentFurDirection);
        }
    }

    // 重置绒毛方向到默认值
    public void ResetFurDirection()
    {
        StartCoroutine(DecayFurDirection());
    }

    // 设置新的默认绒毛方向
    public void SetDefaultFurDirection(Vector3 newDefaultDirection)
    {
        defaultFurDirection = newDefaultDirection.normalized;
    }

    // 风场控制方法
    public void SetBaseWind(Vector3 direction, float strength)
    {
        baseWindDirection = direction;
        baseWindStrength = strength;
    }

    public void AddWindZone(Transform zoneTransform, float radius, float strength)
    {
        WindZone newZone = new WindZone
        {
            windZoneTransform = zoneTransform,
            radius = radius,
            strength = strength,
            falloff = AnimationCurve.EaseInOut(0, 1, 1, 0)
        };

        // 添加到数组
        WindZone[] newZones = new WindZone[windZones.Length + 1];
        windZones.CopyTo(newZones, 0);
        newZones[windZones.Length] = newZone;
        windZones = newZones;
    }

    // 可视化风区域（在Scene视图中显示）
    void OnDrawGizmosSelected()
    {
        if (windZones != null)
        {
            foreach (WindZone zone in windZones)
            {
                if (zone.windZoneTransform != null)
                {
                    Gizmos.color = new Color(0, 1, 1, 0.3f);
                    Gizmos.DrawWireSphere(zone.windZoneTransform.position, zone.radius);

                    // 显示风向
                    Gizmos.color = Color.cyan;
                    Vector3 start = zone.windZoneTransform.position;
                    Vector3 end = start + zone.windZoneTransform.forward * zone.radius * 0.5f;
                    Gizmos.DrawLine(start, end);
                    Gizmos.DrawWireSphere(end, zone.radius * 0.1f);
                }
            }
        }
    }

    void OnDestroy()
    {
        // 清理材质实例
        if (furMaterial != null)
        {
            if (Application.isPlaying)
            {
                Destroy(furMaterial);
            }
            else
            {
                DestroyImmediate(furMaterial);
            }
        }
    }
}
using UnityEngine;

public class RoleController : MonoBehaviour
{

    public GameObject targetGO;
    [Header("移动设置")]
    public float moveSpeed = 5f;      // 移动速度
    public float rotationSpeed = 10f; // 旋转平滑速度

    private Vector3 movement;         // 移动方向向量
    private Rigidbody rb;             // 物理组件

    void Start()
    {
        // 获取Rigidbody组件
        rb = targetGO.GetComponent<Rigidbody>();
        if (rb == null)
        {
            // 如果没有则自动添加
            rb = targetGO.AddComponent<Rigidbody>();
            rb.freezeRotation = true; // 锁定旋转防止物理碰撞导致翻滚
        }
    }

    void Update()
    {
        // 获取WASD输入
        float horizontal = Input.GetAxis("Horizontal");
        float vertical = Input.GetAxis("Vertical");

        // 计算移动方向 (基于世界坐标系)
        movement = new Vector3(horizontal, 0f, vertical).normalized;

        //// 旋转角色朝向移动方向
        //if (movement != Vector3.zero)
        //{
        //    RotateTowardsMovement();
        //}
    }

    void FixedUpdate()
    {
        // 物理移动
        MoveCharacter();
    }

    void MoveCharacter()
    {
        // 计算实际速度（保持Y轴高度不变）
        Vector3 velocity = movement * moveSpeed;
        velocity.y = rb.velocity.y;

        // 应用速度
        rb.velocity = velocity;
    }

    void RotateTowardsMovement()
    {
        // 计算目标朝向
        Quaternion targetRotation = Quaternion.LookRotation(movement);

        // 平滑旋转
        transform.rotation = Quaternion.Slerp(
            transform.rotation,
            targetRotation,
            rotationSpeed * Time.deltaTime
        );
    }
}
using UnityEngine;

public class PlanarReflectionMgr : MonoBehaviour {
    // 单例实例
    private static PlanarReflectionMgr _instance;

    // 获取单例实例
    public static PlanarReflectionMgr Instance {
        get {
            if (_instance == null) {
                // 尝试从场景中找到现有实例
                _instance = FindObjectOfType<PlanarReflectionMgr>();
            }
            return _instance;
        }
    }

    // 保证单例实例在场景切换时不会销毁
    private void Awake() {
        if (_instance != null && _instance != this) {
            Destroy(gameObject);
        }
        else {
            _instance = this;
            DontDestroyOnLoad(gameObject);  // 防止切换场景时销毁
        }
    }


    public Transform plane;
    [Range(0f, 2f)]
    public float strength = 1.0f;
    [Range(0f, 1f)]
    public float mipLevel = 0.0f;









    // 示例：清理资源
    public void Cleanup() {
        // 释放资源或做其他清理工作
        _instance = null;
    }
}

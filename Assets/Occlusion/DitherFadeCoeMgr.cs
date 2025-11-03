using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DitherFadeCoeMgr : MonoBehaviour
{
    public Transform targetTrans;
    private Collider m_TargetCollider;
    // Start is called before the first frame update
    void Start()
    {
        if(targetTrans != null)
        {
            m_TargetCollider = targetTrans.GetComponent<Collider>();
        }
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_RoleScreenPos", GetViewPos());
    }

    private Vector2 GetViewPos()
    {
        if(targetTrans == null) return Vector2.zero;
        var offsetY = new Vector3(0f, m_TargetCollider.bounds.size.y / 2f, 0f);
        var value = Camera.main.WorldToViewportPoint(targetTrans.position + offsetY);
        return value;
    }
}

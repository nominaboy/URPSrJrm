using UnityEngine;

[System.Serializable]
public class JRMMaterialProperty
{
    public enum PropertyType
    {
        Float,
        Color
    }

    public PropertyType type;
    public string propertyName;

    public AnimationCurve curve;
    public Gradient gradient;
}

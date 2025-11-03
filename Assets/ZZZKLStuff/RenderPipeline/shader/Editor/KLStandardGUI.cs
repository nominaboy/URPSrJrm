using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class KLStandardGUI : ShaderGUI
{
    private MaterialEditor materialEditor;
    private MaterialProperty[] properties;
    private Material material;
    public GUIStyle customStyle;

    private enum DirDiffuseType
    {
        _DIFFUSE_OFF,
        _DIFFUSE_CELSHADING,
        _DIFFUSE_LAMBERTIAN,
        _DIFFUSE_RAMPSHADING,
        _DIFFUSE_CELBANDSHADING,
        _DIFFUSE_SDFFACE
    };
    private enum DirSpecularType
    {
        _SPECULAR_OFF,
        _SPECULAR_GGX,
        _SPECULAR_STYLIZED,
        _SPECULAR_BLINNPHONG,
        _SPECULAR_ANGELRING
    };
    private Dictionary<string, List<string>> propertieReference = new Dictionary<string, List<string>>
    {
        { "_PBRFUNCTEX_ON", new List<string> { "_PBRFuncTex" } },
        { "_ALPHATEST_ON", new List<string> { "_AlphatestThreshold", "RenderQueue:AlphaTest" } },

        // Direct Diffuse
        { "_DIFFUSE_OFF", new List<string> { } },
        { "_DIFFUSE_CELSHADING", new List<string> { "_CelThreshold", "_CelSmoothing", "_LightColor", "_DarkColor" } },
        { "_DIFFUSE_LAMBERTIAN", new List<string> { "_LightColor", "_DarkColor" } },
        { "_DIFFUSE_RAMPSHADING", new List<string> { "_DiffuseRampMap", "_RampUOffset", "_RampVOffset" } },
        { "_DIFFUSE_CELBANDSHADING", new List<string> { "_LightColor", "_DarkColor", "_CelThreshold", "_CelBandSoftness", "_CelBands" } },
        { "_DIFFUSE_SDFFACE", new List<string> { "_SDFFaceTex", "_LightColor", "_DarkColor", "_SDFSoftness", "_SDFReversal" } },

        // Direct Specular
        { "_SPECULAR_OFF", new List<string> { } },
        { "_SPECULAR_GGX", new List<string> { "_SpecularIntensity", "_SpecularColor" } },
        { "_SPECULAR_STYLIZED", new List<string> { "_SpecularIntensity", "_SpecularColor",
            "_StylizedSpecularSize", "_StylizedSpecularSoftness", "_StylizedSpecularAlbedoWeight" } },
        { "_SPECULAR_BLINNPHONG", new List<string> { "_SpecularIntensity", "_SpecularColor", "_Shininess" } },
        { "_SPECULAR_ANGELRING", new List<string> { "_AngelRingTex", "_AngelRingThreshold", "_SpecularIntensity", "_SpecularColor" } },

        //{ "_EMISSION_ON", new List<string> { "_EmissionColor", "_EmissionColorAlbedoWeight", "_EmiFlashFrequency" } },
        { "_EMISSION_ON", new List<string> { "_EmissionTex", "_EmiIntensity", "_EmiFlashFrequency" } },
        { "_RIM_ON", new List<string> { "_RimDirectionLightContribution", "_RimColor", "_RimThreshold", "_RimSoftness" } },
        { "_CLEARCOAT", new List<string> { "_ClearCoatMask", "_ClearCoatSmoothness" } },

        // Functions
        //{ "_OCCLUSION_FADE", new List<string> { "_DistanceScale", "_DistanceSensitivity", "RenderQueue:AlphaTest" } },
        //{ "_KL_HEIGHTFOG_ON", new List<string> { "_FogHeight", "_FogColor" } },

    };



    MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, properties);
    }
    MaterialProperty ShaderProperty(string name)
    {
        MaterialProperty prop = FindProperty(name);
        materialEditor.ShaderProperty(prop, name);
        return prop;
    }
    delegate void BoxDelegate();
    void GroupBox(BoxDelegate func)
    {
        GUILayout.BeginVertical(customStyle);
        func();
        GUILayout.EndVertical();
    }
    bool IsReferenced(string name)
    {
        foreach (var pair in propertieReference)
        {
            string key = pair.Key;
            if (key.StartsWith("_DIFFUSE"))
            {
                List<string> value = pair.Value;
                DirDiffuseType type = (DirDiffuseType)Enum.Parse(typeof(DirDiffuseType), key);
                if (FindProperty("_DIFFUSE").floatValue == (int)type)
                {
                    foreach (var item in value)
                    {
                        if (item == name)
                        {
                            return true;
                        }
                    }
                }
            }
            else if (key.StartsWith("_SPECULAR"))
            {
                List<string> value = pair.Value;
                DirSpecularType type = (DirSpecularType)Enum.Parse(typeof(DirSpecularType), key);
                if (FindProperty("_SPECULAR").floatValue == (int)type)
                {
                    foreach (var item in value)
                    {
                        if (item == name)
                        {
                            return true;
                        }
                    }
                }
            }
            else
            {
                List<string> value = pair.Value;
                if (FindProperty(key).floatValue == 1)
                {
                    foreach (var item in value)
                    {
                        if (item == name)
                        {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }
    void PropertyField(string key)
    {
        var _PROPERTY = ShaderProperty(key);
        if (_PROPERTY.floatValue == 1)
        {
            var nonTexList = propertieReference[key].Where(item => !item.Contains("Tex") && !item.Contains("Map") && !item.Contains("RenderQueue")).ToList();
            foreach (var propertieName in nonTexList)
            {
                ShaderProperty(propertieName);
            }
            var texList = propertieReference[key].Where(item => item.Contains("Tex") || item.Contains("Map")).ToList();
            if (texList.Count != 0)
            {
                EditorGUILayout.HelpBox(string.Join(", ", texList), MessageType.Info);
            }

            var renderqueueList = propertieReference[key].Where(item => item.Contains("RenderQueue")).ToList();
            if (renderqueueList.Count != 0)
            {
                int renderQueue = (int)RenderQueue.Geometry;
                foreach (var renderQueueName in renderqueueList)
                {
                    string queueName = renderQueueName.Substring("RenderQueue:".Length).Trim();
                    int tempRenderQueue;
                    switch (queueName.ToUpper())
                    {
                        case "BACKGROUND":
                            tempRenderQueue = (int)RenderQueue.Background;
                            break;
                        case "GEOMETRY":
                            tempRenderQueue = (int)RenderQueue.Geometry;
                            break;
                        case "ALPHATEST":
                            tempRenderQueue = (int)RenderQueue.AlphaTest;
                            break;
                        case "TRANSPARENT":
                            tempRenderQueue = (int)RenderQueue.Transparent;
                            break;
                        case "OVERLAY":
                            tempRenderQueue = (int)RenderQueue.Overlay;
                            break;
                        default:
                            tempRenderQueue = (int)RenderQueue.Geometry;
                            break;
                    }
                    renderQueue = renderQueue > tempRenderQueue ? renderQueue : tempRenderQueue;
                }
                material.renderQueue = renderQueue;
            }
        }
    }
    void PropertyField<T>() where T : Enum
    {
        var values = Enum.GetValues(typeof(T));

        T firstEnumValue = (T)values.GetValue(0);
        string firstEnumName = firstEnumValue.ToString();
        string propName = "_" + firstEnumName.Split('_')[1];
        var _PROPERTY = ShaderProperty(propName);

        foreach (T value in values)
        {
            float floatValue = Convert.ToSingle(value);
            if (_PROPERTY.floatValue == floatValue)
            {
                var nonTexList = propertieReference[value.ToString()].Where(item => !item.Contains("Tex") && !item.Contains("Map") && !item.Contains("RenderQueue")).ToList();
                foreach (var propertieName in nonTexList)
                {
                    ShaderProperty(propertieName);
                }
                var texList = propertieReference[value.ToString()].Where(item => item.Contains("Tex") || item.Contains("Map")).ToList();
                if (texList.Count != 0)
                {
                    EditorGUILayout.HelpBox(string.Join(", ", texList), MessageType.Info);
                }

                var renderqueueList = propertieReference[value.ToString()].Where(item => item.Contains("RenderQueue")).ToList();
                if (renderqueueList.Count != 0)
                {
                    int renderQueue = (int)RenderQueue.Geometry;
                    foreach (var renderQueueName in renderqueueList)
                    {
                        string queueName = renderQueueName.Substring("RenderQueue:".Length).Trim();
                        int tempRenderQueue;
                        switch (queueName.ToUpper())
                        {
                            case "BACKGROUND":
                                tempRenderQueue = (int)RenderQueue.Background;
                                break;
                            case "GEOMETRY":
                                tempRenderQueue = (int)RenderQueue.Geometry;
                                break;
                            case "ALPHATEST":
                                tempRenderQueue = (int)RenderQueue.AlphaTest;
                                break;
                            case "TRANSPARENT":
                                tempRenderQueue = (int)RenderQueue.Transparent;
                                break;
                            case "OVERLAY":
                                tempRenderQueue = (int)RenderQueue.Overlay;
                                break;
                            default:
                                tempRenderQueue = (int)RenderQueue.Geometry;
                                break;
                        }
                        renderQueue = renderQueue > tempRenderQueue ? renderQueue : tempRenderQueue;
                    }
                    material.renderQueue = renderQueue;
                }
            }
        }
    }

    private Texture2D GenerateTex(int width, int height, Color topColor, Color bottomColor)
    {
        Color[] pix = new Color[width * height];
        for (int i = 0; i < pix.Length; i++)
        {
            pix[i] = Color.Lerp(bottomColor, topColor, i / (float)pix.Length);
        }
        Texture2D result = new Texture2D(width, height);
        result.SetPixels(pix);
        result.Apply();
        return result;
    }
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        this.materialEditor = materialEditor;
        this.properties = properties;
        material = materialEditor.target as Material;
        customStyle = new GUIStyle("GroupBox");
        customStyle.normal.background = GenerateTex(64, 64, new Color(0.16f, 0.3f, 0.6f, 0.3f), new Color(0.0f, 0.3f, 0.6f, 0.15f));

        GroupBox(() =>
        {
            ShaderProperty("_BaseMap");
            if (IsReferenced("_PBRFuncTex"))
            {
                ShaderProperty("_PBRFuncTex");
                EditorGUILayout.HelpBox("R: Metallic/G: Roughness/B: RampMapID/A: Null", MessageType.Info);
            }
            if (IsReferenced("_EmissionTex"))
            {
                ShaderProperty("_EmissionTex");
            }
            if (IsReferenced("_DiffuseRampMap"))
            {
                ShaderProperty("_DiffuseRampMap");
            }
            if (IsReferenced("_SDFFaceTex"))
            {
                ShaderProperty("_SDFFaceTex");
            }
            if (IsReferenced("_AngelRingTex"))
            {
                ShaderProperty("_AngelRingTex");
            }
        });
        GroupBox(() =>
        {
            ShaderProperty("_UseHalfLambert");
            ShaderProperty("_PBRFUNCTEX_ON");
            ShaderProperty("_BaseColor");
            ShaderProperty("_Metallic");
            ShaderProperty("_Roughness");
            //ShaderProperty("_OcclusionStrength");
            PropertyField("_ALPHATEST_ON");
            ShaderProperty("_ADDLIGHT_ON");
        });
        GroupBox(() =>
        {
            PropertyField<DirDiffuseType>();
        });
        GroupBox(() =>
        {
            PropertyField<DirSpecularType>();
        });
        GroupBox(() =>
        {
            ShaderProperty("_INDIRDIFFUSE");
            ShaderProperty("_INDIRSPECULAR");
        });
        GroupBox(() =>
        {
            PropertyField("_EMISSION_ON");
        });
        GroupBox(() =>
        {
            PropertyField("_RIM_ON");
        });
        GroupBox(() =>
        {
            PropertyField("_CLEARCOAT");
        });
        GroupBox(() =>
        {
            //PropertyField("_OCCLUSION_FADE");
            ShaderProperty("_Tint");
            //PropertyField("_KL_HEIGHTFOG_ON");
        });
        GroupBox(() =>
        {
            ShaderProperty("_Cull");
            ShaderProperty("_ZTest");
            ShaderProperty("_ZWrite");
            materialEditor.RenderQueueField();
        });
    }
}

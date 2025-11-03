using UnityEditor;
using UnityEngine;

public class EffectOpaqueGUI : ShaderGUI
{
    public enum CullType
    {
        Back = 0,
        Front,
        Off
    }

    protected class Styles
    {
        public static readonly GUIContent BaseOptions =
             new GUIContent("基础选择", "");
        public static readonly GUIContent BaseMapOptions =
             new GUIContent("主贴图", "");
        public static readonly GUIContent CullType =
            new GUIContent("剔除模式", "Front(剔除前面)\r\nBack(剔除后面)\r\nOff (双面显示)");
        public static readonly GUIContent BaseMap =
           new GUIContent("BaseMap", "基本的贴图");
        public static readonly GUIContent AddMap =
           new GUIContent("AddMap", "附加的贴图");
        public static readonly GUIContent MaskMapOptions =
            new GUIContent("遮罩贴图", "");
        public static readonly GUIContent MaskMap =
            new GUIContent("MaskMap", "遮罩贴图");
        public static readonly GUIContent MaskAR =
            new GUIContent("MaskAR", "遮罩贴图使用A通道 或者 R通道,勾选上使用A通道");
        public static readonly GUIContent DissolveMapOptions =
         new GUIContent("溶解贴图", "");
        public static readonly GUIContent DissolveMap =
         new GUIContent("DissolveMap", "溶解贴图");
        public static readonly GUIContent DissolveValue =
         new GUIContent("DissolveValue", "溶解值");
        public static readonly GUIContent OtherOptions =
        new GUIContent("其他设置", "");
        public static readonly GUIContent FresnelOptions =
        new GUIContent("菲涅尔效果", "");
        public static readonly GUIContent FresnelCol =
        new GUIContent("菲涅尔颜色", "a值可以控制菲涅尔整体效果的展示程度");
        public static readonly GUIContent NoiseOptions =
        new GUIContent("噪波贴图", "");
        public static readonly GUIContent NoiseMap =
            new GUIContent("_NoiseMap", "噪波贴图");
    }


    MaterialEditor materialEditor;

    private MaterialProperty baseMapProp;
    private MaterialProperty baseColorProp;
    private MaterialProperty mainUspeed;
    private MaterialProperty mainVspeed;

    private MaterialProperty maskOnProp;
    private MaterialProperty maskMapProp;
    private MaterialProperty maskARProp;
    private MaterialProperty maskUspeed;
    private MaterialProperty maskVspeed;

    private MaterialProperty dissolveOnProp;
    private MaterialProperty dissolveMapProp;
    private MaterialProperty dissolveValueProp;
    private MaterialProperty dissolveUspeed;
    private MaterialProperty dissolveVspeed;


    private MaterialProperty addTexOnProp;
    private MaterialProperty addTexProp;
    private MaterialProperty addTexColorProp;
    private MaterialProperty addTexUspeed;
    private MaterialProperty addTexVspeed;


    private MaterialProperty fresnelOnProp;
    private MaterialProperty fresnelBaseProp;
    private MaterialProperty fresnelScaleProp;
    private MaterialProperty fresnelIndensityProp;
    private MaterialProperty fresnelColProp;

    private MaterialProperty customData1XYProp;
    private MaterialProperty customData1ZWProp;
    private MaterialProperty customData2XProp;
    private MaterialProperty backColorProp;
    private MaterialProperty mainTexAngleProp;
    private MaterialProperty addTexAngleProp;
    private MaterialProperty maskTexAngleProp;

    private MaterialProperty noiseOnProp;
    private MaterialProperty noiseMapProp;
    private MaterialProperty noiseMapUspeedProp;
    private MaterialProperty noiseMapVspeedProp;
    private MaterialProperty noiseIntensityProp;
    private MaterialProperty backColorOnProp;

    private const string k_KeyPrefix = "AOI:Material:UI_State:";
    string m_HeaderStateKey;
    string m_SurfaceInputsFoldoutKey;
    bool m_BaseOptionsFoldout = true;
    static bool m_BaseMapFoldot = false;
    static bool m_MaskMapFoldut = false;
    static bool m_DissolveFoldut = false;
    static bool m_OtherFoldut = false;
    static bool m_FresnelFoldut = false;
    static bool m_NoiseFoldut = false;
    bool m_FirstTimeApply = true;
    public virtual void FindProperties(MaterialProperty[] properties)
    {

        baseMapProp = FindProperty("_MainTex", properties);
        baseColorProp = FindProperty("_Color", properties);
        mainUspeed = FindProperty("_MainTex_Uspeed", properties);
        mainVspeed = FindProperty("_MainTex_Vspeed", properties);
        maskOnProp = FindProperty("_MaskTexOn", properties);
        maskMapProp = FindProperty("_MaskTex", properties);
        maskARProp = FindProperty("_MaskTex_RA", properties);
        maskUspeed = FindProperty("_Mask_Uspeed", properties);
        maskVspeed = FindProperty("_Mask_Vspeed", properties);
        dissolveOnProp = FindProperty("_DissolveTexOn", properties);
        dissolveMapProp = FindProperty("_DissolveTex", properties);
        dissolveValueProp = FindProperty("_DissolveValue", properties);
        dissolveUspeed = FindProperty("_Dissolve_Uspeed", properties);
        dissolveVspeed = FindProperty("_Dissolve_Vspeed", properties);
        addTexOnProp = FindProperty("_AddTexOn", properties);
        addTexProp = FindProperty("_AddTex", properties);
        fresnelOnProp = FindProperty("_FresnelOn", properties);
        fresnelBaseProp = FindProperty("_FresnelBase", properties);
        fresnelScaleProp = FindProperty("_FresnelScale", properties);
        fresnelIndensityProp = FindProperty("_FresnelIndensity", properties);
        fresnelColProp = FindProperty("_FresnelCol", properties);
        addTexColorProp = FindProperty("_AddTex_Color", properties);
        addTexUspeed = FindProperty("_AddTex_Uspeed", properties);
        addTexVspeed = FindProperty("_AddTex_Vspeed", properties);

        customData1XYProp = FindProperty("_CustomData1XY", properties);
        customData1ZWProp = FindProperty("_CustomData1ZW", properties);
        customData2XProp = FindProperty("_CustomData2X", properties);
        backColorProp = FindProperty("_BackColor", properties);
        mainTexAngleProp = FindProperty("_MainTexAngle", properties);
        addTexAngleProp = FindProperty("_AddTexAngle", properties);
        maskTexAngleProp = FindProperty("_MaskTexAngle", properties);

        noiseOnProp = FindProperty("_Noise_On", properties);
        noiseMapProp = FindProperty("_NoiseTexture", properties);
        noiseMapUspeedProp = FindProperty("_NoiseTex_Uspeed", properties);
        noiseMapVspeedProp = FindProperty("_NoiseTex_Vspeed", properties);
        noiseIntensityProp = FindProperty("_Noise_Intensity", properties);
        backColorOnProp = FindProperty("_BackColor_ON", properties);
    }
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        FindProperties(properties);
        this.materialEditor = materialEditor;
        Material material = materialEditor.target as Material;
        if (m_FirstTimeApply)
        {
            m_FirstTimeApply = false;
            OnOpenGUI(material, materialEditor);
        }

        DrawBaseOptions(material);
        DrawBaseMapOptions(material);
        DrawMaskMapOptions(material);
        DrawDissolveMapOptions(material);
        DrawFresnelOptions(material);
        DrawNoiseOptions(material);
        DrawOtherOptions(material);
    }


    public virtual void OnOpenGUI(Material material, MaterialEditor materialEditor)
    {

        m_HeaderStateKey = k_KeyPrefix + material.shader.name; // Create key string for editor prefs
        m_SurfaceInputsFoldoutKey = $"{m_HeaderStateKey}.SurfaceInputsFoldout";
    }



    private void DrawBaseOptions(Material material)
    {
        EditorGUI.BeginChangeCheck();
        m_BaseOptionsFoldout = EditorPrefs.GetBool(m_SurfaceInputsFoldoutKey);
        m_BaseOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_BaseOptionsFoldout, Styles.BaseOptions);
        if (m_BaseOptionsFoldout)
        {
            DrawCullTypeProperties(material);
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
        if (EditorGUI.EndChangeCheck())
        {
            EditorPrefs.SetBool(m_SurfaceInputsFoldoutKey, m_BaseOptionsFoldout);
        }
    }

    private void DrawBaseMapOptions(Material material)
    {

        m_BaseMapFoldot = EditorGUILayout.BeginFoldoutHeaderGroup(m_BaseMapFoldot, Styles.BaseMapOptions);
        if (m_BaseMapFoldot)
        {

            if (baseMapProp != null && baseColorProp != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.BaseMap, baseMapProp, baseColorProp);
                if (material.HasProperty("_MainTex"))
                {
                    materialEditor.TextureScaleOffsetProperty(baseMapProp);

                    materialEditor.ShaderProperty(mainTexAngleProp, "旋转角度");
                    materialEditor.ShaderProperty(backColorOnProp, "开启背面颜色");
                    materialEditor.ShaderProperty(backColorProp, "背面的颜色");
                    GUILayout.Space(10);
                    materialEditor.ShaderProperty(customData1XYProp, "启用CustomData1XY");
                    materialEditor.ShaderProperty(mainUspeed, "U流动");
                    materialEditor.ShaderProperty(mainVspeed, "V流动");

                    materialEditor.ShaderProperty(addTexOnProp, "开启混合贴图");
                    if (addTexOnProp.floatValue == 1)
                    {
                        GUILayout.Space(10);
                        materialEditor.TexturePropertySingleLine(Styles.AddMap, addTexProp, addTexColorProp);
                        materialEditor.TextureScaleOffsetProperty(addTexProp);
                        materialEditor.ShaderProperty(addTexAngleProp, "旋转值");
                        materialEditor.ShaderProperty(addTexUspeed, "U流动");
                        materialEditor.ShaderProperty(addTexVspeed, "V流动");
                    }
                }
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();

    }

    private void DrawMaskMapOptions(Material material)
    {
        m_MaskMapFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_MaskMapFoldut, Styles.MaskMapOptions);
        if (m_MaskMapFoldut)
        {
            if (maskMapProp != null)
            {
                materialEditor.ShaderProperty(maskOnProp, "开启遮罩贴图");
                if (maskOnProp.floatValue == 1)
                {
                    materialEditor.TexturePropertySingleLine(Styles.MaskMap, maskMapProp);
                    materialEditor.TextureScaleOffsetProperty(maskMapProp);
                    materialEditor.ShaderProperty(maskARProp, Styles.MaskAR);
                    materialEditor.ShaderProperty(maskTexAngleProp, "旋转值");
                    GUILayout.Space(10);
                    materialEditor.ShaderProperty(customData1ZWProp, "启用CustomData1ZW");
                    materialEditor.ShaderProperty(maskUspeed, "U流动");
                    materialEditor.ShaderProperty(maskVspeed, "V流动");
                }
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    private void DrawDissolveMapOptions(Material material)
    {
        m_DissolveFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_DissolveFoldut, Styles.DissolveMapOptions);
        if (m_DissolveFoldut)
        {
            if (maskMapProp != null)
            {
                materialEditor.ShaderProperty(dissolveOnProp, "开启溶解贴图");
                if (dissolveOnProp.floatValue == 1)
                {
                    materialEditor.TexturePropertySingleLine(Styles.DissolveMap, dissolveMapProp);
                    materialEditor.TextureScaleOffsetProperty(dissolveMapProp);
                    materialEditor.ShaderProperty(customData2XProp, "启用CustomData2X");
                    materialEditor.ShaderProperty(dissolveValueProp, Styles.DissolveValue);
                    materialEditor.ShaderProperty(dissolveUspeed, "U流动");
                    materialEditor.ShaderProperty(dissolveVspeed, "V流动");
                }
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }
    private void DrawFresnelOptions(Material material)
    {
        m_FresnelFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_FresnelFoldut, Styles.FresnelOptions);
        if (m_FresnelFoldut)
        {
            materialEditor.ShaderProperty(fresnelOnProp, "开启菲涅尔");
            if (fresnelOnProp.floatValue == 1)
            {
                materialEditor.ShaderProperty(fresnelBaseProp, "菲涅尔基础值");
                materialEditor.ShaderProperty(fresnelScaleProp, "菲涅尔大小");
                materialEditor.ShaderProperty(fresnelIndensityProp, "菲涅尔强度");
                materialEditor.ShaderProperty(fresnelColProp, Styles.FresnelCol);
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }
    private void DrawNoiseOptions(Material material)
    {
        m_NoiseFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_NoiseFoldut, Styles.NoiseOptions);
        if (m_NoiseFoldut)
        {
            materialEditor.ShaderProperty(noiseOnProp, "开启噪波效果");
            if (noiseOnProp.floatValue == 1)
            {
                materialEditor.ShaderProperty(noiseIntensityProp, "噪波强度");
                materialEditor.TexturePropertySingleLine(Styles.NoiseMap, noiseMapProp);
                materialEditor.TextureScaleOffsetProperty(noiseMapProp);
                GUILayout.Space(10);
                materialEditor.ShaderProperty(noiseMapUspeedProp, "U流动");
                materialEditor.ShaderProperty(noiseMapVspeedProp, "V流动");
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

   

    
    private void DrawCullTypeProperties(Material material)
    {
        GUILayout.BeginHorizontal();
        EditorGUILayout.PrefixLabel("剔除模式");
        if (material.GetFloat("_CullMode") == (float)UnityEngine.Rendering.CullMode.Off)
        {
            if (GUILayout.Button("双面显示"))
            {
                material.SetFloat("_CullMode", (float)UnityEngine.Rendering.CullMode.Back);
            }
        }
        else if (material.GetFloat("_CullMode") == (float)UnityEngine.Rendering.CullMode.Back)
        {
            if (GUILayout.Button("显示前面"))
            {
                material.SetFloat("_CullMode", (float)UnityEngine.Rendering.CullMode.Front);
            }
        }
        else
        {
            if (GUILayout.Button("显示背面"))
            {
                material.SetFloat("_CullMode", (float)UnityEngine.Rendering.CullMode.Off);
            }
        }
        GUILayout.EndHorizontal();

    }

    private void DrawOtherOptions(Material material)
    {
        m_OtherFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_OtherFoldut, Styles.OtherOptions);
        if (m_OtherFoldut)
        {
            EditorGUI.BeginChangeCheck();
            {
                MaterialProperty[] props = { };
                base.OnGUI(materialEditor, props);
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }
}



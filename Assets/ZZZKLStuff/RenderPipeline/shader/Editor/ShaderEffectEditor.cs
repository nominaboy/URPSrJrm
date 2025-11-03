using System;
using UnityEditor;
using UnityEngine;


public class ShaderEffectEditor : ShaderGUI
{
    public enum BlendType
    {
        Add = 0,
        Alpha,
        //Niuqu,
    }
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
        public static readonly GUIContent BlendType =
          new GUIContent("混合模式", "Add(叠加模式)\r\nAlpha(透明度混合)");
        public static readonly GUIContent CullType =
            new GUIContent("剔除模式", "Front(剔除前面)\r\nBack(剔除后面)\r\nOff (双面显示)");
        public static readonly GUIContent BaseMap =
           new GUIContent("BaseMap", "基本的贴图");
        public static readonly GUIContent AddMap =
           new GUIContent("AddMap", "附加的贴图");
        public static readonly GUIContent BaseMapAlphaR =
           new GUIContent("贴图的R通道做为透明度", "");
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
        //public static readonly GUIContent StencilOption =
        //new GUIContent("模板设置" , "");
        public static readonly GUIContent FresnelOptions =
        new GUIContent("菲涅尔效果", "");
        public static readonly GUIContent FresnelCol =
        new GUIContent("菲涅尔颜色", "a值可以控制菲涅尔整体效果的展示程度");
        public static readonly GUIContent NoiseOptions =
        new GUIContent("噪波贴图", "");
        public static readonly GUIContent NoiseMap =
            new GUIContent("_NoiseMap", "噪波贴图");
        //verticalBillboradingProp
        //public static readonly GUIContent VerticalBillborading =
        //    new GUIContent("广告牌控制垂直方向的约束", "  _VerticalBillborading 为 1 时, 法线方向固定，为视角方向当 _VerticalBillborading 为 0 时, 向上方向固定，为(0, 1, 0)");
    }


    MaterialEditor materialEditor;

    private MaterialProperty blendTypeProp;
    private MaterialProperty baseMapProp;
    private MaterialProperty baseColorProp;
    private MaterialProperty mainUspeed;
    private MaterialProperty mainVspeed;
    private MaterialProperty mainAlphaRProp;

    private MaterialProperty maskOnProp;
    private MaterialProperty maskMapProp;
    private MaterialProperty maskARProp;
    private MaterialProperty maskUspeed;
    private MaterialProperty maskVspeed;

    private MaterialProperty dissolveOnProp;
    private MaterialProperty dissolveAdvancedOnProp;
    private MaterialProperty dissolveMapProp;
    private MaterialProperty dissolveValueProp;
    private MaterialProperty dissolveUspeed;
    private MaterialProperty dissolveVspeed;
    private MaterialProperty dissolvePath;
    private MaterialProperty dissolveEdgeWidth;
    private MaterialProperty dissolveEdgeColor;
    private MaterialProperty dissolvePow;
    private MaterialProperty dissolveSmooth;










    private MaterialProperty wsSoftParticleOnProp;
    private MaterialProperty wsSoftParticleProp;
    //private MaterialProperty softParticleProp;
    private MaterialProperty addTexOnProp;
    private MaterialProperty addTexProp;
    private MaterialProperty addTexColorProp;
    private MaterialProperty addTexUspeed;
    private MaterialProperty addTexVspeed;
    //private MaterialProperty addLerpValue;


    private MaterialProperty fresnelOnProp;
    private MaterialProperty fresnelBaseProp;
    private MaterialProperty fresnelScaleProp;
    private MaterialProperty fresnelIndensityProp;
    private MaterialProperty fresnelColProp;
    //private MaterialProperty bloomFactorProp;
    private MaterialProperty alphaProp;
    //private MaterialProperty noiseTexProp;
    //private MaterialProperty heatTimeProp;
    //private MaterialProperty heatForceProp;

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
    private MaterialProperty alphaIntensityProp;
    //private MaterialProperty billboardOnProp;
    //private MaterialProperty verticalBillboradingProp;

    //private MaterialProperty stencilValProp;
    //private MaterialProperty stencilCompProp;
    //private MaterialProperty stencilOp;

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
    // string str_ZTestValue = "否";
    //static bool m_StencilFoldut = false;

    //static bool isNiuquShader = false;
    public virtual void FindProperties(MaterialProperty[] properties)
    {

        blendTypeProp = FindProperty("_BlendType", properties);
        baseMapProp = FindProperty("_MainTex", properties);
        baseColorProp = FindProperty("_Color", properties);
        mainUspeed = FindProperty("_MainTex_Uspeed", properties);
        mainVspeed = FindProperty("_MainTex_Vspeed", properties);
        mainAlphaRProp = FindProperty("_MainTex_Alpha_R", properties);
        maskOnProp = FindProperty("_MaskTexOn", properties);
        maskMapProp = FindProperty("_MaskTex", properties);
        maskARProp = FindProperty("_MaskTex_RA", properties);
        maskUspeed = FindProperty("_Mask_Uspeed", properties);
        maskVspeed = FindProperty("_Mask_Vspeed", properties);
        dissolveOnProp = FindProperty("_DissolveTexOn", properties);
        dissolveAdvancedOnProp = FindProperty("_DISSOLVE", properties);



        dissolveMapProp = FindProperty("_DissolveTex", properties);
        dissolveValueProp = FindProperty("_DissolveValue", properties);
        dissolveUspeed = FindProperty("_Dissolve_Uspeed", properties);
        dissolveVspeed = FindProperty("_Dissolve_Vspeed", properties);
        dissolvePath = FindProperty("_Dissolve_Path", properties);
        dissolveEdgeWidth = FindProperty("_Dissolve_EdgeWidth", properties);
        dissolveEdgeColor = FindProperty("_Dissolve_EdgeColor", properties);
        dissolvePow = FindProperty("_Dissolve_Pow", properties);
        dissolveSmooth = FindProperty("_Dissolve_Smooth", properties);

        wsSoftParticleOnProp = FindProperty("_WSSoftParticlesOn", properties);
        wsSoftParticleProp = FindProperty("_SPIntensity", properties);
        //softParticleProp = FindProperty("_Soft_Particle", properties);
        addTexOnProp = FindProperty("_AddTexOn", properties);
        addTexProp = FindProperty("_AddTex", properties);
        //addLerpValue = FindProperty("_AddLerpValue", properties);
        fresnelOnProp = FindProperty("_FresnelOn", properties);
        fresnelBaseProp = FindProperty("_FresnelBase", properties);
        fresnelScaleProp = FindProperty("_FresnelScale", properties);
        fresnelIndensityProp = FindProperty("_FresnelIndensity", properties);
        fresnelColProp = FindProperty("_FresnelCol", properties);
        addTexColorProp = FindProperty("_AddTex_Color", properties);
        addTexUspeed = FindProperty("_AddTex_Uspeed", properties);
        addTexVspeed = FindProperty("_AddTex_Vspeed", properties);
        //bloomFactorProp = FindProperty("_BloomFactor", properties);
        alphaProp = FindProperty("_Alpha", properties);

        //noiseTexProp = FindProperty("_NoiseTex", properties);
        //heatTimeProp = FindProperty("_HeatTime", properties);
        //heatForceProp = FindProperty("_HeatForce", properties);
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
        alphaIntensityProp = FindProperty("_Alpha_Intensity", properties);
        //billboardOnProp = FindProperty("_BillboardOn", properties);
        //verticalBillboradingProp = FindProperty("_VerticalBillborading", properties);

        //stencilValProp = FindProperty("_Stencil" , properties);
        //stencilCompProp = FindProperty("_StencilComp" , properties);
        //stencilOp = FindProperty("_StencilOp" , properties);
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
        //DrawStencilOptions(material);
        //if(isNiuquShader) return;
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
        //  
        //if ((BlendType)blendTypeProp.floatValue == BlendType.Niuqu)
        //{
        //    material.SetShaderPassEnabled("UniversalForward", false);
        //    material.SetShaderPassEnabled("TransparentBloomFactor", false);
        //    material.SetShaderPassEnabled("Grab", true);
        //    isNiuquShader = true;
        //}
        //else
        //{
        //    material.SetShaderPassEnabled("UniversalForward", true);
        //    material.SetShaderPassEnabled("TransparentBloomFactor", true);
        //    material.SetShaderPassEnabled("Grab", false);
        //    isNiuquShader = false;

        //}

    }



    private void DrawBaseOptions(Material material)
    {
        EditorGUI.BeginChangeCheck();
        m_BaseOptionsFoldout = EditorPrefs.GetBool(m_SurfaceInputsFoldoutKey);
        m_BaseOptionsFoldout = EditorGUILayout.BeginFoldoutHeaderGroup(m_BaseOptionsFoldout, Styles.BaseOptions);
        if (m_BaseOptionsFoldout)
        {
            DrawBlendTypeProperties(material);
            //if (isNiuquShader)
            //{
            //    materialEditor.ShaderProperty(noiseTexProp, "Noise Texture (RG)");
            //    materialEditor.ShaderProperty(heatTimeProp, "Heat Time");
            //    materialEditor.ShaderProperty(heatForceProp, "Heat Force");
            //    materialEditor.ShaderProperty(maskMapProp, "Mask Texture (A)");
            //    return;
            //}
            DrawCullTypeProperties(material);
            #region  ZTest
            GUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("是否忽略深度测试");
            if (material.GetFloat("_ZTestMode") == (float)UnityEngine.Rendering.CompareFunction.LessEqual)
            {

                if (GUILayout.Button("否"))
                {
                    material.SetFloat("_ZTestMode", (float)UnityEngine.Rendering.CompareFunction.Always);
                }
            }
            else
            {
                if (GUILayout.Button("是"))
                {
                    material.SetFloat("_ZTestMode", (float)UnityEngine.Rendering.CompareFunction.LessEqual);
                }
            }

            GUILayout.EndHorizontal();
            #endregion

            #region ZWirte
            GUILayout.BeginHorizontal();
            EditorGUILayout.PrefixLabel("是否写入深度");
            if (material.GetFloat("_ZWriteMode") == 0)
            {

                if (GUILayout.Button("否"))
                {
                    material.SetFloat("_ZWriteMode", 1);
                }
            }
            else
            {
                if (GUILayout.Button("是"))
                {
                    material.SetFloat("_ZWriteMode", 0);
                }
            }
            GUILayout.EndHorizontal();
            #endregion

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
                    materialEditor.ShaderProperty(mainAlphaRProp, Styles.BaseMapAlphaR);

                    materialEditor.ShaderProperty(addTexOnProp, "开启混合贴图");
                    if (addTexOnProp.floatValue == 1)
                    {
                        GUILayout.Space(10);
                        materialEditor.TexturePropertySingleLine(Styles.AddMap, addTexProp, addTexColorProp);
                        materialEditor.TextureScaleOffsetProperty(addTexProp);
                        materialEditor.ShaderProperty(addTexAngleProp, "旋转值");
                        //materialEditor.ShaderProperty(addLerpValue, "混合值");
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
            materialEditor.ShaderProperty(dissolveOnProp, "开启基础溶解");

            if (dissolveOnProp.floatValue == 1)
            {
                materialEditor.TexturePropertySingleLine(Styles.DissolveMap, dissolveMapProp);
                materialEditor.TextureScaleOffsetProperty(dissolveMapProp);
                materialEditor.ShaderProperty(customData2XProp, "启用CustomData2X");
                materialEditor.ShaderProperty(dissolveValueProp, Styles.DissolveValue);
                materialEditor.ShaderProperty(dissolveUspeed, "U流动");
                materialEditor.ShaderProperty(dissolveVspeed, "V流动");
            }
            else
            {
                materialEditor.ShaderProperty(dissolveAdvancedOnProp, "开启高级溶解");
                if (dissolveAdvancedOnProp.floatValue > 0.5f)
                {
                    materialEditor.TexturePropertySingleLine(Styles.DissolveMap, dissolveMapProp);
                    materialEditor.TextureScaleOffsetProperty(dissolveMapProp);
                    materialEditor.ShaderProperty(customData2XProp, "启用CustomData2X");
                    materialEditor.ShaderProperty(dissolveValueProp, Styles.DissolveValue);
                    materialEditor.ShaderProperty(dissolveUspeed, "U流动");
                    materialEditor.ShaderProperty(dissolveVspeed, "V流动");
                    materialEditor.ShaderProperty(dissolvePath, "溶解Path");
                    materialEditor.ShaderProperty(dissolveEdgeWidth, "溶解边缘宽度");
                    materialEditor.ShaderProperty(dissolveEdgeColor, "溶解边缘颜色");
                    materialEditor.ShaderProperty(dissolvePow, "溶解指数");
                    materialEditor.ShaderProperty(dissolveSmooth, "溶解平滑值");
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

    private void DrawOtherOptions(Material material)
    {
        m_OtherFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_OtherFoldut, Styles.OtherOptions);
        if (m_OtherFoldut)
        {
            //materialEditor.ShaderProperty(SoftParticleOnProp, "是否开始软粒子");
            //if (SoftParticleOnProp.floatValue == 1)
            //{
            //    materialEditor.ShaderProperty(softParticleProp, "软粒子强度");
            //    //  material.SetShaderPassEnabled("UniversalForward", true);
            //}

            materialEditor.ShaderProperty(wsSoftParticleOnProp, "是否开启世界空间软粒子");
            if (wsSoftParticleOnProp.floatValue == 1)
            {
                materialEditor.ShaderProperty(wsSoftParticleProp, "软粒子强度");
                //  material.SetShaderPassEnabled("UniversalForward", true);
            }


            materialEditor.ShaderProperty(alphaProp, "_Alpha(总透明度)");
            materialEditor.ShaderProperty(alphaIntensityProp, "_Alpha强度(总透明度)");
            //materialEditor.ShaderProperty(billboardOnProp, "是否开启广告牌效果(需要使用XY轴空间的面片)"); //
            //if (billboardOnProp.floatValue > 0)
            //    materialEditor.ShaderProperty(verticalBillboradingProp, Styles.VerticalBillborading);
            //GUILayout.Space(10);
            //materialEditor.ShaderProperty(bloomFactorProp, "Bloom发光度");

            EditorGUI.BeginChangeCheck();
            {
                MaterialProperty[] props = { };
                base.OnGUI(materialEditor, props);
            }
        }
        EditorGUILayout.EndFoldoutHeaderGroup();
    }

    //private void DrawStencilOptions(Material material)
    //{
    //    m_StencilFoldut = EditorGUILayout.BeginFoldoutHeaderGroup(m_StencilFoldut , Styles.StencilOption);
    //    if(m_StencilFoldut)
    //    {
    //        materialEditor.ShaderProperty(stencilValProp , "模板值");
    //        materialEditor.ShaderProperty(stencilCompProp , "模板比较");
    //        materialEditor.ShaderProperty(stencilOp , "模板操作");
    //    }
    //    EditorGUILayout.EndFoldoutHeaderGroup();
    //}

    private void DrawBlendTypeProperties(Material material)
    {
        EditorGUI.BeginChangeCheck();
        DoEnumPopup(Styles.BlendType, blendTypeProp, Enum.GetNames(typeof(BlendType)));

        if (EditorGUI.EndChangeCheck())
        {
            //if (isNiuquShader)
            //{
            //    isNiuquShader = false;
            //    material.SetShaderPassEnabled("UniversalForward", true);
            //    material.SetShaderPassEnabled("TransparentBloomFactor", true);
            //    material.SetShaderPassEnabled("Grab", false);
            //}

            switch ((BlendType)blendTypeProp.floatValue)
            {
                case BlendType.Add:
                    material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.One);
                    material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.One);
                    //material.SetFloat("_SrcAlphaFactor", (float)UnityEngine.Rendering.BlendMode.Zero);
                    //material.SetFloat("_DstAlphaFactor", (float)UnityEngine.Rendering.BlendMode.One);
                    break;
                case BlendType.Alpha:
                    material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    //material.SetFloat("_SrcAlphaFactor", (float)UnityEngine.Rendering.BlendMode.Zero);
                    //material.SetFloat("_DstAlphaFactor", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    break;
                    //case BlendType.Niuqu:
                    //    isNiuquShader = true;
                    //    material.SetShaderPassEnabled("UniversalForward", false);
                    //    material.SetShaderPassEnabled("TransparentBloomFactor", false);
                    //    material.SetShaderPassEnabled("Grab", true);
                    //    break;
            }
        }
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

    public void DoEnumPopup(GUIContent label, MaterialProperty property, string[] options)
    {
        DoEnumPopup(label, property, options, materialEditor);
    }
    private void DoEnumPopup(GUIContent label, MaterialProperty property, string[] options, MaterialEditor materialEditor)
    {
        if (property == null)
            throw new ArgumentNullException("property");

        EditorGUI.showMixedValue = property.hasMixedValue;
        var mode = property.floatValue;
        EditorGUI.BeginChangeCheck();
        mode = EditorGUILayout.Popup(label, (int)mode, options);
        if (EditorGUI.EndChangeCheck())
        {
            materialEditor.RegisterPropertyChangeUndo(label.text);
            property.floatValue = mode;
        }

        EditorGUI.showMixedValue = false;

    }
}



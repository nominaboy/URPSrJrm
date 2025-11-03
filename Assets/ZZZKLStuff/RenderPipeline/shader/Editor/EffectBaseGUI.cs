using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class EffectBaseGUI : ShaderGUI
{
    Material mat;

    MaterialProperty blendProp, scrBlendProp, dstBlendProp;//----------------BlendMode (1)
    enum blendMode
    { Additive, AlphaBlend, Multiplicative }
    string[]blendModeNames = System.Enum.GetNames(typeof(blendMode));
     MaterialProperty vectorDataProp, distortValueProp, colorProp, mainTexProp, maskTexProp, distortTexProp, clipTexProp;
    float vectorDataPropX, vectorDataPropY, vectorDataPropZ, vectorDataPropW;
    float distortValuePropX, distortValuePropY, distortValuePropZ, distortValuePropW;
    bool isMaskEnabled, isDistortEnabled, isClipOn;
    MaterialProperty saveValue01Prop;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        mat = materialEditor.target as Material;
        saveValue01Prop = FindProperty("__SaveValue01", properties);

        blendProp = FindProperty("_Blend", properties);//--------------------BlendMode (2)
        scrBlendProp = FindProperty("_SrcFactor", properties);
        dstBlendProp = FindProperty("_DstFactor", properties);
        blendProp.floatValue = EditorGUILayout.Popup("Blend Mode",(int)blendProp.floatValue, blendModeNames);
        switch (blendProp.floatValue)
        {
            case 0:
                scrBlendProp.floatValue = (int)UnityEngine.Rendering.BlendMode.One;
                dstBlendProp.floatValue = (int)UnityEngine.Rendering.BlendMode.One;
                break;
            case 1:
                scrBlendProp.floatValue = (int)UnityEngine.Rendering.BlendMode.SrcAlpha;
                dstBlendProp.floatValue = (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha;
                break;
            case 2:
                scrBlendProp.floatValue = (int)UnityEngine.Rendering.BlendMode.DstColor;
                dstBlendProp.floatValue = (int)UnityEngine.Rendering.BlendMode.Zero;
                break;
        }

EditorGUILayout.Space(10);//间隔20像素
        colorProp = FindProperty("_Color", properties);
        materialEditor.ColorProperty(colorProp, "Color");
        mainTexProp = FindProperty("_MainTex", properties);
        materialEditor.TextureProperty(mainTexProp, "Main Texture");

        vectorDataProp = FindProperty("_VectorData",properties);
        // EditorGUILayout.HelpBox("四维向量可以通过EditorGUILoayout分拆成不同的值", MessageType.None);
        //初始赋值，不然会退出后归0
        vectorDataPropX = vectorDataProp.vectorValue.x;
        vectorDataPropY = vectorDataProp.vectorValue.y;
        vectorDataPropZ = vectorDataProp.vectorValue.z;
        vectorDataPropW = vectorDataProp.vectorValue.w;
        vectorDataPropX = EditorGUILayout.Slider("Main U Speed",vectorDataPropX,-2,2);
        vectorDataPropY = EditorGUILayout.Slider("Main V Speed",vectorDataPropY,-2,2);

        distortValueProp = FindProperty("_DistortValue",properties);
        // EditorGUILayout.HelpBox("四维向量可以通过EditorGUILoayout分拆成不同的值", MessageType.None);
        //初始赋值，不然会退出后归0
        distortValuePropX = distortValueProp.vectorValue.x;
        distortValuePropY = distortValueProp.vectorValue.y;
        distortValuePropZ = distortValueProp.vectorValue.z;
        distortValuePropW = distortValueProp.vectorValue.w;
        distortValuePropZ = EditorGUILayout.Slider("Intensity",distortValuePropZ,0,5);
        
//------------------------------------------------------------------------------------------------------------------------------------
EditorGUILayout.Space(10);//间隔20像素
        isMaskEnabled = saveValue01Prop.vectorValue.x != 0 ? true:false;//意思等同于上面四句
        isMaskEnabled = EditorGUILayout.BeginToggleGroup("Mask",isMaskEnabled);//**********Toggle Start
        if (isMaskEnabled)
            mat.EnableKeyword("_MASKENABLED_ON");
        else
            mat.DisableKeyword("_MASKENABLED_ON");

        maskTexProp = FindProperty("_MaskTex", properties);
        materialEditor.TextureProperty(maskTexProp, "Mask Map");

        vectorDataPropZ = EditorGUILayout.Slider("Mask U Speed",vectorDataPropZ,-2,2);
        vectorDataPropW = EditorGUILayout.Slider("Mask V Speed",vectorDataPropW,-2,2);
        EditorGUILayout.EndToggleGroup();//**********************************************************Toggle End

        Vector4 _newVector = new Vector4(vectorDataPropX, vectorDataPropY, vectorDataPropZ, vectorDataPropW);
        vectorDataProp.vectorValue = _newVector;

EditorGUILayout.Space(10);//间隔20像素
//------------------------------------------------------------------------------------------------------------------------------------
        isDistortEnabled = saveValue01Prop.vectorValue.y != 0? true:false;//意思等同于上面四句
        isDistortEnabled = EditorGUILayout.BeginToggleGroup("Distort",isDistortEnabled);//**********Toggle Start
        if (isDistortEnabled)
            mat.EnableKeyword("_DISTORTENABLED");
        else
            mat.DisableKeyword("_DISTORTENABLED");

        distortTexProp = FindProperty("_DistortTex", properties);
        materialEditor.TextureProperty(distortTexProp, "Distort Map");
        distortValuePropX = EditorGUILayout.Slider("Distort Main",distortValuePropX,-2,2);
        distortValuePropY = EditorGUILayout.Slider("Distort Mask",distortValuePropY,-2,2);
        EditorGUILayout.EndToggleGroup();//**********************************************************Toggle End


EditorGUILayout.Space(10);//间隔20像素
    //------------------------------------------------------------------------------------------------------------------------------------
        isClipOn = saveValue01Prop.vectorValue.z != 0 ? true:false;//意思等同于上面四句
        isClipOn = EditorGUILayout.BeginToggleGroup("Clip",isClipOn);//**********Toggle Start
        if (isClipOn)
            mat.EnableKeyword("_CLIP_ON");
        else
            mat.DisableKeyword("_CLIP_ON");

        clipTexProp = FindProperty("_ClipTex", properties);
        materialEditor.TextureProperty(clipTexProp, "Clip Map");
        distortValuePropW = EditorGUILayout.Slider("Clip",distortValuePropW,0,2);
        EditorGUILayout.EndToggleGroup();//**********************************************************Toggle End

        Vector4 _newVector2 = new Vector4(distortValuePropX, distortValuePropY, distortValuePropZ, distortValuePropW);
        distortValueProp.vectorValue = _newVector2;

        float _saveValue01X = isMaskEnabled ? 1:0;
        float _saveValue01Y = isDistortEnabled ? 1:0;
        float _saveValue01Z = isClipOn ? 1:0;
        Vector4 _saveValue01 = new Vector4(_saveValue01X,_saveValue01Y,_saveValue01Z,0);
        saveValue01Prop.vectorValue = _saveValue01;

EditorGUILayout.Space(10);//间隔20像素
        materialEditor.RenderQueueField();
        materialEditor.EnableInstancingField();
        materialEditor.DoubleSidedGIField();
        

    }

}

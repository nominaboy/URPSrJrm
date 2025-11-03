using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BossAlphaGUI : ShaderGUI
{
    Material mat;
    MaterialProperty tintProp,mainTexProp,illumindexProp;
    MaterialProperty vectorProp, vect2Prop;
    float vectorPropX,vectorPropY,vectorPropZ,vectorPropW,vect2PropX,vect2PropY,vect2PropZ,vect2PropW;
    float illumindexPropX, illumindexPropY,illumindexPropZ, illumindexPropW;
    MaterialProperty SpecColorProp,colorTintProp,colorSelfProp,colorProp;
    bool isIllumEnabled;
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            mat = materialEditor.target as Material;
            vect2Prop = FindProperty("_vect",properties);
            //初始值
            vect2PropX = vect2Prop.vectorValue.x;
            vect2PropY = vect2Prop.vectorValue.y;
            vect2PropZ = vect2Prop.vectorValue.z;
            vect2PropW = vect2Prop.vectorValue.w;
EditorGUILayout.LabelField("程序策划控制参数",EditorStyles.boldLabel);//标题
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);//划线开始----------1
            EditorGUILayout.Space(5);//间隔20像素
            //Tint颜色
            tintProp = FindProperty("_Tint",properties);
            materialEditor.ColorProperty(tintProp, "Tint Color(程序控制)");
            //Fresnal颜色
            colorTintProp = FindProperty("_FresnelColor",properties);
            materialEditor.ColorProperty(colorTintProp, "Frensnel Color");

            vect2PropW = EditorGUILayout.Slider("Frensnel亮度",vect2PropW,0,2);
             EditorGUILayout.Space(5);//间隔20像素
            EditorGUILayout.EndVertical();//划线结束----------------------------------1

EditorGUILayout.Space(10);//间隔20像素
EditorGUILayout.LabelField("美术控制参数",EditorStyles.boldLabel);//标题


EditorGUILayout.BeginVertical(EditorStyles.helpBox);//划线开始----------1
            //Color
            colorProp = FindProperty("_Color",properties);
            materialEditor.ColorProperty(colorProp, "Color");
            //Main Texture
            mainTexProp = FindProperty("_MainTex",properties);
            materialEditor.TextureProperty(mainTexProp, "Main Texture");

            illumindexProp = FindProperty("_Illumindex",properties);
            //初始值
            illumindexPropX = illumindexProp.vectorValue.x;
            illumindexPropY = illumindexProp.vectorValue.y;
            illumindexPropZ = illumindexProp.vectorValue.z;
            illumindexPropW = illumindexProp.vectorValue.w;
            illumindexPropY = EditorGUILayout.Slider("diff亮度",illumindexPropY,0,10);

            vectorProp = FindProperty("_number",properties);
            //获取初始值
            vectorPropX = vectorProp.vectorValue.x;
            vectorPropY = vectorProp.vectorValue.y;
            vectorPropZ = vectorProp.vectorValue.z;
            vectorPropW = vectorProp.vectorValue.w;
            vectorPropX = EditorGUILayout.Slider("diff过渡",vectorPropX,0,2);
            vectorPropY = EditorGUILayout.Slider("暗面加亮",vectorPropY,0,1);
            EditorGUILayout.Space(5);
EditorGUILayout.EndVertical();//划线结束----------------------------------1

EditorGUILayout.BeginVertical(EditorStyles.helpBox);//划线开始----------1
            //Spacular Color
            SpecColorProp = FindProperty("_SpacularColor",properties);
            materialEditor.ColorProperty(SpecColorProp, "Specular Color");

            vectorPropZ = EditorGUILayout.Slider("Specualr",vectorPropZ,0,2);
            vectorPropW = EditorGUILayout.Slider("Glosses",vectorPropW,1,200);
            EditorGUILayout.Space(5);
EditorGUILayout.EndVertical();//划线结束----------------------------------1
            //重新把改写的值组装成一个四维向量
            Vector4 _newVector = new Vector4(vectorPropX, vectorPropY, vectorPropZ, vectorPropW);
            vectorProp.vectorValue = _newVector;

EditorGUILayout.BeginVertical(EditorStyles.helpBox);//划线开始----------1
            //Fresnal自身颜色
            colorSelfProp = FindProperty("_FresnelColorSelf",properties);
            materialEditor.ColorProperty(colorSelfProp, "自身Fresnal Color");  

            vect2PropY = EditorGUILayout.Slider("Frensnel Power",vect2PropY,0,10);
            vect2PropZ = EditorGUILayout.Slider("Frensnel Intensity",vect2PropZ,0,10);
            vect2PropX = EditorGUILayout.Slider("自身Fresnal",vect2PropX,0,1);
EditorGUILayout.EndVertical();//划线结束----------------------------------1
            //重新把改写的值组装成一个四维向量
            Vector4 _NewVector2 = new Vector4(vect2PropX,vect2PropY,vect2PropZ,vect2PropW);
            vect2Prop.vectorValue = _NewVector2;
EditorGUILayout.BeginVertical(EditorStyles.helpBox);//划线开始----------1
        isIllumEnabled = mat.IsKeywordEnabled("_ILLUM_ON") ? true:false;
        isIllumEnabled = EditorGUILayout.BeginToggleGroup("Illum",isIllumEnabled);//**********Toggle Start
        if (isIllumEnabled)
            mat.EnableKeyword("_ILLUM_ON");
        else
            mat.DisableKeyword("_ILLUM_ON");
            // illumindexProp = FindProperty("_Illumindex",properties);
            // materialEditor.RangeProperty(illumindexProp,"Illum index");
            illumindexPropX = EditorGUILayout.Slider("自发光亮度",illumindexPropX,0,10);
        EditorGUILayout.EndToggleGroup();

EditorGUILayout.EndVertical();//划线结束----------------------------------1

            //重新把改写的值组装成一个四维向量
            Vector4 _illumindexProp = new Vector4(illumindexPropX,illumindexPropY,illumindexPropZ,illumindexPropW);
            illumindexProp.vectorValue = _illumindexProp;

            EditorGUILayout.Space(10);//间隔20像素
            materialEditor.RenderQueueField();
        }
}

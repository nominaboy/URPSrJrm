using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BossRimGUI : ShaderGUI
{
    Material mat;
    MaterialProperty tintProp,mainTexProp,illumindexProp;
    MaterialProperty vectorProp, vect2Prop, RimSideProp;
    float vectorPropX,vectorPropY,vectorPropZ,vectorPropW,vect2PropX,vect2PropY,vect2PropZ,vect2PropW;
    MaterialProperty colorProp,colorTintProp,colorSelfProp;
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
            tintProp = FindProperty("_Tint",properties);
            materialEditor.ColorProperty(tintProp, "Tint Color(程序控制)");
             
            colorTintProp = FindProperty("_FresnelColor",properties);
            materialEditor.ColorProperty(colorTintProp, "Frensnel Color");
            vect2PropW = EditorGUILayout.Slider("Frensnel亮度",vect2PropW,0,2);
             EditorGUILayout.Space(5);//间隔20像素
            EditorGUILayout.EndVertical();//划线结束----------------------------------1

EditorGUILayout.Space(10);//间隔20像素
EditorGUILayout.LabelField("美术控制参数",EditorStyles.boldLabel);//标题

            mainTexProp = FindProperty("_MainTex",properties);
            materialEditor.TextureProperty(mainTexProp, "Main Texture");
            vectorProp = FindProperty("_number",properties);
            //获取初始值
            vectorPropX = vectorProp.vectorValue.x;
            vectorPropY = vectorProp.vectorValue.y;
            vectorPropZ = vectorProp.vectorValue.z;
            vectorPropW = vectorProp.vectorValue.w;
            vectorPropX = EditorGUILayout.Slider("diff过渡",vectorPropX,0,20);
            colorProp = FindProperty("_SpacularColor",properties);
            materialEditor.ColorProperty(colorProp, "Specular Color");
            vectorPropY = EditorGUILayout.Slider("暗面加亮",vectorPropY,0,1);
            vectorPropZ = EditorGUILayout.Slider("Specualr",vectorPropZ,0,20);
            vectorPropW = EditorGUILayout.Slider("Glosses",vectorPropW,1,500);

            //重新把改写的值组装成一个四维向量
            Vector4 _newVector = new Vector4(vectorPropX, vectorPropY, vectorPropZ, vectorPropW);
            vectorProp.vectorValue = _newVector;

            vect2PropY = EditorGUILayout.Slider("Frensnel Power",vect2PropY,0,200);
            vect2PropZ = EditorGUILayout.Slider("Frensnel Intensity",vect2PropZ,0,10);

            colorSelfProp = FindProperty("_FresnelColorSelf",properties);
            materialEditor.ColorProperty(colorSelfProp, "自身FresColor a(dif亮度)");  
            vect2PropX = EditorGUILayout.Slider("自身Fresnal",vect2PropX,0,1);


            Vector4 _NewVector2 = new Vector4(vect2PropX,vect2PropY,vect2PropZ,vect2PropW);
            vect2Prop.vectorValue = _NewVector2;

        isIllumEnabled = mat.IsKeywordEnabled("_ILLUM_ON") ? true:false;
        isIllumEnabled = EditorGUILayout.BeginToggleGroup("Illum",isIllumEnabled);//**********Toggle Start
        if (isIllumEnabled)
            mat.EnableKeyword("_ILLUM_ON");
        else
            mat.DisableKeyword("_ILLUM_ON");
            illumindexProp = FindProperty("_Illumindex",properties);
            materialEditor.RangeProperty(illumindexProp,"Illum index");
        EditorGUILayout.EndToggleGroup();

            RimSideProp = FindProperty("_RimSide",properties);
            materialEditor.VectorProperty(RimSideProp, "x:Rim(Right:1, Left:-1), Y:spec");  
           
            EditorGUILayout.Space(10);//间隔20像素
            materialEditor.RenderQueueField();
        }
}

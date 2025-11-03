using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class BakeGI_Mix2_VertexColorGUI : ShaderGUI
{
    // MaterialProperty baseColorProp;
    MaterialProperty layer1MapProp, layer2MapProp, distanceScaleProp, distanceSensitivityProp, occlusionFadeProp;
    MaterialProperty heightContractProp;
    float heightContractPropX, heightContractPropY, heightContractPropZ, heightContractPropW;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        EditorGUILayout.LabelField("Vertex Color R(Layer1) G(null) B(Layer2) A(null)", EditorStyles.boldLabel);//标题
        EditorGUILayout.LabelField("先填充蓝色显示map2，再刷红色部分显示map1", EditorStyles.boldLabel);
        // baseColorProp = FindProperty("_BaseColor", properties);
        // materialEditor.ColorProperty(baseColorProp, "Base Color");

        EditorGUILayout.Space(10);//间隔10像素 

        //获取初始值
        heightContractProp = FindProperty("_HeightContract", properties);
        heightContractPropX = heightContractProp.vectorValue.x;
        heightContractPropY = heightContractProp.vectorValue.y;
        heightContractPropZ = heightContractProp.vectorValue.z;
        heightContractPropW = heightContractProp.vectorValue.w;
        heightContractPropX = EditorGUILayout.Slider("Layer1 HeightContract", heightContractPropX, -1, 1);
        heightContractPropY = EditorGUILayout.Slider("Layer2 HeightContract", heightContractPropY, -1, 1);
        heightContractPropZ = EditorGUILayout.Slider("Global Contract", heightContractPropZ, 0.01f, 2);
        // heightContractPropW = EditorGUILayout.Slider("null", heightContractPropW, -1, 1);
        //重新把改写的值组装成一个四维向量
        Vector4 _newVector1 = new Vector4(heightContractPropX, heightContractPropY, heightContractPropZ, heightContractPropW);
        heightContractProp.vectorValue = _newVector1;

        EditorGUILayout.Space(10);//间隔10像素 
        EditorGUILayout.LabelField("Vertex Color R(Layer1) G(null) B(Layer2) A(null)", EditorStyles.boldLabel);//标题
        layer1MapProp = FindProperty("_Layer1Map", properties);
        materialEditor.TextureProperty(layer1MapProp, "Map1 RGB(color) A(height)");
        layer2MapProp = FindProperty("_Layer2Map", properties);
        materialEditor.TextureProperty(layer2MapProp, "Map2 RGB(color) A(null)");
        
        EditorGUILayout.Space(10);//间隔10像素 
        EditorGUILayout.LabelField("_OCCLUSION_FADE", EditorStyles.boldLabel);
        occlusionFadeProp = FindProperty("_OCCLUSION_FADE", properties);
        materialEditor.ShaderProperty(occlusionFadeProp, "_OCCLUSION_FADE");
        distanceScaleProp = FindProperty("_DistanceScale", properties);
        materialEditor.FloatProperty(distanceScaleProp, "Distance Scale");
        distanceSensitivityProp = FindProperty("_DistanceSensitivity", properties);
        materialEditor.FloatProperty(distanceSensitivityProp, "Distance Sensitivity");

        materialEditor.RenderQueueField();

    }
}

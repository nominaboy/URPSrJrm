using System.Collections;
using System.Collections.Generic;
using System.IO;
using Unity.Plastic.Newtonsoft.Json;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class LoadJsonMesh : EditorWindow {

    [MenuItem("Window/Mesh Loader")]
    public static void ShowWindow() {
        // 打开或聚焦该窗口
        GetWindow<LoadJsonMesh>("Mesh Loader");
    }

    // OnGUI 绘制窗口内容
    private void OnGUI() {
        GUILayout.Label("Mesh Loader", EditorStyles.boldLabel);

        // 创建按钮，点击时调用 LoadJsonMeshes 方法
        if (GUILayout.Button("Load Meshes From JSON")) {
            LoadJsonMeshes();
        }
    }




    private GameObject LoadJsonMeshes() {
            string jsonContent = File.ReadAllText("C:\\FYProgram\\UnityProjects\\URPSampleRoom_Jeremy\\Assets\\ProceduralSkybox\\MingChao\\MCCloud\\MCCloudMeshJson.json");
            Dictionary<string, float[][]> jsonDict = JsonConvert.DeserializeObject<Dictionary<string, float[][]>>(jsonContent);

            float[][] idx = jsonDict["IDX"];
            int length = idx.Length;
            int[] newTriangles = new int[length];

            int maxVID = 0;
            for (int i = 0; i < length; i++) {
                newTriangles[i] = (int)jsonDict["IDX"][i][0];
                int vID = newTriangles[i];
                if (vID > maxVID)
                    maxVID = vID;
            }

            Vector3[] newVertices = new Vector3[maxVID + 1];
            Vector3[] newNormals = new Vector3[maxVID + 1];
            Vector4[] newTangents = new Vector4[maxVID + 1];
            Color[] newColors = new Color[maxVID + 1];
            Vector2[] newUV0s = new Vector2[maxVID + 1];
            Vector2[] newUV1s = new Vector2[maxVID + 1];
            Vector2[] newUV2s = new Vector2[maxVID + 1];
            Vector2[] newUV3s = new Vector2[maxVID + 1];
            Vector2[] newUV4s = new Vector2[maxVID + 1];
            Vector2[] newUV5s = new Vector2[maxVID + 1];
            for (int i = 0; i < length; i++) {
                int vID = newTriangles[i];
                newVertices[vID] = new Vector3(jsonDict["POSITION"][i][0], jsonDict["POSITION"][i][1], jsonDict["POSITION"][i][2]);
                newNormals[vID] = new Vector4(jsonDict["NORMAL"][i][0], jsonDict["NORMAL"][i][1], jsonDict["NORMAL"][i][2]);
                newTangents[vID] = new Vector4(jsonDict["TANGENT"][i][0], jsonDict["TANGENT"][i][1], jsonDict["TANGENT"][i][2], jsonDict["TANGENT"][i][3]);
                newUV0s[vID] = new Vector2(jsonDict["TEXCOORD0"][i][0], 1.0f - jsonDict["TEXCOORD0"][i][1]);
                newUV1s[vID] = new Vector2(jsonDict["TEXCOORD0"][i][2], 1.0f - jsonDict["TEXCOORD0"][i][3]);

                //if (jsonDict.ContainsKey("COLOR"))
                //    newColors[vID] = new Color(jsonDict["COLOR"][i][0], jsonDict["COLOR"][i][1], jsonDict["COLOR"][i][2], jsonDict["COLOR"][i][3]);
                //if (jsonDict.ContainsKey("TEXCOORD2"))
                //    newUV2s[vID] = new Vector2(jsonDict["TEXCOORD2"][i][0], 1.0f - jsonDict["TEXCOORD2"][i][1]);
                //if (jsonDict.ContainsKey("TEXCOORD3"))
                //    newUV3s[vID] = new Vector2(jsonDict["TEXCOORD3"][i][0], 1.0f - jsonDict["TEXCOORD3"][i][1]);
                //if (jsonDict.ContainsKey("TEXCOORD4")) {
                //    newUV4s[vID] = new Vector3(jsonDict["TEXCOORD4"][i][0], jsonDict["TEXCOORD4"][i][1]);
                //    newUV5s[vID] = new Vector3(jsonDict["TEXCOORD4"][i][1], 0);
                //}

                //Debug.Log($"{i} Normal {vID} = {newNormals[vID]}");
            }

            Mesh newMesh = new Mesh();
            newMesh.vertices = newVertices;
            newMesh.normals = newNormals;
            newMesh.tangents = newTangents;
            newMesh.uv = newUV0s;
            newMesh.uv2 = newUV1s;
            //if (jsonDict.ContainsKey("COLOR"))
            //    newMesh.colors = newColors;
            //if (jsonDict.ContainsKey("TEXCOORD2"))
            //    newMesh.uv3 = newUV2s;
            //if (jsonDict.ContainsKey("TEXCOORD3"))
            //    newMesh.uv4 = newUV3s;
            //if (jsonDict.ContainsKey("TEXCOORD4")) {
            //    newMesh.uv5 = newUV4s;
            //    newMesh.uv6 = newUV5s;
            //}

            newMesh.triangles = newTriangles;
            string assetPath = "Assets\\Test";
            //assetPath = assetPath.Substring(0, assetPath.Length - 5);
            AssetDatabase.CreateAsset(newMesh, assetPath + ".asset");

            GameObject go = new GameObject();
            MeshFilter newMeshFilter = go.AddComponent<MeshFilter>();
            newMeshFilter.sharedMesh = newMesh;

            //MeshRenderer newRenderer = go.AddComponent<MeshRenderer>();
            //var pipelineAsset = GraphicsSettings.currentRenderPipeline;
            //if (!pipelineAsset || pipelineAsset.GetType() != typeof(HybridRenderPipelineAsset))
            //    return go;
            //Material defaultModelMaterial = (pipelineAsset as HybridRenderPipelineAsset).defaultMaterial;
            //newRenderer.sharedMaterial = defaultModelMaterial;
            return go;
        
    }
}

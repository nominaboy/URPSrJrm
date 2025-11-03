using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.UIElements;

namespace CatVFX
{
    public class ParticleGUI : ShaderGUI
    {
        private MaterialEditor materialEditor;
        private MaterialProperty[] properties;
        public GUIStyle customStyle;
        private enum DissolveType
        {
            _DISSOLVE_OFF,
            _DISSOLVE_SUB,
            _DISSOLVE_POW,
            _DISSOLVE_SMOOTH,
            _DISSOLVE_EDGE_RADIAL,
            _DISSOLVE_EDGE
        };
        private enum MaskType
        {
            _MASK_OFF,
            _MASK_SINGLE,
            _MASK_DOUBLE
        };
        private Dictionary<string, List<string>> propertieReference = new Dictionary<string, List<string>> {
        { "_DISTORTION", new List<string> { "_NoiseTex1", "_NoiseTex2", "_StrengthX", "_StrengthY"} },
        { "_MASK_OFF", new List<string> {} },
        { "_MASK_SINGLE", new List<string> { "_MaskTex1"} },
        { "_MASK_DOUBLE", new List<string> { "_MaskTex1", "_MaskTex2"} },
        { "_DISSOLVE_OFF", new List<string> {} },
        { "_DISSOLVE_SUB", new List<string> { "_NoiseTex1", "_Pow", "_Dissolve" } },
        { "_DISSOLVE_POW", new List<string> { "_NoiseTex1", "_Pow", "_Dissolve" } },
        { "_DISSOLVE_SMOOTH", new List<string> { "_NoiseTex1", "_Smooth", "_Dissolve" } },
        { "_DISSOLVE_EDGE_RADIAL", new List<string> { "_NoiseTex1", "_EdgeColor", "_EdgeWidth", "_Path", "_Dissolve" } },
        { "_DISSOLVE_EDGE", new List<string> { "_NoiseTex1", "_EdgeColor", "_EdgeWidth", "_Dissolve" } },
        { "_OUTSIDE_COLOR", new List<string> {"_MainTex", "_OutSideColor"} },
        { "_VERTEX_OFFSET", new List<string> {"_VertexTex", "_VertexMaskTex", "_VertexScale"} },
        { "_FLOOR_SMOOTH", new List<string> {"_FloorSmooth" } },
    };
        bool UseCustomData()
        {
            MaterialProperty prop = FindProperty("_CUSTOM_DATA", properties);
            return prop.floatValue != 0;
        }
        MaterialProperty ShaderProperty(string name)
        {
            MaterialProperty prop = FindProperty(name, properties);
            materialEditor.ShaderProperty(prop, UseCustomData() ? prop.displayName : name);
            return prop;
        }
        MaterialProperty FindProperty(string name)
        {
            return FindProperty(name, properties);
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
                if (key.StartsWith("_DISSOLVE"))
                {
                    List<string> value = pair.Value;
                    DissolveType type = (DissolveType)Enum.Parse(typeof(DissolveType), key);
                    if (FindProperty("_DISSOLVE", properties).floatValue == (int)type)
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
                else if (key.StartsWith("_MASK"))
                {
                    List<string> value = pair.Value;
                    MaskType type = (MaskType)Enum.Parse(typeof(MaskType), key);
                    if (FindProperty("_MASK", properties).floatValue == (int)type)
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
                    if (FindProperty(key, properties).floatValue == 1)
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
        void TexSpeedProperty(string texName)
        {
            ShaderProperty(texName + "SpeedX");
            ShaderProperty(texName + "SpeedY");
        }
        void PropertyField(string key)
        {
            var _PROPERTY = ShaderProperty(key);
            if (_PROPERTY.floatValue == 1)
            {
                var texList = propertieReference[key].Where(item => !item.Contains("Tex")).ToList();
                foreach (var propertieName in texList)
                {
                    ShaderProperty(propertieName);
                }
                var propList = propertieReference[key].Where(item => item.Contains("Tex")).ToList();
                if (propList.Count != 0)
                {
                    EditorGUILayout.HelpBox(string.Join(",", propList), MessageType.Info);
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
                    var texList = propertieReference[value.ToString()].Where(item => !item.Contains("Tex")).ToList();
                    foreach (var propertieName in texList)
                    {
                        ShaderProperty(propertieName);
                    }
                    var propList = propertieReference[value.ToString()].Where(item => item.Contains("Tex")).ToList();
                    if (propList.Count != 0)
                    {
                        EditorGUILayout.HelpBox(string.Join(",", propList), MessageType.Info);
                    }
                }
            }
        }

        public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
        {
            material.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
            material.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            base.AssignNewShaderToMaterial(material, oldShader, newShader);
        }
        void SetupParticleSystem()
        {
            GameObject selectedObject = Selection.activeGameObject;
            if (selectedObject != null)
            {
                ParticleSystem[] particleSystems = selectedObject.GetComponentsInChildren<ParticleSystem>();
                if (particleSystems.Length == 0)
                {
                    EditorGUILayout.HelpBox("_CUSTOM_DATA can only be used for particle systems", MessageType.Error);
                }
                foreach (ParticleSystem ps in particleSystems)
                {
                    if (ps.GetComponent<ParticleSystemRenderer>().sharedMaterial == materialEditor.target as Material)
                    {
                        ParticleSystemRenderer particleRenderer = ps.GetComponent<ParticleSystemRenderer>();
                        List<ParticleSystemVertexStream> streams = new List<ParticleSystemVertexStream>();
                        particleRenderer.GetActiveVertexStreams(streams);
                        bool check = true;
                        if (streams.Count == 4)
                        {
                            if (streams[0] != ParticleSystemVertexStream.Position)
                            {
                                check = false;
                            }
                            if (streams[1] != ParticleSystemVertexStream.Color)
                            {
                                check = false;
                            }
                            if (streams[2] != ParticleSystemVertexStream.UV)
                            {
                                check = false;
                            }
                            if (streams[3] != ParticleSystemVertexStream.Custom1XYZW)
                            {
                                check = false;
                            }
                        }
                        else
                        {
                            check = false;
                        }
                        if (!check)
                        {
                            EditorGUILayout.HelpBox("Fix particle vertex streams?", MessageType.Error);
                            if (GUILayout.Button("Fix"))
                            {
                                streams.Clear();
                                streams.Add(ParticleSystemVertexStream.Position);
                                streams.Add(ParticleSystemVertexStream.Color);
                                streams.Add(ParticleSystemVertexStream.UV);
                                streams.Add(ParticleSystemVertexStream.Custom1XYZW);
                                particleRenderer.SetActiveVertexStreams(streams);
                            }
                        }
                    }
                }
            }
        }
        private Texture2D MakeTex(int width, int height, Color color)
        {
            Color[] pix = new Color[width * height];
            for (int i = 0; i < pix.Length; ++i)
            {
                pix[i] = color;
            }
            Texture2D result = new Texture2D(width, height);
            result.SetPixels(pix);
            result.Apply();
            return result;
        }
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            // base.OnGUI (materialEditor, properties);

            this.materialEditor = materialEditor;
            this.properties = properties;
            customStyle = new GUIStyle("GroupBox");
            customStyle.normal.background = MakeTex(2, 2, new Color(0.16f, 0.32f, 0.64f, 0.32f));

            GroupBox(() =>
            {
                ShaderProperty("_MainTex");
                if (UseCustomData())
                {
                    // EditorGUILayout.HelpBox("Offset X(Custom1.y),Offset Y(Custom1.z)", MessageType.None);
                }
                if (IsReferenced("_NoiseTex1"))
                {
                    ShaderProperty("_NoiseTex1");
                }
                if (IsReferenced("_NoiseTex2"))
                {
                    ShaderProperty("_NoiseTex2");
                }
                if (IsReferenced("_MaskTex1"))
                {
                    ShaderProperty("_MaskTex1");
                }
                if (IsReferenced("_MaskTex2"))
                {
                    ShaderProperty("_MaskTex2");
                }
                if (IsReferenced("_VertexTex"))
                {
                    ShaderProperty("_VertexTex");
                }
                if (IsReferenced("_VertexMaskTex"))
                {
                    ShaderProperty("_VertexMaskTex");
                }
            });
            GroupBox(() =>
            {
                ShaderProperty("_MainColor");
            });
            GroupBox(() =>
            {
                if (UseCustomData())
                {
                    SetupParticleSystem();
                }
                ShaderProperty("_CUSTOM_DATA");
            });
            GroupBox(() =>
            {
                PropertyField("_OUTSIDE_COLOR");
            });
            GroupBox(() =>
            {
                PropertyField("_DISTORTION");
            });
            GroupBox(() =>
            {
                PropertyField<DissolveType>();
            });
            GroupBox(() =>
            {
                PropertyField<MaskType>();
            });
            GroupBox(() =>
            {
                PropertyField("_FLOOR_SMOOTH");
            });
            GroupBox(() =>
            {
                PropertyField("_VERTEX_OFFSET");

            });
            GroupBox(() =>
            {
                TexSpeedProperty("_MainTex");
                if (IsReferenced("_NoiseTex1"))
                {
                    TexSpeedProperty("_NoiseTex1");
                }
                if (IsReferenced("_NoiseTex2"))
                {
                    TexSpeedProperty("_NoiseTex2");
                }
                if (IsReferenced("_MaskTex1"))
                {
                    TexSpeedProperty("_MaskTex1");
                }
                if (IsReferenced("_MaskTex2"))
                {
                    TexSpeedProperty("_MaskTex2");
                }
                if (IsReferenced("_VertexTex"))
                {
                    TexSpeedProperty("_VertexTex");
                }
                if (IsReferenced("_VertexMaskTex"))
                {
                    TexSpeedProperty("_VertexMaskTex");
                }
            });
            GroupBox(() =>
            {
                ShaderProperty("_SrcBlend");
                ShaderProperty("_DstBlend");
                ShaderProperty("_ZWrite");
                ShaderProperty("_Cull");
                ShaderProperty("_ZTest");
                materialEditor.RenderQueueField();
            });
        }
    }

}
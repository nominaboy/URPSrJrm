using System.IO;
using UnityEditor;
using UnityEngine;

public class SDFSampler : EditorWindow
{
    [MenuItem("Tools/SDFSampler")]
    public static void Open()
    {
        GetWindow<SDFSampler>().Show();
    }

    private Texture2D inputTex;
    private Texture2D outputTex;

    private string savePath;
    private int size = 128;

    private void OnGUI()
    {
        inputTex = EditorGUILayout.ObjectField("Input Tex", inputTex, typeof(Texture2D), false) as Texture2D;
        outputTex = EditorGUILayout.ObjectField("Output Tex", outputTex, typeof(Texture2D), false) as Texture2D;

        size = (int)EditorGUILayout.Slider("Size", size, 0, 2048);

        if (GUILayout.Button("Choose Save Path"))
        {
            savePath = EditorUtility.SaveFilePanel(
            "Save Output Texture",
            "",
            "sdfOutput.png",
            "png");
        }
            

        if (inputTex != null)
        {
            if (GUILayout.Button("GenerateSDF"))
            {
                if (outputTex == null)
                {
                    outputTex = new Texture2D(size, size, TextureFormat.RFloat, false);
                }

                GenerateSDF(inputTex, outputTex);

                //AssetDatabase.CreateAsset(outputTex, savePath);
                //AssetDatabase.SaveAssets();

                byte[] bytes = outputTex.EncodeToPNG();
                DestroyImmediate(outputTex);
                if (!string.IsNullOrEmpty(savePath))
                {
                    File.WriteAllBytes(savePath, bytes);
                    Debug.Log($"Screenshot saved to: {savePath}");
                }
            }
        }
    }

    private struct Pixel
    {
        public bool isIn;
        public float distance;
    }

    public static void GenerateSDF(Texture2D source, Texture2D destination)
    {
        int sourceWidth = source.width;
        int sourceHeight = source.height;
        int targetWidth = destination.width;
        int targetHeight = destination.height;

        var pixels = new Pixel[sourceWidth, sourceHeight];
        var targetPixels = new Pixel[targetWidth, targetHeight];
        Debug.Log("sourceWidth" + sourceWidth);
        Debug.Log("sourceHeight" + sourceHeight);
        int x, y;
        Color targetColor = Color.white;
        for (x = 0; x < sourceWidth; x++)
        {
            for (y = 0; y < sourceHeight; y++)
            {
                pixels[x, y] = new Pixel();
                // 内白外黑，注意SDF也可内黑外白
                if (source.GetPixel(x, y) == Color.white)
                    pixels[x, y].isIn = true;
                else
                    pixels[x, y].isIn = false;
            }
        }


        int gapX = sourceWidth / targetWidth;
        int gapY = sourceHeight / targetHeight;
        int MAX_SEARCH_DIST = 512;
        int minx, maxx, miny, maxy;
        float max_distance = -MAX_SEARCH_DIST;
        float min_distance = MAX_SEARCH_DIST;
        // SDF内正外负
        for (x = 0; x < targetWidth; x++)
        {
            for (y = 0; y < targetHeight; y++)
            {
                targetPixels[x, y] = new Pixel();
                int sourceX = x * gapX;
                int sourceY = y * gapY;
                int min = MAX_SEARCH_DIST;
                // for循环起点终点
                minx = sourceX - MAX_SEARCH_DIST;
                if (minx < 0)
                {
                    minx = 0;
                }
                miny = sourceY - MAX_SEARCH_DIST;
                if (miny < 0)
                {
                    miny = 0;
                }
                maxx = sourceX + MAX_SEARCH_DIST;
                if (maxx > (int)sourceWidth)
                {
                    maxx = sourceWidth;
                }
                maxy = sourceY + MAX_SEARCH_DIST;
                if (maxy > (int)sourceHeight)
                {
                    maxy = sourceHeight;
                }
                int dx, dy, iy, ix, distance;
                bool sourceIsInside = pixels[sourceX, sourceY].isIn;
                if (sourceIsInside)
                {
                    for (iy = miny; iy < maxy; iy++)
                    {
                        // 循环外部算掉Y距离
                        dy = iy - sourceY;
                        dy *= dy;
                        for (ix = minx; ix < maxx; ix++)
                        {
                            bool targetIsInside = pixels[ix, iy].isIn;
                            if (targetIsInside)
                            {
                                // 两者都in则跳过
                                continue;
                            }
                            dx = ix - sourceX;
                            distance = (int)Mathf.Sqrt(dx * dx + dy);
                            if (distance < min)
                            {
                                min = distance;
                            }
                        }
                    }

                    // 储存in的所有像素sdf最大值，作为上限
                    if (min > max_distance)
                    {
                        max_distance = min;
                    }
                    targetPixels[x, y].distance = min;
                }
                else
                {
                    for (iy = miny; iy < maxy; iy++)
                    {
                        dy = iy - sourceY;
                        dy *= dy;
                        for (ix = minx; ix < maxx; ix++)
                        {
                            bool targetIsInside = pixels[ix, iy].isIn;
                            if (!targetIsInside)
                            {
                                continue;
                            }
                            dx = ix - sourceX;
                            distance = (int)Mathf.Sqrt(dx * dx + dy);
                            if (distance < min)
                            {
                                min = distance;
                            }
                        }
                    }

                    // 储存out的所有像素sdf最小值（负数），作为下限
                    if (-min < min_distance)
                    {
                        min_distance = -min;
                    }
                    // out sdf为负值
                    targetPixels[x, y].distance = -min;
                }
            }
        }

        float clampDist = max_distance - min_distance;
        // [min_distance, max_distance]映射到[0, 1]
        for (x = 0; x < targetWidth; x++)
        {
            for (y = 0; y < targetHeight; y++)
            {
                targetPixels[x, y].distance -= min_distance;
                float value = targetPixels[x, y].distance / clampDist;
                destination.SetPixel(x, y, new Color(value, 1, 1, 1));
            }
        }

        destination.Apply();
    }
}
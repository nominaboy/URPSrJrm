/*****************************************************************
    作者：Jeremy
    功能：预计算PBR LUT
*****************************************************************/
using System;
using UnityEngine;

[ExecuteInEditMode]
public class PBRLUTPrecom : MonoBehaviour {
    public bool m_generateAllLUT = false;
    public Cubemap originalCM;
    public ComputeShader PBRComputeShader;
    public RenderTexture PBRCubemapLUT;
    public RenderTexture PBRBrdfLUT;

    private Vector2 m_PBRBrdfLUTSize;
    private Vector2 m_PBRCubemapLUTSize;
    private int m_MipMaxLevel;
    private void Start() {
        m_generateAllLUT = true;
        UpdateShaderCoePerFrame();
        InitAllLut();
    }
    private void Update() {
        UpdateShaderCoePerFrame();
        InitAllLut();
    }

    private void InitAllLut() {
        if (m_generateAllLUT) {
        
            if (PBRCubemapLUT != null && PBRBrdfLUT != null) {
                ReleaseALLLut();
            }

            CreateSpecBrdfLUT((int)m_PBRBrdfLUTSize.x, (int)m_PBRBrdfLUTSize.y);
            SetupSpecBrdfLUT((int)m_PBRBrdfLUTSize.x, (int)m_PBRBrdfLUTSize.y);
            CreateSpecCubemapLUT((int)m_PBRCubemapLUTSize.x, (int)m_PBRCubemapLUTSize.y);
            int width = (int)m_PBRCubemapLUTSize.x;
            int height = (int)m_PBRCubemapLUTSize.y;
            for (int i = 0; i <= m_MipMaxLevel; i++) {
                SetupSpecCubemapLUT(width, height, i);
                width /= 2;
                height /= 2;
            }
            m_generateAllLUT = false;
        }
        if (PBRCubemapLUT != null) {
            Shader.SetGlobalTexture("_PBREnvironmentMap", PBRCubemapLUT);
        }
        if (PBRBrdfLUT != null) {
            Shader.SetGlobalTexture("_PBRBrdfLUTMap", PBRBrdfLUT);
        }
    }

    #region cubemap LUT
    // 创建RT for specular IBL cubemap LUT
    private void CreateSpecCubemapLUT(int width, int height) {
        PBRCubemapLUT = new RenderTexture(width, height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);
        PBRCubemapLUT.useMipMap = true;
        PBRCubemapLUT.filterMode = FilterMode.Trilinear;
        PBRCubemapLUT.enableRandomWrite = true;
        PBRCubemapLUT.name = "PBRCubemapLUT";
        PBRCubemapLUT.Create();
    }

    // 初始化设置specular IBL cubemap LUT
    private void SetupSpecCubemapLUT(int width, int height, int index) {
        int kernel = PBRComputeShader.FindKernel("PBRCubemapLUT");
        PBRComputeShader.SetTexture(kernel, "_PBRCubemapLUT", PBRCubemapLUT, index);
        PBRComputeShader.SetInt("_mipMapLevel", index);
        PBRComputeShader.GetKernelThreadGroupSizes(kernel, out uint tempX, out uint tempY, out uint tempZ);
        PBRComputeShader.Dispatch(kernel, width / (int)tempX, height / (int)tempY, 1);
    }
    #endregion

    #region BRDF LUT
    // 创建RT for specular IBL BRDF LUT
    private void CreateSpecBrdfLUT(int width, int height) {
        PBRBrdfLUT = new RenderTexture(width, height, 0, RenderTextureFormat.RGFloat, RenderTextureReadWrite.Linear);
        PBRBrdfLUT.filterMode = FilterMode.Bilinear;
        PBRBrdfLUT.useMipMap = false;
        PBRBrdfLUT.enableRandomWrite = true;
        PBRBrdfLUT.name = "PBRBrdfLUT";
        PBRBrdfLUT.Create();
    }
    // 初始化设置specular IBL BRDF LUT
    private void SetupSpecBrdfLUT(int width, int height) {
        int kernel = PBRComputeShader.FindKernel("PBRBrdfLUT");
        PBRComputeShader.SetTexture(kernel, "_PBRBrdfLUT", PBRBrdfLUT);
        PBRComputeShader.GetKernelThreadGroupSizes(kernel, out uint tempX, out uint tempY, out uint tempZ);
        PBRComputeShader.Dispatch(kernel, width / (int)tempX, height / (int)tempY, 1);
    }
    #endregion

    private void ReleaseALLLut() {
        PBRCubemapLUT.Release();
        DestroyImmediate(PBRCubemapLUT);
        PBRBrdfLUT.Release();
        DestroyImmediate(PBRBrdfLUT);
    }

    private void UpdateShaderCoePerFrame() {
        m_PBRBrdfLUTSize = Vector2.one * 512;
        m_PBRCubemapLUTSize = new Vector2(512, 256);
        m_MipMaxLevel = 4;
        Shader.SetGlobalInteger("_mipMapMaxLevel", m_MipMaxLevel);
        Shader.SetGlobalTexture("_EnvironmentMap", originalCM);
    }
}

// 顶点着色器
Shader "Jeremy/TestVolumetricLight"
{
    Properties
    {
        _StartAngle("Start Angle", Float) = 0.0
        _EndAngle("End Angle", Float) = 1.0
        _NoiseMap("Noise Map", 2D) = "white" {}
        _NoiseSpeed("Noise Speed", Float) = 1.0
        _LightColor("Light Color", Color) = (1, 1, 1, 1)
        _LightIntensity("Light Intensity", Float) = 1.0
        _F_Power("Fresnel Power", Float) = 1.0
        _F_Scale("Fresnel Scale", Float) = 1.0
        _F_Bias("Fresnel Bias", Float) = 0.0
        _FadePower("Fade Power", Float) = 1.0
        _FadeOffset("Fade Offset", Float) = 0.0
    }
    SubShader
    {

		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent" "IsEmissive" = "true"  }
        Cull [_CullMode]
		ZWrite Off
		Blend SrcAlpha One

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            // 顶点输入结构体
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            // 片段输入结构体
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            // Uniform 参数
            float _StartAngle;
            float _EndAngle;

            // 顶点着色器
            v2f vert(appdata v)
            {
                v2f o;

                // 获取法线和纹理坐标
                float3 ase_vertexNormal = normalize(v.normal);
                
                // 根据法线和纹理坐标计算顶点偏移
                float3 VertexOffset40 = (ase_vertexNormal * v.uv.x * _EndAngle) + (ase_vertexNormal * (1.0 - v.uv.x) * _StartAngle);

                // 顶点位置增加偏移
                v.vertex.xyz += VertexOffset40;

                // 将顶点位置转换为裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                
                // 传递法线、纹理坐标和视角方向到片段着色器
                o.worldNormal = mul((float3x3)unity_ObjectToWorld, ase_vertexNormal);
                o.uv = v.uv;
                o.viewDir = normalize(WorldSpaceViewDir(v.vertex));

                return o;
            }

                        // Uniform 参数
            sampler2D _NoiseMap;
            float4 _NoiseMap_ST;
            float _NoiseSpeed;
            float4 _LightColor;
            float _LightIntensity;
            float _F_Power;
            float _F_Scale;
            float _F_Bias;
            float _FadePower;
            float _FadeOffset;

            // 片段着色器
            half4 frag(v2f i) : SV_Target
            {
                // 计算UV偏移
                float2 uv0_NoiseMap = i.uv * _NoiseMap_ST.xy + _NoiseMap_ST.zw;
                float2 panner23 = (1.0 * _Time.y * _NoiseSpeed + uv0_NoiseMap);

                // 计算发光效果
                half3 emission = (_LightColor.rgb * _LightIntensity * tex2D(_NoiseMap, panner23).r);

                // 计算Fresnel效应
                float dotResult6 = dot(i.worldNormal, i.viewDir);
                float Fresnel17 = saturate(pow(abs(dotResult6), _F_Power) * _F_Scale + _F_Bias);

                // 计算透明度
                float alpha = Fresnel17 * pow(1.0 - i.uv.x - _FadeOffset, _FadePower);

                return half4(emission, alpha);
            }

            ENDCG
        }
    }
}


Shader "Custom/BoatShader"
{
    Properties
    {
        _WaveSpeed ("Wave Speed", Range(0,10)) = 1
        _WaveHeight ("Wave Height", Range(0,1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : NORMAL;
            };

            float _WaveSpeed;
            float _WaveHeight;

            v2f vert (appdata v)
            {
                v2f o;
                float wave = sin(v.vertex.x * 0.1 + _Time.y * _WaveSpeed) * _WaveHeight;
                v.vertex.y += wave;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldPos = v.vertex.xyz;
                o.normal = v.normal;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                return half4(1.0, 1.0, 1.0, 1.0); // 白色
            }
            ENDCG
        }
    }
}

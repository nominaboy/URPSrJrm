Shader "Custom/Brush"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _BrushSize ("Brush Size", Range(0.01, 10.0)) = 1.0
        _BrushSoftness ("Brush Softness", Range(0.01, 1.0)) = 0.5
        _BrushColor ("Brush Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {"Queue"="Overlay"}
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            float _BrushSize;
            float _BrushSoftness;
            float4 _BrushColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Simple circular brush with falloff based on softness
                float2 uv = (i.pos.xy / i.pos.w) * 0.5 + 0.5;
                float dist = length(uv - float2(0.5, 0.5));
                float alpha = smoothstep(_BrushSize * (1.0 - _BrushSoftness), _BrushSize, dist);
                return _BrushColor * (1.0 - alpha);
            }
            ENDCG
        }
    }
}

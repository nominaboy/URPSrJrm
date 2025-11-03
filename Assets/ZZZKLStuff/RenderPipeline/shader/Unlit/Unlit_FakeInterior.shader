Shader "Jeremy/Unlit/Unlit_FakeInterior"
{
    Properties
    {
        _RoomAtlas("Room Atlas", 2D) = "white"{}
        _RoomsRowsCols("Rooms Rows Cols", Vector) = (1,1,0,0)
        _RoomDepth("Room Depth", Range(0.001, 0.999)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"  "Queue"="Geometry" }
        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "../Utils/KLUtils.hlsl"
            CBUFFER_START(UnityPerMaterial)
                float4 _RoomAtlas_ST;
                float2 _RoomsRowsCols;
                float _RoomDepth;
            CBUFFER_END
            TEXTURE2D(_RoomAtlas);SAMPLER(sampler_RoomAtlas);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };
            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float3 viewDirTS : VAR_VIEWDIRTS;
            };

            Varyings vert (Attributes i)
            {
                Varyings o = (Varyings) 0;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.uv = TRANSFORM_TEX(i.uv, _RoomAtlas);

                float3 viewPosOS = TransformWorldToObject(_WorldSpaceCameraPos.xyz);
                float3 viewDirOS = i.positionOS.xyz - viewPosOS;
                float crossSign = (i.tangentOS.w > 0.0 ? 1.0 : -1.0) * GetOddNegativeScale();
                float3 bitangent = crossSign * cross(i.normalOS.xyz, i.tangentOS.xyz);
                o.viewDirTS = float3(
                        dot(viewDirOS, i.tangentOS.xyz),
                        dot(viewDirOS, bitangent.xyz),
                        dot(viewDirOS, i.normalOS.xyz)
                    );
                o.viewDirTS *= _RoomAtlas_ST.xyx;
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                float2 roomUV = frac(i.uv);
                float2 roomIndexUV = floor(i.uv);

                float2 randomNum = floor(RandomNoise(roomIndexUV.x + roomIndexUV.y * (roomIndexUV.x + 1)) * _RoomsRowsCols.xy);
                roomIndexUV += randomNum;

                // get room depth from room atlas alpha
                // float roomDepth = tex2D(_RoomTex, (roomIndexUV + 0.5) / _Rooms).a;

                float roomDepth = _RoomDepth;
                float depthScale = 1.0 / max(1.0 - roomDepth, 0.001) - 1.0;

                // Ray Tracing
                float3 startPos = float3(roomUV * 2 - 1, -1);
                i.viewDirTS.z *= -depthScale;

                float3 invViewDir = 1.0 / i.viewDirTS.xyz;
                float3 tBundle = abs(invViewDir) - startPos * invViewDir;
                float tOut = min(min(tBundle.x, tBundle.y), tBundle.z);
                float3 endPos = startPos + tOut * i.viewDirTS.xyz;

                float realZ = saturate(endPos.z * 0.5 + 0.5) / depthScale + 1.0;
                float depthLerp = 1.0 - (1.0 / realZ);
                depthLerp *= (depthScale + 1.0);

                roomUV = endPos.xy * lerp(1.0, roomDepth, depthLerp);
                roomUV = roomUV * 0.5 + 0.5;

                half4 color = SAMPLE_TEXTURE2D(_RoomAtlas, sampler_RoomAtlas, (roomIndexUV + roomUV) / _RoomsRowsCols.xy);
                return color;
            }
            ENDHLSL
        }
    }
}

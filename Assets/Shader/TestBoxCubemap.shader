// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/TestBoxCubemap"
{
        Properties
        {
                _MainTex ("Base (RGB)", 2D) = "white" { }
                _Cube("Reflection Map", Cube) = "" {}
                _AmbientColor("Ambient Color", Color) = (1, 1, 1, 1)
                _ReflAmount("Reflection Amount", Float) = 0.5
        }
        SubShader
        {
                Pass
                {
                        CGPROGRAM
                        #pragma glsl
                        #pragma vertex vert
                        #pragma fragment frag
                        #include "UnityCG.cginc"
                        // User-specified uniforms
                        uniform sampler2D _MainTex;
                        uniform samplerCUBE _Cube;
                        uniform float4 _AmbientColor;
                        uniform float _ReflAmount;
                        uniform float _ToggleLocalCorrection;
                        // ----Passed from script InfoRoReflmaterial.cs --------
                        uniform float3 _BBoxMin;
                        uniform float3 _BBoxMax;
                        uniform float3 _EnviCubeMapPos;
                        struct vertexInput
                        {
                                float4 vertex : POSITION;
                                float3 normal : NORMAL;
                                float4 texcoord : TEXCOORD0;
                        };
                        struct vertexOutput
                        {
                                float4 pos : SV_POSITION;
                                float4 tex : TEXCOORD0;
                                float3 vertexInWorld : TEXCOORD1;
                                float3 viewDirInWorld : TEXCOORD2;
                                float3 normalInWorld : TEXCOORD3;
                        };
                        vertexOutput vert(vertexInput input)
                        {
                                vertexOutput output;
                                output.tex = input.texcoord;
                                // Transform vertex coordinates from local to world.
                                float4 vertexWorld = mul(unity_ObjectToWorld, input.vertex);
                                // Transform normal to world coordinates.
                                float4 normalWorld = mul(float4(input.normal,0.0), unity_WorldToObject);
                                // Final vertex output position. 
                                output.pos = UnityObjectToClipPos(input.vertex);
                                // ----------- Local correction ------------
                                output.vertexInWorld = vertexWorld.xyz;
                                output.viewDirInWorld = vertexWorld.xyz - _WorldSpaceCameraPos;
                                output.normalInWorld = normalWorld.xyz;
                                return output;
                        }
                        float4 frag(vertexOutput input) : COLOR
                        {
                                float4 reflColor = float4(1, 1, 0, 0);
                                // Find reflected vector in WS.
                                float3 viewDirWS = normalize(input.viewDirInWorld);
                                float3 normalWS = normalize(input.normalInWorld);
                                float3 reflDirWS = reflect(viewDirWS, normalWS);
                                // Working in World Coordinate System.
                                float3 localPosWS = input.vertexInWorld;
                                float3 intersectMaxPointPlanes = (_BBoxMax - localPosWS) / reflDirWS;
                                float3 intersectMinPointPlanes = (_BBoxMin - localPosWS) / reflDirWS;
                                // Looking only for intersections in the forward direction of the ray.
                                float3 largestParams = max(intersectMaxPointPlanes, intersectMinPointPlanes);
                                // Smallest value of the ray parameters gives us the intersection.
                                float distToIntersect = min(min(largestParams.x, largestParams.y), largestParams.z);
                                // Find the position of the intersection point.
                                float3 intersectPositionWS = localPosWS + reflDirWS * distToIntersect;
                                // Get local corrected reflection vector.
                                float3 localCorrReflDirWS = intersectPositionWS - _EnviCubeMapPos;
                                // Lookup the environment reflection texture with the right vector.
                                reflColor = texCUBE(_Cube, localCorrReflDirWS);
                                // Lookup the texture color.
                                float4 texColor = tex2D(_MainTex, input.tex);
                                return reflColor.xyzz;
                                return _AmbientColor + texColor * _ReflAmount * reflColor;
                        }
                        ENDCG
                }
        }
}
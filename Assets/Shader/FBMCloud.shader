Shader "Jeremy/FBMCloud" {
	Properties {
       
	}
    SubShader {
        Tags { 
            "RenderType" = "Transparent"
			"RenderPipeline" = "UniversalRenderPipeline" 
				"Queue"="Transparent" 
		}
   
		Pass {
			
			Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			//#pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			

			//uniform float cloudscale = 1.1;
			//uniform float speed = 1;
			//uniform float clouddark = 0.5;
			//uniform float cloudlight = 0.3;
			//uniform float cloudcover = 0.2;
			//uniform float cloudalpha = 8.0;
			//uniform float skytint = 0.5;
			//uniform float3 skycolour1 = float3(0.2, 0.4, 0.6);
			//uniform float3 skycolour2 = float3(0.4, 0.7, 1.0);
			//float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );

			float2 hash( float2 p ) {
				p = float2(dot(p,float2(127.1,311.7)), dot(p,float2(269.5,183.3)));
				return -1.0 + 2.0*frac(sin(p)*43758.5453123);
			}

			float noise( in float2 p ) {
				const float K1 = 0.366025404; // (sqrt(3)-1)/2;
				const float K2 = 0.211324865; // (3-sqrt(3))/6;
				float2 i = floor(p + (p.x+p.y)*K1);	
				float2 a = p - i + (i.x+i.y)*K2;
				float2 o = (a.x>a.y) ? float2(1.0,0.0) : float2(0.0,1.0); //float2 of = 0.5 + 0.5*float2(sign(a.x-a.y), sign(a.y-a.x));
				float2 b = a - o + K2;
				float2 c = a - 1.0 + 2.0*K2;
				float3 h = max(0.5-float3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
				float3 n = h*h*h*h*float3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
				return dot(n, (70.0).xxx);	
			}

			float fbm(float2 n) {
				float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );
				float total = 0.0, amplitude = 0.1;
				for (int i = 0; i < 7; i++) {
					total += noise(n) * amplitude;
					n = mul(m, n);
					amplitude *= 0.4;
				}
				return total;
			}








			struct Attributes {
				float4 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings {
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Varyings vert(Attributes i) {
				Varyings o;
				o.positionCS = TransformObjectToHClip(i.positionOS.xyz);

				o.uv = i.uv;
				return o;
			}

			float4 frag(Varyings i) : SV_Target {

				float speed = 0.03;
				float2x2 m = float2x2( 1.6,  1.2, -1.2,  1.6 );
                float cloudscale = 1.1;
				float clouddark = 0.5;
				float cloudlight = 0.3;
				float cloudcover = 0.2;
				float cloudalpha = 8.0;
				float skytint = 0.5;
				float3 skycolour1 = float3(0.2, 0.4, 0.6);
				float3 skycolour2 = float3(0.4, 0.7, 1.0);
				float2 screenUV = i.positionCS.xy / _ScaledScreenParams.xy;

				/**************************************************************/
				float2 p = i.positionCS.xy / _ScaledScreenParams.xy;
				float2 uv = p*float2(_ScaledScreenParams.x/_ScaledScreenParams.y,1.0);    
				float time = _Time.y * speed;
				float q = fbm(uv * cloudscale * 0.5);




				//ridged noise shape
				float r = 0.0;
				uv *= cloudscale;
				uv -= q - time;
				float weight = 0.8;
				for (int i=0; i<8; i++){
					r += abs(weight*noise( uv ));
					uv = mul(m, uv) + time;
					weight *= 0.7;
				}
    
				//noise shape
				float f = 0.0;
				uv = p*float2(_ScaledScreenParams.x/_ScaledScreenParams.y,1.0);
				uv *= cloudscale;
				uv -= q - time;
				weight = 0.7;
				for (int i=0; i<8; i++){
					f += weight*noise( uv );
					uv = mul(m, uv) + time;
					weight *= 0.6;
				}
    
				f *= r + f;
    
				//noise colour
				float c = 0.0;
				time = _Time.y * speed * 2.0;
				uv = p*float2(_ScaledScreenParams.x/_ScaledScreenParams.y,1.0);
				uv *= cloudscale*2.0;
				uv -= q - time;
				weight = 0.4;
				for (int i=0; i<7; i++){
					c += weight*noise( uv );
					uv = mul(m, uv) + time;
					weight *= 0.6;
				}
    
				//noise ridge colour
				float c1 = 0.0;
				time = _Time.y * speed * 3.0;
				uv = p*float2(_ScaledScreenParams.x/_ScaledScreenParams.y,1.0);
				uv *= cloudscale*3.0;
				uv -= q - time;
				weight = 0.4;
				for (int i=0; i<7; i++){
					c1 += abs(weight*noise( uv ));
					uv = mul(m, uv) + time;
					weight *= 0.6;
				}
	
				c += c1;
    
				float3 skycolour = lerp(skycolour2, skycolour1, p.y);
				skycolour = (0).xxx;
				float3 cloudcolour = float3(1.1, 1.1, 0.9) * clamp((clouddark + cloudlight*c), 0.0, 1.0);

   
				f = cloudcover + cloudalpha*f*r;
				//return float4(f.xxx, 1.0);
				//return float4(cloudcolour, 1.0);
				float3 result = lerp(skycolour, clamp(skytint * skycolour + cloudcolour, 0.0, 1.0), clamp(f + c, 0.0, 1.0));
				//fragColor = float4( result, 1.0 );
				/**************************************************************/

				/************************Test****************************/

				//float4 skycolour = (0).xxxx;
				//float3 cloudcolour = float3(1.1, 1.1, 0.9) * clamp((clouddark + cloudlight*c), 0.0, 1.0);
				




				/************************Test**********************************/



				//return (1).xxxx;
                return float4(result, 1.0);
			}
            ENDHLSL
        }
        
   
   
   }
}

Shader "JRMFOWCloud/FOWCompositeDXBC"
{
    VertexShader {
    
        class INPUT {
			v0 : POSITION;

		}
		class OUT {
			o0 : SV_POSITION;
		}
		void main(INPUT in) {
			r0.xyz = v0.yyy * cb1[1].xyz;
			r0.xyz = cb1[0].xyz*v0.xxx + r0.xyz;
			r0.xyz = cb1[2].xyz*v0.zzz + r0.xyz;
			r0.xyz = r0.xyz + cb1[3].xyz;
			r1.xyzw = r0.yyyy * cb0[77].xyzw;
			r1.xyzw = cb0[76].xyzw*r0.xxxx + r1.xyzw;
			r0.xyzw = cb0[78].xyzw*r0.zzzz + r1.xyzw;
			o0.xyzw = r0.xyzw + cb0[79].xyzw;
			return;
		}
    
    }


	/*****************************************************************************************/
	/*****************************************************************************************/
	/*****************************************************************************************/



	FragmentShader {
		class INPUT {
			v0 : SV_POSITION
		}
		class OUT {
		}
		void main(INPUT in) {
			r0.xyzw = v0.xyxy + float4(1.0, 1.0, -1.0, 1.0);
			// cb0_v4 1920.00, 1080.00, 1.00052, 1.00093     _ScreenParams
			r1.xyzw = float4(1.0, 1.0, 1.0, 1.0)/cb0[4].xyxy;
			r0.xyzw = r0.xyzw * r1.xyzw;
			r2.xyzw = tex2D(t0, r0.zw).xyzw //sample_state s0;
			r0.xyzw = tex2D(t0, r0.xy).xyzw //sample_state s0;
			r2.xyz = r2.www * r2.xyz;
			r0.xyz = r0.xyz*r0.www + r2.xyz;
			r3.xyzw = v0.xyxy + float4(1.0, -1.0, -1.0, -1.0);
			r3.xyzw = r1.xyzw * r3.xyzw;
			r1.xy = r1.zw * v0.xy;
			r1.xyzw = tex2D(t0, r1.xy).xyzw //sample_state s0;
			r4.xyzw = tex2D(t0, r3.xy).xyzw //sample_state s0;
			r3.xyzw = tex2D(t0, r3.zw).xyzw //sample_state s0;
			r0.xyz = r4.xyz*r4.www + r0.xyz;
			r0.xyz = r3.xyz*r3.www + r0.xyz;
			r2.x = r2.w + r0.w;
			r0.w = max(r2.w, r0.w);
			r2.x = r4.w + r2.x;
			r2.y = max(r3.w, r4.w);
			r2.x = r3.w + r2.x;
			r0.w = max(r0.w, r2.y);
			r0.w = -r1.w + r0.w;
			r0.w = 0.3 < abs(r0.w);
			r2.y = 1.0/r2.x;
			r2.x = r2.x * 0.25;
			r3.w = max(r1.w, r2.x);
			r3.xyz = r0.xyz * r2.yyy;
			o0.xyzw = r0.wwww;
			return;
		}
		
	}
}

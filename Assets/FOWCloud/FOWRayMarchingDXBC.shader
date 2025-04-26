Shader "JRMFOWCloud/FOWRayMarchingDXBC"
{
    VertexShader {
    
        class INPUT {
			v0 : POSITION;
			v1 : TEXCOORD0;
		}
		class OUT {
			o0 : SV_POSITION;
			o1 : TEXCOORD0;
		}
		void main(INPUT in) {
			r0.xyz = v0.yyy * cb1[1].xyz;
			r0.xyz = cb1[0].xyz*v0.xxx + r0.xyz;
			r0.xyz = cb1[2].xyz*v0.zzz + r0.xyz;
			r0.xyz = r0.xyz + cb1[3].xyz;// positionWS

			r1.xyzw = r0.yyyy * cb0[77].xyzw;
			r1.xyzw = cb0[76].xyzw*r0.xxxx + r1.xyzw;
			r0.xyzw = cb0[78].xyzw*r0.zzzz + r1.xyzw;
			r0.xyzw = r0.xyzw + cb0[79].xyzw;
			o0.xyzw = r0.xyzw;// positionCS

			//cb0_v21 -1.00, 10.00, 1100.00, 0.00091     _ProjectionParams  ComputeScreenPos
			r0.y = r0.y * cb0[21].x;
			r1.xzw = r0.xwy * float3(0.5, 0.5, 0.5);
			o1.zw = r0.zw;
			o1.xy = r1.zz + r1.xw;
			return;
		}
    
    }


	/*****************************************************************************************/
	/*****************************************************************************************/
	/*****************************************************************************************/



	FragmentShader {
		class INPUT {
		}
		class OUT {
		}
		void main(INPUT in) {
			r0.xy = v1.xy/v1.ww;
			r0.xy = r0.xy*float2(2.0, 2.0) + float2(-1.0, -1.0);
			// cb0_v38 0.00, 0.26795, 0.00, 0.00 
			r0.yzw = r0.yyy * cb0[38].xyz;
			// cb0_v37 0.47635, 0.00, 0.00, 0.00 
			r0.xyz = cb0[37].xyz*r0.xxx + r0.yzw;
			// cb0_v40 0.00, 0.00, -1.00, 0.05045
			r0.xyz = r0.xyz-cb0[40].xyz;
			// cb0_v46 0.00, 0.76604, 0.64279, 0.00
			r1.xyz = r0.yyy * cb0[46].xyz;
			// cb0_v45 1.00, 0.00, 0.00, 0.00
			r0.xyw = cb0[45].xyz*r0.xxx + r1.xyz;
			// cb0_v47 0.00, -0.64279, 0.76604, 0.00
			r0.xyz = cb0[47].xyz*r0.zzz + r0.xyw;
			//r0.w = dot(r0.xyzx, r0.xyzx);
			r0.w = dot(r0.xyz, r0.xyz);
			r1.x = rsqrt(r0.w);
			r0.xyz = r0.xyz * r1.xxx;
			r1.xy = v0.xy + float2(0.5, 0.5);
			//cb0_v128 5.00, 25.00, 0.00104, 0.00185
			r1.xy = r1.xy * cb0[128].zw;
			r1.xyzw = tex2D(t1, r1.xy).xyzw //_CameraDepthTexture;
			//cb0_v23 109.00, 1.00, 0.09909, 0.00091
			r1.x = cb0[23].z*r1.x + cb0[23].w;
			r1.x = 1.0/r1.x;
			r0.w = sqrt(r0.w);
			r0.w = r0.w * r1.x;
			// cb0_v20 -221.75, 112.48785, 199.44223, 0.00
			r1.xyz = r0.xyz*r0.www + cb0[20].xyz;
			// cb0_v128 5.00, 25.00, 0.00104, 0.00185 
			r0.w = cb0[128].y-0.03;
			r0.w = r1.y >= r0.w;
			if (r0.w != 0) {
				o0.xyzw = float4(0, 0, 0, 0);
				return;
			}
			r2.xy = -cb0[20].yy + cb0[128].yx;
			r2.xy = r2.xy/r0.yy;
			r2.xzw = r0.xyz*r2.xxx + cb0[20].xyz;
			r0.xzw = r0.xyz*r2.yyy + cb0[20].xyz;
			r1.w = r0.z < r1.y;
			r0.xzw = r1.www ? r1.xyz : r0.xzw;
			r0.y = abs(r0.y)*0.8 + 0.8;
			r0.xzw = -r2.xzw + r0.xzw;
			//r1.x = dot(r0.xzwx, r0.xzwx);
			r1.x = dot(r0.xzw, r0.xzw);
			r1.x = sqrt(r1.x);
			r1.y = 1.0/r1.x;
			r0.xzw = r0.xzw * r1.yyy;
			r1.x = r1.x * 0.02;
			r1.x = min(r1.x, 5.0);
			r0.xzw = r0.xzw * r1.xxx;
			// cb0_v129 0.00389, 0.00389, 1.36221, -0.89758
			r2.xz = r2.xw*cb0[129].xy + cb0[129].zw;
			// cb0_v128 5.00, 25.00, 0.00104, 0.00185 
			r1.y = -cb0[128].x + cb0[128].y;
			r3.y = 1.0/r1.y;
			r3.xz = cb0[129].xy;
			r1.yzw = r0.xzw * r3.xyz;
			r2.y = 1.0;
			r1.yzw = r1.yzw*float3(0.5, 0.5, 0.5) + r2.xyz;
			// cb0_v132 3.33314, 3.18989, 2.68852, 1.00 
			//cb0_v133 0.05514, 0.2857, 0.5566, 1.00 
			//cb0_v134 2.23462, 2.89121, 3.50918, 1.00 
			//cb0_v135 0.03348, 0.13749, 0.248, 1.00 
			r2.xyzw = cb0[134].xyzw-cb0[135].xyzw;
			r4.xyzw = cb0[132].xyzw-cb0[133].xyzw;
			r5.w = 1.0;
			r6.xyzw = float4(0, 0, 0, 0);
			r5.xyz = float3(0, 0, 0);
			r8.w = 0;
			r7.xyz = r1.yzw;
			r3.w = 0;
			r7.w = 0;
			while(true) {
				r9.x = r3.w >= 50;
				r7.w = 0;
				if (r9.x != 0) break;
				r9.xyzw = tex2D(t0, r7.xz).xyzw //Fog Camea Height;
				r9.w = saturate(r7.y);
				r9.x = saturate(-r9.w + r9.x);
				r10.x = 0.0 < r9.x;
				if (r10.x != 0) {
					r9.y = r9.y*0.75 + 0.25;
					r10.x = r9.w + 0.03;
					r10.x = r10.x + r10.x;
					r10.x = min(r9.x, r10.x);
					// cb0_v131 5.53, 257.1871, -350.34351, 230.84621
					r10.x = r10.x * cb0[131].x;
					r10.x = r9.y * r10.x;
					r9.y = r9.y*0.5 + 0.5;
					r9.y = saturate(r9.y * r10.x);
					r9.y = -r9.y + 1.0;
					r10.x = -r8.w + 1.0;
					r9.z = -r9.z + 1.0;
					r9.y = r9.y * r9.y;
					r9.w = -r9.w*0.5 + 1.0;
					r9.y = r9.w * r9.y;
					//cb0_v135 0.03348, 0.13749, 0.248, 1.00 
					r11.xyzw = r9.yyyy*r2.xyzw + cb0[135].xyzw;
					//cb0_v133 0.05514, 0.2857, 0.5566, 1.00 
					r12.xyzw = r9.yyyy*r4.xyzw + cb0[133].xyzw;
					r11.xyzw = r11.xyzw-r12.xyzw;
					r11.xyzw = r9.zzzz*r11.xyzw + r12.xyzw;
					r10.xyzw = r10.xxxx * r11.xyzw;
					r10.xyzw = r1.xxxx * r10.xyzw;
					r9.xyzw = r9.xxxx * r10.xyzw;
					r8.xyz = r5.xyz;
					r8.xyzw = r9.xyzw*r0.yyyy + r8.xyzw;
					r9.x = 0.99 < r8.w;
					if (r9.x != 0) {
						r9.y = 1.0/r8.w;
						r5.xyz = r8.xyz * r9.yyy;
						r6.xyzw = r5.xyzw;
						r8.w = 1.0;
						r7.w = -1;
						break;
					}
					r5.xyz = r8.xyz;
					r7.w = r9.x;
				} else {
					r7.w = 0;
				}
				r7.xyz = r0.xzw*r3.xyz + r7.xyz;
				r3.w = r3.w + 1;
				r6.xyzw = float4(0, 0, 0, 0);
			}
			r0.x = -r8.w + 2.0;
			r8.xyz = r0.xxx * r5.xyz;
			o0.xyzw = r7.wwww ? r6.xyzw : r8.xyzw;
			return;
		}
		
	}
}

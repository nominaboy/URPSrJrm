Shader "JRMFOWCloud/FOWCloudDXBC"
{
    VertexShader {
    
        class INPUT {
			v0 : POSITION;
			v1 : TEXCOORD0;
		}
		class OUT {
			o0 : TEXCOORD0;
			o1 : SV_POSITION;
		}
		void main(INPUT in) {
			//cb0_v131 257.1871, 257.1871, -350.34351, 230.84621
			o0.xy = v1.xy*cb0[131].xy + cb0[131].zw; // uv Scale Offset

			r0.xyzw = v0.yyyy * cb1[1].xyzw;
			r0.xyzw = cb1[0].xyzw*v0.xxxx + r0.xyzw;
			r0.xyzw = cb1[2].xyzw*v0.zzzz + r0.xyzw;
			r0.xyzw = r0.xyzw + cb1[3].xyzw;
			r1.xyzw = r0.yyyy * cb0[77].xyzw;
			r1.xyzw = cb0[76].xyzw*r0.xxxx + r1.xyzw;
			r1.xyzw = cb0[78].xyzw*r0.zzzz + r1.xyzw;
			o1.xyzw = cb0[79].xyzw*r0.wwww + r1.xyzw;
			return;

		}
    
    }


	/*****************************************************************************************/
	/*****************************************************************************************/
	/*****************************************************************************************/



	FragmentShader {
		
		class INPUT {
			v0 : TEXCOORD0;
		}
		class OUT {
			o0
		}

		// t0: t1: t2: 
		void main(INPUT in) {
			
			////cb0_v129 1.00, 1.00, 0.00, 0.00
			//r0.xy = v0.xy*cb0[129].xy + cb0[129].zw;
			//r0.z = min(r0.y, r0.x);
			//r0.z = r0.z >= 0.0;
			//r0.w = max(r0.y, r0.x);
			//r1.xyzw = tex2D(t1, r0.xy).xyzw //unity white;
			//r1.xyzw = r1.xyzw + float4(-1.0, -1.0, -0.0, -0.0);
			//r0.x = 1.0 >= r0.w;
			////r0.xz = r0.xz & float2(0x3f800000, 0x3f800000) // 0x3f800000=1.0, maybe means: if (r0.xz==0xFFFFFFFF) r0.xz=1.0;
			//r0.x = r0.x * r0.z;


			//cb0_v130 0.00, 0.00, 0.00, 0.00
			//r0.x = r0.x * cb0[130].x;
			//r0.xyzw = r0.xxxx*r1.xyzw + float4(1.0, 1.0, 0.0, 0.0);//1 1 0 0 
			r0.xyzw = float4(1, 1, 0, 0);

			//cb0_v127 0.00195, 0.00195, 1.04883, -0.49023
			r1.xy = v0.xy*cb0[127].xy + cb0[127].zw;
			r1.z = min(r1.y, r1.x);
			r1.z = r1.z >= 0.0; // step
			r1.w = max(r1.y, r1.x);
			r2.xyzw = tex2D(t0, r1.xy).xyzw //fow mask;

			//假如所有均为未解锁区域 fowmask : 1, 1, 0, 1/0?
			r2.xyzw = float4(1, 1, 0, 1);



			r2.xyzw = r2.xyzw + float4(-1.0, -1.0, -0.0, -0.0);
			r1.x = 1.0 >= r1.w; // step
			//r1.xz = r1.xz & float2(0x3f800000, 0x3f800000) // 0x3f800000=1.0, maybe means: if (r1.xz==0xFFFFFFFF) r1.xz=1.0;
			r1.x = r1.x * r1.z;
			//cb0_v128 1.00, 10.93, -0.03, -0.005
			r1.x = r1.x * cb0[128].x;
			r1.xyzw = r1.xxxx*r2.xyzw + float4(1.0, 1.0, 0.0, 0.0);
			r0.xyzw = r0.xyzw-r1.xyzw;
			r2.x = v0.x >= 0.0;
			//r2.x = r2.x & 0x3f800000 // 0x3f800000=1.0, maybe means: if (r2.x==0xFFFFFFFF) r2.x=1.0;
			r0.xyzw = r2.xxxx*r0.xyzw + r1.xyzw;
			//cb0_v135 0.645, 0.313, -5.00, 1.00
			r1.y = v0.y-cb0[135].z;
			r1.x = v0.x;
			//cb0_v132 0.0039, 0.0041, 0.0058, 0.0057
			r1.xyzw = r1.xyxy * cb0[132].xyzw;
			//cb0_v133 -0.0014, 0.00, -0.016, -0.0045
			r1.xyzw = cb0[15].yyyy*cb0[133].xyzw + r1.xyzw;
			r2.xyzw = tex2D(t2, r1.zw).xyzw //cloud noise;
			r1.xyzw = tex2D(t2, r1.xy).xyzw //cloud noise;
			r1.zw = -r1.yx + r2.yx;
			//cb0_v135 0.645, 0.313, -5.00, 1.00
			r1.xy = saturate(cb0[135].xy*r1.zw + r1.yx);
			//cb0_v134 0.343, 0.172, 0.868, 0.136
			r1.yz = r1.yy * cb0[134].yw;
			r1.x = r1.x-1.0;
			r1.xw = r1.xx * cb0[134].xz;
			r1.y = r0.z * r1.y;
			r1.x = r1.x*r0.y + r1.y;
			r2.xy = -r0.wx + float2(1.0, 1.0);
			r1.y = r2.x * 0.15;
			r0.y = -r1.w*r0.y + r2.y;
			o0.y = -r1.z*r0.z + r0.y;
			r0.x = r0.x*0.85 + r1.y;
			o0.z = r0.w;
			o0.x = r1.x + r0.x;
			o0.w = 0;
			return;
		}
	}
}

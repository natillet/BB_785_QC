@
@  Copyright 2011-12 ARM Limited
@
@  Licensed under the Apache License, Version 2.0 (the "License");
@  you may not use this file except in compliance with the License.
@  You may obtain a copy of the License at
@
@      http://www.apache.org/licenses/LICENSE-2.0
@
@  Unless required by applicable law or agreed to in writing, software
@  distributed under the License is distributed on an "AS IS" BASIS,
@  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@  See the License for the specific language governing permissions and
@  limitations under the License.
@


        .text
        .syntax   unified

.include "NE10header.s"




        .align   4
        .global   alphablend_neon
        .thumb
        .thumb_func

alphablend_neon:
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
        @
        @ arm_result_t alphablend_neon(arm_float_t * dst,
        @                 arm_float_t * src1,
        @                 arm_float_t * src2)
        @
        @  r0: *dst & current dst entry's address
        @  r1: *src1 & current src1 entry's address	[fgImage]
        @  r2: *src2 & current src2 entry's address	[bgImage]
        @  r3:  the size of the input arrays for loop comparison
        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

        push              {r3}				@ need a reg
		mov               r3, #4278190080	@ 0xff000000
		vdup.32           q12, r3
		mov               r3, #16711680		@ 0x00ff0000
		vdup.32           q13, r3
		mov               r3, #65280		@ 0x0000ff00
		vdup.32           q14, r3
		mov               r3, #255			@ 0x000000ff
		vdup.32           q15, r3
		mov               r3, #0
		movt              r3, #16			@ upper 16 (0x10) => total 0x100000 = 1048576 => image is (512px x 512px) x 4B
		add               r3, r3, r0 

        vldmia          r1!, {d0-d1}			@ load fgImage to q0
        vldmia          r2!, {d2-d3}			@ load bgImage to q1
		
.L_mainloop_float:

        @ calculate values for the next set
@		#define A(x) (((x) & 0xff000000) >> 24)
@		#define R(x) (((x) & 0x00ff0000) >> 16)
@		#define G(x) (((x) & 0x0000ff00) >> 8)
@		#define B(x) ((x) & 0x000000ff)
@		int a_fg = A(fgImage[y]);
@		int dst_r = ((R(fgImage[y]) * a_fg) + (R(bgImage[y]) * (255-a_fg)))/256;
@		int dst_g = ((G(fgImage[y]) * a_fg) + (G(bgImage[y]) * (255-a_fg)))/256;
@		int dst_b = ((B(fgImage[y]) * a_fg) + (B(bgImage[y]) * (255-a_fg)))/256;
@ NOTE: 256 = 2^8! Use right shift to divide!
		vand            q2, q0, q12			@ fgImage & 0xff000000
		vand            q4, q0, q13			@ fgImage & 0x00ff0000
		vand            q6, q0, q14			@ fgImage & 0x0000ff00
		vand            q8, q0, q15			@ fgImage & 0x000000ff
		vshr.u32        q2, q2, #24			@ $ >> 24 			= a_fg
		vshr.u32        q4, q4, #16			@ $ >> 16
		vshr.u32        q6, q6, #8			@ $ >> 16
		vsub.i32        q3, q15, q2			@ 255 - a_fg
		vmul.i32        q4, q2, q4			@ $ * a_fg 			= R(fgImage[y]) * a_fg)
		vmul.i32        q6, q2, q6			@ $ * a_fg 			= G(fgImage[y]) * a_fg)
		vmul.i32        q8, q2, q8			@ $ * a_fg 			= B(fgImage[y]) * a_fg)
		vand            q5, q1, q13			@ bgImage & 0x00ff0000
		vand            q7, q1, q14			@ bgImage & 0x0000ff00
		vand            q9, q1, q15			@ bgImage & 0x000000ff
		vshr.u32        q5, q5, #16			@ $ >> 16
		vshr.u32        q7, q7, #8			@ $ >> 16
		vmul.i32        q5, q3, q5			@ $ * (255 - a_fg) 	= (R(bgImage[y]) * (255-a_fg))
		vmul.i32        q7, q3, q7			@ $ * (255 - a_fg) 	= (G(bgImage[y]) * (255-a_fg))
		vmul.i32        q9, q3, q9			@ $ * (255 - a_fg) 	= (B(bgImage[y]) * (255-a_fg))
		vadd.i32        q4, q4, q5			@ ((R(fgImage[y]) * a_fg) + (R(bgImage[y]) * (255-a_fg)))
		vadd.i32        q6, q6, q7			@ ((G(fgImage[y]) * a_fg) + (G(bgImage[y]) * (255-a_fg)))
		vadd.i32        q8, q8, q9			@ ((B(fgImage[y]) * a_fg) + (B(bgImage[y]) * (255-a_fg)))
		vshr.u32        q4, q4, #8			@ $ / 256			= dst_r
		vshr.u32        q6, q6, #8			@ $ / 256			= dst_g
		vshr.u32        q8, q8, #8			@ $ / 256			= dst_b
@		dstImage[y] =  0xff000000 |
@					  (0x00ff0000 & (dst_r << 16)) |
@					  (0x0000ff00 & (dst_g << 8)) |
@					  (0x000000ff & (dst_b));
		vshl.u32        q4, q4, #16			@ (dst_r << 16)
		vshl.u32        q6, q6, #8			@ (dst_g << 8)
		vand            q4, q4, q13			@ (0x00ff0000 & (dst_r << 16))
		vand            q6, q6, q14			@ (0x0000ff00 & (dst_g << 8))
		vand            q8, q8, q15			@ (0x000000ff & (dst_b))
		vorr            q4, q4, q12			@
		vorr            q6, q6, q4			@
		vorr            q8, q8, q6			

		@ store the result for the current set
        vstmia          r0!, {d16-d17}			@ store dstImage from q6
		cmp             r0, r3
		
        vldmia          r1!, {d0-d1}			@ load fgImage to q0
        vldmia          r2!, {d2-d3}			@ load bgImage to q1
		
        bne             .L_mainloop_float             @ loop if r3 > 0, if we have at least another 4 floats



.L_return_float:
        @ return
        pop               {r3}
        mov               r0, #0
        bx                lr


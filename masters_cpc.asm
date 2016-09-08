#if 0
Copyright (c) 2014, 2016 Jorge Giner Cordero

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
#endif

; Masters.

mstr_bird_sp
	; 1
	.dw bird_up_it
	.db 0, 0
	.dw 0, 0, 0

	; 2
	.dw bird_grid_it0
	.db 8, 8
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 3
	.dw bird_grid_it0
	.db 16, 8
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 4
	.dw bird_grid_it0
	.db 24, 8
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 5
	.dw bird_grid_it0
	.db 32, 8
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 6
	.dw bird_center_it
	.db 16, 16
	.dw 0, 0, 0

	; 7
	.dw bird_left_it
	.db 0, 8
	.dw 0, 0, 0

	; 8
	.dw bird_right_it
	.db 40, 8
	.dw 0, 0, 0

	; 9
	.dw bird_bleft_it
	.db 8, 40
	.dw 0, 0, 0

	; 10
	.dw bird_bright_it
	.db 32, 40
	.dw 0, 0, 0

	; 11
	.dw bird_lwing0_it
	.db 8, 16
	.dw bird_lwing_am
	.db 2, 2
	.db 0, 1

	; 12
	.dw bird_rwing0_it
	.db 32, 16
	.dw bird_rwing_am
	.db 2, 2
	.db 0, 1

	; 13
	.dw bird_lshield_it
	.db 16, 40
	.dw 0, 0, 0

	; 14
	.dw bird_rshield_it
	.db 24, 40
	.dw 0, 0, 0

mstr_bird_ob	.dw birdf
		.dw bird_sp
		.dw 0

mstr_house_sp
	.dw house_it_0
	.db 0, 0
	.dw 0, 0, 0
	.dw house_it_1
	.db 0, HOUSE_YPOS
	.dw 0, 0, 0

mstr_house_ob
	.dw housef
	.dw house_sp_0
	.dw house_sp_1

mstr_ship_sp
	.dw ship_it
	.db 8, BBUFH-16
	.dw 0, 0, 0
	.dw cnon_it
	.db 8, BBUFH-24
	.dw 0, 0, 0
	.dw lwng_it
	.db 0, BBUFH-16
	.dw 0, 0, 0
	.dw rwng_it
	.db 16, BBUFH-16
	.dw 0, 0, 0
	.dw fire_it0
	.db 8, BBUFH-8
	.dw fire_am
	.db 2, 2
	.db 0, 1

mstr_ship_ob
	.dw shipf
	.dw ship_sp
	.dw 0

mstr_mine_sp
	.dw mine_it
	.db 0, 0
	.dw 0, 0, 0

mstr_ashot_sp
	.dw shot_it0
	.db 0, 0
	.dw ashot_am
	.db 1, 1
	.db 0, 1

mstr_cross_ashot_sp
	.dw cross_shot_it
	.db 0, 0
	.dw 0
	.db 0, 0
	.db 0, 0

mstr_explosion_sp
	.dw 0
	.db 0, 0
	.dw explosion_am
	.db 4, 4
	.db 0, 0

mstr_explosion_ob
	.dw explof
	.dw mstr_explosion_sp
	.dw 0

mstr_post_ob
	.dw postf
	.dw 0
	.dw 0

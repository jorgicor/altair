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

alien01	.db 5, ALIEN_IM_H
	.fill 5*ALIEN_IM_H

alien11	.db 5, ALIEN_IM_H
	.fill 5*ALIEN_IM_H

bird_lshield_im
	.db 2
bird_lshield_h
	.db 16
	.db 0, 0, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

bird_rshield_im
	.db 2
bird_rshield_h
	.db 16
	.db 0, 0, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

alient0	.dw alim00
	.dw alien01

alient1	.dw alim01
	.dw alien11

sshot_it
	.dw sshot00
	.dw sshot01

shot_it0
	.dw shot00
	.dw shot01

shot_it1
	.dw shot10
	.dw shot11

cross_shot_it
	.dw cross_shot_im

fire_it0	.dw fire_im0
fire_it1	.dw fire_im1

ship_it	.dw ship_im
lwng_it	.dw lwng_im
rwng_it	.dw rwng_im
cnon_it	.dw cnon_im

house_it_0	.dw house_im_0
house_it_1	.dw house_im_1

explosion_it0	.dw explosion_im0
explosion_it1	.dw explosion_im1
explosion_it2	.dw explosion_im2

mine_it	.dw mine_im

bird_up_it	.dw bird_up
bird_grid_it0	.dw bird_grid0
bird_grid_it1	.dw bird_grid1
bird_center_it	.dw bird_center
bird_left_it	.dw bird_left
bird_right_it	.dw bird_right
bird_bleft_it	.dw bird_bleft
bird_bright_it	.dw bird_bright
bird_lwing0_it	.dw bird_lwing0
bird_lwing1_it	.dw bird_lwing1
bird_rwing0_it	.dw bird_rwing0
bird_rwing1_it	.dw bird_rwing1

bird_lshield_it
	.dw bird_lshield_im

bird_rshield_it
	.dw bird_rshield_im

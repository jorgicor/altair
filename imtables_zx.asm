#if 0
The MIT License (MIT)

Copyright (c) 2014 inmensabolademanteca@gmail.com

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

; This images are incomplete, their right side will be built mirrored.

pmir0	.dw alim00
	.dw alim01
	.dw alim10
	.dw alim11
	.dw alim20
	.dw alim21
	.dw alim30
	.dw alim40
	.dw alim41
	.dw alim50
	.dw alim51
	.dw alim60
	.dw bird_up
	.dw bird_center
	.dw 0

; Images for the current alien are expanded here on leve entry.

alien01	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien02	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien03	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien04	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien05	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien06	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien07	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H

alien11	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien12	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien13	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien14	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien15	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien16	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H
alien17	.db 3, ALIEN_IM_H
	.fill 3*ALIEN_IM_H

alient0	.dw alim00
	.dw alien01
	.dw alien02
	.dw alien03
	.dw alien04
	.dw alien05
	.dw alien06
	.dw alien07

alient1	.dw alim01
	.dw alien11
	.dw alien12
	.dw alien13
	.dw alien14
	.dw alien15
	.dw alien16
	.dw alien17

sshot_it
shot_it0
	.dw shot00
	.dw shot01
	.dw shot02
	.dw shot03
	.dw shot04
	.dw shot05
	.dw shot06
	.dw shot07

shot_it1
	.dw shot10
	.dw shot11
	.dw shot12
	.dw shot13
	.dw shot14
	.dw shot15
	.dw shot16
	.dw shot17

cross_shot_it
	.dw cross_shot_im

fire_it0	.dw fire_im0

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
bird_grid_it2	.dw bird_grid2
bird_grid_it3	.dw bird_grid3
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

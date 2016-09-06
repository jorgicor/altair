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

ashot_am	.db 2
		.dw shot_it0, WHITE
		.dw shot_it1, WHITE

fire_am	.db 2
	.dw fire_it0, RED
	.dw fire_it0, YELLOW


explosion_am	.db 5
		.dw explosion_it0, RED
		.dw explosion_it1, YELLOW
		.dw explosion_it2, RED
		.dw explosion_it1, YELLOW
		.dw explosion_it0, RED

bird_grid_am	.db 4
		.dw bird_grid_it0, WHITE
		.dw bird_grid_it1, WHITE
		.dw bird_grid_it2, WHITE
		.dw bird_grid_it3, WHITE

bird_lwing_am	.db 2
		.dw bird_lwing0_it, bird_wing_co
		.dw bird_lwing1_it, bird_wing_co

bird_rwing_am	.db 2
		.dw bird_rwing0_it, bird_wing_co
		.dw bird_rwing1_it, bird_wing_co

alien_am0	.db 2
		.dw alient0, YELLOW 
		.dw alient1, YELLOW
alien_am1	.db 2
		.dw alient0, CYAN 
		.dw alient1, CYAN
alien_am2	.db 2
		.dw alient0, MAGENT 
		.dw alient1, MAGENT
alien_am3	.db 2
		.dw alient0, WHITE  
		.dw alient0, GREEN
alien_am4	.db 2
		.dw alient0, YELLOW
		.dw alient1, YELLOW
alien_am5	.db 2
		.dw alient0, RED  
		.dw alient1, RED
alien_am6	.db 2
		.dw alient0, YELLOW 
		.dw alient0, GREEN

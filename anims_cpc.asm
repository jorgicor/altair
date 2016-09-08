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

ashot_am	.db 2
		.dw shot_it0
		.dw shot_it1

fire_am	.db 2
	.dw fire_it0
	.dw fire_it1

explosion_am	.db 5
		.dw explosion_it0
		.dw explosion_it1
		.dw explosion_it2
		.dw explosion_it1
		.dw explosion_it0

bird_grid_am	.db 2
		.dw bird_grid_it0
		.dw bird_grid_it1

bird_lwing_am	.db 2
		.dw bird_lwing0_it
		.dw bird_lwing1_it

bird_rwing_am	.db 2
		.dw bird_rwing0_it
		.dw bird_rwing1_it

alien_am0
alien_am1
alien_am2
alien_am3
alien_am4
alien_am5	.db 2
		.dw alient0 
		.dw alient1
alien_am6	.db 1
		.dw alient0

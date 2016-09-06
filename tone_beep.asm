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

; -------------------------
; Sound notes. A4 is 440Hz.
; -------------------------

; The audible human freqs are ~20Hz to ~20000Hz.
; A0 is 27.5 Hz.

; For the beeper.
; v = (437500/freq) - 29.5 or v = ((3500000 / freq) - 236) / 8 .
; This is for a 3.5MHz Spectrum 48K, but what happens with the 128 and
; upper Spectrums where the frdwency is 3.54690 MHz?

beep_tone_t
	.dw BA0
	.dw BAS0
	.dw BB0
	.dw BC1
	.dw BCS1
	.dw BD1
	.dw BDS1
	.dw BE1
	.dw BF1
	.dw BFS1
	.dw BG1
	.dw BGS1
	.dw BA1
	.dw BAS1
	.dw BB1
	.dw BC2
	.dw BCS2
	.dw BD2
	.dw BDS2
	.dw BE2
	.dw BF2
	.dw BFS2
	.dw BG2
	.dw BGS2
	.dw BA2
	.dw BAS2
	.dw BB2
	.dw BC3
	.dw BCS3
	.dw BD3
	.dw BDS3
	.dw BE3
	.dw BF3
	.dw BFS3
	.dw BG3
	.dw BGS3
	.dw BA3
	.dw BAS3
	.dw BB3
	.dw BC4
	.dw BCS4
	.dw BD4
	.dw BDS4
	.dw BE4
	.dw BF4
	.dw BFS4
	.dw BG4
	.dw BGS4
	.dw BA4
	.dw BAS4
	.dw BB4
	.dw BC5
	.dw BCS5
	.dw BD5
	.dw BDS5
	.dw BE5
	.dw BF5
	.dw BFS5
	.dw BG5
	.dw BGS5
	.dw BA5
	.dw BAS5
	.dw BB5
	.dw BC6
	.dw BCS6
	.dw BD6
	.dw BDS6
	.dw BE6
	.dw BF6
	.dw BFS6
	.dw BG6
	.dw BGS6
	.dw BA6
	.dw BAS6
	.dw BB6
	.dw BC7
	.dw BCS7
	.dw BD7
	.dw BDS7
	.dw BE7
	.dw BF7
	.dw BFS7
	.dw BG7
	.dw BGS7
	.dw BA7
	.dw BAS7
	.dw BB7
	.dw BC8
	.dw BCS8
	.dw BD8
	.dw BDS8
	.dw BE8
	.dw BF8
	.dw BFS8
	.dw BG8
	.dw BGS8
	.dw BA8
	.dw BAS8
	.dw BB8
	.dw BC9
	.dw BCS9
	.dw BD9
	.dw BDS9
	.dw BE9
	.dw BF9
	.dw BFS9
	.dw BG9
	.dw BGS9
	.dw BA9


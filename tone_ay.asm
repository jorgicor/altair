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

; -------------------------
; Sound notes. A4 is 440Hz.
; -------------------------

; The audible human freqs are ~20Hz to ~20000Hz.
; A0 is 27.5 Hz.

; For the AY.
; v = 1773400 Hz / (note_freq * 16)
; The AY runs at 1.7734MHz. The AY counts first 16 ticks.

ay_tone_t
	.dw YA0
	.dw YAS0
	.dw YB0
	.dw YC1
	.dw YCS1
	.dw YD1
	.dw YDS1
	.dw YE1
	.dw YF1
	.dw YFS1
	.dw YG1
	.dw YGS1
	.dw YA1
	.dw YAS1
	.dw YB1
	.dw YC2
	.dw YCS2
	.dw YD2
	.dw YDS2
	.dw YE2
	.dw YF2
	.dw YFS2
	.dw YG2
	.dw YGS2
	.dw YA2
	.dw YAS2
	.dw YB2
	.dw YC3
	.dw YCS3
	.dw YD3
	.dw YDS3
	.dw YE3
	.dw YF3
	.dw YFS3
	.dw YG3
	.dw YGS3
	.dw YA3
	.dw YAS3
	.dw YB3
	.dw YC4
	.dw YCS4
	.dw YD4
	.dw YDS4
	.dw YE4
	.dw YF4
	.dw YFS4
	.dw YG4
	.dw YGS4
	.dw YA4
	.dw YAS4
	.dw YB4
	.dw YC5
	.dw YCS5
	.dw YD5
	.dw YDS5
	.dw YE5
	.dw YF5
	.dw YFS5
	.dw YG5
	.dw YGS5
	.dw YA5
	.dw YAS5
	.dw YB5
	.dw YC6
	.dw YCS6
	.dw YD6
	.dw YDS6
	.dw YE6
	.dw YF6
	.dw YFS6
	.dw YG6
	.dw YGS6
	.dw YA6
	.dw YAS6
	.dw YB6
	.dw YC7
	.dw YCS7
	.dw YD7
	.dw YDS7
	.dw YE7
	.dw YF7
	.dw YFS7
	.dw YG7
	.dw YGS7
	.dw YA7
	.dw YAS7
	.dw YB7
	.dw YC8
	.dw YCS8
	.dw YD8
	.dw YDS8
	.dw YE8
	.dw YF8
	.dw YFS8
	.dw YG8
	.dw YGS8
	.dw YA8
	.dw YAS8
	.dw YB8
	.dw YC9
	.dw YCS9
	.dw YD9
	.dw YDS9
	.dw YE9
	.dw YF9
	.dw YFS9
	.dw YG9
	.dw YGS9
	.dw YA9


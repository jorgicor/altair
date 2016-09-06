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

; ---------------------
; AY-3-8912 sound chip.
; ---------------------

; If the AY-3-8912 sound chip is detected.
ay_detected	.db 1

; ---------------------------------
; 'detect_ay' Detect AY-3-8912 chip
; ---------------------------------
;	Will set 'ay_detected' to 1 if the AY sound chip is detected on the
; system, or 0 otherwise.

detect_ay
	ret

; ------------
; 'ay_refresh'
; ------------
;	Updates the AY chip registers copying our buffer of register data.

ay_refresh

; Start from last register, so we can use some speed tricks on this routine.

	ld hl,ay_pattern
	ld e,+AY_NREGS-1

; A always 0.

	xor a

; D always PPI A.

	ld d,PPI_AH
	
; Configure PPI port A as output.
; (Should be already).

	; ld bc,+PPI_CTRL+$82
	; out (c),c

ay_refresh_reg

; Select PSG register.

; 1 Write the PSG register number we want in PPI port A.

	ld b,d
	out (c),e

; 2 Use PPI port C 'select PSG register' function.

	ld bc,+PPI_C+$c0
	out (c),c

; Use PPI port C 'PSG inactive' function.
; (Needed for CPC+).

	out (c),a

; Put the value for the PSG register in PPI port A.

	ld b,d
	ld c,(hl)
	out (c),c

; Use PPI port C 'Write to PSG register'.

	ld bc,+PPI_C+$80
	out (c),c

; Use PPI port C 'PSG inactive' function.
; (Needed for CPC+).

	out (c),a

; Next register.

	dec hl
	dec e

; When E passes from 0 to 255, positive flag SF won't be set.

	jp p,ay_refresh_reg
	ret

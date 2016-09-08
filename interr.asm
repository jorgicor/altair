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

; ----------------------------------------------------------------------------
; CIDLESA's Altair arcade (1981) port to the ZX Spectrum.
;
; Interrupt. Sound and music.
; ----------------------------------------------------------------------------

#ifdef ZX
interrupt
	di
	push af
	push bc
	push de
	push hl
	push ix

	call update_sound

interr_end
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ei
	reti
#endif

#ifdef CPC
cpc_inter_n	.db CPC_INTS_PER_VSYNC

interrupt
	di
	push af
	push hl

; Only update once per vertical retrace.

	ld hl,cpc_inter_n
	dec (hl)
	jr nz,interr_end
	ld (hl),CPC_INTS_PER_VSYNC

	push bc
	push de
	push ix

	call update_sound
	call pollhk

	pop ix
	pop de
	pop bc

interr_end
	pop hl
	pop af
	ei
	reti
#endif


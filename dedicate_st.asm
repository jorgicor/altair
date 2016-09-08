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
; Dedication.
; ----------------------------------------------------------------------------

txdedicate
	.db "NO HE FIRMADO ESTE JUEGO, PERO", 0
	.db "TE DEDICO TODO EL ESFUERZO QUE", 0
	.db "VOLQUE EN EL.", 0
	.db " ", 0
	.db "A TI, MI AMOR, HANANE.", 0
	.db EOF

enter_dedicate_st
	ld a,0
	call clrscr

	ld hl,txdedicate
	call drtext
	ret

update_dedicate_st
	call pollk
	call getkey
	or a
	ret z

	ld a,STATE_MENU
	call set_state
	ret


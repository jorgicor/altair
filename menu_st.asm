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

; ----------------------------------------------------------------------------
; CIDLESA's Altair arcade (1981) port to the ZX Spectrum.
;
; Menu state.
; ----------------------------------------------------------------------------

#ifdef LANG_EN
txdefeat0	.db "WIN BATTLE AFTER", 0
txdefeat1	.db "BATTLE AND DESTROY", 0
txdefeat2	.db "THE MONSTER", 0
txdefeat3	.db "THE MONSTER AS DID", 0
txpoints	.db "POINTS", 0
#endif

#ifdef LANG_ES
txdefeat0	.db "VENCE BATALLA TRAS", 0
txdefeat1	.db "BATALLA Y DESTRUYE AL", 0
txdefeat2	.db "MONSTRUO", 0
txdefeat3	.db "MONSTRUO COMO HIZO", 0
txpoints	.db "PUNTOS", 0
#endif

txextra		.db "EXTRA", 0
tenthou		.db 1, 0, 0, 0, 0
txtop		.db "AAAAAAAAAAAAAAAAAAAAA", 0

; If the bird has been killed at least once.
bird_killed_once	.db 0

MENU_CDELAY	.equ $007f >> 2
MENU_TXDELAY	.equ $00ff >> 2
MENU_WDELAY	.equ $4fff
NUMCLR		.equ PBLUE|YELLOW

menu_code	.db ICLS, PBLUE|BLUE
		.db ITEXT, PBLUE|CYAN, SCRWC-TXCIDELSA_LEN, 23
			.db txcidelsa_str&255, txcidelsa_str>>8
		.db IDELAY, MENU_CDELAY&255, MENU_CDELAY>>8
		.db IDRHLINE, 'C', PBLUE|GREEN, 0, 0, 31
		.db IDRVLINE, 'C', PBLUE|GREEN, 31, 1, 7
		.db IDRHLINE, 'C', PBLUE|GREEN, 8, 31, 0
		.db IDRVLINE, 'C', PBLUE|GREEN, 0, 7, 1
		.db IDELAY, MENU_TXDELAY&255, MENU_TXDELAY>>8
		.db ITEXT, PBLUE|WHITE, 5, 2, txdefeat0&255, txdefeat0>>8
		.db ITEXT, PBLUE|WHITE, 5, 3, txdefeat1&255, txdefeat1>>8
		.db IIFBIRDK, 0
		.db ITEXT, PBLUE|WHITE, 5, 4, txdefeat2&255, txdefeat2>>8
		.db IENDIF
		.db IIFBIRDK, 1
		.db ITEXT, PBLUE|WHITE, 5, 4, txdefeat3&255, txdefeat3>>8
		.db ITEXT, PBLUE|YELLOW, 5, 6, txtop&255, txtop>>8
		.db IENDIF
		.db IDELAY, MENU_CDELAY&255, MENU_CDELAY>>8
		.db IDRVLINE, 'C', PBLUE|GREEN, 31, 8, 22
		.db IDRHLINE, 'C', PBLUE|GREEN, 22, 30, 0
		.db IDRVLINE, 'C', PBLUE|GREEN, 0, 21, 8
		.db IDELAY, MENU_TXDELAY&255, MENU_TXDELAY>>8

		.db IDRALIEN, 0, PBLUE|YELLOW, 8, 11
		.db IDRNUM, NUMCLR, SCORDIG, scoral0&255, scoral0>>8, 11, 11
		.db ITEXT, PBLUE|WHITE, 18, 11, txpoints&255, txpoints>>8

		.db IDRALIEN, 1, PBLUE|CYAN, 8, 12
		.db IDRNUM, NUMCLR, SCORDIG, scoral1&255, scoral1>>8, 11, 12
		.db ITEXT, PBLUE|WHITE, 18, 12, txpoints&255, txpoints>>8

		.db IDRALIEN, 2, PBLUE|MAGENT, 8, 13
		.db IDRNUM, NUMCLR, SCORDIG, scoral2&255, scoral2>>8, 11, 13
		.db ITEXT, PBLUE|WHITE, 18, 13, txpoints&255, txpoints>>8

		.db IDRALIEN, 3, PBLUE|WHITE, 8, 14
		.db IDRNUM, NUMCLR, SCORDIG, scoral3&255, scoral3>>8, 11, 14
		.db ITEXT, PBLUE|WHITE, 18, 14, txpoints&255, txpoints>>8

		.db IDRALIEN, 4, PBLUE|YELLOW, 8, 15
		.db IDRNUM, NUMCLR, SCORDIG, scoral4&255, scoral4>>8, 11, 15
		.db ITEXT, PBLUE|WHITE, 18, 15, txpoints&255, txpoints>>8

		.db IDRALIEN, 5, PBLUE|RED, 8, 16
		.db IDRNUM, NUMCLR, SCORDIG, scoral5&255, scoral5>>8, 11, 16
		.db ITEXT, PBLUE|WHITE, 18, 16, txpoints&255, txpoints>>8

		.db IDRALIEN, 6, PBLUE|GREEN, 8, 17
		.db IDRNUM, NUMCLR, SCORDIG, scoral6&255, scoral6>>8, 11, 17
		.db ITEXT, PBLUE|WHITE, 18, 17, txpoints&255, txpoints>>8

		.db ITEXT, PBLUE|WHITE, 6, 19, txextra&255, txextra>>8
		.db IDRCHR, PBLUE|CYAN, 12, 19, hudlife&255, hudlife>>8
		.db IDRNUM, NUMCLR, SCORDIG, tenthou&255, tenthou>>8, 14, 19
		.db ITEXT, PBLUE|WHITE, 20, 19, txpoints&255, txpoints>>8
		.db IDELAY, MENU_WDELAY&255, MENU_WDELAY>>8
		.db ISTOP

; ---------------
; 'enter_menu_st'
; ---------------

enter_menu_st

	ld a,BORDER_MENU
	call set_border_color

	ld hl,menu_code
	call mach_start
	ret

; ----------------
; 'update_menu_st'
; ----------------

update_menu_st

; Check keys.

	call pollk
	call anykey_options
	ret c

	call mach_update
	jr nz,update_menu_st_timeout
	ret

update_menu_st_timeout
	ld a,STATE_ATTRACT
	call set_state
	ret


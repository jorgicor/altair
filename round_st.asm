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
; Entering game, round info.
; ----------------------------------------------------------------------------

txplayer	.db "PLAYER ", 0
txr1		.db "1", 0
txr2		.db "2", 0

ROUND_TXDELAY	.equ 1024
ROUND_DELAY	.equ 25000

round_code	.db ICLS, BLUE|PBLUE
		.db ITEXT, PBLUE|CYAN, SCRWC-TXCIDELSA_LEN, 23
			.dw txcidelsa_str
		.db IDELAY
			.dw ROUND_TXDELAY
		.db ITEXT, PBLUE|WHITE, 12, 12
			.dw txplayer
		.db ITEXT, PBLUE|YELLOW, 19, 12
txrp			.dw txr1
		.db IDELAY
			.dw 0
		.db IBEEP
			.dw BEEP_FREQX256(440*256), BEEP_MS(440*256, 250)
		.db IDELAY
			.dw ROUND_DELAY
		.db ISTOP

; ----------------
; 'enter_round_st'
; ----------------

enter_round_st
	ld a,BORDER_MENU
	call set_border_color

	ld a,(cur_player)
	or a
	jr z,enter_round_st_r1

	ld hl,txr2
	jr enter_round_st_start

enter_round_st_r1

	ld hl,txr1

enter_round_st_start

	ld (txrp),hl
	ld hl,round_code
	call mach_start
	ret

; -----------------
; 'update_round_st'
; -----------------

update_round_st
	call mach_update
	ret z

	ld a,STATE_GAMEPLAY
	call set_state
	ret


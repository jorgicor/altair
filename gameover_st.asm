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
; Game over state.
; ----------------------------------------------------------------------------

GAMEOVER_ST_DRAW	.equ 0
GAMEOVER_ST_WAIT	.equ 1

gameover_state	.db 0

GAMEOVER_TXDELAY	.equ 1023

gameover_code	.db IDELAY, GAMEOVER_TXDELAY&255, GAMEOVER_TXDELAY>>8
		.db ITEXT, PBLACK|YELLOW
			.db BBUFXC+TXGAMOVER_X, BBUFYC+TXGAMOVER_Y
			.db txgamover_str&255, txgamover_str>>8
		.db ISTOP

; -------------------
; 'enter_gameover_st'
; -------------------

enter_gameover_st

; Clear screen.

	ld a,PBLACK|BLACK
	call clrscr

	ld a,BORDER_GAME
	call set_border_color

; Init hud.

	call drcidelsa
	call drtxhscor
	call drhscor

; Draw scores.

	xor a
	call drtxplayer
	call drscor

	ld a,(two_player_game)
	or a
	jr z,enter_gameover_st0

	ld a,1
	call drtxplayer
	call drscor

enter_gameover_st0

; Reset Sprite and Object tables.

	call init_sprtab
	call init_objtab

	call gameplay_loop

	ld hl,gameover_code
	call mach_start

	ld a,GAMEOVER_ST_DRAW
	ld (gameover_state),a
	ret

; --------------------
; 'update_gameover_st'
; --------------------

update_gameover_st
	ld a,(gameover_state)
	cp GAMEOVER_ST_DRAW
	jp z,gameover_draw
	jp gameover_wait

; ---------------
; 'gameover_draw'
; ---------------

gameover_draw

	call mach_update
	ret z

; Set next state.

	call cicle_gamover_init

	ld a,GAMEOVER_ST_WAIT
	ld (gameover_state),a
	ret

; ---------------
; 'gameover_wait'
; ---------------

gameover_wait
	
	call gameplay_loop

	call pollk
	call anykey_options
	ret

; ------------------
; 'drfx_gameover_st'
; ------------------

drfx_gameover_st
	ld a,(gameover_state)
	cp GAMEOVER_ST_WAIT
	ret nz
	call drgamover
	call cicle_gamover
	ret

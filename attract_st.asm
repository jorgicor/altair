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
; Attract mode state.
; ----------------------------------------------------------------------------

txgamover	.db 'G', PBLACK|WHITE
		.db 'A', PBLACK|WHITE
		.db 'M', PBLACK|WHITE
		.db 'E', PBLACK|WHITE
		.db ' ', PBLACK|BLUE
		.db 'O', PBLACK|WHITE
		.db 'V', PBLACK|WHITE
		.db 'E', PBLACK|WHITE
		.db 'R', PBLACK|WHITE
		.db 0

#ifdef LANG_EN
txbirdpts	.db '5', PBLACK|RED
		.db '0', PBLACK|RED
		.db '0', PBLACK|RED
		.db ' ', PBLACK|BLUE
		.db 'P', PBLACK|WHITE
		.db 'O', PBLACK|WHITE
		.db 'I', PBLACK|WHITE
		.db 'N', PBLACK|WHITE
		.db 'T', PBLACK|WHITE
		.db 'S', PBLACK|WHITE
		.db 0
#endif

#ifdef LANG_ES
txbirdpts	.db '5', PBLACK|RED
		.db '0', PBLACK|RED
		.db '0', PBLACK|RED
		.db ' ', PBLACK|BLUE
		.db 'P', PBLACK|WHITE
		.db 'U', PBLACK|WHITE
		.db 'N', PBLACK|WHITE
		.db 'T', PBLACK|WHITE
		.db 'O', PBLACK|WHITE
		.db 'S', PBLACK|WHITE
		.db 0
#endif

TXBIRDPTS_LEN	.equ 10
TXBIRDPTS_X	.equ (BBUFWC-TXBIRDPTS_LEN)/2
TXBIRDPTS_Y	.equ 2
BIRD_CX		.equ ((BBUFWC-BIRD_WC)/2)*8
BIRD_Y		.equ (TXBIRDPTS_Y+2)*8
TXGAMOVER_LEN	.equ 9
TXGAMOVER_X	.equ 1+((BBUFWC-TXGAMOVER_LEN)/2)
TXGAMOVER_Y	.equ TXBIRDPTS_Y+1+BIRD_HC+3

txgamover_str	.db "GAME OVER", 0

ATTRACT_TXDELAY .equ 128

attract_code	.db IDELAY, ATTRACT_TXDELAY&255, ATTRACT_TXDELAY>>8
		.db ITEXT, PBLACK|YELLOW
			.db BBUFXC+TXGAMOVER_X, BBUFYC+TXGAMOVER_Y
			.db txgamover_str&255, txgamover_str>>8
		.db ISTOP

; Substates.
ATTRACT_ST_FRAME0	.equ 0
ATTRACT_ST_GAMEOVER	.equ 1
ATTRACT_ST_LOOP		.equ 2
attract_stat	.db 0

; Steps to wait until return to menu.
ATTRACT_WTIME	.equ 164
attract_wtime	.db 0

; To cicle_gamover.
GAMOVER_CICLE	.equ TXGAMOVER_LEN*4
gamover_i	.db 0
gamover_color	.db PBLACK|WHITE

; ------------------
; 'enter_attract_st'
; ------------------

enter_attract_st

; Set first state.

	ld a,ATTRACT_ST_FRAME0
	ld (attract_stat),a

; Clear screen.

	ld a,PBLACK|BLACK
	call clrscr

	ld a,BORDER_GAME
	call set_border_color

; Init hud.

	call drcidelsa
	call drtxhscor
	call drhscor

; Reset Sprite and Object tables.

	call init_sprtab
	call init_objtab
	ret

; ------------------
; 'update_attact_st'
; ------------------

update_attract_st

; Check substate.

	ld a,(attract_stat)
	cp ATTRACT_ST_GAMEOVER
	jr z,update_attract_st1
	cp ATTRACT_ST_LOOP
	jr z,update_attract_st2

; ATTRACT_ST_FRAME0.

	call gameplay_loop
	ld hl,attract_code
	call mach_start
	ld a,ATTRACT_ST_GAMEOVER
	ld (attract_stat),a

	; fall !!
	
update_attract_st1

	call pollk
	call anykey_options
	ret c

	call mach_update
	ret z

; The machine has stopped.
; Load bird.

	call reset_bird_shield
	call load_bird_spr
	ld e,BIRD_CX
	ld d,BIRD_Y
	call set_bird_pos

; Init cicle algorithm.

	call cicle_gamover_init

; Set wait time.

	ld a,ATTRACT_WTIME
	ld (attract_wtime),a

; Change substate.

	ld a,ATTRACT_ST_LOOP
	ld (attract_stat),a
	ret

update_attract_st2
	call gameplay_loop

	call pollk
	call anykey_options
	ret c

	ld hl,attract_wtime
	dec (hl)
	ret nz

	ld a,STATE_MENU
	call set_state
	ret

; ----------------
; 'anykey_options'
; ----------------
;	Checks for any key and go to options if any.
;
; Out	CY if key pressed.

anykey_options

	call getkey
	or a
	ret z
	call kfeedbk
	ld a,STATE_OPTIONS
	call set_state
	scf
	ret

; -----------------
; 'drfx_attract_st'
; -----------------

drfx_attract_st
	ld a,(attract_stat)
	cp ATTRACT_ST_LOOP
	ret nz
	call drgamover
	call drbirdpts
	call cicle_gamover
	ret

; --------------------
; 'cicle_gamover_init'
; --------------------
;	Inits the variables needed for algorithm.

cicle_gamover_init

; Reset index.

	xor a
	ld (gamover_i),a

; Color.

	ld a,PBLACK|YELLOW
	ld (gamover_color),a

; Set color to the text.

	ld a,PBLACK|YELLOW
	ld hl,txgamover+1
	ld b,TXGAMOVER_LEN

cicle_gamover_init_loop
	ld (hl),a
	inc hl
	inc hl
	djnz cicle_gamover_init_loop
	ret
	
; ---------------
; 'cicle_gamover'
; ---------------
;	Cicles the game over text between color.

cicle_gamover
	ld a,(gamover_i)
	cp TXGAMOVER_LEN
	jr nc,cicle_gamover_next
	ld hl,txgamover
	ld c,a
	ld b,0
	add hl,bc
	add hl,bc
	inc hl
	push af
	ld a,(gamover_color)
	ld (hl),a
	pop af
	jr cicle_gamover_inc
	
cicle_gamover_next
	cp GAMOVER_CICLE
	jr nz,cicle_gamover_inc
	ld a,(gamover_color)
	cp PBLACK|WHITE
	jr z,cicle_gamover_yellow
	ld a,PBLACK|WHITE
	jr cicle_gamover_reset

cicle_gamover_yellow
	ld a,PBLACK|YELLOW

cicle_gamover_reset
	ld (gamover_color),a
	ld a,255

cicle_gamover_inc
	inc a
	ld (gamover_i),a
	ret

; -----------
; 'drgamover'
; -----------
;	Draws GAME OVER.

drgamover

	ld h,TXGAMOVER_X
	ld l,TXGAMOVER_Y
	ld de,txgamover	
	call drtxfx
	ret

; -----------
; 'drbirdpts'
; -----------
;	Draws the points of destroying bird.

drbirdpts

	ld h,TXBIRDPTS_X
	ld l,TXBIRDPTS_Y
	ld de,txbirdpts
	call drtxfx
	ret

; ----------
; 'chrtobuf'
; ----------
;	Draws a character in a linear buffer.
;
; In	DE points to first of 8 bytes of pixel data. HL dest address in
;	buffer. BC length of a scanline in buffer.
; Saves	BC.

chrtobuf
	ld a,(de)	; 1
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 2
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 3
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 4
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 5
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 6
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 7
	ld (hl),a
	inc de
	add hl,bc
	ld a,(de)	; 8
	ld (hl),a
	inc de
	add hl,bc
	ret

; -----------------------------
; 'lentxfx' Length Text Effect.
; -----------------------------
;	Calculates the length of a text for effects.
;
; In	DE address of text.
; Out	A length of text.
; Saves	BC, DE, HL.

lentxfx
	push de
	push bc
	ld c,0

lentxfx_loop
	ld a,(de)
	or a
	jr z,lentxfx_end
	inc c
	inc de
	inc de
	jr lentxfx_loop

lentxfx_end
	ld a,c
	pop bc
	pop de
	ret

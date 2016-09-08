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
; Entering name when the bird is killed.
; ----------------------------------------------------------------------------

NAME_LEN	.equ 21
NAME_X	.equ 5
NAME_MX	.equ NAME_X + NAME_LEN

name_code	.db ICLS, PRED|RED
		.db ITEXT, PRED|CYAN, SCRWC-TXCIDELSA_LEN, 23
			.db txcidelsa_str&255, txcidelsa_str>>8
		.db IDELAY, MENU_CDELAY&255, MENU_CDELAY>>8
		.db IDRHLINE, 'C', PRED|GREEN, 0, 0, 31
		.db IDRVLINE, 'C', PRED|GREEN, 31, 1, 7
		.db IDRHLINE, 'C', PRED|GREEN, 8, 31, 0
		.db IDRVLINE, 'C', PRED|GREEN, 0, 7, 1
		.db IDELAY, MENU_TXDELAY&255, MENU_TXDELAY>>8
		.db ITEXT, PRED|WHITE, 5, 2, txdefeat0&255, txdefeat0>>8
		.db ITEXT, PRED|WHITE, 5, 3, txdefeat1&255, txdefeat1>>8
		.db ITEXT, PRED|WHITE, 5, 4, txdefeat3&255, txdefeat3>>8
		.db ITEXT, PRED|WHITE, NAME_X, 6, txtop&255, txtop>>8
		.db ISTOP

; y,x pos in characters.
name_char_pos	.dw 0

; Address of current character in txtop.
name_tx_pos	.dw txtop

name_state_f	.dw 0

; ---------------
; 'enter_name_st'
; ---------------

enter_name_st

	ld a,BORDER_NAME
	call set_border_color

	ld hl,name_drawing_f
	ld (name_state_f),hl

	ld hl,+(6<<8)+NAME_X
	ld (name_char_pos),hl

	ld hl,txtop
	ld (name_tx_pos),hl

	call reset_name

	ld hl,name_code
	call mach_start
	ret

; ----------------
; 'update_name_st'
; ----------------

update_name_st
	ld hl,(name_state_f)
	jp jphl

; ----------------
; 'name_drawing_f'
; ----------------

name_drawing_f
	call mach_update
	ret z

	ld hl,name_input_f
	ld (name_state_f),hl
	ret

; --------------
; 'name_input_f'
; --------------

name_input_f
	call pollk
	call getkey

; No key.

	or a
	ret z

; Key pressed.

#ifdef ZX

	cp KEY_CAP
	ret z
	cp KEY_SYM
	ret z	
	cp KEY_RET
	jr z,name_input_enter_pressed
	cp KEY_0
	jr z,name_input_chk_del

#endif

#ifdef CPC

	cp KEY_RET
	jr z,name_input_enter_pressed
	cp KEY_DEL
	jr z,name_input_del

#endif

name_input_key

; Any printable key now.

	call kc2char

#ifdef CPC

; If 0 no printable character.

	or a
	ret z

#endif

; Check if we are not at max len.

	ld l,a
	ld de,(name_char_pos)
	ld a,NAME_MX
	cp e
	ret z
	ld a,l

; We can write.

; Set in the word.

	push de
	ld de,(name_tx_pos)
	ld (de),a
	inc de
	ld (name_tx_pos),de
	pop de

; Draw on screen.

	call font_chadr
	ld a,PRED|WHITE
	call set_char_color
	push de
	call drchrc
	pop de
	inc e
	ld (name_char_pos),de
	ret

name_input_chk_del

; We just pressed the 0 key. Check if CAPS_SHIFT is pressed as well.

	ld e,a
	ld a,KEY_CAP
	call keydown
	ld a,e
	jr z,name_input_key

name_input_del

; Delete.

; Check if we can't delete more.

	ld de,(name_char_pos)
	ld a,NAME_X
	cp e
	ret z

; We can delete.

; Delete in the string.

	push de
	ld de,(name_tx_pos)
	dec de
	ld a,'_'
	ld (de),a
	ld (name_tx_pos),de
	pop de

; Delete on screen.

	dec e
	ld (name_char_pos),de
	call font_chadr
	ld a,PRED|WHITE
	call set_char_color
	call drchrc
	ret

name_input_enter_pressed

	call fix_name

	ld a,STATE_GAMEOVER
	call set_state
	ret

; ------------
; 'reset_name'
; ------------
;	Put '_' in the name.

reset_name
	ld hl,txtop
	ld b,NAME_LEN
	ld a,'_'

reset_name_loop
	ld (hl),a
	inc hl
	djnz reset_name_loop
	ret

; ----------
; 'fix_name'
; ----------
;	Removes '_' from name.

fix_name
	ld hl,txtop
	ld b,NAME_LEN
	
fix_name_loop
	ld a,(hl)
	cp '_'
	jr nz,fix_name_next
	ld a,32
	ld (hl),a

fix_name_next
	inc hl
	djnz fix_name_loop
	ret

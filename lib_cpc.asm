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

; Routines that depend on the CPC.

CPC_ZX_SCR	.equ 1

; ------------------
; 'set_border_color'
; ------------------
;	Sets the border color.
;
; In	A border color.
; Saves	DE, HL.

set_border_color

	ld bc,$7f10
	out (c),c
	add a,$40
	out (c),a
	ret

#if CPC_ZX_SCR

; ----------------------------
; 'scradr' Calc Screen Address
; ----------------------------
;
;	Calcs y*64 + x*2.
;
; In	DE y,x position in characters.
; Out	DE screen address.
; Saves	HL, BC

scradr	push hl

	ld l,d
	ld h,0
	ld d,h

; x*2.

	ld a,e
	add a,a
	ld e,a

; y*64.

	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl

; y*64 + x*2.

	add hl,de

; Add vram.

	ld a,h
	add a,vram>>8
	ld h,a

	ex de,hl

	pop hl
	ret

#else

; ----------------------------
; 'scradr' Calc Screen Address
; ----------------------------
;
;	Calcs y*64 + y*16 + x*2.
;
; In	DE y,x position in characters.
; Out	DE screen address.
; Saves	HL, BC

scradr	push hl

	ld l,d
	ld h,0

; x*2.

	ld a,e
	add e

; y*16.
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld e,l
	ld d,h

; y*64.
	add hl,hl
	add hl,hl

; y*16 + y*64

	add hl,de

; y*16 + y*64 + x*2.

	ld d,0
	ld e,a
	add hl,de

; Add vram.

	ld a,h
	add a,vram>>8
	ld h,a

	ex de,hl

	pop hl
	ret

#endif

; -----------------
; 'set_char_color'
; -----------------
;	Sets the char color for the next drawing operations.
;
; In	A pen + paper.
; Saves	BC, DE, HL.

set_char_color

; If it is the last color, do nothing.

	push hl
	ld hl,char_color
	cp (hl)
	jr nz,set_char_color_dif
	pop hl
	ret

set_char_color_dif

	push bc

	ld hl,char_color_pal

; First byte, paper for both pixels.

	ld b,a
	and PIX1
	ld c,a
	rlca
	or c
	ld (hl),a
	inc hl

; Second byte, paper for pixel 0, ink for 1.

	and PIX0
	ld c,a
	ld a,b
	and PIX0
	rrca
	or c
	ld (hl),a
	inc hl

; Third byte, ink for pixel 0, paper for 1.

	ld (hl),b
	inc hl

; Four byte, ink for both pixels.

	and PIX1
	ld c,a
	ld a,b
	and PIX0
	or c
	ld (hl),a

	pop bc
	pop hl
	ret

; Default, pen 0, paper 0.
char_color	.db 0

; This always have to be completely in one page and 4 byte aligned.

	.org ($+3)&$fffc
 
char_color_pal	.db 0, 0, 0, 0

; ----------------------------------
; 'drchrc' Draw Character With Color
; ----------------------------------
;	Draws a character on the screen using the current char color.
;
; In	HL address to 4 bytes of char data. DE y,x in chars.
; Saves	A,C
;
; A character is packed in 4 bytes. Each 2 bits is an index into a table that
; contains the expanded 2 pixels of each final byte. The first 2 bits will
; give the byte in pos 0,0, the next 2 bits the byte in position 1,0, the
; next 2 bits the byte in position 0,1, the next 1,1 and so on.
;
; If we have the 4 bytes aabbccdd eeffgghh iijjkkll mmnnoopp and aa gives
; byte 0, bb byte 1, cc byte 2, etc, then the final block is:
;
;  0  1
;  2  3
;  4  5
;  6  7
;  8  9
; 10 11
; 12 13
; 14 15
;
; which is the final character of 2x8 bytes, or 4x8 pixels.

drchrc	
	push af
	push bc

; Calc screen address in DE.

	call scradr

; 8 lines tall, 4 x 2 lines tall.

	ld a,4
	ld bc,char_color_pal
	
drchrc_line

	push af

; Even scanline.

	call drchrc_pixln

; Odd scanline.

	call drchrc_pixln

; Next source data.

	inc hl

	pop af
	dec a
	jr nz,drchrc_line

	pop bc
	pop af
	ret

drchrc_pixln

; Byte 0, pixels 0,1.

	xor a
	rlc (hl)
	rla
	rlc (hl)
	rla

; A is index, add to bc.

	add a,c
	ld c,a

; Draw.

	ld a,(bc)
	ld (de),a

; Restore BC.

	ld a,c
	and %11111100
	ld c,a

; Next byte in scanline.

	inc de

; Byte 1, pixels 2,3.

	xor a
	rlc (hl)
	rla
	rlc (hl)
	rla

; A is index in table, add to BC.

	add a,c
	ld c,a

; Draw.
	ld a,(bc)
	ld (de),a

; Restore BC.

	ld a,c
	and %11111100
	ld c,a

; Go to previous byte in scanline.

	dec de

; Next scanline.

	ld a,8
	add a,d
	ld d,a
	ret

; ------------------------
; 'rand' Get Random Number
; ------------------------
;	Returns a random byte.
;
; Out	A random number.
; Saves	HL, DE, BC.

rand	

	push hl
	ld a,(randp)
	ld l,a
	ld h,+randt>>8
	inc a
	ld (randp),a
	ld a,(hl)
	pop hl
	ret

#if 0

	push hl
	push bc
	ld hl,randt
	ld a,(randp)
	ld c,a
	ld b,0
	add hl,bc
	inc a
	ld (randp),a
	ld a,(hl)
	pop bc
	pop hl
	ret

; This one is taken from the Internet. x(i+1)=(5*x(i)+1) mod 256

	push bc
	ld a,(randp)
	ld b,a
	add a,a
	add a,a
	add a,b
	inc a
	ld (randp),a
	pop bc
	ret

#endif

; The rand seed.
randp	.db 0

	.org ($+255)&$ff00

#include "rndnums.asm"

; -------------
; 'install_irq'
; -------------
;	Installs an interrupt routine and enables interrupts.
;
; In	HL interrupt routine address.
; Saves	BC, DE, HL.

install_irq
	ld a,$c3
	ld ($38),a
	ld ($39),hl
	im 1
	ei
	ret

; --------
; 'clrscr'
; --------
;	Fills the screen with two pixels (one byte). To clear to the same
; color specify the same pen and paper, for example PEN0|PAPER0.
;
; In	A 2-pixel byte.

clrscr	

; We have 8 2k blocks.

	ld e,8
	ld hl,vram

clrscr_block

; Clear the visible bytes in the 2k block.

	push af
	push hl
	push de
	ld bc,SCRWB*SCRHC
	call memset
	pop de
	pop hl
	pop af

; Next 2k block.

	ld bc,2048
	add hl,bc
	dec e
	jr nz,clrscr_block
	ret

; ---------------------
; 'clrwin' Clear window
; ---------------------
;	Clears some rect of the screen to a 2-pixel color.
;
; In	A color. D,E y,x char coords. B,C height,width in chars.

clrwin	

; HL screen address.

	push af
	call scradr
	ex de,hl
	pop af

; Prepare to copy width*2 byte - 1.

	sla c
	dec c

clrwin_char_row

	push bc
	push hl

; 8 scanlines.

	ld b,8

clrwin_scan

	push bc
	push hl

; Fill scanline.

	ld (hl),a
	ld e,l
	ld d,h
	inc de
	ld b,0
	ldir

; Next scanline.

	pop hl
	ld bc,2048
	add hl,bc
	
	pop bc
	djnz clrwin_scan

; Next character row.

	pop hl
	ld bc,SCRWB
	add hl,bc

	pop bc
	djnz clrwin_char_row
	ret

; ------
; 'beep'
; ------
;	Simulates the BEEP in the CPC.
;
; In	HL AY period. DE ms to play sound. 
; Saves	BC.

beep

; Active AY tone C with period.

	ld (ay_c),hl
	ld hl,ay_mixer
	res AY_MIX_TONEC_B,(hl)

; Wait that number of ms.

beep_loop

	ld a,248		; 2 us
	
beep_loop1

; Almost 1 ms.

	dec a			; 1 us
	jr nz,beep_loop1	; 3/2 us

; With this and re-entering the loop, we add up to 1 ms.

	dec de			; 2 us
	ld a,d			; 1 us
	or e			; 1 us
	jr nz,beep_loop		; 3/2 us

; Shut AY C channel.

	set AY_MIX_TONEC_B,(hl)
	ret

; ----------
; 'init_cpc'
; ----------
;	Sets the screen as the spectrum screen, in mode 0, that is 32x24 CRTC
; characters, or 64x192 bytes, or 128x192 pixels (1 pixel in CPC, 2 in ZX).
;	Disables roms.

init_cpc

	ld hl,init_cpc_t
	ld a,255

init_cpc_loop

	cp (hl)
	jr z,init_cpc_mode
	ld b,$bc
	ld c,(hl)
	out (c),c
	inc hl
	inc b
	ld c,(hl)
	out (c),c
	inc hl
	jr init_cpc_loop

init_cpc_mode

; Set mode 2, disable roms.

	ld bc,+$7f00+%10001100
	out (c),c
	ret

init_cpc_t

; Width of screen in CRTC characters.

	.db 1, SCRWC

; Center horizontal position.

	.db 2, 42

; Height of screen in CRTC characters.

	.db 6, SCRHC

; Center vertical position.

	.db 7, 30

; End of table marker.

	.db 255

; ---------
; 'set_pal'
; ---------
;	Set hardware palette.
;
; In	HL address of table with 16 bytes which is the hardware color for each
;	pen with 64 decimal added.
; Saves	D.

set_pal

; Start selecting pen 0.

	ld bc,$7f00
	ld e,0

; 16 colors.

	ld a,16

set_pal_loop

; Select color number.

	out (c),e

; Set color.

	ld c,(hl)
	out (c),c

; Next color.

	inc e
	inc hl
	dec a
	jr nz,set_pal_loop
	ret

; ---------------
; 'set_pal_color'
; ---------------
;	Sets the ink for a given pen.
;
; In	E palette index, A border color.
; Saves	HL, BC, DE

set_pal_color

	push bc

; Select pen.

	ld bc,$7f00
	out (c),e

; Set color.

	or $40
	out (c),a

	pop bc
	ret

; --------------------
; 'chadr' Char Address
; --------------------
;	Gets an address of a 4 byte character.
;
; In	HL Address of char 0 data. A char number.
; Out	HL address of character data.
; Saves	BC, DE

chadr4	push bc
	ld b,h
	ld c,l
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,bc
	pop bc
	ret

; ----------------------------------------------------------------------------
; Input
; ----------------------------------------------------------------------------

; Hardware keys. These are filled by an interrupt routine, calling pollhk.
hwkeys	.fill 10, 0

; Real state of keys for each of the 10 rows (bit set pressed).
rkeys	.fill 10, 0

; Last frame keys state.
skeys	.fill 10, 0

; First pressed keys. Keys that have been pressed and weren't last frame.
fkeys	.fill 10, 0

; ---------------------
; 'pollk' Poll keyboard
; ---------------------
;	Get the state of all rows in two buffers, rkeys and fkeys.

pollk	

; Save real keys in saved keys.

	ld hl,rkeys
	ld de,skeys
	ld bc,10
	ldir

; Reset first pressed keys.

	xor a
	ld hl,fkeys
	ld bc,10
	call memset

; Copy hardware keys to real keys.

	ld hl,hwkeys
	ld de,rkeys
	ld bc,10
	ldir

; Calculate which keys are pressed and weren't the last time, and save in
; first pressed keys.

	push ix
	ld b,10
	ld de,rkeys
	ld hl,skeys
	ld ix,fkeys

pollk_calc

	ld a,(de)
	xor (hl)
	ex de,hl
	and (hl)
	ex de,hl
	ld (ix+0),a

	inc de
	inc hl
	inc ix
	djnz pollk_calc

	pop ix
	ret

; ----------------------------
; 'pollhk' Poll hardware keys.
; ----------------------------
;
;	Get the real state of all rows of keys in hwkeys. Uses the hardware
; so interrupts must be disable or (as we do) call it on an interrupt routine.

pollhk

	ld hl,hwkeys

; Configure PPI port A as output.
; (It should be already).

	; ld bc,+PPI_CTRL+$82
	; out (c),c

; Select PSG register 14 which is connected to the keyboard.

; 1 Write 14 in PPI port A.

	ld bc,+PPI_A+14
	out (c),c

; 2 Use PPI port C 'select PSG register' function.

	ld bc,+PPI_C+$c0
	out (c),c

; Use PPI port C 'PSG inactive' function. Needed for CPC+.

	xor a
	out (c),a

; Configure PPI port A as input.

	ld bc,+PPI_CTRL+$92
	out (c),c

; For 10 keyboard lines.

	ld d,10

; C always PPI A.

	ld c,PPI_AH

; PPI C 'Read PSG register' + first keyboard line.

	ld e,$40

pollhk_loop


; Select in PPI C the function: read + keyboard line number.

	ld b,PPI_CH
	out (c),e

; Get the data from PPI A.

	ld b,c
	in a,(c)

; Complement to set 1 active, 0 inactive.

	cpl

; Save in hwkeys.

	ld (hl),a
	inc hl

	inc e
	dec d
	jr nz,pollhk_loop

; Restore PPI port A as output.

	ld bc,+PPI_CTRL+$82
	out (c),c

; Set PSG 'inactive' using PPI port C.

	ld bc,PPI_C
	out (c),c
	ret

; ------------------------------
; 'iskeyfp' Is key first pressed
; ------------------------------
;	Checks if a key has been pressed this frame and wasn't last frame.
;
; In	A bits aaa0 bbbb, where b is keyboard row to check and aaa is the
;	number of bit to check.
; Out	ZF=0 if the key is pressed.
; Saves	BC, DE, HL.

iskeyfp	push hl
	ld hl,fkeys
	call chkkey
	pop hl
	ret

; ---------
; 'keydown'
; ---------
;	Checks if a key is pressed.
;
; In	A bits aaa0 bbbb, where b is keyboard row to check and aaa is the
;	number of bit to check.
; Out	ZF=0 if the key is pressed.
; Saves	BC, DE, HL.

keydown	push hl
	ld hl,rkeys
	call chkkey
	pop hl
	ret

; ------------------
; 'chkkey' Check key
; ------------------
;	Checks for a key in real keys or first pressed keys.
;
; In	A bits aaa0 bbbb, where b is keyboard row to check and aaa is the
;	number of bit to check.
;	HL either rkeys or fkeys.
; Out	ZF=0 if the key is pressed.
; Saves	BC, DE.

chkkey	push de
	ld e,a

; Get line byte.

	and 15
	call getbt
	ld d,a

; Expand key bits.

	ld a,e
	rlca
	rlca
	rlca
	and 7
	ld hl,bitexp_t
	call getbt

; Check if the bit is set.

	and d
	pop de
	ret

bitexp_t
	.db %00000001
	.db %00000010
	.db %00000100
	.db %00001000
	.db %00010000
	.db %00100000
	.db %01000000
	.db %10000000
	
; --------
; 'getkey'
; --------
;	Gets the keycode of a key that has been pressed and wasn't before.
;
; Out	A 0 if no key first pressed, or key code if key first pressed.
; Saves	BC, DE, HL.

getkey	

	push bc
	push de
	push hl

	ld hl,fkeys
	ld b,10

getkey_loop

	xor a
	or (hl)
	jr nz,getkey_any
	inc hl
	djnz getkey_loop
	jr getkey_end

getkey_any

; Build key code.

	ld c,a

; Key line.

	ld a,10
	sub b
	ld e,a

; Ultra trick to select the leftmost bit that is active and only leave it and
; reset the others.

	ld a,c
	dec a
	and c
	xor c

; Find in table.

	ld hl,bitexp_t
	ld bc,9
	cpir

; Bit number is 8 - c.

	ld a,8
	sub c

; Code is (Bit number << 5) | Key line.

	rrca
	rrca
	rrca
	or e

getkey_end

	pop hl
	pop de
	pop bc
	ret

; ------------------
; 'polli' Poll input
; ------------------
;
;	This intends to be a faster way to check input than pollk, for
; gameplay. Uses rinput and finput to set only 8 actions that can be on or off.
; Handles joysticks and keyboard, being transparent to the code.
; 'poll_handler' must contain the function to call: poll_keyboard,
; poll_joystick1, poll_joystick2.

polli	call pollk
	ld hl,(poll_handler)
	jp (hl)

; Handler to set for keyboard or joysticks.

poll_handler	.dw poll_keyboard

; Real state of inputs, first pressed inputs, saved inputs.

rinput	.db 0
finput	.db 0
sinput	.db 0

; Key table to set by game (set_keys).
; Ordered as Kempston joystick.

keyt	
	.db KEY_K&15, 1<<(KEY_K>>5)	; K
	.db KEY_H&15, 1<<(KEY_H>>5)	; H
	.db KEY_J&15, 1<<(KEY_J>>5)	; J
	.db KEY_U&15, 1<<(KEY_U>>5)	; U
	.db KEY_A&15, 1<<(KEY_A>>5)	; A
	.db KEY_S&15, 1<<(KEY_S>>5)	; S
	.db 0, 0
	.db 0, 0

joy1_keyt
	.db KEY_J1R&15, 1<<(KEY_J1R>>5)
	.db KEY_J1L&15, 1<<(KEY_J1L>>5)
	.db KEY_J1D&15, 1<<(KEY_J1D>>5)
	.db KEY_J1U&15, 1<<(KEY_J1U>>5)
	.db KEY_J11&15, 1<<(KEY_J11>>5)
	.db KEY_S&15, 1<<(KEY_S>>5)	; S
	.db 0, 0
	.db 0, 0

joy2_keyt
	.db KEY_J2R&15, 1<<(KEY_J2R>>5)
	.db KEY_J2L&15, 1<<(KEY_J2L>>5)
	.db KEY_J2D&15, 1<<(KEY_J2D>>5)
	.db KEY_J2U&15, 1<<(KEY_J2U>>5)
	.db KEY_J21&15, 1<<(KEY_J21>>5)
	.db KEY_S&15, 1<<(KEY_S>>5)	; S
	.db 0, 0
	.db 0, 0

; ---------------
; 'poll_keyboard'
; ---------------
;	Keyboard poll handler.

poll_keyboard
	ld hl,keyt
	jp poll_kb

; ----------------
; 'poll_joystick1'
; ----------------
;	Joystick 1 poll handler.

poll_joystick1
	ld hl,joy1_keyt
	jp poll_kb

; ----------------
; 'poll_joystick2'
; ----------------
;	Joystick 2 poll handler.

poll_joystick2
	ld hl,joy2_keyt
	jp poll_kb

; ---------
; 'poll_kb'
; ---------
;	Checks keyboard.

; In	HL table to check.

poll_kb call input_pre
	ld e,0
	ld bc,+(KEYTSZ<<8)+1
	call poll_key_table
	jp input_post

; ----------------
; 'poll_key_table'
; ----------------
;
; In	HL key table. C first bit to set in inputs. B n keys to check.
;	E should be 0 on entry or already contain some bits on.
; Out	E with bits set on keys pressed.

; Read row.

poll_key_table

	ld a,(hl)
	inc hl

	push hl
	ld hl,rkeys
	call getbt
	pop hl

; Check specific key.

	and (hl)
	inc hl
	jr z,poll_key_table_2

; The key is on, set bit in e.

	ld a,e
	or c
	ld e,a

poll_key_table_2

; Next key.

	rlc c
	djnz poll_key_table
	ret

; -----------
; 'input_pre'	
; -----------

input_pre

; Reset first pressed input.

	xor a
	ld (finput),a

; Save input.

	ld a,(rinput)
	ld (sinput),a
	ret

; ------------
; 'input_post'
; ------------
;
; In	E bits set for active inputs.

input_post

; Set the real key states.

	ld a,e
	ld (rinput),a

; Set keys first pressed.

	ld hl,sinput
	xor (hl)
	ld hl,rinput
	and (hl)
	ld (finput),a
	ret

; ----------
; 'set_keys'
; ----------
;	Sets the keys to use for gameplay (in keyt and sincl_keyt).
;
; In	HL list of KEYTSZ keycodes ordered as in kempston joystick.
	
set_keys

	ld de,keyt
	ld b,KEYTSZ

set_keys_loop

	ld a,(hl)

; Put row.

	and 15
	ld (de),a
	inc de

; Get number of bit.

	ld a,(hl)
	rlca
	rlca
	rlca
	and 7

; Get bit mask.

	push hl
	ld hl,bitexp_t
	call getbt
	pop hl

; Set bit mask.

	ld (de),a
	inc de

	inc hl
	djnz set_keys_loop

; Now, copy in joystick tables.

	ld hl,keyt+10
	ld de,joy1_keyt+10
	ld bc,6
	ldir

	ld hl,keyt+10
	ld de,joy2_keyt+10
	ld bc,6
	ldir
	ret

; ---------------
; 'kc2char'
; ---------------
;	Transforms a keycode into a character code. 
;
; In	A keycode.
; Out	A character code.
; Saves	BC.

kc2char

; Transform to get a linear code.

	rlca
	rlca
	rlca

; Find in table.

	ld hl,kc2char_t
	call getbt	
	ret

kc2char_t
	
	.db 0	; KEY_CUP	.equ %00000000	; Cursor up
	.db 0	; KEY_CRI	.equ %00100000	; Cursor right
	.db 0	; KEY_CDO	.equ %01000000	; Cursor down
	.db 0	; KEY_F9	.equ %01100000
	.db 0	; KEY_F6	.equ %10000000
	.db 0	; KEY_F3	.equ %10100000
	.db 0	; KEY_ENT	.equ %11000000	; Enter
	.db 0	; KEY_FDO	.equ %11100000

	.db 0	; KEY_CLE	.equ %00000001	; Cursor left
	.db 0	; KEY_CPY	.equ %00100001	; Copy
	.db 0	; KEY_F7	.equ %01000001
	.db 0	; KEY_F8	.equ %01100001
	.db 0	; KEY_F5	.equ %10000001
	.db 0	; KEY_F1	.equ %10100001
	.db 0	; KEY_F2	.equ %11000001
	.db 0	; KEY_F0	.equ %11100001

	.db 0	; KEY_CLR	.equ %00000010	; CLR
	.db '['	; KEY_LBR	.equ %00100010	; [ Left bracket
	.db 0	; KEY_RET	.equ %01000010	; Return
	.db ']'	; KEY_RBR	.equ %01100010	; ] Right bracket
	.db 0	; KEY_F4	.equ %10000010
	.db 0	; KEY_SHI	.equ %10100010	; Shift
	.db 92	; KEY_BSL	.equ %11000010	; Back slash \
	.db 0	; KEY_CTR	.equ %11100010	; Control

	.db '^'	; KEY_EXP	.equ %00000011	; ^ Exponent
	.db '-'	; KEY_MIN	.equ %00100011	; - Minus sign
	.db '@'	; KEY_AT	.equ %01000011	; @ at sign
	.db 'P'	; KEY_P	.equ %01100011
	.db ';'	; KEY_SCL	.equ %10000011	; Semicolon ;
	.db ':'	; KEY_CLN	.equ %10100011	; : Colon
	.db '/'	; KEY_SLA	.equ %11000011	; Slash /
	.db '.'	; KEY_PER	.equ %11100011	; .

	.db '0'	; KEY_0	.equ %00000100
	.db '9'	; KEY_9	.equ %00100100
	.db 'O'	; KEY_O	.equ %01000100
	.db 'I'	; KEY_I	.equ %01100100
	.db 'L'	; KEY_L	.equ %10000100
	.db 'K'	; KEY_K	.equ %10100100
	.db 'M'	; KEY_M	.equ %11000100
	.db ','	; KEY_COM	.equ %11100100	; ,

	.db '8'	; KEY_8	.equ %00000101
	.db '7'	; KEY_7	.equ %00100101
	.db 'U'	; KEY_U	.equ %01000101
	.db 'Y'	; KEY_Y	.equ %01100101
	.db 'H'	; KEY_H	.equ %10000101
	.db 'J'	; KEY_J	.equ %10100101
	.db 'N'	; KEY_N	.equ %11000101
	.db ' '	; KEY_SPC	.equ %11100101

	.db '6'	; KEY_6	.equ %00000110
	.db '5'	; KEY_5	.equ %00100110
	.db 'R'	; KEY_R	.equ %01000110
	.db 'T'	; KEY_T	.equ %01100110
	.db 'G'	; KEY_G	.equ %10000110
	.db 'F'	; KEY_F	.equ %10100110
	.db 'B'	; KEY_B	.equ %11000110
	.db 'V'	; KEY_V	.equ %11100110

	.db '4'	; KEY_4	.equ %00000111
	.db '3'	; KEY_3	.equ %00100111
	.db 'E'	; KEY_E	.equ %01000111
	.db 'W'	; KEY_W	.equ %01100111
	.db 'S'	; KEY_S	.equ %10000111
	.db 'D'	; KEY_D	.equ %10100111
	.db 'C'	; KEY_C	.equ %11000111
	.db 'X'	; KEY_X	.equ %11100111

	.db '1'	; KEY_1	.equ %00001000
	.db '2'	; KEY_2	.equ %00101000
	.db 0	; KEY_ESC	.equ %01001000
	.db 'Q'	; KEY_Q	.equ %01101000
	.db 0	; KEY_TAB	.equ %10001000
	.db 'A'	; KEY_A	.equ %10101000
	.db 0	; KEY_CAP	.equ %11001000	; Caps lock
	.db 'Z'	; KEY_Z	.equ %11101000

	.db 0	; KEY_J1U	.equ %00001001	; Joystick 1 up
	.db 0	; KEY_J1D	.equ %00101001	; Joystick 1 down
	.db 0	; KEY_J1L	.equ %01001001	; Joystick 1 left
	.db 0	; KEY_J1R	.equ %01101001	; Joystick 1 right
	.db 0	; KEY_J11	.equ %10001001	; Joystick 1 fire 1
	.db 0	; KEY_J12	.equ %10101001	; Joystick 1 fire 2
	.db 0	; KEY_J13	.equ %11001001	; Joystick 1 fire 3
	.db 0	; KEY_DEL	.equ %11101001

; ----------------------------
; 'preimt' Prepare Image Table
; ----------------------------
;	Prepares an Image Table. Takes the first image, copies into the second
;	with one extra column on the right and shifts one CPC pixel to the
;	right this second one.
;
; In	HL Image Table pointer.

preimt

; Set IX as Image Table.

	push hl
	pop ix

; Get first image address.

	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl

; Expand first image into second.

	inc ix
	inc ix
	ld e,(ix+0)
	ld d,(ix+1)
	push de
	ld a,1
	call cppad
	pop hl
	call rotar
	ret

; --------------------
; 'rotar' Rotate Right
; --------------------
;	Shifts an image one pixel to the right.
;
; In	HL Image address.

rotar

; Load B width, C height.

	ld b,(hl)
	inc hl
	ld c,(hl)
	inc hl

rotar2
	push bc
	ld e,0

rotar1
	ld a,(hl)
	ld d,a
	and PIX0
	rrca
	or e
	ld (hl),a
	inc hl
	ld a,d
	and PIX1
	rlca
	ld e,a
	djnz rotar1
	pop bc
	dec c
	jr nz,rotar2
	ret

#include "ay.asm"
#include "bbuf_cpc.asm"
#include "bbuf.asm"

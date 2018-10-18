; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ------------------
; 'set_border_color'
; ------------------
;	Sets the border color.
;
; In	A color.
; Saves	DE, HL.

set_border_color

	and 7
	ld (border_color),a
	out ($fe),a
	ret

border_color	.db 0

; ----------------------------
; 'scradr' Calc Screen Address
; ----------------------------
;
; In	DE y,x position in characters.
; Out	DE screen address.
; Saves	HL, BC

; A screen address has the form 010B B000 LLLC CCCC and on entry we have
; 000B BLLL 000C CCCC.

scradr	ld a,d
	and 7
	rrca
	rrca
	rrca
	or e
	ld e,a
	ld a,d
	and $18
	or $40
	ld d,a
	ret

; -----------------
; 'set_char_color'
; -----------------
;	Sets the char color for the next drawing operations.
;
; In	A ink color + paper color [ + LIT ] [ + FLASH ]
; Saves	BC, DE, HL.

set_char_color
	ld (char_color),a
	ret

char_color	.db 0

; ----------------------------------
; 'drchrc' Draw Character With Color
; ----------------------------------
;	Draws a character on the screen using the current char color.
;
; In	HL address to 8 bytes of char data. DE y,x in chars.
; Saves	A,C

drchrc	push af
	call scradr

; Draw character.

	push de
	ld b,8
drchrc1	ld a,(hl)
	ld (de),a
	inc hl
	inc d
	djnz drchrc1
	pop hl

; Draw attribute.

	ld a,h
	rrca
	rrca
	rrca
	and 7
	or $58
	ld h,a
	ld a,(char_color)
	ld (hl),a
	pop af
	ret

; ------------------------
; 'rand' Get Random Number
; ------------------------
;	Returns a random byte.
;
; Out	A random number.
; Saves	HL, DE, BC.

rand	

;	ld a,r
;	ret

; Run through the ROM using Random Pointer and take next value.
; From address $0500 seems more random.

	push hl
	ld a,(randp)
	ld l,a
	ld h,$05
	inc a
	ld (randp),a
	ld a,(hl)
	pop hl
	ret

; This one is taken from the Internet. x(i+1)=(5*x(i)+1) mod 256
; To be tested later.
;	ld a,seed
;	ld b,a
;	add a,a
;	add a,a
;	add a,b
;	inc a

; 0-255. Incremented each time we call rand.
randp	.db 0

; -------------
; 'install_irq'
; -------------
;	Installs an interrupt routine and enables interrupts.
;
; In	HL interrupt routine address.

install_irq

; Install a jump to our interrupt routine at address INTERR.

	ld a,$c3
	ld (INTERR),a
	ld (INTERR+1),hl

; Create interrupt table and enable interrupts.

	ld hl,INTTAB
	ld bc,257
	ld a,h
	ld i,a
	ld a,INTERR&255
	call memset
	im 2
	ei
	ret

; Interrupt JP address.
INTERR	.equ $fdfd
INTTAB	.equ $fe00

; ---------------------
; 'clrscr' Clear Screen
; ---------------------
;	The screen is cleared and attributes are set to a color.
;
; In	A color.

clrscr	push af
	ld hl,vram
	ld bc,VRAMSZ
	xor a
	call memset
	ld hl,aram
	ld bc,ARAMSZ
	pop af
	call memset
	ret

; ---------------------
; 'clrwin' Clear window
; ---------------------
;	Clears some rect of the screen to a color.
;
; In	A color. D,E y,x char coords. B,C height,width in chars.

clrwin	

	call set_char_color 

; Get in HL the address of SPACE character in ROM.

	ld hl,$3d00

clrwiny

; For all rows.

	push bc
	push de

clrwinx

; For all columns.

	push de
	push hl
	call drchrc
	pop hl
	pop de
	inc e
	dec c
	jr nz,clrwinx

; Next row.

	pop de
	pop bc
	inc d
	djnz clrwiny
	ret

; ------
; 'beep'
; ------
; 	This is the ROM BEEPER routine, but we don't want it to enable
; interrupts at end and we use our own boder_color variable.
;
; In	HL period = 437500 / note_freq - 29.5 (or - 30.125 says the ROM)
;	DE duration = note_freq * secs

beep	push ix
	ld a,l
	srl l
	srl l
	cpl
	and $03
	ld c,a
	ld b,0
	ld ix,beep1
	add ix,bc
	ld a,(border_color)
	or $08
beep1	nop
	nop
	nop
	inc b
	inc c
beep5	dec c
	jr nz,beep5
	ld c,$3f
	dec b
	jp nz,beep5
	xor $10
	out ($fe),a
	ld b,h
	ld c,a
	bit 4,a
	jr nz,beep6
	ld a,d
	or e
	jr z,beep7
	ld a,c
	ld c,l
	dec de
	jp (ix)
beep6	ld c,l
	inc c
	jp (ix)
beep7	pop ix
	ret

; -----------------------
; 'romchar' ROM character
; -----------------------
;	Returns the address of character data in ROM.
;
; In	A character code between 32 and 127.
; Out	HL address of character data.
; Saves	BC, DE

romchar

; $3d00 is address of char 32 (space) in ROM.

	sub 32
	ld hl,$3d00
	jp chadr

; -------------------------------
; 'atradr' VRAM Attribute Address
; -------------------------------
;	Given position in characters, calculates the corresponding vram
;	attribute adddress.
;
; In	D,E y,x in character coordinates.
; Out	DE vram attribute address.
; Saves	HL, BC

; An attribute address has the form 010110BB LLLC CCCC and on entry
; we have 000B BLLL 000C CCCC .

atradr	ld a,d
	rrca
	rrca
	rrca
	ld d,a
	and $e0
	or e
	ld e,a
	ld a,d
	and 3
	or $58
	ld d,a
	ret

; ---------------------
; 'pollk' Poll keyboard
; ---------------------
;	Get the state of all rows in two buffers, rkeys and fkeys.
;

pollk	

	push ix
	ld hl,skeys
	ld de,rkeys
	ld ix,fkeys

; In C we are going to rotate a 0 bit to select one of the 8 keyboard rows.

	ld c,$fe

; 8 keyboard rows.

	ld b,8

pollk1
	
; Reset first pressed keys.

	ld (ix+0),0

; Save real keys in saved keys.

	ld a,(de)
	ld (hl),a

; Get row state.

	ld a,c
	in a,(KBPORT)

; Always 1 in 3 upper rows, just in case...

	or $e0

; Complement, only 1 for pressed keys, and save in real keys buffer.

	cpl
	ld (de),a

; Calculate which keys are pressed and weren't the last time, and save in
; first pressed keys.

	xor (hl)
	ex de,hl
	and (hl)
	ex de,hl
	ld (ix+0),a

; Next row.

	inc hl
	inc de
	inc ix
	rlc c
	djnz pollk1
	pop ix
	ret

; Real state of keys for each of the 8 rows (bit set pressed).
rkeys	.fill 8, 0

; Last frame keys state.
skeys	.fill 8, 0

; First pressed keys. Keys that have been pressed and weren't last frame.
fkeys	.fill 8, 0

; ------------------------------
; 'iskeyfp' Is key first pressed
; ------------------------------
;	Checks if a key has been pressed this frame and wasn't last frame.
;
; In	A bits aaaaa bbb, where b is keyboard row to check and aaaaa has one
;	bit 1 and the rest 0 for the key we want to check.
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
; In	A bits aaaaa bbb, where b is keyboard row to check and aaaaa has one
;	bit 1 and the rest 0 for the key we want to check.
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
; In	A bits aaaaa bbb, where b is keyboard row to check and aaaaa has one
;	bit 1 and the rest 0 for the key we want to check.
;	HL either rkeys or fkeys.
; Out	ZF=0 if the key is pressed.
; Saves	BC, DE.

chkkey	push bc
	push af
	and 7
	ld c,a
	ld b,0
	add hl,bc
	pop af
	rrca
	rrca
	rrca
	and $1f
	and (hl)
	pop bc
	ret

; --------
; 'getkey'
; --------
;	Gets the keycode of a key that has been pressed and wasn't before.
;
; Out	A 0 if no key first pressed, or key code if key first pressed.
; Saves	BC, DE, HL.

getkey	

	push bc
	push hl

	ld hl,fkeys
	ld b,8

getkey_loop

	xor a
	or (hl)
	jr nz,getkey_any
	inc hl
	djnz getkey_loop
	jr getkey_end

getkey_any
	
; A key was pressed, take first.

; Ultra trick to select the leftmost bit that is active and only leave it and
; reset the others.

	ld c,a
	dec a
	and c
	xor c

; Build key code (A << 3) | (8 - B)

	rlca
	rlca
	rlca
	ld c,a
	ld a,8
	sub b
	or c

getkey_end
	pop hl
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
; poll_sinclair1, poll_kempston.

polli	ld hl,(poll_handler)
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
	.db %10111111, %00000100	; K
	.db %10111111, %00010000	; H
	.db %10111111, %00001000	; J
	.db %11011111, %00001000	; U
	.db %11111101, %00000001	; A
	.db %11111101, %00000010	; S
	.db 0, 0
	.db 0, 0

; For the Sinclair Joystick, that maps on keys, we use this table.
; 'set_keys' modify this table as well.
; Ordered as Kempston joystick.

sincl1_keyt
	.db %11101111, %00001000	; 7
	.db %11101111, %00010000	; 6
	.db %11101111, %00000100	; 8
	.db %11101111, %00000010	; 9
	.db %11101111, %00000001	; 0
	.db %11111101, %00000010	; S
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
; 'poll_sinclair1'
; ----------------
;	Sinclair 1 joystick handler.

poll_sinclair1
	ld hl,sincl1_keyt
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

; ---------------
; 'poll_kempston'
; ---------------
;	Kempston joystick handler.

poll_kempston

	call input_pre

; Read kempston.

	ld bc,31
	in a,(c)
	and $1f
	ld e,a

; Don't poll the rest of keys if only need 5.

	ld a,KEYTSZ
	cp 5
	jp z,input_post
	
; Poll the rest of keys.

	ld hl,keyt+10
	ld bc,+((KEYTSZ-5)<<8)+(1<<5)
	call poll_key_table

	jp input_post

; ----------------
; 'poll_key_table'
; ----------------
;
; In	HL key table. C first bit to set in inputs. B n keys to check.
;	E should be 0 on entry or already contain some bits on.
; Out	E with bits set on keys pressed.

poll_key_table

; Read row.

	ld a,(hl)
	in a,(KBPORT)
	inc hl
	cpl

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
; In	HL list of keycodes ordered as in kempston joystick.

set_keys

	ld de,keyt
	ld c,KEYTSZ

set_keys_loop

	ld a,(hl)

; Select bits for row number (0-7).

	and 7

; Set row numer from 1-8.

	inc a

; We will rotate row times.

	ld b,a

; Put leftmost bit 0.

	ld a,$7f

set_keys_rotate

; Calculate row, all bits 1 except the numbered B.

	rlca
	djnz set_keys_rotate

; Set in table the row.

	ld (de),a
	inc de

; Now set the key code.

	ld a,(hl)
	rrca
	rrca
	rrca
	and $1f
	
; Load in table.

	ld (de),a
	inc de

; Next key.

	inc hl
	dec c
	jr nz,set_keys_loop

; Now, copy in sinclair joystick table.

	ld hl,keyt+10
	ld de,sincl1_keyt+10
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

; The 3 lower bits complemented.

	ld e,a
	cpl
	and 7
	ld d,a

; For the upper 5 bits, we must see where the bit set is.

	ld a,e
	ld e,255

kc2char_count

	rlca
	inc e
	jr nc,kc2char_count
	
	ld a,e
	rlca
	rlca
	rlca
	or d
	
; Get character code form ROM table at $0205.

	ld e,a
	ld d,0
	ld hl,$0205
	add hl,de
	ld a,(hl)
	ret

; ----------------------------
; 'preimt' Prepare Image Table
; ----------------------------
;	Prepares an Image Table. Takes the first image, copies into the second
;	with one extra column on the right, shifts one pixel left this second
;	one and builds the rest each one shifted one more position to the
;	right.
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

; Rotate once, then copy and rotate.

	ld b,7
	push bc
	jr preimt1

; Copy.

preimt2	push bc
	inc ix
	inc ix
	ld e,(ix+0)
	ld d,(ix+1)
	push de
	xor a
	call cppad
	pop hl

; Rotate.

preimt1	push hl
	call rotar
	pop hl
	pop bc
	djnz preimt2
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

; Shift each line to the right.

	ld a,b
rotar2	or a
rotar1	rr (hl)
	inc hl
	djnz rotar1
	ld b,a
	dec c
	jr nz,rotar2
	ret

#include "ay.asm"
#include "bbuf_zx.asm"
#include "bbuf.asm"

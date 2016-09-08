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

; -----------------
; 'jphl' Juml to HL
; -----------------
;	This can be used with 'call jphl' to call the routine contained in HL.

jphl	jp (hl)

; -------------
; 'modb' Modulo
; -------------
;	Calculates A mod E. If E is 0, returns A, that is, acts as A mod 256.
;
; In	A, E.
; Out	A = A mod E
; Saves HL, BC, DE

; Works by subtracting E, E * 2, E * 4, ... and again E, E * 2, E * 4 until
; no more can be subtracted.

modb

; Check if E is 0.

	rlc e
	jr nz,modb3

; It's 0.

	rrc e
	ret

modb3

; Not 0. Restore and continue.

	rrc e
modb4	push de
modb1	cp e
	jr c,modb2
	sub e
	sla e
	jr nz,modb1
modb2	pop de
	cp e
	jr nc,modb4
	ret

; -----------------------
; 'randr' Random In Range
; -----------------------
;	Calcs a random number in range [D,E].
;
; In	[D,E] range.
; Out	A random number.
; Saves	HL, BC

randr	inc e
	ld a,e
	sub d
	ld e,a
	call rand
	call modb
	add a,d
	ret

; -------------------
; 'memset' Memory Set
; -------------------
;	Like the C function. Sets memory to a value.
;
; In	HL address of first byte. BC how many to set. A value to set to.

memset

; Save value to set in e.

	ld e,a

; If 0 return.

	ld a,b
	or c
	ret z

; Set first value.

	ld (hl),e

; We are going to set BC - 1, as the first is already set.

	dec bc

; If we are done return.

	ld a,b
	or c
	ret z

; Copy from the previous to the next byte.

	ld d,h
	ld e,l
	inc de
	ldir
	ret

; ----------------------------
; 'getwt' Get Word in Table
; ----------------------------
;	Implements LD HL,(HL+A*2)
;
; In	A index in table. HL table.
; Out	HL word at HL+A*2.
; Saves	AF, DE, BC.

getwt	push af
	push bc
	ld c,a
	ld b,0
	add hl,bc
	add hl,bc
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	pop bc
	pop af
	ret

; ----------------------------
; 'getbt' Get Byte in Table
; ----------------------------
;	Implements LD A,(HL+A)
;
; In	A index in table. HL table.
; Out	A byte.
; Saves	HL, DE, BC.

getbt	push hl
	add a,l
	ld l,a
	ld a,h
	adc a,0
	ld h,a
	ld a,(hl)
	pop hl
	ret

; ------
; 'loop'
; ------
;	Loops.
;
; In	BC cicles.
; Out	BC 0.
; Saves DE, HL.

loop	dec bc
	ld a,c
	or b
	jr nz,loop
	ret

; --------------------
; 'chadr' Char Address
; --------------------
;	Gets an address of a 8 byte character.
;
; In	HL Address of char 0 data. A char number.
; Out	HL address of character data.
; Saves	BC, DE

chadr	push bc
	ld b,h
	ld c,l
	ld l,a
	ld h,0
	add hl,hl
	add hl,hl
	add hl,hl
	add hl,bc
	pop bc
	ret
 
; -------------------
; 'drstr' Draw String
; -------------------
;	Draws a string on VRAM.
;	A string is a series of characters from 32 to 127.
;	If 0 is encountered, it signals the end of the string.
;	If 1 is encountered, the next byte is a color to paint the rest
;	of the string.
;
; In	HL string address. DE y,x position in characters. A color.

drstr

; Set initial color.

	call set_char_color

; Get character or command. Return if 0.

drstr2	ld a,(hl)
	inc hl
	or a
	ret z
	cp 1
	jr nz,drstr1

; Set new color.

	ld a,(hl)
	inc hl
	call set_char_color
	jr drstr2

drstr1

; Find address in rom.

	push hl
	call font_chadr
	push de

; Draw draw.

	call drchrc

	pop de
	inc e
	pop hl
	jr drstr2

; ----------------------
; 'strlen' String length
; ----------------------
;	Calculates the length of a string.
;
; In	HL str address.
; Out	B len.
; Saves	DE, C.

strlen	ld b,0

strlen_next

	ld a,(hl)
	inc hl

; If 0 end of string.

	or a
	ret z

; If 1 the next byte is a color.

	cp 1
	jr z,strlen_color

; Increment length.

	inc b
	jr strlen_next

strlen_color
	inc hl
	jr strlen_next
	
; -------------------
; 'addnum' Add number
; -------------------
;	Decimal addition. The numbers are stored each digit in a byte.
; The number in address pointed by HL is added to the one pointed by DE
; and stores in this same sequence pointed by DE.
;
; If HL points to these bytes 			0019
; And DE to these             			0001
; Then the bytes pointed by DE will contain	0020
;
; In	HL array of digits. DE array of digits. B number of digits.
; Saves	None.

addnum

; Go to the end of the numbers.

	ld c,b
	ld b,0
	dec c
	add hl,bc
	ex de,hl
	add hl,bc
	ex de,hl
	ld b,c
	inc b

; Reset CY.

	or a

addnum1 ld a,(de)
	adc a,(hl)
	cp 10
	jr c,addnum0

; The sum is equal or more than 10.

	sub 10
	ld (de),a
	scf
	jr addnum2

; The sum is less than 10.

addnum0	ld (de),a

; Reset CY.

	or a

addnum2	dec hl
	dec de
	djnz addnum1
	ret

; -------------------
; 'drnum' Draw number
; -------------------
;
; In	B number of digits. HL pointer to digits. DE y,x in chars. C color.
; Saves	C

drnum

; In the begining, while it is a zero digit, draw a space.

	dec b

drnum_zero

	ld a,(hl)
	or a
	jr nz,drnum_rest
	ld a,' '
	call drchrsf
	inc e
	inc hl
	djnz drnum_zero

drnum_rest

; Now, some digits remain.

	inc b

drnum_num

	ld a,(hl)
	add a,'0'

; Find in rom and draw with color.

	call drchrsf

drnum_next

; Go to next digit.

	inc e
	inc hl
	djnz drnum_num
	ret

; -------------------------
; 'drchrsf' Draw char safe.
; -------------------------
;	Draws a character, preserves most of registers.
;
; In	A character code. DE y,x in characters. C color.
; Saves	BC, DE, HL.

drchrsf push hl
	call font_chadr
	push de
	push bc
	ld a,c
	call set_char_color
	call drchrc
	pop bc
	pop de
	pop hl
	ret

; --------
; 'minnum'
; --------
;	Selects the minimum of two decimal numbers.
;
; In	HL addr number 1. DE addr number 2. B digits.
; Out	A 0 if equal, -1 if HL is the minimum, 1 if DE is the minimum.
; Saves	HL, DE.

minnum
	push de
	push hl

minnum_loop

	ld a,(de)
	cp (hl)
	jr nz,minnum_cp

; Digits are equal, go to next.

	inc hl
	inc de
	djnz minnum_loop
	xor a
	jr minnum_end

minnum_cp

; The digits are different.

	jr c,minnum_is_2
	ld a,-1
	jr minnum_end

minnum_is_2

; The second number is less than the first.

	ld a,1

minnum_end
	pop hl
	pop de
	ret

; --------------------
; 'digit' Gets a digit
; --------------------
;	Gets a digit of a number, starting from the most significant.
;
; In	HL number address. B digit to obtain (number length - digits from
;	the least significant).
; Out	A digit. B 0. HL points at digit.

digit	dec hl
	inc b

digit_loop
	inc hl
	ld a,(hl)
	djnz digit_loop
	ret

; ---------------
; 'mirror' Mirror
; ---------------
;	Mirrors the left side of an image into the left side.
;
; In	HL image address.

mirror	

; Load A,C height, width.

	ld c,(hl)
	inc hl
	ld a,(hl)
	inc hl

; BC is width.

	ld b,0

; Save height counter and first position in line.

mirror3	push af
	push hl

; Point DE to first byte in line, HL to last.

	ld d,h
	ld e,l
	add hl,bc
	dec hl

; Bytes to mirror on a line in B (careful when width is odd).

	push bc
	ld a,c
	or a
	rra
	ld b,a

; Mirror line.

mirror2	push bc
	ld a,(de)
	inc de
	ld b,8
mirror1	rlca
	rr c
	djnz mirror1
	ld (hl),c
	dec hl
	pop bc
	djnz mirror2
	pop bc

; Go to next line.

	pop hl
	add hl,bc
	pop af
	dec a
	jr nz,mirror3
	ret

; ----------------------
; 'mirims' Mirror Images
; ----------------------
;	Runs through a null terminated list of image pointers, takes each
;	image and builds its right side by mirroring its left side.
;
; In	HL address of a table of pointer to Images.

mirims	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,d
	or e
	ret z
	push hl
	ex de,hl
	call mirror
	pop hl
	jr mirims

; -----------------------
; 'flipv' Vertically flip
; -----------------------
;	Flips and image vertically.
;
; In	HL Image address.

flipv	ld c,(hl)	
	inc hl
	ld b,(hl)
	inc hl

; If only one row, nothing to do.

	ld a,1
	cp b
	ret z

; Point DE to start of last image row.

	push hl
	ld a,b
	ld d,0
	ld e,c
	jr flipv3
flipv2	add hl,de
flipv3	dec a
	jr nz,flipv2
	ex de,hl
	pop hl

; How many lines to swap?

	srl b

; Swap one line.

flipv4	push bc
	ld b,c
flipv1	ld c,(hl)
	ld a,(de)
	ld (hl),a
	ld a,c
	ld (de),a
	inc hl
	inc de
	djnz flipv1
	pop bc

; All lines served.

	dec b
	ret z

; Go to next lines.
; HL already pointing to next line. Fix DE.

	push hl
	ex de,hl
	ld d,0
	ld e,c
	xor a
	sbc hl,de
	sbc hl,de
	ex de,hl
	pop hl
	jr flipv4

; -------------------------
; 'cppad' Copy with padding
; -------------------------
;	Copies one image src into image dst. Height of the src
;	must be less or equal than the width of dst.
;	The width of the dst image must equal the width src image if
;	we are copying, or it has to be the width of src plus one if we
;	want padding.
;
; In	HL source image. DE dest image.
;	A 0 for copy, 1 for copying with padding.
; Saves	A.

cppad

; Take width and height of source.

	ld c, (hl)
	inc hl
	ld b, (hl)
	inc hl

; Point to dest image data.

	inc de
	inc de

; Put a 0 in A'.

	ex af,af'
	xor a
	ex af,af'

; Copy all lines.

cppad1	push bc
	ld b,0
	ldir
	or a
	jr z,cppad2

; Put a 0 on last row byte if padding.

	ex af,af'
	ld (de),a
	inc de
	ex af,af'

; For all rows.

cppad2	pop bc
	djnz cppad1
	ret


#if 0
; -----------
; 'two_pow_n'
; -----------
;	Given A, it is taken modulus 8 (thus 0-7) and then returns in A the
;
; In	A.
; Out	A 1,2,4,8,16,32,64,128.

two_pow_n
	push hl
	and 7
	ld hl,two_pow_t
	call getbt
	pop hl
	ret

two_pow_t	.db 1,2,4,8,16,32,64,128
#endif


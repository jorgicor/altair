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

; Common to all hardware.

; --------------------
; 'inirecs' Init Rects
; --------------------
;	Sets Current Rect Pointer to the start of the Rect List and sets
;	the Number of Rects to 0.
;
; Saves	DE, BC.

inirecs ld hl,bbuf_reclst
	ld (bbuf_rectp),hl
	xor a
	ld (bbuf_nrects),a
	ret

; -------------------------------
; 'savrec' Save Rect in Rect List
; -------------------------------
;	Saves a rect in the rect list if there is space enough (MAXRECS) and
;	points Current Rect Pointer to the next rect and increments Number of
;	Rects.
;
; In	B,C height,width. DE address of first byte of rect. A restore value.
; Saves BC, DE.

savrec	push af
	ld a,(bbuf_nrects)
	cp MAXRECS
	jr nz,savrec1
	pop af
	ret
savrec1	inc a
	ld (bbuf_nrects),a
	pop af
	ld hl,(bbuf_rectp)
	ld (hl),c
	inc hl
	ld (hl),b
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	ld (hl),a
	inc hl
	ld (bbuf_rectp),hl
	ret

; ---------------------
; 'blkrecs' Blank Rects
; ---------------------
;	Goes through the Rect List and calls 'erase' for each.

blkrecs	ld hl,bbuf_reclst
	ld a,(bbuf_nrects)
blkrec1	or a
	ret z
	push af
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld a,(hl)
	inc hl
	push hl
	call erase
	pop hl
	pop af
	dec a
	jr blkrec1

; ------------------
; 'erase' Erase Rect
; ------------------
;	Fills a rect with a value. The rect is assummed in a buffer with a
;	with of BBUFWB bytes.
;
; In:	B,C height,width in bytes. DE address of first byte.
;	A value to erase to.

erase

; Set DE as the offset we have to add to go to the next line at destiny.

	ex af,af'
	ld a,BBUFWB
	sub c
	ld l,a
	ex af,af'
	ld h,0
	ex de,hl

; Fill rect.

erase2	push bc
erase1 	ld (hl),a
	inc hl
	dec c
	jr nz,erase1
	pop bc
	add hl,de
	djnz erase2
	ret	

; -----------------
; 'drim' Draw Image
; -----------------
;	Draws an image in the Back Buffer, draws its color, and saves the
;	rects where we have painted to be restored later.
;	An image starts with two bytes. The first is the width in bytes; the
;	second is the height in pixels. Then comes the actual image data.
;
; In	HL start of image. D,E x,y position in bytes.

drim

; Calc Back Buffer paint address.

	ex de,hl
	ld bc,bbuf
	call cbpos
	ex de,hl

; Set C width and B height.

	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl

; Now, HL start of image data. DE address in Back Buffer. B,C height, width.
; Save rect to restore later, and paint.

	push hl
	xor a
	call savrec
	pop hl
	call cpim
	ret

; -----------------
; 'cpim' Copy Image
; -----------------
;	Copies a set of bytes into a buffer, arranged as rows and columns.
;	The buffer where to paint is assumed to be have a width of BBUFWB
;	bytes.
;
; In	B,C is height in bytes, width in bytes. HL start of image data.
; 	DE address where to paint.

cpim	

; Calc offset between buffer lines.

	ld a,BBUFWB
	sub c

; Copy all lines.

cpim1	push bc

; Copy a line.

	ld b,0
	ldir

#if 0
	push af
	ld b,c
cpim2	ld a,(de)
	or (hl)
	ld (de),a
	inc hl
	inc de
	djnz cpim2
	pop af
#endif

; Here B is 0. Go to next line at destiny.

	ex de,hl
	ld c,a
	add hl,bc
	ex de,hl

; For height lines.

	pop bc
	djnz cpim1
	ret

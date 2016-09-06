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

; -----------
; 'init_bbuf'
; -----------
;	Init back buffer.

init_bbuf

; VRAM to Back Buffer addresses generation
;
; We are going to generate a table of tuples (vram address, backbuffer
; address). Each Back Buffer address is the address of the first pixel
; of a scanline that must be copied, beginning at the corresponding vram
; address. This includes data scanlines and attribute scanlines, so it
; has 8 tuples for pixel scanlines, 1 tuple for the corresponding attribute
; scanline, and so on.
;
; The screen addresses are in the form:
;	010b b000 cccx xxxx
;		bb = one of the three blocks of screen
;		ccc = character row in block
;		xxxxx = character column in row
; Given our Back Buffer Width, we generate the addresses so they will be
; centered horizontally on the screen.

; 1. First generate only the vram addresses and vram attribute addresses.

	ld hl,bbuf_scr_t
	ld d,BBUFYC
	ld e,BBUFXC
	ld b,BBUFHC

init_bbuf3
	push bc

; Generate 8 scanlines for this character line.

	push de
	call scradr
	ld b,8

init_bbuf2
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	inc hl
	inc hl
	inc d
	djnz init_bbuf2
	pop de

; Generate the attribute address.

	push de
	call atradr
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	inc hl
	inc hl
	pop de

; Increment y character position and go to next.

	inc d
	pop bc
	djnz init_bbuf3

; 2. Generate the Back Buffer and Attribute Buffer addresses.

	ld hl,bbuf_scr_t
	ld de,bbuf
	ld ix,abuf
	ld b,BBUFHC

init_bbuf5
	push bc

; Generate 8 Back Buffer scanline addresses.

	ld a,8
	ld bc,BBUFWC

init_bbuf4
	inc hl
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	ex de,hl
	add hl,bc
	ex de,hl
	dec a
	jr nz,init_bbuf4

; Generate the Attribute Buffer scanline address.

	push de
	push ix
	pop de
	inc hl
	inc hl
	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	ex de,hl
	add hl,bc
	ex de,hl
	push de
	pop ix
	pop de

; BBUFHC times.

	pop bc
	djnz init_bbuf5
	ret

; ---------
; 'clrbbuf'
; ---------
;	Clears back buffer and back buffer color and resets rect list.
;
; In	A color.

clrbbuf

; Set Back Buffer color.

	ld hl,abuf
	ld bc,+BBUFWC*BBUFHC
	call memset

; Clear backbuffer.

	ld hl,bbuf
	ld bc,+BBUFWB*BBUFHB
	xor a
	call memset

; Reset rects.

	xor a
	ld (bbuf_nrects),a
	ret

; Number of filled rects.
bbuf_nrects	.db 0

; Pointer to the next to be filled rect.
bbuf_rectp	.dw bbuf_reclst

; ----------------------------
; 'dump_bbuf' Dump Back Buffer
; ----------------------------
;	Transfer Back Buffer to Video RAM.

dump_bbuf
	ld hl,bbuf_scr_t

; Number of scanlines to transfer (pixel scans + attribute scans).

	ld a,+BBUFHB+BBUFHC

dump_bbuf1	

; Take Video RAM address.

	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl

; Take Back Buffer or Attribute Buffer address.

	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl

; Set HL back buffer, DE Video RAM address, and transfer scanline.

	push hl
	ld h,b
	ld l,c

#if BBUFWB>0
	ldi
#endif
#if BBUFWB>1
	ldi
#endif
#if BBUFWB>2
	ldi
#endif
#if BBUFWB>3
	ldi
#endif
#if BBUFWB>4
	ldi
#endif
#if BBUFWB>5
	ldi
#endif
#if BBUFWB>6
	ldi
#endif
#if BBUFWB>7
	ldi
#endif
#if BBUFWB>8
	ldi
#endif
#if BBUFWB>9
	ldi
#endif
#if BBUFWB>10
	ldi
#endif
#if BBUFWB>11
	ldi
#endif
#if BBUFWB>12
	ldi
#endif
#if BBUFWB>13
	ldi
#endif
#if BBUFWB>14
	ldi
#endif
#if BBUFWB>15
	ldi
#endif
#if BBUFWB>16
	ldi
#endif
#if BBUFWB>17
	ldi
#endif
#if BBUFWB>18
	ldi
#endif
#if BBUFWB>19
	ldi
#endif
#if BBUFWB>20
	ldi
#endif
#if BBUFWB>21
	ldi
#endif
#if BBUFWB>22
	ldi
#endif
#if BBUFWB>23
	ldi
#endif
#if BBUFWB>24
	ldi
#endif
#if BBUFWB>25
	ldi
#endif
#if BBUFWB>26
	ldi
#endif
#if BBUFWB>27
	ldi
#endif
#if BBUFWB>28
	ldi
#endif
#if BBUFWB>29
	ldi
#endif
#if BBUFWB>30
	ldi
#endif
#if BBUFWB>31
	ldi
#endif

	pop hl

; For all scanlines.

	dec a
	jp nz,dump_bbuf1
	ret

; ---------------------------
; 'cimadr' Calc Image Address
; ---------------------------
;	Given an Image Table, returns the address of the start of an Image
;	given the lower 3 bits of the x position where the image is to be
;	painted.
;
; In	HL Start of an Image table. A x position in pixels.
; Out	HL address of Image.
; Saves	DE.

cimadr	and 7
	rlca
	ld c,a
	ld b,0
	add hl,bc
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ret

; ---------------------------
; 'tobyxp' To Byte X Position
; ---------------------------
;
; In	A pixel x coordinate.
; Out	A byte x coordinate.
; Saves	BC, DE, HL.

tobyxp	and $f8
	rrca
	rrca
	rrca
	ret

; ----------------------------
; 'cbpos' Calc Buffer position
; ----------------------------
;	Given position in bytes calculates the final address in back buffer.
;
; In	BC start of buffer. H,L x in bytes, y in bytes.
; Out	HL address in buffer.
; Saves	DE.

cbpos	push bc
	ld a,h
	ld h,0

; Multiply y position by 8, save in BC.

	add hl,hl
	add hl,hl
	add hl,hl
	ld c,l
	ld b,h

; Y position multiplied by 16.

	add hl,hl

; Set HL = y*16 + y*8 = y*24.

	add hl,bc

; Add x position.

	ld c,a
	ld b,0
	add hl,bc

; Add offset, ie buffer address.

	pop bc
	add hl,bc
	ret

; ----------
; 'colorize'
; ----------
;	Colorizes the back attribute buffer by changing its paper color.
; Only used for effects. Uses bbuf_paper and bbuf_last_paper. The game
; can change bbuf_paper to apply a new paper color.
;
; Saves	D.

colorize

	ld a,(bbuf_paper)
	cp BBUF_BLACK
	jr nz,colorize_do
	ld hl,bbuf_last_paper
	cp (hl)
	ret z

colorize_do

	ld (bbuf_last_paper),a

; Draw the color as paper in backbuffer attributes.

	ld hl,abuf
	ld bc,ABUFSZ
	ld e,a
	
colorize_loop

	ld a,(hl)
	and %10000111
	or e
	ld (hl),a
	inc hl
	dec bc
	ld a,b
	or c
	jr nz,colorize_loop
	ret

; --------------------------------------------
; 'set_bbuf_paper' Set back buffer paper color
; --------------------------------------------
;	Sets the backbuffer paper color.
;
; In	A color
; Saves	A, BC, DE, HL

set_bbuf_paper

	ld (bbuf_paper),a
	ret

; Paper to colorize back buffer for effects.
bbuf_paper	.db BBUF_BLACK
bbuf_last_paper	.db BBUF_BLACK

; -------------------
; 'drspr' Draw Sprite
; -------------------
;	Draws a Sprite in the Back Buffer and Attribute Buffer.
;
; In	HL sprite ptr.
; Out	HL next sprite ptr.

drspr

; Set IX as Sprite pointer.

	push hl
	pop ix

; HL Image Table address.

	ld l,(ix+SP_ITL)
	ld h,(ix+SP_ITH)

; If address is 0, go to next sprite.

	ld a,h
	or l
	jr z,drspr1

; Set IY as the Image address.

	ld a,(ix+SP_PX)
	call cimadr
	push hl
	pop iy

; Byte align x position and draw image.

	ld a,(ix+SP_PX)
	call tochrp
	ld d,a
	ld e,(ix+SP_PY)
	call drim

; Check if we colorize or apply color pattern.

	ld a,(ix+SP_COH)
	or a
	jr z,drspr2
	ld a,(ix+SP_PX)
	or (ix+SP_PY)
	and 7
	jr nz,drspr2

; Apply color pattern.
; 1. Transform positions to character positions.

	ld a,(ix+SP_PX)
	call tochrp
	ld d,a
	ld a,(ix+SP_PY)
	call tochrp
	ld e,a

; 2. Get pattern address and draw.

	ld l,(ix+SP_COL)
	ld h,(ix+SP_COH)
	call drptrn
	jr drspr1

; Colorize.
; Fix y position and dimension to draw color.

drspr2	ld e,(ix+SP_PY)
	ld c,(iy+IM_HEI)
	call chrfix

; Byte align x position.

	ld a,(ix+SP_PX)
	call tochrp

; Calc draw adress in HL.

	ld h,a
	ld l,e
	push bc
	ld bc,abuf
	call cbpos
	pop bc

; Set BC height, width.

	ld b,c
	ld c,(iy+IM_WID)

; Save color rect.

	ex de,hl
	ld a,ABUFCLR
	call savrec

; Draw color using Erase.

	ld a,(ix+SP_COL)
	call erase

; Set HL to point to the next Sprite.

drspr1	push ix
	pop hl
	ld bc,SPRSZ
	add hl,bc
	ret

; ---------------------------
; 'drptrn' Draw Color Pattern
; ---------------------------
;
; In	HL address of color pattern. DE x,y in characters.

drptrn

; Calc first byte position.

	ex de,hl
	ld bc,abuf
	call cbpos

; Take dimensions of pattern.

	ex de,hl
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl

; Save rect.

	push hl
	ld a,ABUFCLR
	call savrec
	pop hl

; Draw pattern.

	call cpim
	ret

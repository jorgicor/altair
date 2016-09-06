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

; -------------------------------------
; 'init_bbuf' Generate video addresses.
; -------------------------------------
;	Generates a table of tuples (video ram address, back buffer address)
; for each scanline.

init_bbuf	

; First generate the video adresses.

	ld hl,bbuf_scr_t
	ld de,+BBUFYC*SCRWB+BBUFXB+vram
	ld b,BBUFHC

init_bbuf_vram_loop

	push bc
	push de

; 8 pixels height each character.

	ld a,8

; Separation of each scanline of a character in video ram.

	ld bc,2048

init_bbuf_vram_chrline

; Generate 8 scanlines for a character line.

	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	inc hl
	inc hl
	ex de,hl
	add hl,bc
	ex de,hl
	dec a
	jr nz,init_bbuf_vram_chrline

; Go to next character.

	pop de
	ex de,hl
	ld bc,SCRWB
	add hl,bc
	ex de,hl

	pop bc
	djnz init_bbuf_vram_loop

; Now, generate the back buffer addresses.

	ld hl,+bbuf_scr_t+2
	ld de,bbuf
	ld bc,BBUFWB
	ld a,BBUFHB

init_bbuf_loop

	ld (hl),e
	inc hl
	ld (hl),d
	inc hl
	inc hl
	inc hl
	ex de,hl
	add hl,bc
	ex de,hl
	dec a
	jr nz,init_bbuf_loop
	ret

; ---------
; 'clrbbuf'
; ---------
;	Clears back buffer to a 2-pixel and resets rect list.
;
; In	A 2-pixel byte.

clrbbuf

; Clear backbuffer.

	ld hl,bbuf
	ld bc,+BBUFWB*BBUFHB
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

	ld a,BBUFHB

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

#if BBUFWC>0
	ldi
	ldi
#endif
#if BBUFWC>1
	ldi
	ldi
#endif
#if BBUFWC>2
	ldi
	ldi
#endif
#if BBUFWC>3
	ldi
	ldi
#endif
#if BBUFWC>4
	ldi
	ldi
#endif
#if BBUFWC>5
	ldi
	ldi
#endif
#if BBUFWC>6
	ldi
	ldi
#endif
#if BBUFWC>7
	ldi
	ldi
#endif
#if BBUFWC>8
	ldi
	ldi
#endif
#if BBUFWC>9
	ldi
	ldi
#endif
#if BBUFWC>10
	ldi
	ldi
#endif
#if BBUFWC>11
	ldi
	ldi
#endif
#if BBUFWC>12
	ldi
	ldi
#endif
#if BBUFWC>13
	ldi
	ldi
#endif
#if BBUFWC>14
	ldi
	ldi
#endif
#if BBUFWC>15
	ldi
	ldi
#endif
#if BBUFWC>16
	ldi
	ldi
#endif
#if BBUFWC>17
	ldi
	ldi
#endif
#if BBUFWC>18
	ldi
	ldi
#endif
#if BBUFWC>19
	ldi
	ldi
#endif
#if BBUFWC>20
	ldi
	ldi
#endif
#if BBUFWC>21
	ldi
	ldi
#endif
#if BBUFWC>22
	ldi
	ldi
#endif
#if BBUFWC>23
	ldi
	ldi
#endif
#if BBUFWC>24
	ldi
	ldi
#endif
#if BBUFWC>25
	ldi
	ldi
#endif
#if BBUFWC>26
	ldi
	ldi
#endif
#if BBUFWC>27
	ldi
	ldi
#endif
#if BBUFWC>28
	ldi
	ldi
#endif
#if BBUFWC>29
	ldi
	ldi
#endif
#if BBUFWC>30
	ldi
	ldi
#endif
#if BBUFWC>31
	ldi
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
;	given the lower 2nd bit of the x position where the image is to be
;	painted. That is, on the CPC, the table only requires at maximum
;	2 entries.
;
; In	HL Start of an Image table. A x position in pixels.
; Out	HL address of Image.
; Saves	DE.

cimadr	and 2
	ld c,a
	ld b,0
	add hl,bc
	ld a,(hl)
	inc hl
	ld h,(hl)
	ld l,a
	ret

; --------------------------
; 'tobyp' To Byte X Position
; --------------------------
;
; In	A pixel x coordinate.
; Out	A byte x coordinate.
; Saves	BC, DE, HL.

tobyxp	and %11111100
	rrca
	rrca
	ret

; ----------------------------
; 'cbpos' Calc Buffer position
; ----------------------------
;	Given position in bytes calculates the final address in back buffer.
; This is written for a 48 byte width backbuffer.
;
; In	BC start of buffer. H,L x in bytes, y in bytes.
; Out	HL address in buffer.
; Saves	DE.

cbpos	push bc
	ld a,h
	ld h,0

; Multiply y position by 16, save in BC.

	add hl,hl
	add hl,hl
	add hl,hl
	add hl,hl
	ld c,l
	ld b,h

; Y position multiplied by 32.

	add hl,hl

; Set HL = y*32 + y*16 = y*48.

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

;;;;;;;;;;;;;;;;;;;;; USE THE AMSTRAD PALETTE!!!!!!!!!!!!

colorize

; If same color do nothing.

	ld a,(bbuf_paper)
	ld hl,bbuf_last_paper
	cp (hl)
	ret z	

; Save color in bbuf_last_paper.

	ld (hl),a

; Change palette color 0.

	ld e,0
	call set_pal_color
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
	call tobyxp
	ld d,a
	ld e,(ix+SP_PY)
	call drim

; Set HL to point to the next Sprite.

drspr1	push ix
	pop hl
	ld bc,SPRSZ
	add hl,bc
	ret

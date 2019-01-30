; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ------------------------------
; 'font_chadr' Font Char Address
; ------------------------------
;	Returns the address of character data in ROM or custom font.
;
; In	A character code.
; Out	HL address of character data.
; Saves	BC, DE

font_chadr

	ld hl,font_SPC
	
; Check if it is in our font range.

	cp 32
	ret c
	cp 96
	ret nc

; It is in our font range.

	sub 32
	jp chadr4

; -----------
; 'idralien_f'
; -----------
;	Draws an alien image directly on the screen.

idralien_f

; Get color (Ignored for CPC).

;	ld c,(ix+IDRALIEN_COLOR)

; Get image.

	ld a,(ix+IDRALIEN_ID)
	ld hl,alims
	call getwt

; Go to image data.

	inc hl
	inc hl

; Screen address.

	ld e,(ix+IDRALIEN_X)
	ld d,(ix+IDRALIEN_Y)
	call scradr

; DE src image, HL screen dst.

	ex de,hl

; 6 pixel lines, 4 bytes per line.

	ld bc,$0604

dralchr_loop

	push bc

	#if 0
	ld a,(de)
	ld (hl),a
	#endif

; pixel from src

	ld a,(de)

; mask from pixel

	ld b,pixmask_t>>8
	ld c,a
	ld a,(bc)

; apply mask to dest.

	and (hl)

; mix with src (this works because we always consider PEN0 (0) as the
; transparent).

	or c
	ld (hl),a

	inc de
	inc hl

	pop bc
	dec c
	jr nz,dralchr_loop

; Next pixel char line in dst.

	push bc
	ld bc,2044
	add hl,bc
	pop bc

; Next pixel char line in src.

	ld c,4
	djnz dralchr_loop

	scf
	ret

; --------------
; 'init_pixmask'
; --------------
;	For each posible 2-pixel byte, generates a mask to let pass the pixel
; info where the pixel palette index is 0.

init_pixmask

	ld hl,pixmask_t

; Start from 0, to 255 possible values.

	ld c,0

init_pixmask_ab

	ld a,c
	and PIX0|PIX1
	jr nz,init_pixmask_0
	ld a,PIX0|PIX1
	jr init_pixmask_next

init_pixmask_0

	ld a,c
	and PIX0
	jr nz,init_pixmask_1
	ld a,PIX0
	jr init_pixmask_next

init_pixmask_1

	ld a,c
	and PIX1
	jr nz,init_pixmask_none
	ld a,PIX1
	jr init_pixmask_next

init_pixmask_none

	xor a

init_pixmask_next

	ld (hl),a
	inc l
	inc c
	jr nz,init_pixmask_ab
	ret

	.org ($+255)&$ff00

pixmask_t	.fill 256, 0
	
; -------------------------
; 'chstrf' Change Starfield
; -------------------------
; 	Increments Star Mode Counter and when it reaches 0, we swap the
;	starfield.

chstrf

; Increment Star Mode Counter.

	ld a,(starmc)
	add a,16
	ld (starmc),a
	ret nz

; Star Mode Counter reached 0.
; Configure Draw Stars to erase and erase all stars.

	ld a,BLACK|PBLACK
	ld (drstrsv),a
	call drstrs

; Configure Draw Stars to draw again.

	ld a,+(PIX0&BLUE)|(PIX1&PBLACK)
	ld (drstrsv),a

; Swap Star Mode.

	ld a,(starm)
	xor 1
	ld (starm),a
	ret

; -------------------
; 'drstrs' Draw Stars
; -------------------
; 	Draws the starfield on Back Buffer.
; This algorithm can be configured to draw or to erase, by changing the byte
; at address 'drstrsv'.

drstrs

; Save 'rand' seed.

	ld a,(randp)
	ld (srandsv),a

; Set the start address where to take random values to draw the stars.
; We use two addresses depending on Star Mode, address 0 and adress 192.


	ld a,(starm)
	or a
	jr nz,drstrs1
	ld (randp),a
	jr drstrs2
drstrs1	ld a,192
	ld (randp),a

drstrs2 

; Set HL to backbuf, B to number of lines to paint.

	ld hl,bbuf
	ld b,BBUFHC

drstrs8	push bc
	push hl

; In C we will count the x offset on a line.

	ld c,0

; Get an offset where to paint a new star between 0 and 15.

drstrs7	call rand
	and 15

; Save in B and add to Line Offset.

	ld b,a
	add a,c

; If we have surpassed the line length, go to next line.

	cp BBUFWB
	jr nc,drstrs6

; Set new Line Offset.

	ld c,a

; Add the offset to HL.

	ld a,b
	add a,l
	ld l,a
	ld a,0
	adc a,h
	ld h,a

; Draw the star. This is 'ld (hl),8'.
; 'drstarv' is modified from outside so the same routine clears or paints.

	.db $36
drstrsv	.db +(PIX0&BLUE)|(PIX1&PBLACK)

; Go to next star.

	inc hl
	inc c
	jr drstrs7

; Go to the start of the next line for BBUFHC lines.

drstrs6 pop hl
	ld bc,BBUFWB*8
	add hl,bc
	pop bc
	djnz drstrs8

; Restore rand seed.

	ld a,(srandsv)
	ld (randp),a
	ret

; Star Mode Counter.
; Grows until some point, where Star Mode is switched. 
starmc	.db 0

; Star Mode.
; Takes values 0 or 1 to set two different starfield patterns.
starm	.db 0

; Saves the 'rand' seed to restore it after we paint the stars.
srandsv	.db 0

; -------------------------
; 'drtxfx' Draw Text Effect
; -------------------------
;	Draws a text in the backbuffer. The text data is arranged in a special
; way, pairs of (character code, color). If 'character code' is 0, the
; sequence ends.
;
; In	DE address of special text format data. HL x,y character position.

drtxfx

; Calc text length and save in A'.

	call lentxfx
	ex af,af'
	
; y pos * 8 = pos y in pixels.

	ld a,l
	rlca
	rlca
	rlca
	ld l,a

; x byte pos = x char pos * 2

	sla h

; Calc position in back buffer.

	ld bc,bbuf
	call cbpos

; Save rect.
; Save text address.

	push de

; Width in bytes.

	ex af,af'
	rlca
	ld c,a

; Height.

	ld b,8

; Pos in backbuffer and restore value.

	ex de,hl
	xor a
	call savrec
	ex de,hl

; Restore text address.

	pop de

drtxfx_loop

; Take font address. If 0, finish.

	ld a,(de)
	or a
	jr z,drtxfx_end

; Save bbuf pos.

	push hl

; Get char data address using A.

	call font_chadr

; Set color.

	inc de
	ld a,(de)
	inc de
	call set_char_color

; Take address in bbuf in DE, saving index in text string.

	pop bc
	push de
	ld e,c
	ld d,b

; Save address in bbuf.

	push de

; Now, HL address of char data, DE address in bbuf.
; Draw character.

	call drchrc_bbuf

; Restore bbuf pos and go to next character.

	pop hl
	inc hl
	inc hl

; Restore index in text string.

	pop de

	jr drtxfx_loop

drtxfx_end
	
	ret

; -------------------------------------------
; 'drchrc_bbuf' Draw Character In Back Buffer
; -------------------------------------------
;	Draws a character with the current color in the back buffer.
; Font data is arranged as in drchrc.
;
; In	HL address to 4 bytes of char data. DE address in bbuf.

drchrc_bbuf
	
; 8 lines tall, 4 x 2 lines tall.

	ld a,4
	ld bc,char_color_pal
	
drchrc_line_bbuf

	push af

; Even scanline.

	call drchrc_pixln_bbuf

; Odd scanline.

	call drchrc_pixln_bbuf

; Next source data.

	inc hl

	pop af
	dec a
	jr nz,drchrc_line_bbuf

	ret

; ------------------------------------------------------------
; 'drchrc_pixln_bbuf' Draw Character Pixel Line In Back Buffer
; ------------------------------------------------------------
;	Draws a character horizontal line in the back buffer.
; Supporting routine for 'drchrc_bbuf'.
;
; In	HL address a byte of char data. DE dest address in bbuf.
;	BC palette address.
; Out	DE address of the next horizontal line below.
; Saves	HL, BC.

drchrc_pixln_bbuf

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

	push bc
	ex de,hl
	ld bc,BBUFWB
	add hl,bc
	ex de,hl
	pop bc

	ret


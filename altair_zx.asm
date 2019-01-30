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

; Check if it is from A-Z, use our font in this case.

	cp $41
	jp c,romchar
	cp $5B
	jp nc,romchar
	sub $41
	ld hl,font_A
	jp chadr

; -----------
; 'idralien_f'
; -----------
;	Draws an alien image directly on the screen.

idralien_f

; Get color.

	ld c,(ix+IDRALIEN_COLOR)

; Get image.

	ld a,(ix+IDRALIEN_ID)
	ld hl,alims
	call getwt

; Go to image data.

	inc hl
	inc hl

; Draw both chars.

	ld e,(ix+IDRALIEN_X)
	ld d,(ix+IDRALIEN_Y)

; Char 1.

	push hl
	push de
	call dralchr
	pop de
	pop hl

; Go to byte 1 in image and increment screen x.

	inc hl
	inc e

; Char 2.

	call dralchr
	scf
	ret

; -------------------------
; 'dralchr' Draw alien char
; -------------------------
;	Draws one char of an alien image.
;
; In	HL first image byte. C color. D,E y,x in chars
; Saves	C.

dralchr

	push de

; Draw one char.

	call scradr
	ld b,6

dralchr_loop

	ld a,(hl)
	ld (de),a
	inc hl
	inc hl
	inc d
	djnz dralchr_loop

; Color.

	pop de
	call atradr
	ld a,c
	ld (de),a
	ret

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

	xor a
	ld (drstrsv),a
	call drstrs

; Configure Draw Stars to draw again.

	ld a,8
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
	ld e,0
	jr drstrs2
drstrs1	ld e,192
drstrs2 ld d,0

; Set HL to backbuf, B to number of lines to paint.

	ld hl,bbuf
	ld b,BBUFHC

drstrs8	push bc

; In C we will count the x offset on a line.

	ld c,0

; Get an offset where to paint a new star between 0 and 7.

drstrs7	ld a,(de)
	inc de
	and 7

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
drstrsv	.db 8

; Go to next star.

	inc hl
	inc c
	jr drstrs7

; Go to the start of the next line for BBUFHC lines.

drstrs6 neg
	add a,BBUFWB*8
	add a,l
	ld l,a
	ld a,0
	adc a,h
	ld h,a
	pop bc
	djnz drstrs8

; Restore rand seed.

	ld a,(srandsv)
	ld (randp),a
	ret
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

; Calc length and save in A'.

	call lentxfx
	ex af,af'

; Prepare alternative registers for color.
; We will have HL' with address of first char in attribute buffer.

	push hl
	exx
	pop hl
	ld bc,abuf
	call cbpos

; Save the rect for the attributes.

	ex af,af'
	ld c,a
	ex af,af'
	ld b,1
	ld d,h
	ld e,l
	ld a,ABUFCLR
	push hl
	call savrec
	pop hl
	exx

; y pos * 8 = pos y in pixels.

	ld a,l
	rlca
	rlca
	rlca
	ld l,a

; Calc position in back buffer.

	ld bc,bbuf
	call cbpos

; Save pixel rect.

	push de
	ex af,af'
	ld c,a
	ex af,af'
	ld b,8
	ld d,h
	ld e,l
	xor a
	push hl
	call savrec
	pop hl
	pop de

; Draw each character.

	ld bc,BBUFWC

drtxfx_loop

; If char is 0 end.

	ld a,(de)
	or a
	jr z,drtxfx_end

; Save character index.

	push de

; Calc address of character data.

	push hl
	call font_chadr
	ex de,hl
	pop hl

; Now, HL address in backbuf, DE address of char.

	push hl
	call chrtobuf
	pop hl

; Next x pos in backbuf.

	inc hl

; Attribute in string.

	pop de
	inc de

; Draw attribute.

	ld a,(de)
	exx
	ld (hl),a
	inc hl
	exx

; Next character.

	inc de
	jr drtxfx_loop
	
drtxfx_end
	ret

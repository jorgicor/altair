; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Disclaimer text.
; ----------------------------------------------------------------------------

#ifdef LANG_EN
txdisclaim
	.db "ALTAIR IS A GAME MADE IN 1981", 0
	.db "FOR THE ARCADES, DEVELOPED BY", 0
	.db "THE SPANISH COMPANY CIDELSA.", 0
	.db "THIS IS THE CONVERSION TO THE", 0
#ifdef ZX
	.db "ZX SPECTRUM, PROGRAMMED IN", 0
	.db "THE YEAR 2014.", 0
#endif
#ifdef CPC
	.db "AMSTRAD CPC, PROGRAMMED IN", 0
	.db "THE YEAR 2014.", 0
#endif
	.db " ", 0
	.db "THIS VERSION SHOWS THE NAME", 0
	.db "CIDELSA ON SOME SCREENS.", 0
	.db "THIS IS TO SIMULATE THE", 0
	.db "ORIGINAL AND AS A TRIBUTE, AND", 0
	.text "DOESN'T MEAN THAT CIDELSA TOOK"
	.db 0
	.db "PART IN THE PRESENT VERSION.", 0
	.db EOF
#endif

#ifdef LANG_ES
txdisclaim
	.db "ALTAIR ES UN JUEGO DE 1981 PARA", 0
	.db "MAQUINAS RECREATIVAS, DESARRO-", 0
	.db "LLADO POR LA EMPRESA CIDELSA.", 0
#ifdef ZX
	.db "ESTA ES LA VERSION PARA ZX", 0
	.db "SPECTRUM, PROGRAMADA EN EL", 0
#endif
#ifdef CPC
	.db "ESTA ES LA VERSION PARA", 0
	.db "AMSTRAD CPC, PROGRAMADA EN EL", 0
#endif
	.db "2014.", 0
	.db " ", 0
	.db "ESTA VERSION MUESTRA EL NOMBRE", 0
	.db "DE CIDELSA EN VARIAS PANTALLAS.", 0
	.db "ESTO ES PARA IMITAR AL JUEGO", 0
	.db "ORIGINAL Y COMO HOMENAJE, Y NO", 0
	.db "INDICA LA PARTICIPACION DE", 0
	.db "CIDELSA EN LA PRESENTE VERSION.", 0
	.db EOF
#endif

; ---------------------
; 'enter_disclaimer_st'
; ---------------------

enter_disclaimer_st
	ld a,BLACK_BLACK
	call clrscr

	ld hl,txdisclaim
	call drtext
	ret

; ----------------------
; 'update_disclaimer_st'
; ----------------------

update_disclaimer_st
	call pollk
	call getkey
	or a
	ret z

	ld a,STATE_MENU
	call set_state

	; ld a,STATE_DEDICATE
	; call set_state

	ret

; ----------------------
; 'drtext' Draws a text.
; ----------------------
;	Draws a series of lines centered and full screen.
;
; In	HL first string address.

drtext

; Count lines and save in C for the rest of the algorithm.

	push hl
	call cntlines
	ld c,b
	pop hl

; Calc start y position, (screen_height-nlines)/2.

	ld a,SCRHC
	sub b
	srl a
	ld d,a
	ld e,0

; Now draw the lines.

drtext_next

; Calc centered x position, (screen_width-strlen)/2.

	push hl
	call strlen
	ld a,SCRWC
	sub b
	srl a
	ld e,a
	pop hl

	ld a,WHITE_BLACK
	push bc
	push de
	push hl
	call drstr
	pop hl
	pop de
	pop bc

	dec c
	inc d
	ret z

	call nextline
	jr nc,drtext_next 
	ret

; ----------
; 'nextline'
; ----------
;	If HL points to a string, it finds the next one.
;
; In	HL address of string.
; Out	HL address of new string if CY=0. Or no more lines if CY=1.
; Saves	BC, DE.

nextline

	ld a,(hl)
	inc hl
	cp EOF
	jr z,next_line_eof
	or a
	jr nz,nextline
	ld a,(hl)
	cp EOF
	jr z,next_line_eof
	ret

next_line_eof
	scf
	ret

; ----------------------
; 'cntlines' Count lines
; ----------------------
;	Counts lines in a text ended by code EOF.
;
; In	HL address of text.
; Out	B number of lines.
; Saves	DE, C.

cntlines

	ld b,0

cntlines1

	ld a,(hl)
	inc hl
	cp EOF
	ret z
	or a
	jr nz,cntlines1
	inc b
	jr cntlines1

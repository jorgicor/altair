; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Dedication.
; ----------------------------------------------------------------------------

txdedicate
	.db "NO HE FIRMADO ESTE JUEGO, PERO", 0
	.db "TE DEDICO TODO EL ESFUERZO QUE", 0
	.db "VOLQUE EN EL.", 0
	.db " ", 0
	.db "A TI, MI AMOR, HANANE.", 0
	.db EOF

enter_dedicate_st
	ld a,0
	call clrscr

	ld hl,txdedicate
	call drtext
	ret

update_dedicate_st
	call pollk
	call getkey
	or a
	ret z

	ld a,STATE_MENU
	call set_state
	ret


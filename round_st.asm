; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Entering game, round info.
; ----------------------------------------------------------------------------

txplayer	.db "PLAYER ", 0
txr1		.db "1", 0
txr2		.db "2", 0

ROUND_TXDELAY	.equ 1024
ROUND_DELAY	.equ 25000

round_code	.db ICLS, BLUE|PBLUE
		.db ITEXT, PBLUE|CYAN, SCRWC-TXCIDELSA_LEN, 23
			.dw txcidelsa_str
		.db IDELAY
			.dw ROUND_TXDELAY
		.db ITEXT, PBLUE|WHITE, 12, 12
			.dw txplayer
		.db ITEXT, PBLUE|YELLOW, 19, 12
txrp			.dw txr1
		.db IDELAY
			.dw 0
		.db IBEEP
			.dw BEEP_FREQX256(440*256), BEEP_MS(440*256, 250)
		.db IDELAY
			.dw ROUND_DELAY
		.db ISTOP

; ----------------
; 'enter_round_st'
; ----------------

enter_round_st
	ld a,BORDER_MENU
	call set_border_color

	ld a,(cur_player)
	or a
	jr z,enter_round_st_r1

	ld hl,txr2
	jr enter_round_st_start

enter_round_st_r1

	ld hl,txr1

enter_round_st_start

	ld (txrp),hl
	ld hl,round_code
	call mach_start
	ret

; -----------------
; 'update_round_st'
; -----------------

update_round_st
	call mach_update
	ret z

	ld a,STATE_GAMEPLAY
	call set_state
	ret


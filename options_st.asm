; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Game options state (redefine keys, etc).
; ----------------------------------------------------------------------------

#ifdef LANG_EN
OPTIONS_TX_X	.equ (SCRWC - 20) / 2
TXPRESS_X	.equ (SCRWC - 13) /2
TXPN_X		.equ (SCRWC - 8) / 2
TXKINFO_X	.equ (SCRWC - 5) / 2
#endif

#ifdef LANG_ES
OPTIONS_TX_X	.equ (SCRWC - 21) / 2
TXPRESS_X	.equ (SCRWC - 16) /2
TXPN_X		.equ (SCRWC - 9) / 2
TXKINFO_X	.equ (SCRWC - 9) / 2
#endif

#ifdef LANG_EN
txp1start	.db "1 ONE PLAYER", 0
txp2start	.db "2 TWO PLAYER", 0
txplayer1ink	.db "3 PLAYER 1: KEYBOARD  ", 0
#ifdef ZX
txplayer1inj1	.db "3 PLAYER 1: SINCLAIR", 0
txplayer1inj2	.db "3 PLAYER 1: KEMPSTON", 0
#endif
#ifdef CPC
txplayer1inj1	.db "3 PLAYER 1: JOYSTICK 1", 0
txplayer1inj2	.db "3 PLAYER 1: JOYSTICK 2", 0
#endif
txplayer2ink	.db "4 PLAYER 2: KEYBOARD  ", 0
#ifdef ZX
txplayer2inj1	.db "4 PLAYER 2: SINCLAIR", 0
txplayer2inj2	.db "4 PLAYER 2: KEMPSTON", 0
#endif
#ifdef CPC
txplayer2inj1	.db "4 PLAYER 2: JOYSTICK 1", 0
txplayer2inj2	.db "4 PLAYER 2: JOYSTICK 2", 0
#endif
txredefine	.db "5 REDEFINE KEYS", 0
#endif

#ifdef LANG_ES
txp1start	.db "1 UN JUGADOR", 0
txp2start	.db "2 DOS JUGADORES", 0
txplayer1ink	.db "3 JUGADOR 1: TECLADO   ", 0
#ifdef ZX
txplayer1inj1	.db "3 JUGADOR 1: SINCLAIR", 0
txplayer1inj2	.db "3 JUGADOR 1: KEMPSTON", 0
#endif
#ifdef CPC
txplayer1inj1	.db "3 JUGADOR 1: JOYSTICK 1", 0
txplayer1inj2	.db "3 JUGADOR 1: JOYSTICK 2", 0
#endif
txplayer2ink	.db "4 JUGADOR 2: TECLADO   ", 0
#ifdef ZX
txplayer2inj1	.db "4 JUGADOR 2: SINCLAIR", 0
txplayer2inj2	.db "4 JUGADOR 2: KEMPSTON", 0
#endif
#ifdef CPC
txplayer2inj1	.db "4 JUGADOR 2: JOYSTICK 1", 0
txplayer2inj2	.db "4 JUGADOR 2: JOYSTICK 2", 0
#endif
txredefine	.db "5 REDEFINIR TECLAS", 0
#endif

txp1inputs	.dw txplayer1ink
		.dw txplayer1inj1
		.dw txplayer1inj2

txp2inputs	.dw txplayer2ink
		.dw txplayer2inj1
		.dw txplayer2inj2

options_code	.db ICLS, PBLUE|BLUE
		.db ITEXT, PBLUE|CYAN, SCRWC-TXCIDELSA_LEN, 23
			.dw txcidelsa_str
		.db IDRHLINE, 'C', PBLUE|GREEN, 0, 0, 31
		.db IDRVLINE, 'C', PBLUE|GREEN, 31, 1, 7
		.db IDRHLINE, 'C', PBLUE|GREEN, 8, 31, 0
		.db IDRVLINE, 'C', PBLUE|GREEN, 0, 7, 1
		.db ITEXT, PBLUE|WHITE, 5, 2
			.dw txdefeat0
		.db ITEXT, PBLUE|WHITE, 5, 3
			.dw txdefeat1
		.db IIFBIRDK, 0
		.db ITEXT, PBLUE|WHITE, 5, 4
			.dw txdefeat2
		.db IENDIF
		.db IIFBIRDK, 1
		.db ITEXT, PBLUE|WHITE, 5, 4
			.dw txdefeat3
		.db ITEXT, PBLUE|YELLOW, 5, 6
			.dw txtop
		.db IENDIF
		.db IDRVLINE, 'C', PBLUE|GREEN, 31, 8, 22
		.db IDRHLINE, 'C', PBLUE|GREEN, 22, 30, 0
		.db IDRVLINE, 'C', PBLUE|GREEN, 0, 21, 8
		.db ISTOP

options_code2	.db ITEXT, PBLUE|WHITE, OPTIONS_TX_X, 11
			.dw txp1start
		.db ITEXT, PBLUE|WHITE, OPTIONS_TX_X, 12
			.dw txp2start
		.db ITEXT, PBLUE|WHITE, OPTIONS_TX_X, 13
p1intext		.dw txplayer1ink
		.db ITEXT, PBLUE|WHITE, OPTIONS_TX_X, 14
p2intext		.dw txplayer2ink
		.db ITEXT, PBLUE|WHITE, OPTIONS_TX_X, 15
			.dw txredefine
		.db ISTOP

#ifdef LANG_EN
txpress		.db "PRESS KEY FOR", 0

txp1	.db "PLAYER 1", 0
txp2	.db "PLAYER 2", 0

txpkup	.db " UP  ", 0
txpkdo	.db "DOWN ", 0
txpkle	.db "LEFT ", 0
txpkri	.db "RIGHT", 0
txpkfi	.db "FIRE ", 0
txpkstp	.db "PAUSE", 0
#endif

#ifdef LANG_ES
txpress		.db "PULSA TECLA PARA", 0

txp1	.db "JUGADOR 1", 0
txp2	.db "JUGADOR 2", 0

txpkup	.db "  ARRIBA ", 0
txpkdo	.db "  ABAJO  ", 0
txpkle	.db "IZQUIERDA", 0
txpkri	.db " DERECHA ", 0
txpkfi	.db " DISPARO ", 0
txpkstp	.db "  PARAR  ", 0
#endif

redefine_table1
	.dw txpkup, p1keys+3
	.dw txpkdo, p1keys+2
	.dw txpkle, p1keys+1
	.dw txpkri, p1keys
	.dw txpkfi, p1keys+4
	.dw txpkstp, p1keys+5
	.dw 0

redefine_table2
	.dw txpkup, p2keys+3
	.dw txpkdo, p2keys+2
	.dw txpkle, p2keys+1
	.dw txpkri, p2keys
	.dw txpkfi, p2keys+4
	.dw txpkstp, p2keys+5
	.dw 0

; Index into the table redefine_table.
redefine_i	.db 0

pnkeys	.dw p1keys
	.dw p2keys

p1keys	.db KEY_K, KEY_H, KEY_J, KEY_U, KEY_A, KEY_S, KEY_D
p2keys	.db KEY_K, KEY_H, KEY_J, KEY_U, KEY_A, KEY_S, KEY_D

IN_KEYBOARD	.equ 0
IN_JOYSTICK1	.equ 1	; Sinclair 1 on ZX
IN_JOYSTICK2	.equ 2	; Kempston on ZX
IN_NINPUTS	.equ 3

p1input	.db IN_KEYBOARD
p2input	.db IN_KEYBOARD

#ifdef ZX
input_types
	.dw poll_keyboard
	.dw poll_sinclair1
	.dw poll_kempston
#endif

#ifdef CPC
input_types
	.dw poll_keyboard
	.dw poll_joystick1
	.dw poll_joystick2
#endif

OPTIONS_WTIME	.equ 65535
options_wtime	.dw 0

; ------------------
; 'enter_options_st'
; ------------------

enter_options_st
	ld a,BORDER_MENU
	call set_border_color

	call options_reset_wtime

; Set initial text for current controls.

	ld a,(p1input)
	ld hl,txp1inputs
	call getwt
	ld (p1intext),hl

	ld a,(p2input)
	ld hl,txp2inputs
	call getwt
	ld (p2intext),hl

; Run drawing machine.

	ld hl,options_code
	call mach_start
	call mach_update_till_end

	ld hl,options_code2
	call mach_start
	call mach_update_till_end
	ret

; -------------------
; 'update_options_st'
; -------------------

update_options_st

	call pollk
	call getkey
	or a
	jr z,update_options_chk_time

	cp KEY_1
	jr z,start_one_player
	cp KEY_2
	jr z,start_two_players
	cp KEY_3
	jr z,change_p1_input
	cp KEY_4
	jr z,change_p2_input
	cp KEY_5
	jr z,start_redefine
	
update_options_chk_time

; Check time to go to attract mode.

	ld hl,(options_wtime)
	dec hl
	ld (options_wtime),hl
	ld a,h
	or l
	ret nz

	ld a,STATE_ATTRACT
	call set_state
	ret

change_p1_input

	call kfeedbk

	ld a,(p1input)
	call next_input
	ld (p1input),a
	ld hl,txp1inputs
	call getwt
	
	ld de,(13<<8)+OPTIONS_TX_X
	ld a,PBLUE|WHITE
	call drstr
	ret

change_p2_input

	call kfeedbk

	ld a,(p2input)
	call next_input
	ld (p2input),a
	ld hl,txp2inputs
	call getwt
	
	ld de,(14<<8)+OPTIONS_TX_X
	ld a,PBLUE|WHITE
	call drstr
	ret

start_redefine
	call kfeedbk
	call redefine
	call options_reset_wtime
	ret

start_two_players

	call kfeedbk

; Set two player game.

	ld a,1
	ld (two_player_game),a

; Set player lifes.

	ld a,PLAYER_LIFES
	ld (lifesp1),a
	ld (lifesp2),a
	jr start_game

start_one_player

	call kfeedbk

; Set one player game.

	xor a
	ld (two_player_game),a

; Set player lifes.

	ld a,PLAYER_LIFES
	ld (lifesp1),a
	xor a
	ld (lifesp2),a

start_game

; Player 1 starts.

	xor a
	ld (cur_player),a

; Reset levels.

	ld (levelp1),a
	ld (levelp2),a

; Reset bird killed.

	ld (bird_killed_cur_game),a

; Reset score.

	call rstscor

; Enter gameplay.

	ld a,STATE_ROUND
	call set_state
	ret

; ------------
; 'next_input'
; ------------
;	Given A IN_KEYBOARD, IN_JOYSTICK1, IN_JOYSTICK2, lets A as the next
; input type.
;
; In	A 0 - 2.
; Out	(A + 1) mod 3
; Saves	BC, DE, HL.

next_input
	inc a
	cp IN_NINPUTS
	ret nz
	xor a
	ret

; ---------------------
; 'options_reset_wtime'
; ---------------------

options_reset_wtime
	ld hl,OPTIONS_WTIME
	ld (options_wtime),hl
	ret

; ----------
; 'redefine'
; ----------

redefine
	ld hl,txpress
	ld de,(18<<8)+TXPRESS_X
	ld a,PBLUE|YELLOW
	call drstr

	ld hl,txp1
	ld de,(17<<8)+TXPN_X
	ld a,PBLUE|YELLOW
	call drstr

	ld hl,redefine_table1
	call redefine_loop

	ld hl,txp2
	ld de,(17<<8)+TXPN_X
	ld a,PBLUE|YELLOW
	call drstr

	ld hl,redefine_table2
	call redefine_loop

	ld a,BLUE|PBLUE
	ld de,1+(17<<8)
	ld bc,SCRWC-2+(4<<8)
	call clrwin
	ret

redefine_loop

; Load text address, or 0 if end.

	ld e,(hl)
	inc hl
	ld d,(hl)
	ld a,d
	or e
	jr z,redefine_end
	inc hl
	push hl
	
; Draw the info text.

	ex de,hl
	ld de,(20<<8)+TXKINFO_X
	ld a,PBLUE|YELLOW
	call drstr

; Load key config address for player.

	pop hl
	ld c,(hl)
	inc hl
	ld b,(hl)
	inc hl

redefine_wkey

; Wait for a key.

	push bc
	push hl
	call pollk
	pop hl
	pop bc
	call getkey
	jr z,redefine_wkey

; Save key.

	ld (bc),a

; Some feedback.

	call kfeedbk
	jr redefine_loop

redefine_end
	ret


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

; ----------------------------------------------------------------------------
; CIDLESA's Altair arcade (1981) port to the ZX Spectrum.
;
; Gameplay state.
; ----------------------------------------------------------------------------

; If the bird hast been killed in this game.
bird_killed_cur_game	.db 0

; If we are on two player mode.
two_player_game	.db 0

; If the player's ship is destroyed.
ship_killed	.db 0

; All aliens killed.
aliens_killed	.db 0

; Aliens alive.
aliens_alive	.db 0

; If go to next level.
goto_next_level	.db 0

; Pause enabled.
paused		.db 0

ALIENS_KILLED_WTIME	.equ 24
aliens_killed_wtime	.db ALIENS_KILLED_WTIME

; The player starts with this extra lifes.
PLAYER_LIFES	.equ 2

; Current player (0 or 1).
cur_player	.db 0

pdata_table
	.dw lifesp1
	.dw lifesp2

; Data for player 1.
lifesp1	.db 0
levelp1	.db 0

; Data for player 2.
lifesp2	.db 0
levelp2	.db 0

; Current player data is duplicated here.
lifes	.db 0
level	.db 0

; 10000 boundary overflow.
tenthof	.db 0

; -------------------
; 'enter_gameplay_st'
; -------------------

enter_gameplay_st

; Clear screen.

	ld a,PBLACK|BLACK
	call clrscr

	ld a,BORDER_GAME
	call set_border_color

; Set input for this player.

; 1. Set defined keys.

	ld hl,pnkeys
	ld a,(cur_player)
	call getwt
	call set_keys

; 2. Set input type.

	ld hl,p1input
	ld a,(cur_player)
	call getbt
	ld hl,input_types
	call getwt
	ld (poll_handler),hl

; Copy current player data.

	ld hl,pdata_table
	ld a,(cur_player)
	call getwt
	ld de,lifes
	ld bc,2
	ldir

; Init hud.

	call drcidelsa
	call drtxhscor
	call drhscor

	xor a
	call drtxplayer
	call drscor

	ld a,(two_player_game)
	or a
	jr z,enter_gameplay_st00

	ld a,1
	call drtxplayer
	call drscor

enter_gameplay_st00

; Draw UP for current player.

	ld a,(cur_player)
	call drscorup

	call init_level
	ret

; --------------------
; 'update_gameplay_st'
; --------------------

update_gameplay_st

	call polli

; Check if pause key pressed.

	call chkpause
	ret c

; Check if game paused.

	ld a,(paused)
	or a
	ret nz

; Update gameplay.

	call gameplay_loop

; If ship is destroyed...

	call chk_ship_killed
	ret c

; If all aliens killed.

	call chk_aliens_killed
	ret c

; If we want next level...

	call chk_goto_next_level
	ret c

; Restart if service key.

	ld a,(cheats_rst)
	or a
	call nz,chkrestart
	ret

; ---------------------
; 'chk_goto_next_level'
; ---------------------

chk_goto_next_level

	ld a,(goto_next_level)
	or a
	ret z

	xor a
	ld (goto_next_level),a

	call nextlevel
	scf
	ret

; -----------------
; 'chk_ship_killed'
; -----------------
;	Checks if the player is killed. If so changes state.
;
; Out	CY if killed.

chk_ship_killed

	ld a,(ship_killed)
	or a
	ret z

	call stop_all_snd

	ld a,STATE_KILLED
	call set_state
	scf
	ret

; -------------------
; 'chk_aliens_killed'
; -------------------
;
; Out	CY if all aliens killed and wait until some time passes.

chk_aliens_killed

	ld a,(aliens_killed)
	or a
	ret z

; All aliens are killed. Wait some time.

	ld hl,aliens_killed_wtime
	dec (hl)
	ret nz

; Time passed.

	call nextlevel
	scf
	ret

; -----------------------------
; 'chkrestart' Check if restart
; -----------------------------
;	Restart if service key.

chkrestart

	ld a,(finput)
	and K_SERVB
	ret z

	call nextlevel
	ret

; -----------------------------
; 'chkpause' Check if pause
; -----------------------------
;	Pause game if pause key pressed.

chkpause

; Check for key.

	ld a,(finput)
	and K_SERVA
	ret z

; Switch paused.

	ld a,(paused)
	xor 1
	ld (paused),a

; Pause or resume sound.
	
	or a
	jr z,chkpause_resume

chkpause_stop

	call pause_sound
	jr chkpause_end
	
chkpause_resume

	call resume_sound

chkpause_end

	scf
	ret

; -----------
; 'nextlevel'
; -----------

nextlevel
	call stop_all_snd
	ld a,(level)
	inc a
	cp 8
	jr nz,nextlevel_set

; After the bird, we skip the first two levels always.

	ld a,2

nextlevel_set
	ld (level),a
	call init_level
	ret

; ------------------------------------------
; 'chk_tenthof' Check 10000 points overflow.
; ------------------------------------------
;	If CY set the overflow.
;
; Saves	BC, DE.

chk_tenthof

	rla
	and 1
	ld hl,tenthof
	or (hl)
	ld (hl),a
	ret

; --------------
; 'chk_add_life'
; --------------
;	Checks if we have to add a new life, and adds it if so.

chk_add_life

	ld a,(tenthof)
	or a
	ret z

; Add life.

	ld hl,lifes
	inc (hl)

; Control if we pass from 255.

	ret nz

; We passed, set to 255.

	dec (hl)
	ret

; ---------------
; 'gameplay_loop'
; ---------------

gameplay_loop

; Init rect list.

	call inirecs	

; Draw stars.

	call drstrs

; Draw sprites.

	call drsprs

; Draw effects.

	call drfx

; Colorize the attribute buffer if needed.

	call colorize

; Dump Back Buffer to VRAM.

	call dump_bbuf

; Erase sprites.

	call blkrecs

; Swap starfield if needed.

	call chstrf

; Execute object behaviors.

	call exobs

; Update animations.

	call update_anims

	ret

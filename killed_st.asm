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

; ----------------------------------------------------------------------------
; CIDLESA's Altair arcade (1981) port to the ZX Spectrum.
;
; Killed state.
; ----------------------------------------------------------------------------

kill_color	.db 0
kill_colors	.db BBUF_RED
		.db BBUF_GREEN

KILLED_WTIME	.equ 32
killed_wtime	.db KILLED_WTIME

; -----------------
; 'enter_killed_st'
; -----------------

enter_killed_st

	call init_objtab
	call stop_anims

	ld a,SND_DIE
	call play_snd

; Set wait time.

	ld a,KILLED_WTIME
	ld (killed_wtime),a
	ret

; ------------------
; 'update_killed_st'
; ------------------

update_killed_st

; Paused?

	call polli
	call chkpause
	ld a,(paused)
	or a
	ret nz

; Draw.

	call draw_killed

; Wait some time.

	ld hl,killed_wtime
	dec (hl)
	ret nz

; Time out!

	call stop_all_snd

; Reset backbuffer paper color.

	ld a,BBUF_BLACK
	call set_bbuf_paper
	
; Minus one life.

	ld hl,lifes
	dec (hl)

; Reset high score overflow and 10000 points overflow.

	xor a
	ld (hscorof),a
	ld (tenthof),a
	
; Restore score of current player to the last backup.

	ld a,(cur_player)
	call restscor
	call drscor

; Backup the lifes and level of this player.

	ld hl,pdata_table
	call getwt
	ex de,hl
	ld hl,lifes
	ld bc,2
	ldir

; If two player game, switch player, only if player can play.

	ld a,(two_player_game)
	or a
	jr z,cannot_switch

; Check the lifes of the other player.

	ld a,(cur_player)
	xor 1
	ld hl,pdata_table
	call getwt
	ld a,(hl)
	cp 255
	jr z,cannot_switch

switch_player

; Switch player.

	ld a,(cur_player)
	xor 1
	ld (cur_player),a
	jr continue_playing_switched

cannot_switch

; Check my lifes.

	ld a,(lifes)
	cp 255
	jr nz,continue_playing_not_switched

	call sethscor
	call drhscor

	ld a,(bird_killed_cur_game)
	or a
	jr z,end_game_goto_over
	ld a,STATE_NAME
	jr end_game

end_game_goto_over
	ld a,STATE_GAMEOVER

end_game
	call set_state
	ret

continue_playing_switched

	ld a,STATE_ROUND
	call set_state
	ret

continue_playing_not_switched

	ld a,STATE_GAMEPLAY
	call set_state
	ret

; -------------
; 'draw_killed'
; -------------
;	Draws the killed stated.

draw_killed

	call gameplay_loop

; Next kill color in table.

	ld de,kill_color
	ld a,(de)
	inc a
	and 1
	ld (de),a
	ld hl,kill_colors
	call getbt
	call set_bbuf_paper
	ret


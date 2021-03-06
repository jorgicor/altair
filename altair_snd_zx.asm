; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; -------------------
; Beeper sound table.
; -------------------

beep_snd_t
	.db SND_CHAN0+SND_PROC
	.dw start_die_snd_beep
	.db SND_CHAN0+SND_PROC
	.dw start_shot_snd_beep
	.db SND_CHAN1
	.dw 0
	.db SND_CHAN1
	.dw snd_lvl2_beep_h
	.db SND_CHAN1
	.dw 0
	.db SND_CHAN1
	.dw 0
	.db SND_CHAN1
	.dw 0
	.db SND_CHAN1
	.dw 0
	.db SND_CHAN1
	.dw 0
	.db SND_CHAN1
	.dw snd_bird_beep_h
	.db SND_CHAN1
	.dw snd_bird2_beep_h

; ---------------------
; 'start_shot_snd_beep'
; ---------------------
;
; In	IY shot object. IX sound channel.

start_shot_snd_beep
	ld (shot_snd_ob),iy
	ld hl,SHOT_SND_START
	ld (shot_snd),hl
	ld (ix+SND_CHAN_DATA),shot_snd_beep_f&255
	ld (ix+SND_CHAN_DATA+1),shot_snd_beep_f>>8
	ld (ix+SND_CHAN_FLAGS),+SND_CHAN_F_ON+SND_CHAN_F_PROC
	ret

; -----------------
; 'shot_snd_beep_f'
; -----------------
;
; In	IX channel data.

SHOT_SND_START	.equ 100
SHOT_SND_DELTA	.equ 25

shot_snd_beep_f

; Set duration; if sound too long, set minimum duration.

	ld hl,(shot_snd)
	push hl
	ld de,1
	ld a,2
	cp h
	jr nc,shot_snd_beep
	dec de

shot_snd_beep

	call beep
	pop hl

	ld bc,SHOT_SND_DELTA
	add hl,bc
	ld (shot_snd),hl
	ret

; --------------------
; 'start_die_snd_beep'
; --------------------
;
; In	IX sound channel.

die_snd	.dw 0

start_die_snd_beep
	ld hl,1
	ld (die_snd),hl
	ld (ix+SND_CHAN_DATA),die_snd_beep_f&255
	ld (ix+SND_CHAN_DATA+1),die_snd_beep_f>>8
	ld (ix+SND_CHAN_FLAGS),+SND_CHAN_F_ON+SND_CHAN_F_PROC
	ret

; ----------------
; 'die_snd_beep_f'
; ----------------
;
; In	IX channel data.

die_snd_beep_f
	ld hl,(die_snd)
	ld a,7
	cp h
	jr nc,die_snd_beep_play
	call stop_snd_ix
	ret

die_snd_beep_play
	push hl
	ld de,1
	call beep
	pop hl
	ld bc,25
	add hl,bc
	ld (die_snd),hl
	add hl,bc
	ld de,1
	call beep
	ret

; --------------------
; Songs for the beeper
; --------------------

snd_lvl2_beep_h
	.db 8
snd_lvl2_beep_d
	.db E4, E4, E5, E5, REST, REST, REST, REST, REST
	.db SND_GOTO
	.dw snd_lvl2_beep_d

snd_bird_beep_h
	.db 4
snd_bird_beep_d
	.db E6, E5, AS5, E6, AS5, E5
	.db B4, C3, D5, G4, CS6, G5, DS6
	.db E4, F6, FS4, C6, FS5, C4, FS5
	.db SND_GOTO
	.dw snd_bird_beep_d

snd_bird2_beep_h
	.db 13
snd_bird2_beep_d
	.db C4, C5, FS5, REST
	.db SND_GOTO
	.dw snd_bird2_beep_d


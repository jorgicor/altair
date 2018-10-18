; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; -------------
; 'update_beep'
; -------------
;	Updates sound channels for the ZX Spectrum beeper.
; In this case, only one of the channels play, and the first channel that
; can play, plays. The rest of channels, if they are tune channels, they
; pass time but don't play anything.

update_beep

	push ix

; No silence for now...

	ld d,0

; For all channels.

	ld ix,snd_chan_t
	ld e,SND_NCHANS
	ld bc,SND_CHAN_SZ

update_beep_loop

	bit SND_CHAN_B_ON,(ix+SND_CHAN_FLAGS)
	jr z,update_beep_next

; Is procedural?

	bit SND_CHAN_B_PROC,(ix+SND_CHAN_FLAGS)
	jr z,update_beep_tune

; It is procedural. We are in silence?

	xor a
	cp d
	jr nz,update_beep_next

; Not in silence, play.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)

	push bc
	push de
	call jphl
	pop de
	pop bc
	jr update_beep_silence

update_beep_tune

; Dec tune speed counter.

	dec (ix+SND_CHAN_T)
	jr nz,update_beep_silence

; Reset speed counter.

	ld a,(ix+SND_CHAN_T0)
	ld (ix+SND_CHAN_T),a

update_beep_play

; Get note in HL and point to next note.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)
	ld a,(hl)
	inc hl
	ld (ix+SND_CHAN_DATA),l
	ld (ix+SND_CHAN_DATA+1),h

; Chek for REST.

	cp REST
	jr z,update_beep_silence

; Check for GOTO.

	cp SND_GOTO
	jr z,update_beep_goto

update_beep_note

; We enter here with A being the note index. Save for later.

	ld h,a

; If already playing some sound, it has priority.

	xor a
	or d
	jr nz,update_beep_silence

; Play note.

	push de

; Get note period from table.

	ld a,h
	ld hl,beep_tone_t
	call getwt

; And play.

	ld de,4
	call beep

	pop de
	jr update_beep_silence

update_beep_goto

; Go to an adress in the tune.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)
	ld a,(hl)
	ld (ix+SND_CHAN_DATA),a
	inc hl
	ld a,(hl)
	ld (ix+SND_CHAN_DATA+1),a
	jr update_beep_play

update_beep_silence
	
	ld d,1
	
update_beep_next

; Go to next channel.

	add ix,bc
	dec e
	jr nz,update_beep_loop

update_beep_end

	pop ix
	ret


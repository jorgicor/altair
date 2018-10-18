; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; Channels.
SND_CHAN0	.equ 0
SND_CHAN1	.equ 1

; Flag that can be added to the channel in the sounds table to signal that
; the sound is procedural.
SND_PROC	.equ $80

; To select only the channel bits when we take the channel and flags from the
; sound tables.
SND_CHAN_MASK	.equ 1

; -----------------------------------
; Indexes into the channel structure.
; -----------------------------------

; Flags. Bits:
;	0	The channel is on (1) or off.
;	1	The channel is playing a procedural sound (1) or not.
; These bits can be accesed with SND_CHAN_B_X if using res,bit or set
; instructions or with SND_CHAN_F_X if using load instructions or masking.
SND_CHAN_FLAGS	.equ 0

; Current speed counter. Only used for tunes.
SND_CHAN_T	.equ 1

; Sound speed. Only used for tunes.
SND_CHAN_T0	.equ 2

; If the sound is procedural, this points to a function to call to generate
; the sound. If not, this points to the current tune data.
SND_CHAN_DATA	.equ 3

; Counter for the tunes repeat feature.
SND_CHAN_REPT	.equ 5

; Address to return when an END_REPEAT is found.
SND_CHAN_REPADR	.equ 6

; Bits to check on flags.
SND_CHAN_B_ON	.equ 0
SND_CHAN_B_PROC	.equ 1
SND_CHAN_F_ON	.equ 1
SND_CHAN_F_PROC	.equ 2

; Number of channels.
SND_NCHANS	.equ 2

; Size of the channel struct.
SND_CHAN_SZ	.equ 8

; If sound is paused.
snd_paused	.db 0

; Channel table.
snd_chan_t

snd_chan0_flags	.db 0
snd_chan0_t	.db 0
snd_chan0_t0	.db 0
snd_chan0_data	.dw 0
snd_chan0_rept	.db 0
snd_chan0_repadr	.dw 0
snd_chan0_spare	.db 0

snd_chan1_flags	.db 0
snd_chan1_t	.db 0
snd_chan1_t0	.db 0
snd_chan1_data	.dw 0
snd_chan1_rept	.db 0
snd_chan1_repadr	.dw 0
snd_chan1_spare	.db 0

; Sound tables to fast indexing.
snd_tables
	.dw beep_snd_t
	.dw ay_snd_t

#ifdef CPC
; No need for the CPC to define this.
beep_snd_t
#endif

; ----------
; 'play_snd'
; ----------
;	Starts a sound. If another sound was playing in that channel, it is
; stopped. If the sound data or function is null (0) no sound is played.
; If the sound to play is procedural, the function to start the sound
; will be called with IX pointing to the channel data. If it is needed to pass
; data to the function, use the IY register.
;
; In	A sound index in table.
; Saves	BC, DE, HL.

play_snd

	push bc
	push de
	push hl

; Calc offset in any sound table.

	ld c,a
	ld b,0
	ld h,b
	ld l,c
	add hl,bc
	add hl,bc
	ld b,h
	ld c,l

; Select table based on ay_detected.

	ld a,(ay_detected)
	ld hl,snd_tables
	call getwt
	add hl,bc
	call start_snd

play_snd_end

	pop hl
	pop de
	pop bc
	ret

; -----------
; 'start_snd'
; -----------
;
; In	HL address of table sound data.

start_snd
	push ix

; Check channel and sound type.

; Stop sound on this channel.

	ld a,(hl)
	and SND_CHAN_MASK
	call get_snd_chan_ix
	call stop_snd_ix

; Get channel and data.

	ld c,(hl)
	inc hl
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl

; Check if valid sound.

	ld a,h
	or l
	jr z,start_snd_end

; Check if procedural.

	ld a,c
	and SND_PROC
	jr z,start_snd_tune

; Procedural sound.
; Call the procedural start function with IX pointing to channel data. 

	call jphl
	jr start_snd_end

start_snd_tune

; It is a tune.

; Take tune speed.

	ld a,(hl)
	inc hl

; Set channel values for tune.

	ld (ix+SND_CHAN_T0),a
	ld (ix+SND_CHAN_T),a
	ld (ix+SND_CHAN_DATA),l
	ld (ix+SND_CHAN_DATA+1),h
	ld (ix+SND_CHAN_FLAGS),SND_CHAN_F_ON

start_snd_end
	pop ix
	ret

; -----------------
; 'get_snd_chan_ix'
; -----------------
;	Given a channel index, returns IX pointing to the channel data.
;
; In	A channel.
; Out	IX channel data address.
; Saves	BC, DE, HL.

get_snd_chan_ix
	push bc

; x8 .

	rlca
	rlca
	rlca

; Get chan data address.

	ld ix,snd_chan_t
	ld b,0
	ld c,a
	add ix,bc

	pop bc
	ret

; -------------
; 'stop_snd_ix'
; -------------
;	Stops sound channel.
;
; In	IX pointer to channel data.

stop_snd_ix
	ld (ix+SND_CHAN_FLAGS),0
	ret

; ----------
; 'stop_snd'
; ----------
;	Stops sound channel.
;
; In	A channel.
; Saves	All.

stop_snd
	push ix
	call get_snd_chan_ix
	call stop_snd_ix
	pop ix
	ret

; --------------
; 'stop_all_snd'
; --------------
; 	Stops any sound.
;
; Saves	BC, DE, HL.

stop_all_snd
	push bc
	push ix

	ld a,SND_NCHANS
	ld ix,snd_chan_t
	ld bc,SND_CHAN_SZ

stop_all_snd_loop

	call stop_snd_ix
	add ix,bc
	dec a
	jr nz,stop_all_snd_loop 

	pop ix
	pop bc
	ret

; -------------
; 'pause_sound'
; -------------
; 	Pauses sound.
;
; Saves	BC, DE, HL.

pause_sound

	push bc
	push de
	push hl

; If already paused, do nothing.

	ld hl,snd_paused
	ld a,(hl)
	or a
	jr nz,pause_sound_end

; Set as paused.

	ld (hl),1

; If beeper sound, do nothig else.

	ld a,(ay_detected)
	or a
	jr z,pause_sound_end

; Deactivate sound mixer.

	ld a,63
	ld (ay_mixer),a
	call ay_refresh

pause_sound_end

	pop hl
	pop de
	pop bc
	ret

; --------------
; 'resume_sound'
; --------------
; 	Resumes paused sound.
;
; Saves	BC, DE, HL.

resume_sound

	push bc
	push de
	push hl

; If not paused, do nothig.

	ld hl,snd_paused
	ld a,(hl)
	or a
	jr z,resume_sound_end

; Set resumed.

	ld (hl),0

; If beeper sound, do nothig else.

	ld a,(ay_detected)
	or a
	jr z,resume_sound_end

resume_sound_end

	pop hl
	pop de
	pop bc
	ret

; --------------
; 'update_sound'
; --------------
; 	Plays the current sounds in channels.

update_sound

; Check if sound paused.

	ld a,(snd_paused)
	or a
	ret nz

; Sound running.

update_sound_run

	ld a,(ay_detected)
	or a
	jp z,update_beep
	jp update_ay

; -----------
; 'update_ay'
; -----------
;	Updates sound channels for the AY-3-8912. Both channels can play.

update_ay

	push ix

; For all channels.
; D is current channel bit mask (1,2). E is channel count.

	ld d,1
	ld e,0
	ld ix,snd_chan_t
	ld bc,SND_CHAN_SZ

update_ay_loop

	bit SND_CHAN_B_ON,(ix+SND_CHAN_FLAGS)
	jp z,update_ay_silence

; This sound is active.
; Is procedural?

	bit SND_CHAN_B_PROC,(ix+SND_CHAN_FLAGS)
	jr z,update_ay_tune

; Play.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)
	push bc
	push de
	call jphl
	pop de
	pop bc
	jp update_ay_next

update_ay_tune

; Dec tune speed counter.

	dec (ix+SND_CHAN_T)
	jp nz,update_ay_next

; Reset speed counter.

	ld a,(ix+SND_CHAN_T0)
	ld (ix+SND_CHAN_T),a

update_ay_play

; Get note in HL and point to next note.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)
	ld a,(hl)
	inc hl
	ld (ix+SND_CHAN_DATA),l
	ld (ix+SND_CHAN_DATA+1),h

; Check for REST.

	cp REST
	jr z,update_ay_silence

; Check for GOTO.

	cp SND_GOTO
	jr z,update_ay_goto

; Check for REPEAT

	cp SND_REPEAT
	jr z,update_ay_repeat

; Check for END_REPEAT

	cp SND_END_REPEAT
	jr z,update_ay_end_repeat
	jr update_ay_note

update_ay_goto

; Go to an adress in the tune.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)
	ld a,(hl)
	ld (ix+SND_CHAN_DATA),a
	inc hl
	ld a,(hl)
	ld (ix+SND_CHAN_DATA+1),a
	jr update_ay_play

update_ay_repeat

; We start a repeat block.

; Get counter.

	ld l,(ix+SND_CHAN_DATA)
	ld h,(ix+SND_CHAN_DATA+1)
	ld a,(hl)
	ld (ix+SND_CHAN_REPT),a
	inc hl
	ld (ix+SND_CHAN_REPADR),l
	ld (ix+SND_CHAN_REPADR+1),h
	ld (ix+SND_CHAN_DATA),l
	ld (ix+SND_CHAN_DATA+1),h
	jr update_ay_play

update_ay_end_repeat

; We repeat the block or continue.

	dec (ix+SND_CHAN_REPT)
	jr z,update_ay_play

; Repeat the block.

	ld l,(ix+SND_CHAN_REPADR)
	ld h,(ix+SND_CHAN_REPADR+1)
	ld (ix+SND_CHAN_DATA),l
	ld (ix+SND_CHAN_DATA+1),h
	jr update_ay_play

update_ay_note

; Play note.
; We enter here with A being the note index. Get note period.

	ld hl,ay_tone_t
	call getwt

; Set note period in the correct AY channel. This is (ay_a + e*2) <- hl.

	push de
	push bc
	sla e
	ld d,0
	ex de,hl
	ld bc,ay_a
	add hl,bc
	ld (hl),e
	inc hl
	ld (hl),d
	pop bc
	pop de

; Reset this channel bit on mixer -> activate.

	ld hl,ay_mixer
	ld a,d
	cpl
	and (hl)
	ld (hl),a
	jr update_ay_next

update_ay_silence

; Silence the AY channel.

	ld hl,ay_mixer
	ld a,d
	or (hl)
	ld (hl),a
	
update_ay_next

; Go to next channel.

	add ix,bc
	sla d
	inc e

	ld a,e
	cp SND_NCHANS
	jp nz,update_ay_loop

update_ay_end

	pop ix
	call ay_refresh
	ret

#include "notes.asm"

#ifdef ZX
	#include "sound_zx.asm"
	#include "tone_beep.asm"
#endif

#ifdef CPC
	#include "sound_cpc.asm"
#endif

#include "tone_ay.asm"

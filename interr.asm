; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Interrupt. Sound and music.
; ----------------------------------------------------------------------------

#ifdef ZX
interrupt
	di
	push af
	push bc
	push de
	push hl
	push ix

	call update_sound

interr_end
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ei
	reti
#endif

#ifdef CPC
cpc_inter_n	.db CPC_INTS_PER_VSYNC

interrupt
	di
	push af
	push hl

; Only update once per vertical retrace.

	ld hl,cpc_inter_n
	dec (hl)
	jr nz,interr_end
	ld (hl),CPC_INTS_PER_VSYNC

	push bc
	push de
	push ix

	call update_sound
	call pollhk

	pop ix
	pop de
	pop bc

interr_end
	pop hl
	pop af
	ei
	reti
#endif


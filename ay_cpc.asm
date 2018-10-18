; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ---------------------
; AY-3-8912 sound chip.
; ---------------------

; If the AY-3-8912 sound chip is detected.
ay_detected	.db 1

; ---------------------------------
; 'detect_ay' Detect AY-3-8912 chip
; ---------------------------------
;	Will set 'ay_detected' to 1 if the AY sound chip is detected on the
; system, or 0 otherwise.

detect_ay
	ret

; ------------
; 'ay_refresh'
; ------------
;	Updates the AY chip registers copying our buffer of register data.

ay_refresh

; Start from last register, so we can use some speed tricks on this routine.

	ld hl,ay_pattern
	ld e,+AY_NREGS-1

; A always 0.

	xor a

; D always PPI A.

	ld d,PPI_AH
	
; Configure PPI port A as output.
; (Should be already).

	; ld bc,+PPI_CTRL+$82
	; out (c),c

ay_refresh_reg

; Select PSG register.

; 1 Write the PSG register number we want in PPI port A.

	ld b,d
	out (c),e

; 2 Use PPI port C 'select PSG register' function.

	ld bc,+PPI_C+$c0
	out (c),c

; Use PPI port C 'PSG inactive' function.
; (Needed for CPC+).

	out (c),a

; Put the value for the PSG register in PPI port A.

	ld b,d
	ld c,(hl)
	out (c),c

; Use PPI port C 'Write to PSG register'.

	ld bc,+PPI_C+$80
	out (c),c

; Use PPI port C 'PSG inactive' function.
; (Needed for CPC+).

	out (c),a

; Next register.

	dec hl
	dec e

; When E passes from 0 to 255, positive flag SF won't be set.

	jp p,ay_refresh_reg
	ret

; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ---------------------
; AY-3-8912 sound chip.
; ---------------------

; (S)elect register or (R)ead register port.
AY_SR_PORT	.equ	$fffd

; Write value port.
AY_W_PORT	.equ	$bffd	

AY_SR_PORT_H	.equ	AY_SR_PORT >> 8
AY_W_PORT_H	.equ	AY_W_PORT >> 8
AY_PORT_L	.equ	$fd

; If the AY-3-8912 sound chip is detected.
ay_detected	.db 0

; ---------------------------------
; 'detect_ay' Detect AY-3-8912 chip
; ---------------------------------
;	Will set 'ay_detected' to 1 if the AY sound chip is detected on the
; system, or 0 otherwise.

detect_ay

; Select a 4 bit register.

	ld bc,AY_SR_PORT
	ld a,AY_R_AH
	out (c),a

; Start from 0, next $ff to 0.

	ld e,0

detect_ay_loop

; We always shoud read the entry value & 0x0f as this is a 4 bit register.

	ld a,e
	and $0f

; Write a value to it.

	ld b,AY_W_PORT_H
	out (c),e

; Read it back.

	ld b,AY_SR_PORT_H
	in e,(c)

; Must be the same.

	cp e
	jr nz,detect_ay_negative

; Next value.

	dec e
	jr nz,detect_ay_loop

; Detected.
; Set A to 1.

	ld a,1
	ld (ay_detected),a
	ret

detect_ay_negative
	
; Not detected.

	xor a
	ld (ay_detected),a
	ret

; ------------
; 'ay_refresh'
; ------------
;	Updates the AY chip registers copying our buffer of register data.

ay_refresh
	ld hl,ay_data
	ld e,AY_NREGS
	ld d,0
	ld c,AY_PORT_L

ay_refresh_reg

	ld a,d
	ld b,AY_SR_PORT_H
	out (c),a
	ld a,(hl)
	inc hl
	ld b,AY_W_PORT_H
	out (c),a
	inc d
	dec e
	jr nz,ay_refresh_reg
	ret	


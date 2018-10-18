; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ---------------------
; AY-3-8912 sound chip.
; ---------------------

; Course pitches are 0-15 (4 bits)
; Noise pitch is 0-15.
; Mixer, enabled low (0):
;	bit 0 tone a
;	bit 1 tone b
;	bit 2 tone c
;	bit 3 noise a
;	bit 4 noise b
;	bit 5 noise c
; Volumes are 4 bit, but if bit 5 is set the envelope pattern is used instead
; of the volume specified.
; Envelope pattern is 4 bit:
; 	0	\_______	single decay then off
;	1	/		single attack then hold
;	4	/|______	single attack then off
;	8	\|\|\|\|	repeated decay
;	9	= 0
;	10	\/\/\/\/	repeated decay-attack
;	11	\|		single decay then holf
;	12	/|/|/|/|	repeated attack
;	14	/\/\/\/\	repeated attack-decay
;	15	= 4

; Registers indexes.

AY_R_A		.equ 0
AY_R_AL		.equ 0
AY_R_AH		.equ 1
AY_R_B		.equ 2
AY_R_BL		.equ 2
AY_R_BH		.equ 3
AY_R_C		.equ 4
AY_R_CL		.equ 4
AY_R_CH		.equ 5
AY_R_NOISE	.equ 6
AY_R_MIXER	.equ 7
AY_R_VOL_A	.equ 8
AY_R_VOL_B	.equ 9
AY_R_VOL_C	.equ 10
AY_R_ENV	.equ 11
AY_R_ENV_L	.equ 11
AY_R_ENV_H	.equ 12
AY_R_PATTERN	.equ 13

; Total number of registers.
AY_NREGS	.equ 14

; To access the bits in mixer.
AY_MIX_TONEA_F	.equ 	1
AY_MIX_TONEA_B	.equ 	0
AY_MIX_TONEB_F	.equ 	1
AY_MIX_TONEB_B	.equ 	1
AY_MIX_TONEC_F	.equ 	1
AY_MIX_TONEC_B	.equ 	2

; Max allowed volume.
AY_MAX_VOL	.equ 15

; AY buffer data. All this data will be dumped to the AY chip registers.

ay_data
ay_a
ay_a_fine	.db 0
ay_a_course	.db 0
ay_b
ay_b_fine	.db 0
ay_b_course	.db 0
ay_c
ay_c_fine	.db 0
ay_c_course	.db 0
ay_noise	.db 0
ay_mixer	.db 63
ay_vol_a	.db 15
ay_vol_b	.db 15
ay_vol_c	.db 15
ay_env
ay_env_fine	.db 0
ay_env_course	.db 0
ay_pattern	.db 0

#ifdef ZX
	#include "ay_zx.asm"
#endif

#ifdef CPC
	#include "ay_cpc.asm"
#endif

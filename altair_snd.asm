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

; --------------------------------------
; Sound for the AY chip as it is common.
; --------------------------------------

SND_DIE		.equ 0
SND_SHOT	.equ 1
SND_LVL1	.equ 2
SND_LVL2	.equ 3
SND_LVL3	.equ 4
SND_LVL4	.equ 5
SND_LVL5	.equ 6
SND_LVL6	.equ 7
SND_LVL7	.equ 8
SND_BIRD	.equ 9
SND_BIRD2	.equ 10

; Ay sound table.

ay_snd_t
	.db SND_CHAN0+SND_PROC
	.dw start_die_snd_ay
	.db SND_CHAN0+SND_PROC
	.dw start_shot_snd_ay
	.db SND_CHAN1 
	.dw snd_lvl1_ay_h
	.db SND_CHAN1 
	.dw snd_lvl2_ay_h
	.db SND_CHAN1 
	.dw snd_lvl3_ay_h
	.db SND_CHAN1 
	.dw snd_lvl4_ay_h
	.db SND_CHAN1 
	.dw snd_lvl3_ay_h
	.db SND_CHAN1 
	.dw snd_lvl6_ay_h
	.db SND_CHAN1 
	.dw snd_lvl6_ay_h
	.db SND_CHAN1 
	.dw snd_bird_ay_h
	.db SND_CHAN1 
	.dw snd_bird2_ay_h

; ----------------
; For the AY chip.
; ----------------

; -------------------
; 'start_shot_snd_ay'
; -------------------
;	In the arcade, the shot sound starts at E7 and gets lower in pitch.
;
; In	IY shot object. IX sound channel.

start_shot_snd_ay
	ld (shot_snd_ob),iy
	ld hl,SHOT_SND_AY_START
	ld (shot_snd),hl
	ld (ix+SND_CHAN_DATA),shot_snd_ay_f&255
	ld (ix+SND_CHAN_DATA+1),shot_snd_ay_f>>8
	ld (ix+SND_CHAN_FLAGS),+SND_CHAN_F_ON+SND_CHAN_F_PROC
	ld a,AY_MAX_VOL
	ld (ay_vol_a),a
	ret

; ---------------
; 'shot_snd_ay_f'
; ---------------
;
; In	IX channel data.

SHOT_SND_AY_START	.equ YE7
SHOT_SND_AY_DELTA	.equ 10
shot_snd	.dw 0
shot_snd_ob	.dw 0

shot_snd_ay_f

; Set duration; if sound too long, set minimum duration.

	ld hl,(shot_snd)
	push hl
	ld de,1
	ld a,2
	cp h
	jr nc,shot_snd_ay
	dec de

shot_snd_ay

	ld (ay_a),hl
	ld hl,ay_mixer
	res AY_MIX_TONEA_B,(hl)
	pop hl

	ld bc,SHOT_SND_AY_DELTA
	add hl,bc
	ld (shot_snd),hl
	ret

; -------------------
; 'start_shot_snd_ay'
; -------------------
;	As seen in the real arcade, the die sound maintains a 42Hz note,
; which is E1 more or less, and decrements the volumne step by step.
;
; In	IY shot object. IX sound channel.

start_die_snd_ay
	ld (ix+SND_CHAN_T),8
	ld (ix+SND_CHAN_DATA),die_snd_ay_f&255
	ld (ix+SND_CHAN_DATA+1),die_snd_ay_f>>8
	ld (ix+SND_CHAN_FLAGS),+SND_CHAN_F_ON+SND_CHAN_F_PROC
	ld hl,YE1
	ld (ay_a),hl
	ld a,AY_MAX_VOL
	ld (ay_vol_a),a
	ret

; --------------
; 'die_snd_ay_f'
; --------------
;
; In	IX channel data.

die_snd_ay_f

	ld hl,ay_mixer
	res AY_MIX_TONEA_B,(hl)

	dec (ix+SND_CHAN_T)
	ret nz

	ld (ix+SND_CHAN_T),8
	ld hl,ay_vol_a
	dec (hl)
	ret nz

	call stop_snd_ix
	ret

; ------
; Tunes.
; ------

snd_lvl1_ay_h
	.db 4
snd_lvl1_ay_d
#ifdef ZX
#include "song_11_zx.asm"
#endif
#ifdef CPC
#include "song_11_cpc.asm"
#endif
	.db SND_GOTO
	.dw snd_lvl1_ay_d

snd_lvl2_ay_h
	.db 4
snd_lvl2_ay_d
#ifdef ZX
#include "song_21_zx.asm"
#endif
#ifdef CPC
#include "song_21_cpc.asm"
#endif
	.db SND_REPEAT, 4
#ifdef ZX
#include "song_22_zx.asm"
#endif
#ifdef CPC
#include "song_22_cpc.asm"
#endif
	.db SND_END_REPEAT
snd_lvl2_ay_loop
#ifdef ZX
#include "song_23_zx.asm"
#endif
#ifdef CPC
#include "song_23_cpc.asm"
#endif
	.db SND_GOTO
	.dw snd_lvl2_ay_loop
	
snd_lvl3_ay_h
	.db 4
snd_lvl3_ay_d
	.db SND_REPEAT, 7
#ifdef ZX
#include "song_31_zx.asm"
#endif
#ifdef CPC
#include "song_31_cpc.asm"
#endif
	.db SND_END_REPEAT
	.db SND_REPEAT, 14
#ifdef ZX
#include "song_32_zx.asm"
#endif
#ifdef CPC
#include "song_32_cpc.asm"
#endif
	.db SND_END_REPEAT
snd_lvl3_ay_loop
#ifdef ZX
#include "song_33_zx.asm"
#endif
#ifdef CPC
#include "song_33_cpc.asm"
#endif
	.db SND_GOTO
	.dw snd_lvl3_ay_loop

snd_lvl4_ay_h
	.db 4
snd_lvl4_ay_d
	.db SND_REPEAT, 8
#ifdef ZX
#include "song_41_zx.asm"
#endif
#ifdef CPC
#include "song_41_cpc.asm"
#endif
	.db SND_END_REPEAT
	.db SND_REPEAT, 16
#ifdef ZX
#include "song_42_zx.asm"
#endif
#ifdef CPC
#include "song_42_cpc.asm"
#endif
	.db SND_END_REPEAT
snd_lvl4_ay_loop
#ifdef ZX
#include "song_43_zx.asm"
#endif
#ifdef CPC
#include "song_43_cpc.asm"
#endif
	.db SND_GOTO
	.dw snd_lvl4_ay_loop

snd_lvl6_ay_h
	.db 4
snd_lvl6_ay_d
	.db SND_REPEAT, 2
#ifdef ZX
#include "song_61_zx.asm"
#endif
#ifdef CPC
#include "song_61_cpc.asm"
#endif
	.db SND_END_REPEAT
	.db SND_REPEAT, 2
#ifdef ZX
#include "song_62_zx.asm"
#endif
#ifdef CPC
#include "song_62_cpc.asm"
#endif
	.db SND_END_REPEAT
snd_lvl6_ay_loop
#ifdef ZX
#include "song_63_zx.asm"
#endif
#ifdef CPC
#include "song_63_cpc.asm"
#endif
	.db SND_GOTO
	.dw snd_lvl6_ay_loop

snd_bird_ay_h
	.db 4
snd_bird_ay_d
	.db E6, E5, AS5, E6, AS5, E5
	.db B4, C3, D5, G4, CS6, G5, DS6
	.db E4, F6, FS4, C6, FS5, C4, FS5
	.db SND_GOTO
	.dw snd_bird_ay_d

snd_bird2_ay_h
	.db 13
snd_bird2_ay_d
	.db C4, C5, FS5, REST
	.db SND_GOTO
	.dw snd_bird2_ay_d

snd_round_ay_h
	.db 4
snd_round_ay_d
	.db DS7, CS9, F5, E3
	.db CS9, G8, FS6, B2
	.db CS6, G3, AS3, CS9, D2
	.db B8, E3
	.db CS9, FS8, FS6, B2
	.db CS6, G3, AS3, CS9, D2
	.db B7, F6, E3
	.db CS9, B8, FS5, D4
	.db REST, REST, REST, REST
	.db SND_GOTO
	.dw snd_round_ay_d

#ifdef ZX
	#include "altair_snd_zx.asm"
#endif

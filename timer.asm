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
; These are not really timers. Some counters...
; ----------------------------------------------------------------------------

; To access each structure in timer_table.
TI_CNT	.equ 0
TI_MAX	.equ 1
TI_FUL	.equ 2
TI_FUH	.equ 3
TIMER_SZ	.equ 4

TIME_TO_SPAWN_ALIEN		.equ 8
TIME_TO_SPAWN_ALIEN_SLOW	.equ TIME_TO_SPAWN_ALIEN*2
TIME_TO_SHOOTING_ON		.equ HOUSE_NALIENS*TIME_TO_SPAWN_ALIEN*2
TIME_TO_DOUBLE_PACE		.equ TIME_TO_SHOOTING_ON*2
TIME_TO_SHOOT_SLOW		.equ TIME_TO_SPAWN_ALIEN_SLOW
TIME_TO_SHOOT			.equ TIME_TO_SPAWN_ALIEN
TIME_TO_MINE			.equ TIME_TO_SPAWN_ALIEN

; List of timers.
timer_table
	.db 0, TIME_TO_SPAWN_ALIEN_SLOW
	.dw ti_spawn_alien_slow
	.db 0, TIME_TO_SPAWN_ALIEN
	.dw ti_spawn_alien_fast
	.db 0, TIME_TO_DOUBLE_PACE
	.dw ti_double_pace
	.db 0, TIME_TO_SHOOTING_ON
	.dw ti_shooting_on
	.db 0, TIME_TO_SHOOT_SLOW
	.dw ti_shoot_slow
	.db 0, TIME_TO_SHOOT
	.dw ti_shoot_fast
	.db 0, TIME_TO_MINE
	.dw ti_mine
	.db 0, 0

; --------------------------
; 'ti_rst' Reset all timers.
; --------------------------

ti_rst
	push ix	
	ld ix,timer_table
	ld bc,TIMER_SZ

ti_rst_loop

	ld a,(ix+TI_CNT)
	cp (ix+TI_MAX)
	jr z,ti_rst_end
	ld (ix+TI_CNT),0
	add ix,bc
	jr ti_rst_loop

ti_rst_end
	pop ix
	ret

; --------------------------
; 'ti_update' Update timers.
; --------------------------

ti_update
	push ix

	ld ix,timer_table
	ld bc,TIMER_SZ
	ld a,(pace)
	ld e,1

ti_update_loop
	ld a,(ix+TI_CNT)
	ld l,(ix+TI_MAX)
	cp l
	jr z,ti_update_end
	add a,e
	cp l
	jr z,ti_update_exec
	ld (ix+TI_CNT),a

ti_update_next
	add ix,bc
	jr ti_update_loop

ti_update_exec
	ld (ix+TI_CNT),0
	ld l,(ix+TI_FUL)
	ld h,(ix+TI_FUH)
	push bc
	push de
	call jphl
	pop de
	pop bc
	jr ti_update_next

ti_update_end
	pop ix
	ret

; ------
; Timers
; ------

ti_spawn_alien_slow
	ld a,(level)
	or a
	call z,ti_spawn_alien
	ret

ti_spawn_alien_fast
	ld a,(level)
	or a
	call nz,ti_spawn_alien
	ret

ti_spawn_alien
	ld a,(house_naliens)
	cp HOUSE_NALIENS
	ret z	
	call house_spawn_alien
	ld a,(house_naliens)
	inc a
	ld (house_naliens),a
	cp HOUSE_NALIENS
	call z,house_end
	ret

; ---------------
; 'ti_shoot_slow'
; ---------------

ti_shoot_slow
	ld a,(pace)
	cp 2
	ret z
	call ti_shoot
	ret

; ---------------
; 'ti_shoot_fast'
; ---------------

ti_shoot_fast
	ld a,(pace)
	cp 1
	ret z
	call ti_shoot
	ret

; ----------
; 'ti_shoot'
; ----------

ti_shoot
	ld a,(shooting_on)
	or a
	ret z

; Randomize.

	call rand	
	cp 13
	ret c

; Select alien.

	push ix
	ld e,HOUSE_NALIENS

ti_shoot_loop
	ld ix,(armed_alien)
	ld a,(ix+OB_FUL)
	or (ix+OB_FUH)
	jr nz,ti_shoot_alien_found

; If no more aliens end.

	dec e
	jr z,ti_shoot_end

; Select next alien.

	call next_armed_alien
	jr ti_shoot_loop

; This alien can shoot.

ti_shoot_alien_found
	call spawn_alien_shot
	call next_armed_alien
	
ti_shoot_end
	pop ix
	ret

; ----------------
; 'ti_shooting_on'
; ----------------

ti_shooting_on
	ld a,(shooting_on)
	or a
	ret nz
	inc a
	ld (shooting_on),a
	ret

; ----------------
; 'ti_double_pace'
; ----------------
;	Timer to double the pace of the alien movement and shot spawn.

ti_double_pace
	ld a,(pace)
	cp 2
	ret z
	ld a,2
	ld (pace),a
	call doubled_pace
	ret

; ---------
; 'ti_mine'
; ---------
;	Timer to put mines.

ti_mine

; Check correct level.

	ld a,(level)
	cp BIRD_LEVEL-1
	ret nz

; Randomize.

	call rand
	cp 127
	ret nc

; Select an alien randomly.

	push ix

	ld d,0
	ld e,ALIEN_OB_SLOTS-1
	call randr
	ld e,a
	ld d,a

; Find it.

	ld hl,alien_ob
	ld bc,OBJSZ
	or a
	jr z,ti_mine_found

ti_mine_find

	add hl,bc
	dec a
	jr nz,ti_mine_find

ti_mine_found

; Check if alive.

	push hl
	pop ix
	ld a,(ix+OB_FUL)
	or (ix+OB_FUH)
	jr nz,ti_mine_alive

; Try to find one sequentially.

	ld a,d
	inc a
	cp ALIEN_OB_SLOTS
	jr nz,ti_mine_find_seq_next

; Return to first.

	ld hl,alien_ob
	xor a
	jr ti_mine_find_seq_chk_loop

ti_mine_find_seq_next

; Point to next alien.

	add hl,bc

ti_mine_find_seq_chk_loop

; A complete loop has been done?

	cp e
	jr z,ti_mine_end

; Check next.

	ld d,a
	jr ti_mine_found

ti_mine_alive

; Is alive, drop mine.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	ld a,(ix+OB_DY)
	push hl
	pop ix
	ld l,(ix+SP_PX)
	ld h,(ix+SP_PY)

; Check if we go up or down.

	and $80
	jr z,ti_mine_down

; Going up, drop mine below.

; Check if we can (don't drop after last line - 1).

	ld a,h
	add a,ALIEN_IM_H+8
	cp BBUFH-8
	jr nc,ti_mine_end

; We can, drop mine.

	jr ti_mine_drop

ti_mine_down

; Going down, drop mine above.

; Check if we can (don't drop before second line, as the ship never touches).

	ld a,h
	cp 16
	jr c,ti_mine_end

; We can, drop mine.

	sub 8

ti_mine_drop

; Drop mine.

; Caracter boundary.

	and $f8
	ld d,a
	ld a,l
	and $f8
	ld e,a
	call addmine

ti_mine_end
	pop ix
	ret

shooting_on	.db 0
pace		.db 1

; level init info: shooting on, pace

level_start_info
	.db 1, 1
	.db 0, 2
	.db 1, 2
	.db 1, 2
	.db 1, 2
	.db 1, 2
	.db 1, 2

set_level_info
	ld hl,level_start_info
	ld a,(level)
	call getwt
	ld a,l
	ld (shooting_on),a
	ld a,h
	ld (pace),a
	ret


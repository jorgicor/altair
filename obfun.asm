; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Object behaviors
; ----------------------------------------------------------------------------

; ------------
; Object Table
; ------------

SHIP_OB_SLOT		.equ 0
SHIP_OB_SLOTS		.equ 1
HOUSE_OB_SLOT		.equ SHIP_OB_SLOT+SHIP_OB_SLOTS
HOUSE_OB_SLOTS		.equ 1
ALIEN_OB_SLOT		.equ HOUSE_OB_SLOT+HOUSE_OB_SLOTS
ALIEN_OB_SLOTS		.equ 6
SHIP_SHOT_OB_SLOT	.equ ALIEN_OB_SLOT+ALIEN_OB_SLOTS
SHIP_SHOT_OB_SLOTS	.equ 2
ALIEN_SHOT_OB_SLOT	.equ SHIP_SHOT_OB_SLOT+SHIP_SHOT_OB_SLOTS
ALIEN_SHOT_OB_SLOTS	.equ 6
EXPLOSION_OB_SLOT	.equ ALIEN_SHOT_OB_SLOT+ALIEN_SHOT_OB_SLOTS
EXPLOSION_OB_SLOTS	.equ 6
POST_OB_SLOT		.equ EXPLOSION_OB_SLOT+EXPLOSION_OB_SLOTS
POST_OB_SLOTS		.equ 1
NOBJS			.equ POST_OB_SLOT+POST_OB_SLOTS

; Careful, we are reusing slots for the bird.
BIRD_OB_SLOT		.equ HOUSE_OB_SLOT
BIRD_OB_SLOTS		.equ 1

; Alien images by level.
alien_ims0
	.dw alim00
	.dw alim10
	.dw alim20
	.dw alim30
	.dw alim40
	.dw alim50
	.dw alim60

; Alien images by level.
alien_ims1
	.dw alim01
	.dw alim11
	.dw alim21
	.dw alim31
	.dw alim41
	.dw alim51
	.dw 0

; Starting x position (House relative), Starting dx.
; For each of the 6 spawned ships.
alien_start_poss
	.db 0, 1
	.db 0, 0
	.db 8, 255
	.db 4, 1
	.db 4, 0
	.db 8, 255

; Functions to calculate the starting positions for the aliens shots, by level.
ashot_startpos_funs
	.dw calc_ashot_startpos
	.dw calc_ashot_startpos
	.dw calc_ashot_startpos
	.dw calc_cross_ashot_startpos
	.dw calc_ashot_startpos
	.dw calc_cross_ashot_startpos
	.dw calc_ashot_startpos

; Master sprites for the alien shots by level.
ashot_mstr_sps
	.dw mstr_ashot_sp
	.dw mstr_ashot_sp
	.dw mstr_ashot_sp
	.dw mstr_cross_ashot_sp
	.dw mstr_ashot_sp
	.dw mstr_cross_ashot_sp
	.dw mstr_ashot_sp

; Aliens shots behavior functions by level.
ashot_move_funs
	.dw ashot_move
	.dw ashot_move
	.dw ashot_move
	.dw cross_ashot_move
	.dw ashot_move
	.dw cross_ashot_move
	.dw ashot_move

; Alien animations by level.
alien_ams	.dw alien_am0
		.dw alien_am1
		.dw alien_am2
		.dw alien_am3
		.dw alien_am4
		.dw alien_am5
		.dw alien_am6

; Counter of frames since the level started.
level_frames	.dw 0

; This is the number of aliens to spawn.
HOUSE_NALIENS	.equ 6
house_naliens	.db 0

; This points to the alien object that can shoot.
; It can be an already killed alien; in that case we must find the next
; alien to be armed.
armed_alien	.dw 0

START_POSS_SZ	.equ 6
start_poss
	.db HOUSE_LPOS, SHIP_MPOS
	.db HOUSE_LPOS, SHIP_RPOS
	.db HOUSE_MPOS, SHIP_LPOS
	.db HOUSE_MPOS, SHIP_RPOS
	.db HOUSE_RPOS, SHIP_LPOS
	.db HOUSE_RPOS, SHIP_MPOS

house_start_pos	.db 0
ship_start_pos	.db 0

; 1 if the ship images are vertically flipped.
ship_flipped	.db 0

; Player shots alive.
cannon_shots	.db 0

; If the bird has been killed.
bird_killed	.db 0
bird_visible	.db 0

; Checks if it is time to end the bird's level.
BIRD_LEVEL_TIME	.equ 630
bird_level_time	.dw BIRD_LEVEL_TIME

; If ship collided mine.
SHIP_STUCK_TIME	.equ 32
ship_stuck_time	.db SHIP_STUCK_TIME

; -----------------
; 'calc_start_poss'
; -----------------
;	Calc random ship and house start positions.

calc_start_poss

; On bird's level, always on center.

	ld a,(level)
	cp BIRD_LEVEL
	jr nz,calc_start_poss_std
	ld a,SHIP_MPOS
	ld (ship_start_pos),a
	ret

calc_start_poss_std

; Rest of levels.

	ld de,START_POSS_SZ-1
	call randr
	ld hl,start_poss
	call getwt
	ld a,l
	ld (house_start_pos),a
	ld a,h
	ld (ship_start_pos),a
	ret

; ------------
; 'init_level'
; ------------

init_level

; If the ship images were flipped, fix them.

	call chk_vflip_ship

; Reset Sprite and Object tables.

	call init_sprtab
	call init_objtab

; Ship is alive.

	xor a
	ld (ship_killed),a

; Aliens alive (even at bird's level).

	ld (aliens_killed),a

; Don't go to next level.

	ld (goto_next_level),a

; Reset time to wait if all aliens killed.

	ld a,ALIENS_KILLED_WTIME
	ld (aliens_killed_wtime),a

; If high score overflowed, set hscoremx.

	ld a,(hscorof)
	ld hl,hscormx
	or (hl)
	ld (hl),a
	xor a
	ld (hscorof),a

; If 10000 points boundary passed, add life.

	call chk_add_life

; Reset 10000 points overflow.

	xor a
	ld (tenthof),a

; Draw lifes for current player.

	ld a,(lifes)
	call drlifes

; Backup player score.

	ld a,(cur_player)
	call backscor

; Get starting positions for House and Ship.

	call calc_start_poss

; If last level init boss level, if not std level.

	ld a,(level)
	cp 7
	jr z,init_level_0
	call init_std_level
	ret
init_level_0
	call init_bird_level
	ret

; ----------------
; 'chk_vflip_ship'
; ----------------
;	If the ship images were flipped, fix them.

chk_vflip_ship
	ld a,(ship_flipped)
	or a
	call nz, vflip_ship
	ret

; -----------------
; 'init_bird_level'
; -----------------

init_bird_level

; Spawn objects.

	call spawn_ship
	call spawn_bird
	ret

; ----------------
; 'init_std_level'
; ----------------

init_std_level

; Prepare alien images for current level.

	ld hl,alien_ims0
	ld a,(level)
	call getwt
	ld (alient0),hl
	ld hl,alient0
	call preimt

	ld hl,alien_ims1
	ld a,(level)
	call getwt
	ld a,h
	or l
	jr z,init_std_level1
	ld (alient1),hl
	ld hl,alient1
	call preimt

init_std_level1

; Music for this level.

	ld a,(level)
	add a,SND_LVL1
	call play_snd

; Set aliens alive.

	ld a,HOUSE_NALIENS
	ld (aliens_alive),a

; Init level flags.

	call set_level_info	

; Spawn main objects.

	call spawn_ship
	call spawn_house
	call spawn_postf
	ret

; -------------
; 'init_sprtab'
; -------------

init_sprtab
	ld hl,sprtab
	ld bc,SPRSZ*NSPRS
	xor a
	call memset
	ret

; -------------
; 'init_objtab'
; -------------

init_objtab
	ld hl,objtab
	ld bc,OBJSZ*NOBJS
	xor a
	call memset
	ret

; ------------
; 'stop_anims'
; ------------
;	Stop all sprite animations.

stop_anims
	push iy
	ld a,NSPRS
	ld iy,sprtab
	ld bc,SPRSZ

stop_anims_loop
	call stop_anim
	add iy,bc
	dec a
	jr nz,stop_anims_loop
	pop iy
	ret

; -------------
; 'spawn_ship'
; -------------
;	Spawns the player ship.

spawn_ship

; Reset level frames.

	ld hl,0
	ld (level_frames),hl

; Create Sprite.

	ld hl,mstr_ship_sp
	ld bc,SPRSZ*SHIP_SP_SLOTS
	ld de,ship_sp
	ldir

; Set position.

	ld a,(ship_start_pos)
	ld e,a
	ld d,BBUFH-24
	xor a
	call set_ship_pos

; Create Object.

	ld hl,mstr_ship_ob
	ld de,ship_ob
	ld bc,OBJSZ
	ldir

; Clear shots.

	xor a
	ld (cannon_shots),a

; Can move.

	ld (ship_stuck_time),a

; If bird level, no cannon.

	; ld a,(level)
	; cp BIRD_LEVEL
	; ret nz
	; call hide_cannon
	ret

; --------------
; 'set_ship_pos'
; --------------
;	Sets the ship position.
;
; In	A 1 looking down, 0 up. D,E y,x position.
; Saves	HL, BC, DE.

set_ship_pos

	push af

; Set x positions.

	ld a,e
	ld (lwng_sp+SP_PX),a
	add a,8
	ld (ship_sp+SP_PX),a
	ld (cnon_sp+SP_PX),a
	ld (fire_sp+SP_PX),a
	add a,8
	ld (rwng_sp+SP_PX),a

; Set y positions.

	pop af
	or a
	jr nz,set_ship_pos_down

; The ship is looking up.

	ld a,d
	ld (cnon_sp+SP_PY),a
	add a,8
	ld (ship_sp+SP_PY),a
	ld (lwng_sp+SP_PY),a
	ld (rwng_sp+SP_PY),a
	add a,8
	ld (fire_sp+SP_PY),a
	ret

; The ship is looking down.

set_ship_pos_down
	ld a,d
	ld (fire_sp+SP_PY),a
	add a,8
	ld (ship_sp+SP_PY),a
	ld (lwng_sp+SP_PY),a
	ld (rwng_sp+SP_PY),a
	add a,8
	ld (cnon_sp+SP_PY),a
	ret

; ----------------------
; 'get_level_anim_speed'
; ----------------------
;	Returns the animation speed for aliens for each level.

get_level_anim_speed
	ld a,(level)
	or a
	ld a,8
	ret z
	srl a
	ret

; -------------
; 'spawn_house'
; -------------
;	Spawns the house of aliens object and sprites in a random x position.

spawn_house

; Arm first alien.

	ld hl,alien_ob
	ld (armed_alien),hl

; 0 aliens spon.

	xor a
	ld (house_naliens),a

; Copy master sprites.

	ld hl,mstr_house_sp
	ld bc,SPRSZ*HOUSE_SP_SLOTS
	ld de,house_sp_0
	ldir

; Set x position.

	ld a,(house_start_pos)
	ld (house_sp_0+SP_PX),a
	ld (house_sp_1+SP_PX),a

; Create object.

	ld hl,mstr_house_ob
	ld de,house_ob
	ld bc,OBJSZ
	ldir
	ret

; -------------
; 'spawn_alien'
; -------------
;	Spawns an alien at a certain position.
;
; In	DE y,x position in pixels. A desired delta x.

spawn_alien

	push ix
	push iy

; Save position and delta x.

	push af
	push de

; Find free sprite slot.

	ld d,ALIEN_SP_SLOT
	ld e,ALIEN_SP_SLOT+ALIEN_SP_SLOTS
	call getspr
	jr c,spawn_alien_fail1

; Set sprite data.

	push hl
	pop iy
	pop de
	ld (iy+SP_PX),e
	ld (iy+SP_PY),d
	ld hl,alien_ams
	ld a,(level)
	call getwt
	call get_level_anim_speed
	ld e,1
	call set_anim
	
; Create the object.

	ld d,ALIEN_OB_SLOT
	ld e,ALIEN_OB_SLOT+ALIEN_OB_SLOTS
	call getob
	jr c,spawn_alien_fail2

; Set the object data.

	push hl
	pop ix
	ld (ix+OB_FUL),alienf&255
	ld (ix+OB_FUH),alienf>>8
	push iy
	pop hl
	ld (ix+OB_SPL),l
	ld (ix+OB_SPH),h

; Restore and set delta x.

	pop af
	ld (ix+OB_DX),a
	ld (ix+OB_DY),2
	jr spawn_alien_end

spawn_alien_fail1
	pop de

spawn_alien_fail2
	pop af

spawn_alien_end
	pop iy
	pop ix
	ret

; -----------------------
; 'housef' House Behavior
; -----------------------
;
; In	IX Object Pointer.

housef	

; House controls two sprites.
; Swaps their positions.

	ld a,(frames)	
	and 1
	ret nz
	push ix
	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy
	ld e,(iy+SP_PY)
	ld l,(ix+OB_SP2L)
	ld h,(ix+OB_SP2H)
	push hl
	pop ix
	ld d,(ix+SP_PY)
	ld (ix+SP_PY),e
	ld (iy+SP_PY),d
	pop ix
	ret

; ---------------------------------------------
; 'house_spawn_alien' Spawn alien inside house.
; ---------------------------------------------

house_spawn_alien

; Get alien start x position and start dx.

	ld hl,alien_start_poss
	ld a,(house_naliens)
	call getwt

; House x + alien x start position.

	ld a,(house_sp_0+SP_PX)
	add a,l
	ld e,a
	ld d,HOUSE_YPOS

; Start dx in A and spawn.

	ld a,h
	call spawn_alien
	ret
	
; -----------
; 'house_end'
; -----------
;	Destroys the house.

; No more aliens to spawn, disappear.

house_end
	push ix
	xor a
	ld hl,house_sp_0
	ld bc,SPRSZ*HOUSE_SP_SLOTS
	call memset
	ld ix,house_ob
	call freeob
	pop ix
	ret

; --------
; 'alienf'
; --------

alienf	ld a,(pace)
alienf1	push af
	call movali
	pop af
	dec a
	jr nz,alienf1

; Check collision with mines.

	call chk_alien_mines
	ret

; -------------
; 'spawn_postf'
; -------------
;	Spawn post frame object.

spawn_postf
	ld hl,mstr_post_ob
	ld de,post_ob
	ld bc,OBJSZ
	ldir

	; Init timers.
	call ti_rst

	ret

; ------------------
; 'next_armed_alien'
; ------------------

next_armed_alien
	ld hl,(armed_alien)
	ld bc,OBJSZ
	add hl,bc

; Check if we have to go to the first.

	ld a,+(alien_ob+(HOUSE_NALIENS*OBJSZ))&255
	cp l
	jr nz,next_armed_alien_ok
	ld a,+(alien_ob+(HOUSE_NALIENS*OBJSZ))>>8
	cp h
	jr nz,next_armed_alien_ok
	
; We have to return to the first.

	ld hl,alien_ob

next_armed_alien_ok
	ld (armed_alien),hl
	ret

; ---------------------------
; 'postf' Post Level Behavior
; ---------------------------
;	Post Frame calculations.

postf	
	push ix

; Update timers.

	call ti_update

; Ship - Mines.

	call chk_ship_mines

; Ship - Aliens collisions.

	call chk_ship_aliens

; Ship wings - Aliens collisions.

	call chk_lwing_aliens
	call chk_rwing_aliens

	pop ix
	ret

; ----------------
; 'calc_shot_dir'
; ----------------
;	Calculates the direction for a shot at a certain position, given
; the position of the player's ship.
;
; In	H,L shot pos y,x.
; Out	H,L direction (H y direction: +2 or -2; L x direction: -1, 0, 1).
; Saves	BC.

calc_shot_dir

	push iy

; Get ship position, centered, in DE.

	ld iy,ship_sp
	ld a,(iy+SP_PX)
	add a,4
	ld e,a
	ld a,(iy+SP_PY)
	add a,4
	ld d,a
	
; L is x position for a straight shot.
; Check if the shot must be oblique.

	ld a,l
	cp e
	jr c,calc_shot_dir_chkright
	jr nz,calc_shot_dir_chkleft
	jr calc_shot_dir_straight

calc_shot_dir_chkright

; abs(shot_yc - ship_yc) .

	ld a,h
	sub d
	jr nc,calc_shot_dir_chkright_1
	neg

calc_shot_dir_chkright_1

; Divide as we advance 2 in y and 1 in x.
; abs(shot_yc - ship_yc) / 2 .
; This is distance in x between straight shot and olique shot on the
; ship's y pos.

	srl a

; Divide again to find middle point.

	srl a

; And add shot x to translate.

	add a,l

; Where is ship about middle point?
; If ship is before middle point, shoot straight, else shoot to the right.

	cp e
	jr nc,calc_shot_dir_straight
	
; Shoot to the right.

	ld l,1
	jr calc_shot_dir_up_down
	
calc_shot_dir_chkleft

; abs(shot_yc - ship_yc) .

	ld a,h
	sub d
	jr nc,calc_shot_dir_chkleft_1
	neg

calc_shot_dir_chkleft_1

; Divide as we advance 2 in y and 1 in x.
; abs(shot_yc - ship_yc) / 2 .
; This is distance in x between straight shot and olique shot on the
; ship's y pos.

	srl a

; Divide again to find middle point.

	srl a

; To the left.

	neg

; And add shot x to translate.

	add a,l

; Where is ship about middle point?
; If ship is after middle point, shoot straight, else shoot to the left.

	cp e
	jr c,calc_shot_dir_straight
	jr z,calc_shot_dir_straight
	
; Shoot to the left.

	ld l,-1
	jr calc_shot_dir_up_down
	
calc_shot_dir_straight
	ld l,0

calc_shot_dir_up_down

; Get shot y center position and compare with ship's y position.

	ld a,h
	cp d
	jr c,calc_shot_dir_down
	ld h,-2
	jr calc_shot_dir_end

calc_shot_dir_down
	ld h,2

calc_shot_dir_end
	pop iy
	ret

; ------------------
; 'spawn_alien_shot'
; ------------------
;
; In	ix alien object.

spawn_alien_shot
	push ix
	push iy

; Get alien sprite.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy

; Get centered position.

	ld a,(iy+SP_PX)
	add a,ALIEN_IM_W/2
	ld l,a
	ld a,(iy+SP_PY)
	add a,ALIEN_IM_H/2
	ld h,a
	call calc_shot_dir

; Save dy,dx.

	push hl

; Find free sprite slot.

	ld d,ALIEN_SHOT_SP_SLOT
	ld e,ALIEN_SHOT_SP_SLOT+ALIEN_SHOT_SP_SLOTS
	call getspr
	jr c,spawn_alien_shot_fail

; Calculate shot starting position.

	push hl
	ld hl,ashot_startpos_funs
	ld a,(level)
	call getwt
	call jphl
	pop hl

; Fill sprite data.

	push hl
	push de
	ex de,hl
	ld hl,ashot_mstr_sps
	ld a,(level)
	call getwt
	ld bc,SPRSZ
	ldir
	pop de
	pop iy
	ld (iy+SP_PX),e
	ld (iy+SP_PY),d

; Get object.

	ld d,ALIEN_SHOT_OB_SLOT
	ld e,ALIEN_SHOT_OB_SLOT+ALIEN_SHOT_OB_SLOTS
	call getob
	jr c,spawn_alien_shot_fail
	push hl
	pop ix

; Set object.

	push iy
	pop hl
	ld (ix+OB_SPL),l
	ld (ix+OB_SPH),h
	ld (ix+OB_FUL),ashotf&255
	ld (ix+OB_FUH),ashotf>>8

; Restore dx,dy.

	pop hl
	
; Continue setting object.

	ld (ix+OB_DX),l
	ld (ix+OB_DY),h

; Stop tune only of beeper.

	ld a,(ay_detected)
	or a
	jr nz,spawn_alien_shot_ay

	ld a,SND_CHAN1
	call stop_snd

spawn_alien_shot_ay

; Set sound.

	push iy
	push ix
	pop iy
	ld a,SND_SHOT
	call play_snd
	pop iy

	jr spawn_alien_shot_end

spawn_alien_shot_fail
	pop hl

spawn_alien_shot_end
	pop iy
	pop ix
	ret

; ------------------------------------------------------------
; 'calc_ashot_startpos' Calculate Alien Shot Starting Position
; ------------------------------------------------------------
;	For the 'line' alien shot, calculates its starting position given
; the alien that shoots.
;
; In	IY alien sprite.
; Out	DE y,x position.
; Saves	BC, HL.

calc_ashot_startpos

	; Ensure y position pair.

	ld a,(iy+SP_PY)
	add a,ALIEN_IM_H/2
	and $fe
	ld d,a

	ld a,(iy+SP_PX)
	add a,ALIEN_IM_W/2
	ld e,a
	ret

; ------------------------------------------------------------------------
; 'calc_cross_ashot_startpos' Calculate Alien Cross Shot Starting Position
; ------------------------------------------------------------------------
;	For the 'cross' alien shot, calculates its starting position given
; the alien that shoots.
;
; In	IY alien sprite.
; Out	DE y,x position.
; Saves	BC, HL.

calc_cross_ashot_startpos

	; Should be character aligned.

	ld a,(iy+SP_PY)
	add a,ALIEN_IM_H/2
	and $f8
	ld d,a

	ld a,(iy+SP_PX)
	add a,ALIEN_IM_W/2
	and $f8
	ld e,a
	ret

; ---------
; 'ashotf'
; ---------
;	Alien shot behavior.

ashotf
	push ix

; Load sprite into IY.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy

	ld hl,ashot_move_funs
	ld a,(level)
	call getwt
	call jphl
	jr c,ashot_end

ashot_free

; Dont't free sprite if ship killed, so we can see it on top.

	ld a,(ship_killed)
	or a
	call z,freesp

; If we had sound stop.

	ld hl,(shot_snd_ob)
	push ix
	pop de
	ld a,h
	cp d
	jr nz,ashot_freeob
	ld a,l
	cp e
	jr nz,ashot_freeob

	ld a,SND_CHAN0
	call stop_snd

ashot_freeob
	call freeob

ashot_end
	pop ix
	ret

; Table with 1 if the shot should follow the ship position or 0 if not.
; One entry for each level.
shot_should_follow_table
	.db 0, 0, 0, 0, 1, 1, 0

; ----------------------
; 'does_shot_change_dir'
; ----------------------
;
; In	None.
; Out	ZF=0 if it is a shot that should follow the ship.
; Saves	HL, BC, DE.

should_shot_follow
	push hl
	ld hl,shot_should_follow_table
	ld a,(level)
	call getbt
	or a
	pop hl
	ret
	
; ---------------------------------
; 'ashot_move' Moves standard shot.
; ---------------------------------
;
; In	IX object. IY sprite.
; Out	CY 0 then shot must be freed.
; Saves C.

ashot_move

; Check if must change direction.

	call should_shot_follow
	jr z,ashot_move_now

; Calc shot center pos and calc direction.

	ld a,(iy+SP_PX)
	inc a
	ld l,a
	ld a,(iy+SP_PY)
	add a,2
	ld h,a
	call calc_shot_dir

; Set new direction (only change x direction).

	ld (ix+OB_DX),l

ashot_move_now

; Move.

	ld b,ALIEN_SHOT_SPEED
	ld e,(ix+OB_DX)
	ld d,(ix+OB_DY)

ashot_move_loop

	call ashot_move_step
	ret nc
	djnz ashot_move_loop
	scf
	ret

; --------------------------------------
; 'ashot_move_step' Alien shot move step
; --------------------------------------
;	Moves the 'line' alien shot one step.
;
; In	IY alien shot sprite. D,E dy,dx.
; Out	CY 0 if shot must be destroyed.
; Saves	BC, DE, HL.

ashot_move_step

; Check if going down or up.

	ld a,d
	cp -2
	ld a,(iy+SP_PY)
	jr z,ashot_move_step_up

; Going down.

	cp BBUFH-4
	jr z,ashot_move_step_out
	jr ashot_move_step_dy

ashot_move_step_up
	
; Going up.

	or a
	jr z,ashot_move_step_out	

ashot_move_step_dy

; y + dy.

	add a,d
	ld (iy+SP_PY),a

; Check dx.

	ld a,e
	or a
	jr z,ashot_move_step_in
	cp -1
	ld a,(iy+SP_PX)
	jr z,ashot_move_step_left

; Going right.

	cp BBUFW - 2
	jr z,ashot_move_step_out
	jr ashot_move_step_dx

ashot_move_step_left

; Going left.

	or a
	jr z,ashot_move_step_out

ashot_move_step_dx

; x + dx.

	add a,e
	ld (iy+SP_PX),a

ashot_move_step_in

; Check collisions.

	push bc
	push de
	ld de,(4<<8)+2
	call chk_shot_ship
	pop de
	pop bc
	ret

ashot_move_step_out

; Shot must be destroyed.

	or a
	ret

; -----------------
; cross_ashot_move
; -----------------
;
; In	IX object. IY sprite.
; Out	CY 0 if must be freed.
; Saves ??

cross_ashot_move

; If time to update x pos, don't check to change direction.

	ld a,(frames)
	and 1
	jr z,cross_ashot_move_now

; Check if must change direction.

	call should_shot_follow
	jr z,cross_ashot_move_now

; Calc shot center pos and calc direction.

	ld a,(iy+SP_PX)
	add a,4
	ld l,a
	ld a,(iy+SP_PY)
	add a,4
	ld h,a
	call calc_shot_dir

; Set new direction (only change x direction).

	ld (ix+OB_DX),l

cross_ashot_move_now

	ld e,(ix+OB_DX)
	ld d,(ix+OB_DY)

; Check if going down or up.

	ld a,d
	cp -2
	ld a,(iy+SP_PY)
	jr z,cross_ashot_up

; Going down.

	cp BBUFH-8
	jr z,cross_ashot_out
	add a,8
	jr cross_ashot_dy

cross_ashot_up
	
; Going up.

	or a
	jr z,cross_ashot_out	
	add a,-8

cross_ashot_dy

	ld (iy+SP_PY),a

; Check if time to update x pos.

	ld a,(frames)
	and 1
	jr z,cross_ashot_in

; Check dx.

	ld a,e
	or a
	jr z,cross_ashot_in
	cp -1
	ld a,(iy+SP_PX)
	jr z,cross_ashot_left

; Going right.

	cp BBUFW - 8
	jr z,cross_ashot_out
	add a,8
	jr cross_ashot_dx

cross_ashot_left

; Going left.

	or a
	jr z,cross_ashot_out
	add a,-8

cross_ashot_dx

	ld (iy+SP_PX),a

cross_ashot_in

; Check collisions.

	push bc
	push de
	ld de,(8<<8)+8
	call chk_shot_ship
	pop de
	pop bc
	ret

cross_ashot_out

; shot must be destroyed.

	or a
	ret
	
; -------------------
; 'movali' Move Alien
; -------------------
;
; In	IX Object pointer.

movali

; Set IY Sprite pointer.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy

; The algorithm is something like this:
;
;	if (y == 0 && dy < 0) {
;		dy = 2;
;		goto dychanged;
;	} else if (y == BBUFH-8 && dy > 0) {
;		dy = -2;
;		goto dy_changed;
;	} else
;		goto dy_not_changed;
;
; dy_changed:
;	if (x == 8)
;		dx = rand[0, 1];
;	else if (x == BBUFW-24)
;		dx = rand[-1,0];
;	else
;		dx = rand[-1,0,1];
;	goto sum;
;
; dy_not_changed:
;	if (x == 8 && dx == -1)
;		dx = 1;
;	else if (x == BBUFW-24 && dx == 1)
;		dx = -1;
;
; sum:
;	x += dx;
;	y += dy;

; Load position and movement delta and start checking conditions.

	ld d,(iy+SP_PX)
	ld e,(iy+SP_PY)
	ld h,(ix+OB_DX)
	ld l,(ix+OB_DY)
	call movali1
	jr z,movali3
	call movali2
	jr z,movali3
	call movali4
	jr z,movali5
	call movali6
	jr movali5
movali3	call movali7
	jr z,movali5
	call movali8
	jr z,movali5
	call movali9

; Add delta to position (x += dx, y += dy).

movali5 ld a,d
	add a,h
	ld (ix+OB_DX),h
	ld (iy+SP_PX),a
	ld a,e
	add a,l
	ld (ix+OB_DY),l
	ld (iy+SP_PY),a
	ret

; If y is 0 and dy is negaive -> dy is 2.

movali1 ld a,e
	or a
	ld c,a
	ld a,l
	xor -2
	or c
	ret nz
	ld l,2
	ret

; If y is BBUFH-8 and dy is positive -> dy is -2.

movali2 ld a,e
	xor BBUFH-8
	ld c,a
	ld a,l
	xor 2
	or c
	ret nz
	ld l,-2
	ret

; If x is 8 and dx is -1 -> dx is 1.

movali4 ld a,d
	xor 8
	ld c,a
	ld a,h
	xor 255
	or c
	ret nz
	ld h,1
	ret

; If x is BBUFW-24 and dx is 1 -> dx is -1.

movali6 ld a,d
	xor BBUFW-24
	ld c,a
	ld a,h
	xor 1
	or c
	ret nz
	ld h,255
	ret

; If x is 8 -> dx is rand[0,1].

movali7 ld a,d
	cp 8
	ret nz
	call rand
	and 1
	ld h,a
	xor a
	ret

; If x is BBUFW-24 -> dx is rand[-1,0].

movali8 ld a,d
	xor BBUFW-24
	ret nz
	call rand
	and 1
	jr nz,moval81
	ld h,a
	ret
moval81	ld h,255
	xor a
	ret

; Set dx rand[-1,0,1].

movali9	call rand
	cp 85
	jr nc,moval91
	ld h,255
	xor a
	ret
moval91	cp 85*2
	jr nc,moval92
	xor a
	ld h,a
	ret
moval92	ld h,1
	xor a
	ret

; --------------
; 'doubled_pace'
; --------------
; 	Aliens will move faster.

doubled_pace

; Double pace of the aliens animations.

	push ix
	push iy
	
	ld e,ALIEN_OB_SLOTS
	ld ix,alien_ob
	ld bc,OBJSZ

update_peace_loop
	ld a,(ix+OB_FUL)
	or (ix+OB_FUH)
	jr z,update_peace_next
	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy
	srl (iy+SP_SPE)
	srl (iy+SP_SPC)

update_peace_next
	add ix,bc
	dec e
	jr nz,update_peace_loop

	pop iy
	pop ix
	ret

; -------
; 'shipf'
; -------
;	Player's ship behavior.
;
; In	IX ship object.

shipf

; Inc level frames.

	ld hl,(level_frames)
	inc hl
	ld (level_frames),hl

; Check if stuck.

	ld hl,ship_stuck_time
	xor a
	cp (hl)
	jr z,shipf_can_move
	dec (hl)
	jp nz,shipf_no_move

shipf_can_move

; Take current x pos.

	ld a,(lwng_sp+SP_PX)
	ld e,a

; Take y pos, depending on looking down or up.

	ld a,(ship_flipped)
	or a
	jr nz,shipf_is_down
	ld a,(cnon_sp+SP_PY)
	jr shipf_k

shipf_is_down
	ld a,(fire_sp+SP_PY)

; Check keys.

shipf_k	ld d,a

; Save or flip state and current position to see at the end if we moved.

	ld a,(ship_flipped)
	push af
	push de

; Check keys pressed.

	ld hl,rinput
	ld a,K_LEFT
	and (hl)
	jr nz,shipfl
	ld a,K_RIGHT
	and (hl)
	jr nz,shipfr

shipf1	

; Only left - right movement on last level.

	ld a,(level)
	cp BIRD_LEVEL
	jr z,shipfp

; Check up - down.

	ld hl,rinput
	ld a,K_UP
	and (hl)
	jr nz,shipfu
	ld a,K_DOWN
	and (hl)
	jr nz,shipfd
	jr shipfp

; Wants to go left.

shipfl	ld a,e
	or a
	jr z,shipf1
	sub 8
	ld e,a
	jr shipf1

; Wants to go right.

shipfr	ld a,e
	cp BBUFW-24
	jr z,shipf1
	add a,8
	ld e,a
	jr shipf1

; Wants to go up.

shipfu

; Check if we are looking up.

	ld a,(ship_flipped)
	or a
	jr z,shipfu_already_up

; We are looking down. Check if we are on top.

	ld a,d
	or a
	jr z,shipfp

; We were looking down and we aren't on top. Only flip.

shipf_flip

	push de
	call vflip_ship
	pop de
	jr shipfp

; We were looking upwards already.

shipfu_already_up

	ld a,d
	sub 8
	ld d,a

; If we reached top, flip.

	or a
	jr nz,shipfp
	jr shipf_flip

; Wants to go down.

shipfd

; Check if we are looking down.

	ld a,(ship_flipped)
	or a
	jr nz,shipfu_already_down

; We are looking up. Check if we are on bottom.

	ld a,d
	cp BBUFH-24
	jr z,shipfp

; We were looking up and we aren't on bottom. Only flip.

	jr shipf_flip

; We were looking downwards already.

shipfu_already_down

; Move.

	ld a,d
	add a,8
	ld d,a

; If we reached bottom, flip.

	cp BBUFH-24
	jr nz,shipfp
	jr shipf_flip

; Set final position.

shipfp	

; Restore previous position and flipped state.

	pop bc
	pop af

; Now we have in BC the previous pos, and in DE the new one, and in A the
; previous flip state.

	ld hl,ship_flipped
	cp (hl)
	jr nz,shipf_moved
	ld a,d
	cp b
	jr nz,shipf_moved
	ld a,e
	cp c
	jr z,shipf_no_move

shipf_moved

; We have moved, set position.

	ld a,(ship_flipped)
	call set_ship_pos

; Engage engines.

	ld hl,fire_am
	ld (fire_sp+SP_ANL),hl
	jr shipf_chk_cannon

; We haven't moved, shut engines.

shipf_no_move
	ld hl,0
	ld (fire_sp+SP_ANL),hl
	ld (fire_sp+SP_ITL),hl

; Now, check if we need to fire.

shipf_chk_cannon

; Cannon isn't ready. Check if we can spawn new shot.

	ld a,(cannon_shots)
	cp SHIP_SHOT_OB_SLOTS
	jr z,ship_cant_shoot

; Cannon is ready again. Show it.

	call show_cannon

; Cannon is ready.

shipf_cannon_ready

; Check fire key.

	ld a,(finput)
	and K_FIRE
	ret z

; Spawn shot.

	ld a,(cnon_sp+SP_PX)
	add a,3
	ld e,a

; If flipped (1) spawn at same y of cannon, else spawn at y+4.

	ld a,(ship_flipped)
	xor 1
	rlca
	rlca
	ld hl,cnon_sp+SP_PY
	add a,(hl)
	ld d,a
	ld a,(ship_flipped)
	push ix
	call spawn_ship_shot
	pop ix

; Cannon must wait to be ready again.

	call hide_cannon
	ret

ship_cant_shoot

	ret

; -------------
; 'show_cannon'
; -------------
;	Shows the ship's cannon.
;
; Saves	BC, DE.

show_cannon
	; ld a,(level)
	; cp BIRD_LEVEL
	; ret z
	ld hl,cnon_it
	ld (cnon_sp+SP_ITL),hl
	ret

; -------------
; 'hide_cannon'
; -------------
;	Hides the ship's cannon.
;
; Saves	AF, BC, DE.

hide_cannon
	ld hl,0
	ld (cnon_sp+SP_ITL),hl
	ret

; ---------------------------------
; 'vflip_ship' Vertically flip ship
; ---------------------------------
;	Flips ship Flip flag and vertically flips ship images.

vflip_ship
	ld a,(ship_flipped)
	xor 1
	ld (ship_flipped),a
	ld hl,ship_im
	call flipv
	ld hl,cnon_im
	call flipv
	ld hl,lwng_im
	call flipv
	ld hl,rwng_im
	call flipv
	ld hl,fire_im0
	call flipv
#ifdef CPC
	ld hl,fire_im1
	call flipv
#endif
	ret

; -----------------
; 'spawn_ship_shot'
; -----------------
;
; In	D,E y,x position. A 0 go up, 1 go down.

spawn_ship_shot

	push ix
	push iy

; Save direction.

	push af

; Find free sprite slot.

	push de
	ld d,SHIP_SHOT_SP_SLOT
	ld e,SHIP_SHOT_SP_SLOT+SHIP_SHOT_SP_SLOTS
	call getspr
	pop de
	jr c,spawn_ship_shot_fail

; Fill sprite data.

	push hl
	pop iy
	ld (iy+SP_ITL),sshot_it&255
	ld (iy+SP_ITH),sshot_it>>8
	ld (iy+SP_PX),e
	ld (iy+SP_PY),d
#ifdef ZX
	ld (iy+SP_COL),YELLOW
	ld (iy+SP_COH),0
#endif

	; ld a,(level)
	;cp BIRD_LEVEL
	;jr nz,spawn_ship_shot_no_bird
	;ld (iy+SP_ITL),0
	;ld (iy+SP_ITH),0

spawn_ship_shot_no_bird
	
; Find free object slot.
	
	ld d,SHIP_SHOT_OB_SLOT
	ld e,SHIP_SHOT_OB_SLOT+SHIP_SHOT_OB_SLOTS
	call getob
	jr c,spawn_ship_shot_fail

; Fill object data.

	push hl
	pop ix
	push iy
	pop hl
	ld (ix+OB_FUL),shotf&255
	ld (ix+OB_FUH),shotf>>8
	ld (ix+OB_SPL),l
	ld (ix+OB_SPH),h
	ld (ix+OB_DX),0

; Restore direction, set in object.

	pop af
	or a
	jr nz,spawn_ship_shot_down
	ld (ix+OB_DY),-4
	jr spawn_ship_shot_ok

spawn_ship_shot_down
	ld (ix+OB_DY),4
	jr spawn_ship_shot_ok

spawn_ship_shot_ok

; Increment number of shots alive.

	ld hl,cannon_shots
	inc (hl)
	jr spawn_ship_shot_end

spawn_ship_shot_fail

	pop af

spawn_ship_shot_end

	pop iy
	pop ix
	ret

; -------
; 'shotf'
; -------
;
; In	IX Object pointer.

shotf	

; Get sprite.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy

; Go up or down in a loop, checking collisions.

	ld b,SHIP_SHOT_SPEED
	ld c,(ix+OB_DY)

shotf_move

	push bc
	call chk_shot_aliens
	jr nz,shotf_bfree
	call chk_shot_shield
	jr nc,shotf_bfree
	call chk_shot_mines
	jr c,shotf_bfree
	pop bc
	jr shotf_no_collision

shotf_bfree
	pop bc
	jr shotf_free

shotf_no_collision
	ld a,(iy+SP_PY)

; If we reached 0, the next move will put us out of the screen, so disappear.

	or a
	jr z,shotf_free

; If reached the bottom, disappear.

	cp BBUFH-4
	jr z,shotf_free
	
; If safe, move.

	add a,c
	ld (iy+SP_PY),a
	djnz shotf_move

	ret

shotf_free

; We must disappear.
; Decrement number of ship shots.

	ld hl,cannon_shots
	dec (hl)

; Free sprite and object.

	call freesp
	call freeob
	ret

; -----------------
; 'chk_shot_aliens'
; -----------------
;	Checks all aliens that collide with this shot and explodes them.
;
; In	IY shot sprite.
; Out	ZF if no collision.

chk_shot_aliens

; Don't check on bird's level.

	ld a,(level)
	cp 7
	ret z

; Iterate aliens.

	push ix

	ld e,ALIEN_OB_SLOTS
	ld ix,alien_ob
	ld bc,OBJSZ

; D 1 collision, 0 none.

	ld d,0

chk_shot_aliens_loop

; Check if alien exists.

	ld a,(ix+OB_FUL)
	or (ix+OB_FUH)
	jr z,chk_shot_aliens_next

; If it is inside the house, can't be killed.

	call chk_alien_in_house
	jr c,chk_shot_aliens_next

; Check for collision.

	call chk_shot_alien
	jr c,chk_shot_aliens_next

; If collision, explode, add score and set D.

	push bc
	push de

	call explode_alien

	pop de
	pop bc
	ld d,1

chk_shot_aliens_next

; Go to next alien object.

	add ix,bc
	dec e
	jr nz,chk_shot_aliens_loop

; End.

	pop ix

; Set ZF if any collision.

	ld a,d
	or a
	ret

; --------------------
; 'chk_alien_in_house'
; --------------------
;	Checks if an alien is inside the box of the house.
;
; In	IX alien object.
; Out	CF 1 then is inside.
; Saves	BC, DE.

chk_alien_in_house
	push iy

; Load sprite into IY.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy

; Are there aliens?

	ld a,(house_naliens)
	cp HOUSE_NALIENS
	jr z,chk_alien_in_house_false
	
; Check if inside.

	ld a,(iy+SP_PY)
	cp 16-ALIEN_IM_H-1
	jr nc,chk_alien_in_house_false
	scf
	jr chk_alien_in_house_ret

chk_alien_in_house_false
	or a

chk_alien_in_house_ret
	pop iy
	ret

; ----------------
; 'chk_shot_alien'
; ----------------
;	Checks if there is collision between a shot and an alien.
;
; In	IY shot sprite. IX alien object.
; Out	CY 1 no collision, 0 collision.
; Saves	BC, DE.

chk_shot_alien

	push ix
	push de

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop ix

	ld de,(4<<8)+2
	ld hl,(ALIEN_IM_H<<8)+ALIEN_IM_W
	call chk_spr_spr

	pop de
	pop ix
	ret

; ----------------------------------------------
; 'chk_spr_spr' Check sprite vs sprite collision
; ----------------------------------------------
;	Checks collisions between two sprites.
;
; In	IY spr A. IX spr B. D, E height, width A in pixels.
;	H,L height,width B in pixels.
; Out	CY 1 no collision, 0 collision.
; Saves	BC, DE, HL.

chk_spr_spr
	push de
	push hl

; Width and height minus one.

	dec d
	dec e
	dec h
	dec l

; If ax + aw - 1 < bx ret.

	ld a,(iy+SP_PX)
	add a,e
	cp (ix+SP_PX)
	jr c,chk_spr_spr_ret

; If bx + bw - 1 < ax

	ld a,(ix+SP_PX)
	add a,l
	cp (iy+SP_PX)
	jr c,chk_spr_spr_ret

; If by + bh - 1 < ay ret

	ld a,(ix+SP_PY)
	add a,h
	cp (iy+SP_PY)
	jr c,chk_spr_spr_ret

; If ay + ah - 1 < by ret

	ld a,(iy+SP_PY)
	add a,d
	cp (ix+SP_PY)
	jr c,chk_spr_spr_ret

; Collision, CY = 0.

	or a

chk_spr_spr_ret
	pop hl
	pop de
	ret
	
; ---------------
; 'explode_alien'
; ---------------
;
; In	IX alien object.

explode_alien

	push iy

; Add score for killing this one.

	ld a,(level)
	ld c,a
	ld a,(cur_player)
	call addscor

; If 10000 points boundary crossed, set tenth overflow.

	call chk_tenthof

; Decrement aliens alive and check if all killed.

	ld hl,aliens_alive
	dec (hl)
	jr nz,explode_alien_score
	inc a
	ld (aliens_killed),a

explode_alien_score

; Draw new score hud.

	ld a,(cur_player)
	call drscor

; Kill alien but save position in DE.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy
	ld e,(iy+SP_PX)
	ld d,(iy+SP_PY)
	call freesp
	call freeob

; Spawn explosion.

	call spawn_explosion
	pop iy
	ret

; -----------------
; 'spawn_explosion'
; -----------------
;
; In	D,E y,x position.

spawn_explosion

; Fix position: x in char boundaries, try to center y.

	ld a,e
	and $f8
	ld e,a

	ld a,d
	sub EXPLOSION_OFFS
	jr nc,spawn_explosion_coordf1
	xor a

spawn_explosion_coordf1

	ld d,a
	ld a,BBUFH-EXPLOSION_IM_H
	cp d
	jr nc,spawn_explosion_setpos
	ld d,a

spawn_explosion_setpos

; Set position in sprite master to copy later.  

	ld a,e
	ld (mstr_explosion_sp+SP_PX),a
	ld a,d
	ld (mstr_explosion_sp+SP_PY),a

; Create sprite.

	ld d,EXPLOSION_SP_SLOT
	ld e,EXPLOSION_SP_SLOT+EXPLOSION_SP_SLOTS

; For the birds level, we spawn an explosion sprite after the bird's ones,
; so it is painted above.

	ld a,(level)
	cp BIRD_LEVEL
	jr nz,spawn_explosion_no_bird
	ld d,BIRD_EXPLOSION_SP_SLOT
	ld e,BIRD_EXPLOSION_SP_SLOT+1

spawn_explosion_no_bird
	call getspr
	jr c,spawn_explosion_fail
	ld a,l
	ld (mstr_explosion_ob+OB_SPL),a
	ld a,h
	ld (mstr_explosion_ob+OB_SPH),a
	ex de,hl
	ld hl,mstr_explosion_sp
	ld bc,SPRSZ
	ldir

; Create object.

	ld d,EXPLOSION_OB_SLOT
	ld e,EXPLOSION_OB_SLOT+EXPLOSION_OB_SLOTS
	call getob
	jr c,spawn_explosion_fail
	ex de,hl
	ld hl,mstr_explosion_ob
	ld bc,OBJSZ
	ldir
	
spawn_explosion_fail
	ret

; ---------------------------
; 'explof' Explosion Function
; ---------------------------

explof
	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy
	call is_anim_playing
	ret nz

explof_end
	call freesp
	call freeob
	ret

; -------------------------------------------------
; 'stop_multisp_anims' Stop multisprite animations.
; -------------------------------------------------
; 	Stops all the animations for some contiguous sprites.	
;
; In	IY address of first sprite. L nsprites.
; Saves	IY, H, DE.

stop_multisp_anims
	push iy
	ld bc,SPRSZ
stop_multisp_anims_loop
	ld a,(iy+SP_ANL)
	or (iy+SP_ANH)
	call nz,stop_anim
	add iy,bc
	dec l
	jr nz,stop_multisp_anims_loop
	pop iy
	ret

; -------------------------------
; 'move_multisp' Move multisprite
; -------------------------------
; 	Positions some contiguous sprites by applying some offset.	
;
; In	D,E delta y,x. IY address of first sprite. L nsprites.
; Saves	IY, H, DE.

move_multisp

	push iy
	ld bc,SPRSZ

move_multisp_loop
	ld a,(iy+SP_PX)
	add a,e
	ld (iy+SP_PX),a
	ld a,(iy+SP_PY)
	add a,d
	ld (iy+SP_PY),a
	add iy,bc
	dec l
	jr nz,move_multisp_loop

	pop iy
	ret

; ------------------------------------------
; 'set_multisp_pos' Set multisprite position
; ------------------------------------------
; 	Positions some contiguous sprites making a frame.	
;
; In	D,E y,x position. L nsprites. IY address of first sprite.
; Saves	H, IY.

set_multisp_pos

; Calc deltas.

	ld a,e
	sub (iy+SP_PX)
	ld e,a

	ld a,d
	sub (iy+SP_PY)
	ld d,a

	call move_multisp
	ret
	
; -----------------
; 'chk_shot_shield'
; -----------------

chk_shot_shield

	push ix

; If not on bird's level, no collision.

	ld a,(level)
	cp BIRD_LEVEL
	jr nz,chk_shot_shield_dont

; If already killed, do nothing.

	ld a,(bird_killed)
	or a
	jr nz,chk_shot_shield_dont

; If not on screen yet, do nothing.

	ld a,(bird_visible)
	or a
	jr z,chk_shot_shield_dont

; Check collision with left shield.

	ld ix,bird_lshield_sp
	ld a,(bird_lshield_h)
	call shot_shield_chk
	jr nc,shot_shield_collision

; Check collision with right shield.

	ld ix,bird_rshield_sp
	ld a,(bird_rshield_h)
	call shot_shield_chk
	jr c,chk_shot_shield_end
	jr shot_shield_collision

shot_shield_chk

; Check collision.

	ld de,+(4<<8)+2
	ld h,a
	ld l,8
	call chk_spr_spr
	ret

shot_shield_collision

; Go to the image.

	ld l,(ix+SP_ITL)
	ld h,(ix+SP_ITH)
	ld e,(hl)
	inc hl
	ld d,(hl)
	ex de,hl

; Take height.

	inc hl
	ld e,(hl)

; Go to first byte on.

	ld d,0
	add hl,de

#ifdef CPC
; For the CPC, double as we have 2 bytes per line.
	add hl,de 
	dec hl
#endif

; Check if full or partial or empty.

	ld a,(hl)
	cp SHIELD_FULL
	jr z,shot_shield_full
	cp SHIELD_PARTIAL
	jr z,shot_shield_partial

; It's empty. This can only happen on last line. We hit the bird.

	call kill_bird
	or a
	jr chk_shot_shield_end

shot_shield_partial

; Partial, so set empty.
	
	ld a,SHIELD_EMPTY
	ld (hl),a

#ifdef CPC
	inc hl
	ld (hl),a
#endif

; Set carry off.

	or a

; Reduce height.

	sbc hl,de

#ifdef CPC
	sbc hl,de
#endif

	dec (hl)
	jr z,shot_shield_zero
	or a
	jr chk_shot_shield_end

shot_shield_zero

; Don't let the height be 0.

	inc (hl)
	or a
	jr chk_shot_shield_end

shot_shield_full

; Full, so set partial hit.

	ld a,SHIELD_PARTIAL
	ld (hl),a

#ifdef CPC
	inc hl
	ld (hl),a
#endif

	or a
	jr chk_shot_shield_end

chk_shot_shield_dont
	scf

chk_shot_shield_end
	pop ix
	ret

; -----------------
; 'chk_ship_aliens'
; -----------------

chk_ship_aliens
	push ix
	push iy
	ld iy,ship_sp

	ld e,ALIEN_OB_SLOTS
	ld ix,alien_ob
	ld bc,OBJSZ

chk_ship_aliens_loop
	ld a,(ix+OB_FUL)
	or (ix+OB_FUH)
	jr z,chk_ship_aliens_next
	ld h,(ix+OB_SPH)
	ld l,(ix+OB_SPL)
	push ix

	push hl
	pop ix

	push bc
	push de

	ld de,(8<<8)+8
	ld hl,(ALIEN_IM_H<<8)+ALIEN_IM_W
	call chk_spr_spr
	call nc,kill_ship

	pop de
	pop bc
	pop ix

chk_ship_aliens_next
	add ix,bc
	dec e
	jr nz,chk_ship_aliens_loop

	pop iy
	pop ix
	ret

; --------------
; 'destroy_wing'
; --------------
;
; In	IY wing sprite.
; Saves	BC, DE, HL.

destroy_wing
	xor a
	ld (iy+SP_ITL),a
	ld (iy+SP_ITH),a
	ret

; ------------------
; 'chk_lwing_aliens'
; ------------------

chk_lwing_aliens
	push iy
	ld iy,lwng_sp
	ld a,(iy+SP_ITL)
	or (iy+SP_ITH)
	jr z,chk_lwing_aliens_end
	call chk_wing_aliens
	call c,destroy_wing
chk_lwing_aliens_end
	pop iy
	ret

; ------------------
; 'chk_rwing_aliens'
; ------------------

chk_rwing_aliens
	push iy
	ld iy,rwng_sp
	ld a,(iy+SP_ITL)
	or (iy+SP_ITH)
	jr z,chk_rwing_aliens_end
	call chk_wing_aliens
	call c,destroy_wing
chk_rwing_aliens_end
	pop iy
	ret

; -----------------
; 'chk_wing_aliens'
; -----------------

chk_wing_aliens
	push ix

	ld e,ALIEN_OB_SLOTS
	ld ix,alien_ob
	ld bc,OBJSZ

chk_wing_aliens_loop
	ld a,(ix+OB_FUL)
	or (ix+OB_FUH)
	jr z,chk_wing_aliens_next
	ld h,(ix+OB_SPH)
	ld l,(ix+OB_SPL)
	push ix

	push hl
	pop ix

	push bc
	push de

	ld de,(8<<8)+8
	ld hl,(ALIEN_IM_H<<8)+ALIEN_IM_W
	call chk_spr_spr

	pop de
	pop bc
	pop ix

	jr nc,chk_wing_aliens_collided

chk_wing_aliens_next
	add ix,bc
	dec e
	jr nz,chk_wing_aliens_loop
	or a

chk_wing_aliens_end
	pop ix
	ret

chk_wing_aliens_collided
	call explode_alien	
	scf
	jr chk_wing_aliens_end

; -----------
; 'kill_ship'
; -----------
;
; Saves	BC, DE, HL.

kill_ship
	ld a,1
	ld (ship_killed),a
	ret

; ---------------
; 'chk_shot_ship'
; ---------------
;	Checks shot collision with ship body and wings.
;
; In	IY shot spr. D,E height,width in pixels.
; Out	CY 0 collision.
; Saves	HL.

chk_shot_ship
	push ix
	push hl
	ld hl,(8<<8)+8
	ld ix,ship_sp
	call chk_spr_spr
	jr nc,chk_shot_ship_body

; Is there the left wing?

	ld ix,lwng_sp
	ld a,(ix+SP_ITL)
	or (ix+SP_ITH)
	jr z,chk_shot_ship_rwing_exists

; Yes, check.

	call chk_spr_spr
	jr nc,chk_shot_ship_wing

chk_shot_ship_rwing_exists

	ld ix,rwng_sp

; Is there the right wing?

	ld a,(ix+SP_ITL)
	or (ix+SP_ITH)
	jr nz,chk_shot_ship_rwing
	scf
	jr chk_shot_ship_end

chk_shot_ship_rwing

; Yes, check.

	call chk_spr_spr
	jr nc,chk_shot_ship_wing
	jr chk_shot_ship_end

chk_shot_ship_body

	ld a,(cheats_god)
	or a
	call z,kill_ship
	jr chk_shot_ship_collision

chk_shot_ship_wing
	push iy
	push ix
	pop iy
	call destroy_wing
	pop iy

chk_shot_ship_collision
	or a

chk_shot_ship_end
	pop hl
	pop ix
	ret

; Bird.

BEND	.equ 0
BMOVE	.equ 1
BWAIT	.equ 2
BSTART	.equ 3
	
BIRD_NMOVES	.equ 5
bird_moves
	.dw move1
	.dw move2
	.dw move3
	.dw move4
	.dw move5

; Special move not in table. With this one we start.
move0	.db BWAIT, 32, 0
	.db BEND

move1	.db BMOVE, 0, 24, 0, 24, 0, 24, 0, 16, 0, 0
	.db BWAIT, 8, 0
	.db BMOVE, 8, 8, 8, 8, 8, -8, 8, -8
		.db 0, -16, 0, -24, 0, -24, 0, -24, 0, 0
	.db BWAIT, 64, 0
	.db BEND

move2	.db BMOVE, 24, 0, 24, 0, 24, 0, 24, 0, 0, 0
	.db BWAIT, 64, 0
	.db BEND

move3	.db BMOVE, 16, 24, 16, 24, 16, 24, -16, 24, -16, -24, 0, 0
	.db BWAIT, 16, 0 
	.db BMOVE, -16, -24, 0, -24, 0, -24, 0, 0
	.db BEND

move4	.db BMOVE, 0, 24, 0, 24, 0, 24, 0, 24, 0, 0
	.db BWAIT, 8, 0
	.db BMOVE, 8, 8, 24, -8, 24, -24, 24, -24, 0, -24, 0, -24, 0, 0
	.db BWAIT, 64, 0
	.db BEND

move5	.db BMOVE, 0, 24, 0, 16, 0, 16, 0, 16, 0, 8, 0, 8, 0, 8, 0, 8, 0, 0
	.db BWAIT, 4, 0
	.db BMOVE, 8, 0, 8, 0, 8, 0, 8, 0, 8, 0
		.db 0, -8, 0, -8, 0, -16, 0, -16, 0, -16, 0, -16, 0, -24
		.db 0, 0
	.db BWAIT, 48
	.db BEND

; Time to wait.
bird_wtime	.dw 0

bird_instr	.db 0
bird_pc		.dw 0
bird_reverse	.db 0
bird_last_move	.db 255
	
; When the bird spawns, we show a color effect.
bird_spawn_colors	.db BBUF_RED
			.db BBUF_BLACK

BIRD_SPAWN_TIME		.equ 32

; ------------
; 'spawn_bird'
; ------------

spawn_bird

; Bird is alive (but not shown still).

	xor a
	ld (bird_killed),a
	ld (bird_visible),a

	push ix
	ld ix,bird_ob
	ld (ix+OB_FUL),bird_prespawn_1&255
	ld (ix+OB_FUH),bird_prespawn_1>>8
	pop ix
	ret

; -----------------
; 'bird_prespawn_1'
; -----------------
;	Wait some time to show red color effect.

bird_prespawn_1
	ld a,(level_frames)
	cp BIRD_SPAWN_TIME
	ret nz

	ld (ix+OB_FUL),bird_prespawn_2&255
	ld (ix+OB_FUH),bird_prespawn_2>>8
	ld (ix+OB_CNT0),0
	ld (ix+OB_CNT1),4
	ld (ix+OB_CNT3),13
	ret

; -----------------
; 'bird_prespawn_2'
; -----------------

bird_prespawn_2
	
	dec (ix+OB_CNT1)
	ret nz
	ld (ix+OB_CNT1),4

	ld a,(ix+OB_CNT0)
	inc a
	and 1
	ld (ix+OB_CNT0),a
	ld hl,bird_spawn_colors
	call getbt
	call set_bbuf_paper

	ld hl,+BEEP_FREQX256(131*256)
	ld de,+BEEP_MS(131*256, 31)
	call beep

	dec (ix+OB_CNT3)
	ret nz

; Load sprite and reset shield.

	call reset_bird_shield
	call load_bird_spr

; Select random x position.

	ld d,0
	ld e,BBUFWC-BIRD_WC
	call randr
	rlca
	rlca
	rlca
	ld e,a
	ld d,0
	call set_bird_pos

; Load object.

	ld hl,mstr_bird_ob
	ld de,bird_ob
	ld bc,OBJSZ
	ldir

; Now the bird is on screen.

	ld a,1
	ld (bird_visible),a

; Init bird's machine.

	ld a,BSTART
	ld (bird_instr),a

; Set timeout time.

	ld hl,BIRD_LEVEL_TIME
	ld (bird_level_time),hl
	ret

; ---------------
; 'load_bird_spr'
; ---------------
; 	Loads all the bird's sprites into the sprites table.

load_bird_spr
	ld hl,mstr_bird_sp
	ld bc,SPRSZ*BIRD_SP_SLOTS
	ld de,bird_sp
	ldir
	ret

; -------------------
; 'reset_bird_shield'
; -------------------
;	Refills the bird's bottom shield.

reset_bird_shield

	ld hl,bird_lshield_im
	call reset_shield_part
	ld hl,bird_rshield_im
	call reset_shield_part
	ret

; -------------------
; 'reset_shield_part'
; -------------------
;	Refills the bird's bottom shield (left or right part).
;
; In	HL bird_lshield_im or bird_rshield_im

reset_shield_part

; Width.

	ld b,(hl)
	inc hl

; Height.

	ld c,16
	ld (hl),c
	inc hl

; Load all bits on.

	ld a,SHIELD_FULL

reset_shield2
	push bc

reset_shield1
	ld (hl),a
	inc hl
	djnz reset_shield1
	pop bc
	dec c
	jr nz,reset_shield2
	ret

; --------------------------------
; 'set_bird_pos' Set bird position
; --------------------------------
; 	Position the bird.
;
; In	DE y,x position in pixels.

set_bird_pos
	push iy
	ld iy,bird_sp
	ld l,BIRD_NSPS
	call set_multisp_pos
	pop iy
	ret

; -----------
; 'kill_bird'
; -----------

kill_bird

; Set it killed.

	ld a,1
	ld (bird_killed),a
	ld (bird_killed_cur_game),a
	ld (bird_killed_once),a

; Add score.

	ld a,(level)
	ld c,a
	ld a,(cur_player)
	call addscor

; If 10000 points boundary crossed, add life.

	call chk_tenthof

; Draw the score.

	ld a,(cur_player)
	call drscor

; Spawn explosion.

	ld a,(bird_lshield_sp+SP_PX)
	ld e,a
	ld a,(bird_lshield_sp+SP_PY)
	add a,-16
	ld d,a
	call spawn_explosion

bird_level_finish

; (This is called too from birdf directly, when timeout).
; Stop bird animations.

	push iy
	ld iy,bird_sp
	ld l,BIRD_NSPS
	call stop_multisp_anims
	pop iy

; And bird must die.

	push ix
	ld ix,bird_ob
	ld (ix+OB_FUL),bird_die_f&255
	ld (ix+OB_FUH),bird_die_f>>8
	ld (ix+OB_CNT0),0
	ld (ix+OB_CNT1),19
	pop ix

; And player too. Don't let him move.

	push ix
	ld ix,ship_ob
	call freeob
	pop ix

	ld a,SND_CHAN1
	call stop_snd

	ld a,SND_DIE
	call play_snd

	ret

; -----------
; 'bird_die_f
; -----------
;	Cicle colors again.

bird_die_f

	ld a,(ix+OB_CNT0)
	inc a
	and 1
	ld (ix+OB_CNT0),a
	ld hl,kill_colors
	call getbt
	call set_bbuf_paper

	dec (ix+OB_CNT1)
	ret nz

	call freeob

	ld a,BBUF_BLACK
	call set_bbuf_paper

	ld a,1
	ld (goto_next_level),a
	ret

; -------
; 'birdf'
; -------

birdf	

	push iy

; Check collision with ship.

	push ix

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop ix
	ld iy,ship_sp
	ld de,+(8<<8)+8
	ld hl,+((BIRD_HC*8)<<8)+(BIRD_WC*8)
	call chk_spr_spr

	pop ix
	jr c,birdf_chk_time

; Collision.

	call kill_ship
	jr birdf_end

birdf_chk_time

; Check if too much time has passed...

	ld hl,(bird_level_time)
	dec hl
	ld (bird_level_time),hl
	ld a,h
	or l
	jr nz,birdf_run

; Timeout, end level.

	call bird_level_finish	
	jr birdf_end

birdf_run

; Behave.

	ld iy,bird_sp
	call bird_exec

birdf_end

	pop iy
	ret

bird_pre_select
	xor a
	ld (bird_reverse),a

	ld a,$ff
	ld (bird_last_move),a

	ld hl,move0
	jr bird_next

bird_exec

	ld hl,(bird_pc)
	ld a,(bird_instr)
	cp BSTART
	jr z,bird_pre_select
	cp BMOVE
	jr z,bird_move
	cp BWAIT
	jr z,bird_wait
	
bird_select
	ld d,0
	ld e,BIRD_NMOVES-1
	call randr

; Don't let choose the same last move.

	ld hl,bird_last_move
	cp (hl)
	jr z,bird_select

; Set last move.

	ld (hl),a

; Select move.

	ld hl,bird_moves
	call getwt

bird_next
	ld a,(hl)
	ld (bird_instr),a
	inc hl
	ld (bird_pc),hl
	cp BWAIT
	jr z,bird_prewait

	ld a,SND_BIRD
	call play_snd

	jr bird_exec

bird_prewait

; Prepare BWAIT intruction.
	
	ld a,SND_BIRD2
	call play_snd

	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (bird_pc),hl
	ex de,hl
	ld (bird_wtime),hl
	jr bird_exec

bird_move
	ld e,(hl)
	inc hl
	ld d,(hl)
	inc hl
	ld (bird_pc),hl
	ld a,e
	or d
	jr z,bird_next

; We have to reverse sign?

	ld a,(bird_reverse)
	or a
	jr z,bird_move_chk

; Reverse X sign.

	ld a,e
	neg
	ld e,a

bird_move_chk

; Check if going left or right.

	bit 7,e
	jr z,bird_move_chk_right

; Going left.

	ld a,e
	neg
	sub (iy+SP_PX)
	jr z,bird_move_do
	jr c,bird_move_do

; We will reverse. New offset already in A.

	ld e,a

bird_move_reverse

; Reverse.

	ld a,(bird_reverse)
	xor 1
	ld (bird_reverse),a
	jr bird_move_do

bird_move_chk_right

; Going right.

	ld a,BBUFW-(BIRD_WC*8)
	sub (iy+SP_PX)
	sub e
	jr nc,bird_move_do

; We will reverse. New offset in A. 

	ld e,a
	jr bird_move_reverse
	
bird_move_do

	ld l,BIRD_NSPS
	call move_multisp
	ret

bird_wait
	ld hl,bird_wtime
	dec (hl)
	ret nz
	ld hl,(bird_pc)
	jr bird_next

; ---------
; 'addmine'
; ---------
;	Adds a mine if there is a free slot.
;
; In 	DE y,x position in pixels.

addmine

; Change position in master sprite.

	ld a,e
	ld (mstr_mine_sp+SP_PX),a
	ld a,d
	ld (mstr_mine_sp+SP_PY),a

; Try to get a free slot.

	ld d,MINE_SP_SLOT
	ld e,MINE_SP_SLOT+MINE_SP_SLOTS
	call getspr
	ret c

; Load sprite.

	ex de,hl
	ld hl,mstr_mine_sp
	ld bc,SPRSZ
	ldir
	ret

; -----------------
; 'chk_alien_mines'
; -----------------
;	Checks collisions between aliens and mines. If an alien overlaps
; a mine, the mine disappears. Only checks if we are in the correct level.
;
; In	IX alien object.

chk_alien_mines

; Check if correct level.

	ld a,(level)
	cp BIRD_LEVEL-1
	ret nz

; Get sprite.

	ld l,(ix+OB_SPL)
	ld h,(ix+OB_SPH)
	push hl
	pop iy

; Run through all mines.

	ld ix,mine_sp
	ld b,MINE_SP_SLOTS
	ld de,+(6<<8)+16
	ld hl,+(8<<8)+8

chk_alien_mines_loop
	push bc

; Check if mine exists.

	ld a,(ix+SP_ITL)
	or (ix+SP_ITH)
	jr z,chk_alien_mines_next

; Check for collision.

	call chk_spr_spr	
	jr c,chk_alien_mines_next

; Collision, free mine.

	push iy
	push ix
	pop iy
	call freesp
	pop iy

chk_alien_mines_next

; Next mine sprite.

	ld bc,SPRSZ
	add ix,bc
	pop bc
	djnz chk_alien_mines_loop

	pop ix
	ret

; ----------------
; 'chk_ship_mines'
; ----------------
;	Checks collision between ship and mines. If the ship collides with
; mines, they disappear, but the ship won't be able to move for some time.

chk_ship_mines

; Are we in correct level?

	ld a,(level)
	cp BIRD_LEVEL-1
	ret nz

; We are; check.

	push ix
	push iy

	ld ix,mine_sp
	ld de,SPRSZ
	ld b,MINE_SP_SLOTS

chk_ship_mines_loop

; Check if mine exists.

	ld a,(ix+SP_ITL)
	or (ix+SP_ITH)
	jr z,chk_ship_mines_next

; If not in the same y position, no collision.

	ld iy,ship_sp
	ld a,(iy+SP_PY)
	cp (ix+SP_PY)
	jr nz,chk_ship_mines_next

; Get mine character position in H.

	ld a,(ix+SP_PX)
	call tochrp
	ld h,a

; Get character position of ship's body in L.

	ld a,(iy+SP_PX)
	call tochrp
	ld l,a

; Check body.

	cp h
	jr z,chk_ship_mines_overlap

; Check left wing.

; Check if destroyed.

	ld iy,lwng_sp
	ld a,(iy+SP_ITL)
	or (iy+SP_ITH)
	jr z,chk_ship_mines_rwing

; Not destroyed.

	ld a,l
	dec a
	cp h
	jr z,chk_ship_mines_overlap

chk_ship_mines_rwing

; Check right wing.

; Check if destroyed.

	ld iy,rwng_sp
	ld a,(iy+SP_ITL)
	or (iy+SP_ITH)
	jr z,chk_ship_mines_next

; Not destroyed.

	ld a,l
	inc a
	cp h
	jr nz,chk_ship_mines_next

chk_ship_mines_overlap

; They overlap, destroy mine.

	push ix
	pop iy
	call freesp

; And player won't be able to move.

	ld a,SHIP_STUCK_TIME
	ld (ship_stuck_time),a
	
chk_ship_mines_next
	add ix,de
	djnz chk_ship_mines_loop

	pop iy
	pop ix
	ret

; ----------------
; 'chk_shot_mines'
; ----------------
;	Checks collision between ship's shot and mines.
;
; In	IY shot sprite.
; Out	CY 1 collision.

chk_shot_mines

	push ix

; Are we in correct level?

	ld a,(level)
	cp BIRD_LEVEL-1
	jr nz,chk_mines_no_overlap

; Check.

	ld ix,mine_sp
	ld b,MINE_SP_SLOTS
	ld de,SPRSZ

chk_shot_mines_loop

; Check if mine exists.

	ld a,(ix+SP_ITL)
	or (ix+SP_ITH)
	jr z,chk_shot_mines_next

; Check if shot is in the same square.

	ld a,(iy+SP_PY)
	and $f8
	cp (ix+SP_PY)
	jr nz,chk_shot_mines_next

	ld a,(iy+SP_PX)
	and $f8
	cp (ix+SP_PX)
	jr nz,chk_shot_mines_next

; Overlap.

; Free mine.

	push iy
	push ix
	pop iy
	call freesp
	pop iy

	scf
	jr chk_shot_mines_end

; Next mine.

chk_shot_mines_next

	add ix,de
	djnz chk_shot_mines_loop

chk_mines_no_overlap

; No collision.

	or a

chk_shot_mines_end
	pop ix
	ret
	

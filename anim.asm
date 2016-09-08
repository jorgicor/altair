#if 0
Copyright (c) 2014, 2016 Jorge Giner Cordero

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
; Animation code.
; ----------------------------------------------------------------------------

; ------------------------
; 'set_anim' Set Animation
; ------------------------
;	Sets an animation for a sprite and sets it to the first frame of the
; animation.
;
; In	HL address of animation. A speed (0 stopped, 1 each frame, 2 each
;	two frames, etc). E 1 looped. IY sprite.
; Saves	BC.

set_anim
	ld (iy+SP_ANL),l
	ld (iy+SP_ANH),h
	ld (iy+SP_SPE),a
	ld (iy+SP_SPC),a
	ld (iy+SP_FRA),0
	ld (iy+SP_LOP),e
	call update_spr_anim
	ret

; -----------
; 'stop_anim'
; -----------

stop_anim
	ld (iy+SP_SPE),0
	ld (iy+SP_SPC),0
	ret

; -----------------
; 'is_anim_playing'
; -----------------
;
; In	IY sprite.
; Out	ZF if not playing.
; Saves	BC, DE, HL.

is_anim_playing
	ld a,(iy+SP_ANL)
	or (iy+SP_ANH)
	ret z
	xor a
	or (iy+SP_SPE)
	ret

; -----------------------------------------
; 'update_spr_anim' Update Sprite Animation
; -----------------------------------------
;	Given a sprite animation, updates its image table and color given
; the current frame.
;
; In	IY Sprite.
; Saves	BC.

update_spr_anim

; Point HL to the animation data for this frame.

	ld l,(iy+SP_FRA)
	ld h,0
	add hl,hl
#ifdef ZX
	add hl,hl
#endif
	ld e,(iy+SP_ANL)
	ld d,(iy+SP_ANH)
	inc de
	add hl,de

; Update Image Table and color.

	ld a,(hl)
	inc hl
	ld (iy+SP_ITL),a
	ld a,(hl)
	ld (iy+SP_ITH),a
#ifdef ZX
	inc hl
	ld a,(hl)
	inc hl
	ld (iy+SP_COL),a
	ld a,(hl)
	ld (iy+SP_COH),a
#endif
	ret

; --------------------------------
; 'update_anims' Update Animations
; --------------------------------
;	Runs through all aprites and updates its animations.

update_anims
	ld hl,sprtab
	ld bc,SPRSZ
	ld a,NSPRS

update_anims_loop
	push af
	push hl
	push hl
	pop iy
	call update_anim
	pop hl
	add hl,bc
	pop af
	dec a
	jr nz,update_anims_loop
	ret

; ------------------------------
; 'update_anim' Update Animation
; ------------------------------
;	Goes to the next frame of animation and handles looped animations.
;	Updates the sprite's image table and color accordingly.
;
; In	IY Sprite.
; Saves	BC.

update_anim

; Return if no animation.

	ld l,(iy+SP_ANL)
	ld h,(iy+SP_ANH)
	ld a,h
	or l
	ret z

; If speed count > 0, decrement speed count.

	xor a
	or (iy+SP_SPC)
	jr z,update_anim1
	dec a
	ld (iy+SP_SPC),a

update_anim1

; If speed count reached 0 or the same speed was 0, update sprite.

	or a
	jr nz,update_anim2
	or (iy+SP_SPE)
	jr z,update_anim2

; Increment the frame index.

	ld a,(iy+SP_FRA)
	inc a

; If the frame index reaches the total frames of this anim, reset to 0.

	cp (hl)
	jr nz,update_anim3
	xor a

update_anim3

; If not looped and reached total frames, set speed to 0 and end.

	ld l,a
	or a
	jr nz,update_anim4
	or (iy+SP_LOP)
	jr nz,update_anim4
	ld (iy+SP_SPE),a
	ret

update_anim4

; Update frame and reset speed counter.

	ld (iy+SP_FRA),l
	ld a,(iy+SP_SPE)
	ld (iy+SP_SPC),a

update_anim2
	call update_spr_anim
	ret

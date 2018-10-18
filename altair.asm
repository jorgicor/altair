; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
;
; Project started 23 Sep 2013.
; ----------------------------------------------------------------------------

#include "c_config.asm"

#ifdef ZX
#include "c_lib_zx.asm"
#endif

#ifdef CPC
#include "c_lib_cpc.asm"
#endif

#include "const.asm"

#ifdef ZX
	.org $8000
#endif

#ifdef CPC
	.org $40
#endif

start	
	di

#ifdef ZX

; Set Stack Pointer.
	ld sp,0

#endif

#ifdef CPC

; Set Stack Pointer.

	ld sp,$c000

; Init cpc hardware.

	call init_cpc

; Set palette.

	ld hl,palette
	call set_pal

#endif

; Detect if AY sound chip is present.

	call detect_ay

; Clear vram.

	xor a
	call clrscr

; Set border color.

	ld a,BORDER_GAME
	call set_border_color

; Install interrupt routine.

	ld hl,interrupt
	call install_irq

#ifdef ZX
; Prepare alien images.

	ld hl,pmir0
	call mirims
#endif

#ifdef CPC
	call init_pixmask
#endif

; Init back buffer addresses.

	call init_bbuf

; Clear backbuffer.

	ld a,ABUFCLR
	call clrbbuf

; Set first state.

	ld a,STATE_DISCLAIMER
	call set_state

; Main loop.

theloop

	call update_state

; Increment frame counter.

	ld hl,frames
	inc (hl)

	jr theloop

; ------------------------------
; 'tochrp' To Character Position
; ------------------------------
;
; In	A pixel coordinate.
; Out	A character coordinates.
; Saves	BC, DE, HL.

tochrp	and $f8
	rrca
	rrca
	rrca
	ret

; ---------------------
; 'drsprs' Draw Sprites
; ---------------------
;	Runs through the Sprite Table and draws all sprites.

drsprs	
	ld b,NSPRS
	ld hl,sprtab
drsprs1	push bc
	call drspr
	pop bc
	djnz drsprs1
	ret

; --------------------------------
; 'chrfix' Fix Dimension For Color
; --------------------------------
;	Given the y position in pixels and the height in pixels, calculate
;	the y position character aligned and the height in characters that
;	is needed to fill the area.
;
; In	E y position in pixels. C height in pixels.
; Out	E y in characters. C height in characters.
; Saves	HL

chrfix	

; Set height in characters to (y & 7 + h + 7) / 8.

	ld a,e
	and 7
	add a,c
	add a,7
	call tochrp
	ld c,a

; Set y position in characters.

	ld a,e
	call tochrp
	ld e,a
	ret

; -----------------------------
; 'getspr' Get Free Sprite Slot
; -----------------------------
;	Finds a free sprite slot between [D,E[.
;
; In	[D,E[ slots where to find.
; Out	HL address of slot. CY 0 if found, 1 if no free slot.

getspr	ld hl,sprtab
	ld c,SPRSZ
	ld b,NSPRS
	call gtslot
	ret

; --------------------
; 'freesp' Free Sprite
; --------------------
;	Frees sprite pointed by IY.
;
; In	IY Sprite Pointer.
; Saves	AF, BC, DE, HL.

freesp	ld (iy+SP_ITL),0
	ld (iy+SP_ITH),0
	ld (iy+SP_ANL),0
	ld (iy+SP_ANH),0
	ret

; --------------------
; 'freeob' Free Object
; --------------------
;	Frees object pointed by IX.
;
; In	IX Object Pointer.
; Saves	AF, BC, DE, HL.

freeob	ld (ix+OB_FUL),0
	ld (ix+OB_FUH),0
	ret

; ------------------
; 'getob' Get Object
; ------------------
;	Finds a free object slot in the Object Table.
;
; In	[D,E[ slots where to find.
; Out	HL address of slot. CY 0 if found, 1 if no free slot.

getob	ld hl,objtab
	ld c,OBJSZ
	ld b,NOBJS
	call gtslot
	ret

; -----------------
; 'gtslot' Get Slot
; -----------------
;	Finds a structure in an array of structures. If the first word is 0
;	this means that the structure is free.
;
; In	[D,E[ slots where to find. C size of structure.
;	B table size. HL table address.
; Out	HL address of slot. CY 0 if found, 1 if no free slot.

gtslot	

; A will count until we reach E or NOBJS.

	xor a
gtslot2	cp b
	jr z,gtslot3
	cp e
	jr z,gtslot3

; We only consider the slot if it is equal or greater than D.

	cp d
	jr c,gtslot1

; Check if we have a free slot.

	push af
	ld a,(hl)
	inc hl
	or (hl)
	dec hl
	jr z,gtslot4
	pop af

; Go to next slot.

gtslot1	push bc
	ld b,0
	add hl,bc
	pop bc
	inc a
	jr gtslot2

; Find none. Exit with CY 1.

gtslot3	scf
	ret

; Found. Exit with CY 0.

gtslot4	pop af
	or a
	ret

; --------------------------------
; 'exobs' Execute Object Behaviors
; --------------------------------
;	Runs through the Object Table and executes the behavior for each if
;	if any.

exobs	
	ld b,NOBJS
	ld hl,objtab
exobs1	push bc
	call exob
	pop bc
	djnz exobs1
	ret

; ------------------------------
; 'exob' Execute Object Behavior
; ------------------------------
;	Executes the behavior of an object, if any. Goes to the next object.
;
; In	HL Object address.
; Out	HL Adrress of next Object.

exob

; Set IX to Object pointer.

	push hl
	push hl
	pop ix

; Get behavior function.

	ld l,(ix+OB_FUL)
	ld h,(ix+OB_FUH)

; If behavior function address is 0, go to next object.
; Else execute behavior.

	ld a,h
	or l
	jr z,exob1
	call jphl

; Point HL to next Object.

exob1	pop hl
	ld bc,OBJSZ
	add hl,bc
	ret

; ---------
; 'kfeedbk'
; ---------
;
; Sound to make when keys pressed in menus etc.

kfeedbk	
	push bc
	push de
	push hl
	ld hl,+BEEP_FREQX256(440*256)
	ld de,+BEEP_MS(440*256, 25)
	call beep
	pop hl
	pop de
	pop bc
	ret

; N rects filled and current rect pointer.
;nrects	.db 0
;rectp	.dw reclst

; Frame counter.
frames	.db 0

; Cheats.
cheats_god	.db CHEATS_GOD
cheats_rst	.db CHEATS_RST

#include "lib.asm"

#ifdef ZX
#include "lib_zx.asm"
#include "altair_zx.asm"
#include "font_zx.asm"
#endif

#ifdef CPC
#include "lib_cpc.asm"
#include "altair_cpc.asm"
#endif

#include "states.asm"
#include "gameplay_st.asm"
#include "drmach.asm"
#include "menu_st.asm"
#include "attract_st.asm"
#include "options_st.asm"
#include "killed_st.asm"
#include "round_st.asm"
#include "name_st.asm"
#include "disclaimer_st.asm"
#include "dedicate_st.asm"
#include "gameover_st.asm"
#include "hud.asm"
#include "anim.asm"
#include "obfun.asm"
#include "timer.asm"
#include "interr.asm"
#include "sound.asm"
#include "altair_snd.asm"
#include "images.asm"

endp	.equ $

#include "ram.asm"

	.echo "Number of sprites "
	.echo NSPRS
	.echo "\nNumber of rects "
	.echo MAXRECS
	.echo "\nTotal program memory: "
	.echo (eofram - start)
	.echo " bytes.\n"
	.echo "Cheats adresses:\nInvincible: "
	.echo cheats_god
	.echo "\nPass level: "
	.echo cheats_rst
	.echo "\n"

	.end

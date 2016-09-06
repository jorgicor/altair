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
; Game state handling.
; ----------------------------------------------------------------------------

; -------------
; States Tables
; -------------

enter_states
	.dw enter_menu_st
	.dw enter_gameplay_st
	.dw enter_attract_st
	.dw enter_options_st
	.dw enter_killed_st
	.dw enter_round_st
	.dw enter_name_st
	.dw enter_disclaimer_st
	.dw enter_dedicate_st
	.dw enter_gameover_st

update_states
	.dw update_menu_st
	.dw update_gameplay_st
	.dw update_attract_st
	.dw update_options_st
	.dw update_killed_st
	.dw update_round_st
	.dw update_name_st
	.dw update_disclaimer_st
	.dw update_dedicate_st
	.dw update_gameover_st

; Current state.

stat	.db STATE_NONE

; Update handler. Update function address of the current state.

update_handler	.dw 0

; -----------
; 'set_state'
; -----------
;	Changes the previous state to the new one, calling first the exit
; handler on the old one, and then enter handler on the new one.
;
; In	A desired new state.

set_state

; Desired state.

	ld c,a

; If we are on the same sate, do nothing.

	ld a,(stat)
	cp c
	ret z

set_state_enter

; Call enter handler.

	ld hl,enter_states
	ld a,c
	call getwt
	push bc
	call jphl
	pop bc

; Set state var.

	ld a,c
	ld (stat),a

; Set state update handler for quick access.

	ld hl,update_states
	call getwt
	ld (update_handler),hl
	ret

; -----------------------------------
; 'update_state' Update current state
; -----------------------------------

update_state

	ld hl,(update_handler)
	call jphl
	ret

; -------------------
; 'drfx' Draw effects
; -------------------
;	Draws over the backbuf once the frame is rendered on it.

drfx	ld a,(stat)
	cp STATE_ATTRACT
	jp z,drfx_attract_st
	cp STATE_GAMEOVER
	jp z,drfx_gameover_st
	ret

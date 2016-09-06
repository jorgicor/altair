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
; Instruction machine for drawing step by step.
; ----------------------------------------------------------------------------

ISTOP		.equ 0
IDRHLINE	.equ 1
IDRVLINE	.equ 2
ITEXT		.equ 3
ICLS		.equ 4
IDRALIEN	.equ 5
IDELAY		.equ 6
IDRNUM		.equ 7
IDRCHR		.equ 8
IIFBIRDK	.equ 9
IENDIF		.equ 10
IBEEP		.equ 11

IDRHLINE_CHAR	.equ 1
IDRHLINE_COLOR	.equ 2
IDRHLINE_ROW	.equ 3
IDRHLINE_COLUMN	.equ 4
IDRHLINE_MAXCOL	.equ 5

IDRVLINE_CHAR	.equ 1
IDRVLINE_COLOR	.equ 2
IDRVLINE_COLUMN	.equ 3
IDRVLINE_ROW	.equ 4
IDRVLINE_MAXROW	.equ 5

ITEXT_COLOR	.equ 1
ITEXT_COLUMN	.equ 2
ITEXT_ROW	.equ 3
ITEXT_TXLO	.equ 4
ITEXT_TXHI	.equ 5

ICLS_COLOR	.equ 1

IDRALIEN_ID	.equ 1
IDRALIEN_COLOR	.equ 2
IDRALIEN_X	.equ 3
IDRALIEN_Y	.equ 4

IDELAY_TIMELO	.equ 1
IDELAY_TIMEHI	.equ 2

IDRNUM_COLOR	.equ 1
IDRNUM_DIGITS	.equ 2
IDRNUM_NUMLO	.equ 3
IDRNUM_NUMHI	.equ 4
IDRNUM_X	.equ 5
IDRNUM_Y	.equ 6

IDRCHR_COLOR	.equ 1
IDRCHR_X	.equ 2
IDRCHR_Y	.equ 3
IDRCHR_LO	.equ 4
IDRCHR_HI	.equ 5

IIFBIRDK_TEST	.equ 1

IBEEP_HZL	.equ 1
IBEEP_HZH	.equ 2
IBEEP_DURL	.equ 3
IBEEP_DURH	.equ 4

; How many arguments needs each instruction.

mach_nargs	.db 1	; ISTOP
		.db 6	; IDRHLINE char_code color row start_column end_column
		.db 6	; IDRVLINE char_code color column start_row end_row
		.db 6	; ITEXT color column row text_addr_lo text_addr_hi
		.db 2	; ICLS color
		.db 5	; IDRALIEN id color column row
		.db 3	; IDELAY timelo timehi
		.db 7	; IDRNUM color ndigits numadrlo numadrhi column row
		.db 6	; IDRCHR color column row charaddr_lo charaddr_hi
		.db 2	; IIFBIRDK bool
		.db 1	; IENDIF
		.db 5	; IBEEP hzlo hzho durationlo durationhi

mach_fun	.dw 0
mach_funs	.dw istop_f
		.dw idrhline_f
		.dw idrvline_f
		.dw idrtext_f
		.dw icls_f
		.dw idralien_f
		.dw idelay_f
		.dw idrnum_f
		.dw idrchr_f
		.dw iifbirdk_f
		.dw iendif_f
		.dw ibeep_f

; Next instruction address.
mach_pc		.dw 0

; Current arguments are saved here
mach_args	.fill 8

; Delay for each step.
mach_delay0	.dw 0

; Current delay counter.
mach_delay	.dw 0

; Stopped?
mach_stopped	.db 1

; If skipping until IENDIF.
mach_wendif	.db 0

; Enable or disable delays.
mach_delayon	.db 1

; ------------
; 'mach_start'
; ------------
;	Start machine.
;
; In	HL address of instructions.

mach_start

; Set running.

	xor a
	ld (mach_stopped),a
	ld (mach_wendif),a

; Decode first instruction.

	ld (mach_pc),hl
	call mach_decode

; Set no delay at start and delay on.

	ld hl,0
	ld (mach_delay),hl
	ld (mach_delay0),hl
	ld a,1
	ld (mach_delayon),a
	ret

; -------------
; 'mach_update'
; -------------
;	Update machine.
;
; Out	Z if running.

mach_update

; Stopped?

	ld a,(mach_stopped)
	or a
	ret nz

; Wait some time.

	ld hl,(mach_delay)
	ld a,h
	or l
	jr z,mach_update_do
	dec hl
	ld (mach_delay),hl
	xor a
	ret
	
mach_update_do

; Reset delay.

	ld hl,(mach_delay0)
	ld (mach_delay),hl

#if 0
; beeper
	ld hl,$066b
	ld de,1
	call $03b5
#endif

; Execute instruction step.

	push ix
	ld ix,mach_args
	ld hl,(mach_fun)
	call jphl
	call c,mach_decode
	pop ix

mach_update_skip

; We are jumping instructions until endif?

	ld a,(mach_wendif)
	or a
	jr z,mach_update_end

; Jump instrunctions until endif.

	ld a,(mach_args)
	cp IENDIF
	jr z,mach_update_end
	cp ISTOP
	jr z,mach_update_end

	call mach_decode
	jr mach_update_skip

mach_update_end
	xor a
	ret

; -------------------
; 'mach_enable_delay'
; -------------------
;	Sets the delay on or off.
;
; In	A 1 or 0 to enable or disable.
; Saves	BC, DE, HL.

mach_enable_delay

	ld (mach_delayon),a
	or a
	ret nz

; Delay disabled.

	ld (mach_delay0),a
	ld (mach_delay),a
	ret

; --------------------
; mach_update_till_end
; --------------------
;	Updates the machine in a loop until it ends.

mach_update_till_end
	call mach_update
	jr z,mach_update_till_end
	ret

; -------------
; 'mach_decode'
; -------------
;	Decode instruction pointed by mach_pc, and sets next instruction.

mach_decode
	ld hl,(mach_pc)

; Take instruction id.

	ld a,(hl)

; Set function ptr.

	push hl
	ld hl,mach_funs
	call getwt
	ld (mach_fun),hl
	pop hl

; Get number of arguments.

	push hl
	ld hl,mach_nargs
	call getbt
	pop hl

; Save arguments in mach_args.

	ld de,mach_args
	ld c,a
	ld b,0
	ldir

; Set next instruction address.

	ld (mach_pc),hl
	ret

;	ISTOP.
istop_f ld a,1
	ld (mach_stopped),a
	xor a
	ld (mach_wendif),a
	or a
	ret

;	IDRHLINE
idrhline_f
	ld a,(ix+IDRHLINE_CHAR)
	call font_chadr
	ld d,(ix+IDRHLINE_ROW)
	ld e,(ix+IDRHLINE_COLUMN)
	ld a,(ix+IDRHLINE_COLOR)
	push de
	call set_char_color
	call drchrc
	pop de
	ld a,e
	cp (ix+IDRHLINE_MAXCOL)
	jr nz,idrhline_f_next
	scf
	ret
idrhline_f_next
	jr c,idrhline_f_inc
	dec (ix+IDRHLINE_COLUMN)
	jr idrhline_f_end
idrhline_f_inc
	inc (ix+IDRHLINE_COLUMN)
idrhline_f_end
	or a
	ret

;	IDRVLINE
idrvline_f
	ld a,(ix+IDRVLINE_CHAR)
	call font_chadr
	ld d,(ix+IDRVLINE_ROW)
	ld e,(ix+IDRVLINE_COLUMN)
	ld a,(ix+IDRVLINE_COLOR)
	push de
	call set_char_color
	call drchrc
	pop de
	ld a,d
	cp (ix+IDRVLINE_MAXROW)
	jr nz,idrvline_f_next
	scf
	ret
idrvline_f_next
	jr c,idrvline_f_inc
	dec (ix+IDRVLINE_ROW)
	jr idrvline_f_end
idrvline_f_inc
	inc (ix+IDRVLINE_ROW)
idrvline_f_end
	or a
	ret

; idrtext_f
idrtext_f
	ld l,(ix+ITEXT_TXLO)
	ld h,(ix+ITEXT_TXHI)
	ld a,(hl)
	or a
	jr nz,idrtext_f_next
	scf
	ret
idrtext_f_next
	inc hl
	ld (ix+ITEXT_TXLO),l
	ld (ix+ITEXT_TXHI),h
	call font_chadr
	ld d,(ix+ITEXT_ROW)
	ld e,(ix+ITEXT_COLUMN)
	ld a,(ix+ITEXT_COLOR)
	call set_char_color
	call drchrc
	inc (ix+ITEXT_COLUMN)
	or a
	ret
	
icls_f	ld a,(ix+ICLS_COLOR)
	call clrscr
	scf
	ret

alims	.dw alim00
	.dw alim10
	.dw alim20
	.dw alim30
	.dw alim40
	.dw alim50
	.dw alim60

; -----------
; 'idralien_f'
; -----------
;	Draws an alien image directly on the screen.
;	Specific code for each machine. Look in altair_zx, altair_cpc, etc.

; ----------------------------
; 'idelay_f' Instruction DELAY
; ----------------------------
;	Sets the delay for each step of the machine.

idelay_f

; If delay is disabled for the machine, set no delay.

	ld a,(mach_delayon)
	or a
	jr z,idelay_f_end

; Set delay.

	ld l,(ix+IDELAY_TIMELO)
	ld h,(ix+IDELAY_TIMEHI)
	ld (mach_delay0),hl
	ld (mach_delay),hl

idelay_f_end

	scf
	ret
	
; ----------------------
; 'idrnum_f' Draw number
; ----------------------
;	Draws number.

idrnum_f

	ld b,(ix+IDRNUM_DIGITS)	
	ld c,(ix+IDRNUM_COLOR)
	ld d,(ix+IDRNUM_Y)
	ld e,(ix+IDRNUM_X)
	ld l,(ix+IDRNUM_NUMLO)
	ld h,(ix+IDRNUM_NUMHI)
	call drnum
	scf
	ret

; --------------------
; 'idrchr_f' Draw char
; --------------------
;	Draws character data.

idrchr_f
	ld l,(ix+IDRCHR_LO)
	ld h,(ix+IDRCHR_HI)
	ld e,(ix+IDRCHR_X)
	ld d,(ix+IDRCHR_Y)
	ld a,(ix+IDRCHR_COLOR)
	call set_char_color
	call drchrc
	scf
	ret

iifbirdk_f
	ld a,(bird_killed_once)
	cp (ix+IIFBIRDK_TEST)
	jr z,iifbirdk_f_end
	ld a,1
	ld (mach_wendif),a

iifbirdk_f_end
	scf
	ret

iendif_f
	xor a
	ld (mach_wendif),a
	scf
	ret
	
; ---------
; 'ibeep_f'
; ---------

ibeep_f
	ld l,(ix+IBEEP_HZL)
	ld h,(ix+IBEEP_HZH)
	ld e,(ix+IBEEP_DURL)
	ld d,(ix+IBEEP_DURH)
	call beep
	scf
	ret
	

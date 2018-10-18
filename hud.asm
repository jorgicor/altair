; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Display of scores, lifes, etc, during gameplay.
; ----------------------------------------------------------------------------

txcidelsa	.db 1, CYAN
txcidelsa_str	.db "CIDELSA", 0
tx1	.db 1, YELLOW, '1', 0
txhscor	.db 1, WHITE, "HIGH SCORE", 0
tx2	.db 1, YELLOW, '2', 0
txup	.db 1, CYAN, "UP", 0
txupclr	.db 1, BLACK, "  ", 0

; Lenght of some texts.
TXHSCOR_LEN	.equ 10
TXCIDELSA_LEN	.equ 7

; Number of max lifes to paint.
MAXLIFES	.equ 5

; Number of digits for scores.

SCORDIG	.equ 5

; Players score.

scor1	.db 0, 0, 0, 0, 0
scor2	.db 0, 0, 0, 0, 0

; Players backup score.

bscor1	.db 0, 0, 0, 0, 0
bscor2	.db 0, 0, 0, 0, 0

; Table to access scorX by index.

plscor	.dw scor1
	.dw scor2

; Default starting score

defscor	.db 0, 0, 0, 0, 0

; Score to sum when alien or bird destroyed.

scoral0		.db 0, 0, 0, 3, 0
scoral1		.db 0, 0, 0, 6, 0
scoral2		.db 0, 0, 0, 7, 0
scoral3		.db 0, 0, 0, 9, 0
scoral4		.db 0, 0, 1, 0, 0
scoral5		.db 0, 0, 1, 2, 0
scoral6		.db 0, 0, 1, 5, 0
scorbird	.db 0, 0, 5, 0, 0

; Table to access alien points by index.

alscor	.dw scoral0
	.dw scoral1
	.dw scoral2
	.dw scoral3
	.dw scoral4
	.dw scoral5
	.dw scoral6
	.dw scorbird

; High score.

hscor	.db 0, 0, 0, 0, 0

; High score overflow. Set to 1 if score passes from 99999 to 0.
hscorof	.db 0

; High score max. Set to 1 if we pass a level in which the high score
; overflowed.
hscormx	.db 0

; Maximum number.
maxnum	.db 9, 9, 9, 9, 9

; -----------
; 'drcidelsa'
; -----------

drcidelsa
	ld a,CYAN
	ld hl,txcidelsa
	ld d,23
	ld e,BBUFXC+BBUFWC-TXCIDELSA_LEN
	call drstr
	ret

; --------------------------------
; 'drtxhscor' Draw High Score Text
; --------------------------------
;	Draws high score title.

drtxhscor
	ld hl,txhscor
	ld de,BBUFXC+((BBUFWC-TXHSCOR_LEN)/2)
	call drstr
	ret

; -------------------------
; 'drhscor' Draw High Score
; -------------------------
;	Draws high score value.

drhscor ld hl,hscor
	ld b,SCORDIG
	ld c,RED
	ld d,1
	ld e,BBUFXC+((BBUFWC-SCORDIG)/2)
	call drnum
	ret

; ---------------------
; 'rstscor' Reset score
; ---------------------
;	Reset score for players.
;
; Saves A.

rstscor ld de,scor1
	call cpdefscor
	ld de,scor2
	call cpdefscor
	ld de,bscor1
	call cpdefscor
	ld de,bscor2
	call cpdefscor
	ret

; ------------------------------
; 'cpdefscor' Copy defalut score
; ------------------------------
;	Copies default score into number.
;
; In	DE destiny number.
; Saves	A.

cpdefscor

	ld hl,defscor
	ld bc,SCORDIG
	ldir
	ret

; ----------------------------------
; 'drscorup' Draw UP in player score
; ----------------------------------
;	Draws UP in the player score selected and clears the rival one.
;
; In	A player 0 or 1.
; Saves	A.

drscorup
	push af
	or a
	jr z,drscorup0

; Player 2 UP.

	ld hl,txup
	ld de,BBUFXC+BBUFWC-3
	call drstr
	ld hl,txupclr
	ld de,BBUFXC+2
	call drstr
	jr drscorup_end

; Player 1 UP.

drscorup0
	ld hl,txup
	ld de,BBUFXC+2
	call drstr
	ld hl,txupclr
	ld de,BBUFXC+BBUFWC-3
	call drstr

drscorup_end
	pop af
	ret

; --------------------------------------
; 'drtxplayer' Draw player number 1 or 2
; --------------------------------------
;
; In	A player 0 or 1.
; Saves	A.

drtxplayer

	push af
	or a
	jr z,drtxplayer0

; Player 2.

	ld hl,tx2
	ld de,BBUFXC+BBUFWC-4
	call drstr
	jr drtxplayer_end

; Player 1.

drtxplayer0

	ld hl,tx1
	ld de,BBUFXC+1
	call drstr

drtxplayer_end
	pop af
	ret

; --------------------------
; 'drscor' Draw player score
; --------------------------
;
; In	A player 0 or 1.
; Saves	A.

drscor

	push af
	or a
	jr z,drscor0

; Player 2.

	ld hl,scor2
	ld b,SCORDIG
	ld c,RED
	ld d,1
	ld e,BBUFXC+BBUFWC-SCORDIG
	call drnum
	jr drscor_end

; Player 1.

drscor0
	ld hl,scor1
	ld b,SCORDIG
	ld c,RED
	ld d,1
	ld e,BBUFXC
	call drnum

drscor_end
	pop af
	ret

; -------------------
; 'addscor' Add score
; -------------------
;	Adds score to one of the players. Returns if player passed a
; 10000 points boundary.
;
; In	A player (0 or 1). C alien (= level 0-7).
; Out	CY=1 if 10000 points boundary crossed.
; Saves	None.

addscor	

; Get player score number.

	ld hl,plscor
	call getwt
	ld d,h
	ld e,l

; Get the fifth digit.

	ld b,SCORDIG-5
	call digit
	push af
	
; Get alien value points.

	ld hl,alscor
	ld a,c
	call getwt

; Add.

	push de
	ld b,SCORDIG
	call addnum
	pop hl

; Check if 10000 boundary passed.

	ld b,SCORDIG-5
	call digit
	ld b,a
	pop af
	cp b
	ret z

; Boundary crossed.

; Check if we passed from 99999 to 0.

	xor a
	or b
	jr nz,addscor_end

; Set high score overflow.

	ld a,1
	ld (hscorof),a
	
addscor_end

	scf
	ret

; -----------------------
; 'backscor' Backup score
; -----------------------
;	On level entry the score is saved. If we are killed we return to
; this saved score.
;
; In	A player (0 or 1)
; Saves	A.

backscor

; Which player?

	or a
	jr nz,backscor2

; Player 1.

	ld hl,scor1
	ld de,bscor1
	jr backscor_end

; Player 2.
backscor2

	ld hl,scor2
	ld de,bscor2

backscor_end

	ld bc,SCORDIG
	ldir
	ret
	
; ------------------------
; 'restscor' Restore score
; ------------------------
;	On level entry the score is saved. If we are killed we return to
; this saved score.
;
; In	A player to restore score.
; Saves	A.

restscor

; Which player?

	or a
	jr nz,restscor2

; Player 1.

	ld hl,bscor1
	ld de,scor1
	jr restscor_end

; Player 2.

restscor2

	ld hl,bscor2
	ld de,scor2

restscor_end

	ld bc,SCORDIG
	ldir
	ret

; ---------------------------
; 'drlifes' Draw player lifes
; ---------------------------
;
; In	A number of lifes.

drlifes	

; min(MAXLIFES, desired lifes)

	ld c,MAXLIFES
	call min
	ld c,a

; y,x pos.

	ld d,23
	ld e,BBUFXC

; If 0 lifes only blank.

	or a
	jr z,drlifes_chk_blank

; Draw lifes.

	ld hl,hudlife
	ld a,CYAN
	call set_char_color
	push bc

drlifes_next

	push hl
	push de
	call drchrc
	pop de
	pop hl
	inc e
	dec c
	jr nz,drlifes_next

	pop bc

drlifes_chk_blank

; Now blank remining characters, if any.

	ld a,MAXLIFES
	sub c

; We have painted the max, no need to blank anything.

	ret z

; We have to blank A characters.

	ld c,a
	ld a,32
	call font_chadr
	ld a,CYAN
	call set_char_color

drlifes_blank
	
	push hl
	push de
	call drchrc
	pop de
	pop hl
	inc e
	dec c
	jr nz,drlifes_blank
	ret

; -------------------------
; 'sethscor' Set High Score
; -------------------------
;	Sets the high score depending on the scores in the backup of the two
; players, and hscormx.

sethscor

	ld a,(hscormx)
	or a
	jr z,sethscor_select

; Max high score reached.

	ld hl,maxnum
	ld de,hscor
	ld bc,SCORDIG
	ldir
	ret

sethscor_select

	ld hl,bscor1
	ld de,bscor2
	call minnum
	cp 1
	jr z,sethscor1
	ex de,hl

sethscor1

; HL has the high score of the two players. Compare with high score.

	ld de,hscor
	call minnum
	cp -1
	ret z

; Better score!

	ld bc,SCORDIG
	ldir
	ret
	
; -------------
; 'min' Minimum
; -------------
;	Returns minimum of C and A in A.
;
; In	A, C.
; Out	A = min(A, C)
; Saves	B, DE, HL.

min	cp c
	ret c
	ld a,c
	ret
	

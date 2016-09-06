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
; Constants.
; ----------------------------------------------------------------------------

; ------------
; Sprite Table
; ------------

MINE_SP_SLOT		.equ 0
MINE_SP_SLOTS		.equ 12
EXPLOSION_SP_SLOT	.equ MINE_SP_SLOT+MINE_SP_SLOTS
EXPLOSION_SP_SLOTS	.equ 6
SHIP_SHOT_SP_SLOT	.equ EXPLOSION_SP_SLOT+EXPLOSION_SP_SLOTS
SHIP_SHOT_SP_SLOTS	.equ 2
SHIP_SP_SLOT		.equ SHIP_SHOT_SP_SLOT+SHIP_SHOT_SP_SLOTS
SHIP_SP_SLOTS		.equ 5
ALIEN_SHOT_SP_SLOT	.equ SHIP_SP_SLOT+SHIP_SP_SLOTS
ALIEN_SHOT_SP_SLOTS	.equ 6
ALIEN_SP_SLOT		.equ ALIEN_SHOT_SP_SLOT+ALIEN_SHOT_SP_SLOTS
ALIEN_SP_SLOTS		.equ 6
BIRD_LSHIELD_SP_SLOT	.equ ALIEN_SP_SLOT+ALIEN_SP_SLOTS
BIRD_LSHIELD_SP_SLOTS	.equ 1
BIRD_RSHIELD_SP_SLOT	.equ BIRD_LSHIELD_SP_SLOT+BIRD_LSHIELD_SP_SLOTS
BIRD_RSHIELD_SP_SLOTS	.equ 1
HOUSE_SP_SLOT		.equ BIRD_RSHIELD_SP_SLOT+BIRD_RSHIELD_SP_SLOTS
HOUSE_SP_SLOTS		.equ 2
NSPRS			.equ HOUSE_SP_SLOT+HOUSE_SP_SLOTS

; Careful, for the bird we are reusing the sprites form ALIEN_SHOT_SP_SLOTS
BIRD_NSPS		.equ 14
BIRD_SP_SLOT		.equ ALIEN_SHOT_SP_SLOT
BIRD_SP_SLOTS		.equ BIRD_NSPS
BIRD_EXPLOSION_SP_SLOT	.equ HOUSE_SP_SLOT

; Maximum number of rects that the Rect List can contain.
MAXRECS	.equ NSPRS*2

; Object slots.
; Function.
OB_FUL	.equ 0
OB_FUH	.equ 1
; Sprite pointer.
OB_SPL	.equ 2
OB_SPH	.equ 3
; Dimensions.
OB_DX	.equ 4
OB_DY	.equ 5
; Other sprite
OB_SP2L	.equ 4
OB_SP2H	.equ 5
; Counters.
OB_CNT0	.equ 4
OB_CNT1	.equ 5
OB_CNT3	.equ 2
OBJSZ	.equ 6

; -------------
; Sprite Struct
; -------------

#ifdef ZX
; Address of Image Table.
SP_ITL	.equ 0
SP_ITH	.equ 1
; Position in pixels.
SP_PX	.equ 2
SP_PY	.equ 3
; Color if SP_COH is 0, otherwise address of Color Pattern.
SP_COL	.equ 4
SP_COH	.equ 5
; Animation address, 0 no animation.
SP_ANL	.equ 6
SP_ANH	.equ 7
; Speed and speed counter for animation.
SP_SPE	.equ 8
SP_SPC	.equ 9
; Frame of animation.
SP_FRA	.equ 10
; If looped or not.
SP_LOP	.equ 11
SPRSZ	.equ 12
#endif

#ifdef CPC
; Address of Image Table.
SP_ITL	.equ 0
SP_ITH	.equ 1
; Position in pixels.
SP_PX	.equ 2
SP_PY	.equ 3
; Animation address, 0 no animation.
SP_ANL	.equ 4
SP_ANH	.equ 5
; Speed and speed counter for animation.
SP_SPE	.equ 6
SP_SPC	.equ 7
; Frame of animation.
SP_FRA	.equ 8
; If looped or not.
SP_LOP	.equ 9
SPRSZ	.equ 10
#endif

; Image Slots.
; Dimensions.
IM_WID	.equ 0
IM_HEI	.equ 1

; Image constants.
SHIP_IM_WC	.equ 3
SHIP_IM_W	.equ SHIP_IM_WC*8
SHIP_IM_H	.equ 16
SHIP_IM_HC	.equ SHIP_IM_H/8
HOUSE_IM_WC	.equ 3
ALIEN_IM_H	.equ 6
ALIEN_IM_WC	.equ 2
ALIEN_IM_W	.equ ALIEN_IM_WC*8
EXPLOSION_IM_H	.equ 12
EXPLOSION_OFFS	.equ (EXPLOSION_IM_H - ALIEN_IM_H) / 2
BIRD_WC		.equ 6
BIRD_HC		.equ 7

; Starting positions.
HOUSE_LPOS	.equ 8
HOUSE_MPOS	.equ 8 * ((BBUFWC - HOUSE_IM_WC) / 2)
HOUSE_RPOS	.equ 8 * (BBUFWC - HOUSE_IM_WC - 1)
SHIP_LPOS	.equ 8
SHIP_MPOS	.equ 8 * ((BBUFWC - SHIP_IM_WC) / 2)
SHIP_RPOS	.equ 8 * (BBUFWC - SHIP_IM_WC - 1)

BIRD_LEVEL	.equ 7

;
SHIP_SHOT_SPEED		.equ 4
ALIEN_SHOT_SPEED	.equ 4

HOUSE_YPOS	.equ 8

; Main program states.
STATE_NONE	.equ -1
STATE_MENU	.equ 0
STATE_GAMEPLAY	.equ 1
STATE_ATTRACT	.equ 2
STATE_OPTIONS	.equ 3
STATE_KILLED	.equ 4
STATE_ROUND	.equ 5
STATE_NAME	.equ 6
STATE_DISCLAIMER	.equ 7
STATE_DEDICATE	.equ 8
STATE_GAMEOVER	.equ 9

; End of line.
EOF	.equ 2

#ifdef ZX
BLACK_BLACK		.equ BLACK|PBLACK
WHITE_BLACK		.equ WHITE|PBLACK
BLUE_BLUE		.equ BLUE|BLUE
GREEN_BLUE		.equ PBLUE|GREEN
CYAN_BLUE		.equ CYAN|PBLUE
ABUFCLR			.equ BLUE|PBLACK
BBUF_BLACK		.equ ABUFCLR
BBUF_GREEN		.equ BLACK|PGREEN
BBUF_RED		.equ BLACK|PRED
SHIELD_FULL		.equ $ff
SHIELD_PARTIAL		.equ $55
SHIELD_EMPTY		.equ 0
#endif

#ifdef CPC
BLACK_BLACK		.equ BLACK|PBLACK
WHITE_BLACK		.equ WHITE|PBLACK
BLUE_BLUE		.equ BLUE|PBLUE
GREEN_BLUE		.equ PBLUE|GREEN
CYAN_BLUE		.equ CYAN|PBLUE
ABUFCLR			.equ BLACK|PBLACK
BBUF_BLACK		.equ BBLACK
BBUF_GREEN		.equ BGREEN
BBUF_RED		.equ BRED
SHIELD_FULL		.equ WHITE|PWHITE
SHIELD_PARTIAL		.equ WHITE|PBLACK
SHIELD_EMPTY		.equ BLACK|PBLACK
#endif

; Some border colors.
BORDER_MENU		.equ BBLUE
BORDER_GAME		.equ BBLACK
BORDER_NAME		.equ BRED


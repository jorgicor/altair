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

; Masks to access pixel left and right on a byte.
PIX0	.equ %10101010
PIX1	.equ %01010101

; Video ram address.
vram	.equ $c000

; Screen width and height in characters.
SCRWC	.equ 32
SCRHC	.equ 24

; Screen width and height in bytes.
SCRWB	.equ SCRWC*2
SCRHB	.equ SCRHC*8

; Screen width and height in subpixels (spectrum pixel size).
SCRW	.equ SCRWC*8
SCRH	.equ SCRHB

; Screen width and height in screen pixels (1 pixel is 2 subpixels).
SCRWP	.equ SCRWB*2
SCRHP	.equ SCRH

; Border colors.

BBLACK	.equ 20
BBLUE	.equ 4
BBRBLUE	.equ 21
BRED	.equ 28
BMAGENT	.equ 24
BMAUVE	.equ 29
BBRRED	.equ 12
BPURPLE	.equ 5
BBRMAGE	.equ 13
BGREEN	.equ 22
BCYAN	.equ 6
BSKYBLU	.equ 23
BYELLOW	.equ 30
BWHITE	.equ 0
BPABLUE	.equ 31
BORANGE	.equ 14
BPINK	.equ 7
BPAMAGE	.equ 15
BBRGREE	.equ 18
BSEGREE	.equ 2
BBRCYAN	.equ 19
BLIME	.equ 26
BPAGREE	.equ 25
BPACYAN	.equ 27
BBRYELL	.equ 10
BPAYELL	.equ 3
BBRWHIT	.equ 11

; Pens.
;
; When a routine wants a 'block color', we should pass a pen and paper.
; For example, PEN3 + PAPER5.

PEN0	.equ %00000000
PEN1	.equ %10000000
PEN2	.equ %00001000
PEN3	.equ %10001000
PEN4	.equ %00100000
PEN5	.equ %10100000
PEN6	.equ %00101000
PEN7	.equ %10101000
PEN8	.equ %00000010
PEN9	.equ %10000010
PEN10	.equ %00001010
PEN11	.equ %10001010
PEN12	.equ %00100010
PEN13	.equ %10100010
PEN14	.equ %00101010
PEN15	.equ %10101010

PAPER0	.equ PEN0 >> 1
PAPER1	.equ PEN1 >> 1
PAPER2	.equ PEN2 >> 1
PAPER3	.equ PEN3 >> 1
PAPER4	.equ PEN4 >> 1
PAPER5	.equ PEN5 >> 1
PAPER6	.equ PEN6 >> 1
PAPER7	.equ PEN7 >> 1
PAPER8	.equ PEN8 >> 1
PAPER9	.equ PEN9 >> 1
PAPER10	.equ PEN10 >> 1
PAPER11	.equ PEN11 >> 1
PAPER12	.equ PEN12 >> 1
PAPER13	.equ PEN13 >> 1
PAPER14	.equ PEN14 >> 1
PAPER15	.equ PEN15 >> 1

; Spectrum mapping.
BLACK	.equ PEN0
BLUE	.equ PEN3
RED	.equ PEN12
MAGENT	.equ PEN14
GREEN	.equ PEN5
CYAN	.equ PEN8
YELLOW	.equ PEN7
WHITE	.equ PEN9
PBLACK	.equ PAPER0
PBLUE	.equ PAPER3
PRED	.equ PAPER12
PMAGENT	.equ PAPER14
PGREEN	.equ PAPER5
PCYAN	.equ PAPER8
PYELLOW	.equ PAPER7
PWHITE	.equ PAPER9

; Key codes.

KEY_FDO	.equ %11100000
KEY_F0	.equ %11100001
KEY_CTR	.equ %11100010	; Control
KEY_PER	.equ %11100011	; .
KEY_COM	.equ %11100100	; ,
KEY_SPC	.equ %11100101
KEY_V	.equ %11100110
KEY_X	.equ %11100111
KEY_Z	.equ %11101000
KEY_DEL	.equ %11101001

KEY_ENT	.equ %11000000	; Enter
KEY_F2	.equ %11000001
KEY_BSL	.equ %11000010	; Back slash \
KEY_SLA	.equ %11000011	; Slash /
KEY_M	.equ %11000100
KEY_N	.equ %11000101
KEY_B	.equ %11000110
KEY_C	.equ %11000111
KEY_CAP	.equ %11001000	; Caps lock
KEY_J13	.equ %11001001	; Joystick 1 fire 3

KEY_F3	.equ %10100000
KEY_F1	.equ %10100001
KEY_SHI	.equ %10100010	; Shift
KEY_CLN	.equ %10100011	; : Colon
KEY_K	.equ %10100100
KEY_J	.equ %10100101
KEY_F	.equ %10100110
KEY_D	.equ %10100111
KEY_A	.equ %10101000
KEY_J12	.equ %10101001	; Joystick 1 fire 2

KEY_F6	.equ %10000000
KEY_F5	.equ %10000001
KEY_F4	.equ %10000010
KEY_SCL	.equ %10000011	; Semicolon ;
KEY_L	.equ %10000100
KEY_H	.equ %10000101
KEY_G	.equ %10000110
KEY_J21	.equ %10000110	; Joystick 2 fire 1
KEY_S	.equ %10000111
KEY_TAB	.equ %10001000
KEY_J11	.equ %10001001	; Joystick 1 fire 1

KEY_F9	.equ %01100000
KEY_F8	.equ %01100001
KEY_RBR	.equ %01100010	; ] Right bracket
KEY_P	.equ %01100011
KEY_I	.equ %01100100
KEY_Y	.equ %01100101
KEY_T	.equ %01100110
KEY_J2R	.equ %01100110	; Joystick 2 right
KEY_W	.equ %01100111
KEY_Q	.equ %01101000
KEY_J1R	.equ %01101001	; Joystick 1 right

KEY_CDO	.equ %01000000	; Cursor down
KEY_F7	.equ %01000001
KEY_RET	.equ %01000010	; Return
KEY_AT	.equ %01000011	; @ at sign
KEY_O	.equ %01000100
KEY_U	.equ %01000101
KEY_R	.equ %01000110
KEY_J2L	.equ %01000110	; Joystick 2 left
KEY_E	.equ %01000111
KEY_ESC	.equ %01001000
KEY_J1L	.equ %01001001	; Joystick 1 left

KEY_CRI	.equ %00100000	; Cursor right
KEY_CPY	.equ %00100001	; Copy
KEY_LBR	.equ %00100010	; [ Left bracket
KEY_MIN	.equ %00100011	; - Minus sign
KEY_9	.equ %00100100
KEY_7	.equ %00100101
KEY_5	.equ %00100110
KEY_J2D	.equ %00100110	; Joystick 2 down
KEY_3	.equ %00100111
KEY_2	.equ %00101000
KEY_J1D	.equ %00101001	; Joystick 1 down

KEY_CUP	.equ %00000000	; Cursor up
KEY_CLE	.equ %00000001	; Cursor left
KEY_CLR	.equ %00000010	; CLR
KEY_EXP	.equ %00000011	; ^ Exponent
KEY_0	.equ %00000100
KEY_8	.equ %00000101
KEY_6	.equ %00000110
KEY_J2U	.equ %00000110	; Joystick 2 up
KEY_4	.equ %00000111
KEY_1	.equ %00001000
KEY_J1U	.equ %00001001	; Joystick 1 up

; ----------------------------------------------------------------------------
; Gameplay key flags.
;
; The game can call 'polli' each frame and then check the logical inputs with:
;
; ld a,(rinput)
; and K_UP
; jr z,up_is_down
;
; Or if it wants to check if a key is first pressed this frame:
;
; ld a,(finput)
; and K_FIRE
; jr z,fire_is_pressed_now
; ----------------------------------------------------------------------------

; Gameplay keys.
K_RIGHT	.equ 1
K_LEFT	.equ 2
K_DOWN	.equ 4
K_UP	.equ 8
K_FIRE	.equ 16
K_SERVA	.equ 32
K_SERVB	.equ 64
K_SERVC	.equ 128

; How many gameplay keys we need to poll. The minimum must be 5 (direction
; and fire). The max must be 8. The game can configure it.
#ifndef KEYTSZ
#define KEYTSZ 5
#endif

; Back buffer dimension in chars.
BBUFWC	.equ 24
BBUFHC	.equ 21

; Dimensions in bytes.
BBUFWB	.equ BBUFWC*2
BBUFHB	.equ BBUFHC*8

; Back buffer position on screen in chars.
BBUFXC	.equ 4
BBUFYC	.equ 2

; Back buffer position on screen in bytes.
BBUFXB	.equ BBUFXC*2
BBUFYB	.equ BBUFYC*8

; Dimension in subpixels (spectrum pixel size).
BBUFW	.equ BBUFWC*8
BBUFH	.equ BBUFHB

; Dimension in pixels (2 spectrum pixels are 1 cpc pixel).
BBUFWP	.equ BBUFW/2
BBUFHP	.equ BBUFH

; Maximum number of rects to clear that the buffer can handle.
BBUF_MAXRECS	.equ 100

; --------
; 8255 PPI
; --------
;
; Port A is $f4xx. Writes or reads from PSG data bus.
; Port B is $f5xx.
; 	bit 7 cassete read data.
;	bit 6 parallel/printer port ready (0 ready).
;	bit 5 1 device connected to expansion port.
;	bit 4 refresh rate 1 50 hz 0 60 hz. Cannot be chnaged.
;	bit 3-1 distributor id
;	bit 0 6845 vsync state 1 active.
; Port C is $f6xx.
;	bit 7-6 PSG function
;	    00 inactive.
;	    01 read from selected PSG register.
;	    10 write to selected PSG register.
;	    11 Select PSG register.
;	bit 5 cassette write data.
;	bit 4 cassette motor 1 motor on 0 off
;	bit 3-0 Select keyboard line.
; Control Port is $f7xx.
;	bit 7 if 1 configures
;		bit 5-6 0
;		bit 4 port A 0 output 1 input
;		bit 3 0, port C hi output
;		bit 2 0
;		bit 1 1, port B input
;		bit 0 0, port C lo output
;	bit 7 if 0 changes one bit of port C
;		bit 6-4 not used
;		bit 3-1 bumber of bit
;		bit 0 new value for bit (0 clear 1 set)

PPI_A	.equ $f400
PPI_AH	.equ PPI_A >> 8
PPI_B	.equ $f500
PPI_BH	.equ PPI_B >> 8
PPI_C	.equ $f600
PPI_CH	.equ PPI_C >> 8
PPI_CTRL	.equ $f700
PPI_CTRL_H	.equ PPI_CTRL >> 8

; Number of interrupts per vertical retrace
CPC_INTS_PER_VSYNC	.equ 6

; -------------------------
; Sound notes. A4 is 440Hz.
; -------------------------

; The audible human freqs are ~20Hz to ~20000Hz.
; A0 is 27.5 Hz.

; For the AY.
; v = 1000000 Hz / (note_freq * 16)
; The AY runs at 1MHz. The AY counts first 16 ticks.

YA0	.equ 2273
YAS0	.equ 2145
YB0	.equ 2025
YC1	.equ 1911
YCS1	.equ 1804
YD1	.equ 1703
YDS1	.equ 1607
YE1	.equ 1517
YF1	.equ 1432
YFS1	.equ 1351
YG1	.equ 1276
YGS1	.equ 1204
YA1	.equ 1136
YAS1	.equ 1073
YB1	.equ 1012
YC2	.equ 956
YCS2	.equ 902
YD2	.equ 851
YDS2	.equ 804
YE2	.equ 758
YF2	.equ 716
YFS2	.equ 676
YG2	.equ 638
YGS2	.equ 602
YA2	.equ 568
YAS2	.equ 536
YB2	.equ 506
YC3	.equ 478
YCS3	.equ 451
YD3	.equ 426
YDS3	.equ 402
YE3	.equ 379
YF3	.equ 358
YFS3	.equ 338
YG3	.equ 319
YGS3	.equ 301
YA3	.equ 284
YAS3	.equ 268
YB3	.equ 253
YC4	.equ 239
YCS4	.equ 225
YD4	.equ 213
YDS4	.equ 201
YE4	.equ 190
YF4	.equ 179
YFS4	.equ 169
YG4	.equ 159
YGS4	.equ 150
YA4	.equ 142
YAS4	.equ 134
YB4	.equ 127
YC5	.equ 119
YCS5	.equ 113
YD5	.equ 106
YDS5	.equ 100
YE5	.equ 95
YF5	.equ 89
YFS5	.equ 84
YG5	.equ 80
YGS5	.equ 75
YA5	.equ 71
YAS5	.equ 67
YB5	.equ 63
YC6	.equ 60
YCS6	.equ 56
YD6	.equ 53
YDS6	.equ 50
YE6	.equ 47
YF6	.equ 45
YFS6	.equ 42
YG6	.equ 40
YGS6	.equ 38
YA6	.equ 36
YAS6	.equ 34
YB6	.equ 32
YC7	.equ 30
YCS7	.equ 28
YD7	.equ 27
YDS7	.equ 25
YE7	.equ 24
YF7	.equ 22
YFS7	.equ 21
YG7	.equ 20
YGS7	.equ 19
YA7	.equ 18
YAS7	.equ 17
YB7	.equ 16
YC8	.equ 15
YCS8	.equ 14
YD8	.equ 13
YDS8	.equ 13
YE8	.equ 12
YF8	.equ 11
YFS8	.equ 11
YG8	.equ 10
YGS8	.equ 9
YA8	.equ 9
YAS8	.equ 8
YB8	.equ 8
YC9	.equ 7
YCS9	.equ 7
YD9	.equ 7
YDS9	.equ 6
YE9	.equ 6
YF9	.equ 6
YFS9	.equ 5
YG9	.equ 5
YGS9	.equ 5
YA9	.equ 4

#define BEEP_FREQX256(freqx256)	16000000/(freqx256)
#define BEEP_MS(freqx256,ms)	ms

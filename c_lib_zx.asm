; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; Video ram address.
vram	.equ $4000
VRAMSZ	.equ 6144

; Attribute ram address.
aram	.equ $5800
ARAMSZ	.equ 768

; Screen width and height in characters.
SCRWC	.equ 32
SCRHC	.equ 24

; Screen width and height in bytes.
SCRWB	.equ SCRWC
SCRHB	.equ SCRHC*8

; Screen width and height in subpixels (subpixel = pixel).
SCRW	.equ SCRWB*8
SCRH	.equ SCRHB

; Screen width and height in screen pixels.
SCRWP	.equ SCRW
SCRHP	.equ SCRH

; Colors
LIT	.equ $40
FLASH	.equ $80

#if !BRIGHT_MODE
BLACK	.equ 0
BLUE	.equ 1
RED	.equ 2
MAGENT	.equ 3
GREEN	.equ 4
CYAN	.equ 5
YELLOW	.equ 6
WHITE	.equ 7
PBLACK	.equ BLACK << 3
PBLUE	.equ BLUE << 3
PRED	.equ RED << 3
PMAGENT	.equ MAGENT << 3
PGREEN	.equ GREEN << 3
PCYAN	.equ CYAN << 3
PYELLOW	.equ YELLOW << 3
PWHITE	.equ WHITE << 3
#else
BLACK	.equ LIT
BLUE	.equ LIT+1
RED	.equ LIT+2
MAGENT	.equ LIT+3
GREEN	.equ LIT+4
CYAN	.equ LIT+5
YELLOW	.equ LIT+6
WHITE	.equ LIT+7
PBLACK	.equ LIT
PBLUE	.equ LIT+(1 << 3)
PRED	.equ LIT+(2 << 3)
PMAGENT	.equ LIT+(3 << 3)
PGREEN	.equ LIT+(4 << 3)
PCYAN	.equ LIT+(5 << 3)
PYELLOW	.equ LIT+(6 << 3)
PWHITE	.equ LIT+(7 << 3)
#endif

; Border colors.

BBLACK	.equ 0
BBLUE	.equ 1
BRED	.equ 2
BMAGENT	.equ 3
BGREEN	.equ 4
BCYAN	.equ 5
BYELLOW	.equ 6
BWHITE	.equ 7

; Keys.

KEY_CAP	.equ %00001000
KEY_Z	.equ %00010000
KEY_X	.equ %00100000
KEY_C	.equ %01000000
KEY_V	.equ %10000000
KEY_A	.equ %00001001
KEY_S	.equ %00010001
KEY_D	.equ %00100001
KEY_F	.equ %01000001
KEY_G	.equ %10000001
KEY_Q	.equ %00001010
KEY_W	.equ %00010010
KEY_E	.equ %00100010
KEY_R	.equ %01000010
KEY_T	.equ %10000010
KEY_1	.equ %00001011
KEY_2	.equ %00010011
KEY_3	.equ %00100011
KEY_4	.equ %01000011
KEY_5	.equ %10000011
KEY_0	.equ %00001100
KEY_9	.equ %00010100
KEY_8	.equ %00100100
KEY_7	.equ %01000100
KEY_6	.equ %10000100
KEY_P	.equ %00001101
KEY_O	.equ %00010101
KEY_I	.equ %00100101
KEY_U	.equ %01000101
KEY_Y	.equ %10000101
KEY_RET	.equ %00001110
KEY_L	.equ %00010110
KEY_K	.equ %00100110
KEY_J	.equ %01000110
KEY_H	.equ %10000110
KEY_SPC	.equ %00001111
KEY_SYM	.equ %00010111
KEY_M	.equ %00100111
KEY_N	.equ %01000111
KEY_B	.equ %10000111

; Keyboard port.
KBPORT	.equ $fe

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
BBUFWB	.equ BBUFWC
BBUFHB	.equ BBUFHC*8

; Back buffer position on screen in chars.
BBUFXC	.equ 4
BBUFYC	.equ 2

; Back buffer position on screen in bytes.
BBUFXB	.equ BBUFXC
BBUFYB	.equ BBUFYC*8

; Dimension in subpixels (spectrum pixel size).
BBUFW	.equ BBUFWC*8
BBUFH	.equ BBUFHB

; Dimension in pixels (2 spectrum pixels are 1 cpc pixel).
BBUFWP	.equ BBUFW
BBUFHP	.equ BBUFH

; Maximum number of rects to clear that the buffer can handle.
BBUF_MAXRECS	.equ 100

; -------------------------
; Sound notes. A4 is 440Hz.
; -------------------------

; The audible human freqs are ~20Hz to ~20000Hz.
; A0 is 27.5 Hz.

; For the beeper.
; v = (437500/freq) - 29.5 or v = ((3500000 / freq) - 236) / 8 .
; This is for a 3.5MHz Spectrum 48K, but what happens with the 128 and
; upper Spectrums where the frequency is 3.54690 MHz?

BA0	.equ 15880
BAS0	.equ 14987
BB0	.equ 14144
BC1	.equ 13348
BCS1	.equ 12598
BD1	.equ 11889
BDS1	.equ 11220
BE1	.equ 10589
BF1	.equ 9993
BFS1	.equ 9430
BG1	.equ 8899
BGS1	.equ 8398
BA1	.equ 7925
BAS1	.equ 7479
BB1	.equ 7057
BC2	.equ 6659
BCS2	.equ 6284
BD2	.equ 5930
BDS2	.equ 5595
BE2	.equ 5280
BF2	.equ 4982
BFS2	.equ 4700
BG2	.equ 4435
BGS2	.equ 4184
BA2	.equ 3948
BAS2	.equ 3725
BB2	.equ 3514
BC3	.equ 3315
BCS3	.equ 3127
BD3	.equ 2950
BDS3	.equ 2783
BE3	.equ 2625
BF3	.equ 2476
BFS3	.equ 2335
BG3	.equ 2203
BGS3	.equ 2077
BA3	.equ 1959
BAS3	.equ 1848
BB3	.equ 1742
BC4	.equ 1643
BCS4	.equ 1549
BD4	.equ 1460
BDS4	.equ 1377
BE4	.equ 1298
BF4	.equ 1223
BFS4	.equ 1153
BG4	.equ 1087
BGS4	.equ 1024
BA4	.equ 965
BAS4	.equ 909
BB4	.equ 856
BC5	.equ 807
BCS5	.equ 760
BD5	.equ 715
BDS5	.equ 674
BE5	.equ 634
BF5	.equ 597
BFS5	.equ 562
BG5	.equ 529
BGS5	.equ 497
BA5	.equ 468
BAS5	.equ 440
BB5	.equ 413
BC6	.equ 389
BCS6	.equ 365
BD6	.equ 343
BDS6	.equ 322
BE6	.equ 302
BF6	.equ 284
BFS6	.equ 266
BG6	.equ 250
BGS6	.equ 234
BA6	.equ 219
BAS6	.equ 205
BB6	.equ 192
BC7	.equ 180
BCS7	.equ 168
BD7	.equ 157
BDS7	.equ 146
BE7	.equ 136
BF7	.equ 127
BFS7	.equ 118
BG7	.equ 110
BGS7	.equ 102
BA7	.equ 95
BAS7	.equ 88
BB7	.equ 81
BC8	.equ 75
BCS8	.equ 69
BD8	.equ 64
BDS8	.equ 58
BE8	.equ 53
BF8	.equ 49
BFS8	.equ 44
BG8	.equ 40
BGS8	.equ 36
BA8	.equ 33
BAS8	.equ 29
BB8	.equ 26
BC9	.equ 23
BCS9	.equ 20
BD9	.equ 17
BDS9	.equ 14
BE9	.equ 12
BF9	.equ 10
BFS9	.equ 7
BG9	.equ 5
BGS9	.equ 3
BA9	.equ 2

; For the AY.
; v = 1773400 Hz / (note_freq * 16)
; The AY runs at 1.7734MHz. The AY counts first 16 ticks.

YA0	.equ 4030
YAS0	.equ 3804
YB0	.equ 3591
YC1	.equ 3389
YCS1	.equ 3199
YD1	.equ 3019
YDS1	.equ 2850
YE1	.equ 2690
YF1	.equ 2539
YFS1	.equ 2397
YG1	.equ 2262
YGS1	.equ 2135
YA1	.equ 2015
YAS1	.equ 1902
YB1	.equ 1795
YC2	.equ 1695
YCS2	.equ 1599
YD2	.equ 1510
YDS2	.equ 1425
YE2	.equ 1345
YF2	.equ 1270
YFS2	.equ 1198
YG2	.equ 1131
YGS2	.equ 1068
YA2	.equ 1008
YAS2	.equ 951
YB2	.equ 898
YC3	.equ 847
YCS3	.equ 800
YD3	.equ 755
YDS3	.equ 712
YE3	.equ 673
YF3	.equ 635
YFS3	.equ 599
YG3	.equ 566
YGS3	.equ 534
YA3	.equ 504
YAS3	.equ 476
YB3	.equ 449
YC4	.equ 424
YCS4	.equ 400
YD4	.equ 377
YDS4	.equ 356
YE4	.equ 336
YF4	.equ 317
YFS4	.equ 300
YG4	.equ 283
YGS4	.equ 267
YA4	.equ 252
YAS4	.equ 238
YB4	.equ 224
YC5	.equ 212
YCS5	.equ 200
YD5	.equ 189
YDS5	.equ 178
YE5	.equ 168
YF5	.equ 159
YFS5	.equ 150
YG5	.equ 141
YGS5	.equ 133
YA5	.equ 126
YAS5	.equ 119
YB5	.equ 112
YC6	.equ 106
YCS6	.equ 100
YD6	.equ 94
YDS6	.equ 89
YE6	.equ 84
YF6	.equ 79
YFS6	.equ 75
YG6	.equ 71
YGS6	.equ 67
YA6	.equ 63
YAS6	.equ 59
YB6	.equ 56
YC7	.equ 53
YCS7	.equ 50
YD7	.equ 47
YDS7	.equ 45
YE7	.equ 42
YF7	.equ 40
YFS7	.equ 37
YG7	.equ 35
YGS7	.equ 33
YA7	.equ 31
YAS7	.equ 30
YB7	.equ 28
YC8	.equ 26
YCS8	.equ 25
YD8	.equ 24
YDS8	.equ 22
YE8	.equ 21
YF8	.equ 20
YFS8	.equ 19
YG8	.equ 18
YGS8	.equ 17
YA8	.equ 16
YAS8	.equ 15
YB8	.equ 14
YC9	.equ 13
YCS9	.equ 12
YD9	.equ 12
YDS9	.equ 11
YE9	.equ 11
YF9	.equ 10
YFS9	.equ 9
YG9	.equ 9
YGS9	.equ 8
YA9	.equ 8

#define BEEP_FREQX256(freqx256)	437500*256/(freqx256)-29
#define BEEP_MS(freqx256,ms)	(freqx256)*(ms)/256000

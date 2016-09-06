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
; RAM Area, not saved on tape, so we save space there.
; ----------------------------------------------------------------------------

LIB_RAM_START	.equ endp

#ifdef ZX
#include "r_lib_zx.asm"
#endif

#ifdef CPC
#include "r_lib_cpc.asm"
#endif

; Sprite and object tables.
sprtab		.equ LIB_RAM_END
SPRTABSZ	.equ NSPRS*SPRSZ
objtab		.equ sprtab+SPRTABSZ
OBJTABSZ	.equ NOBJS*OBJSZ

; End of RAM used by game.
eofram	.equ objtab+OBJTABSZ

; Direct addresses to some objects.
ship_ob		.equ objtab+(OBJSZ*SHIP_OB_SLOT)
house_ob	.equ objtab+(OBJSZ*HOUSE_OB_SLOT)
alien_ob	.equ objtab+(OBJSZ*ALIEN_OB_SLOT)
post_ob		.equ objtab+(OBJSZ*POST_OB_SLOT)
bird_ob		.equ objtab+(OBJSZ*BIRD_OB_SLOT)

; Direct addresses to some sprites.
house_sp_0	.equ sprtab+(SPRSZ*HOUSE_SP_SLOT)
house_sp_1	.equ house_sp_0+SPRSZ
bird_sp		.equ sprtab+(SPRSZ*BIRD_SP_SLOT)
bird_lshield_sp	.equ sprtab+(SPRSZ*BIRD_LSHIELD_SP_SLOT)
bird_rshield_sp	.equ sprtab+(SPRSZ*BIRD_RSHIELD_SP_SLOT)
ship_sp		.equ sprtab+(SPRSZ*SHIP_SP_SLOT)
cnon_sp		.equ sprtab+(SPRSZ*(SHIP_SP_SLOT+1))
lwng_sp		.equ sprtab+(SPRSZ*(SHIP_SP_SLOT+2))
rwng_sp		.equ sprtab+(SPRSZ*(SHIP_SP_SLOT+3))
fire_sp		.equ sprtab+(SPRSZ*(SHIP_SP_SLOT+4))
mine_sp		.equ sprtab+(SPRSZ*MINE_SP_SLOT)


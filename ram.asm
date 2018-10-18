; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
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


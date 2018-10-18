; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; ----------------------------------------------------------------------------
; Image data, animations, master sprites and objects.
; ----------------------------------------------------------------------------

#ifdef ZX
#include "zxims.asm"
#include "imtables_zx.asm"
#include "anims_zx.asm"
#include "masters_zx.asm"
#endif

#ifdef CPC
#include "cpcims.asm"
#include "imtables_cpc.asm"
#include "anims_cpc.asm"
#include "masters_cpc.asm"
#endif

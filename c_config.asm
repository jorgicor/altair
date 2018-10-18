; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; Platform.
; ZX, CPC.

; If master version, the width of the back buffer (ABUFW) cannot be changed.
; If not, its value can be changed IF the function cbpos is changed as well.
MASTER_VERSION	.equ 1

; Language (comes from command line).
; LANG_ES, LANG_EN.

; Setting this all colors will have the BRIGHT attribute on.
BRIGHT_MODE	.equ 1

; Configure key table size.
#define KEYTSZ 7

; Immune to shots (1 enabled).
#define CHEATS_GOD 0

; Pass level using service key C.
#define CHEATS_RST 0

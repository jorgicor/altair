; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; Back buffer.
bbuf	.equ LIB_RAM_START
BBUFSZ	.equ BBUFWB*BBUFHB

; Table of tuples (screen addr, bbuf addr) for each pixel scanline.
bbuf_scr_t	.equ bbuf+BBUFSZ
BBUF_SCRSZ	.equ BBUFHB*4

; Rect list. Tuples of (b:width, b:height, w:address, b:value).
bbuf_reclst	.equ bbuf_scr_t+BBUF_SCRSZ
BBUF_RECLSTSZ	.equ 5*BBUF_MAXRECS

LIB_RAM_END	.equ bbuf_reclst+BBUF_RECLSTSZ

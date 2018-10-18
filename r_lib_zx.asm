; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; Back buffer.
bbuf	.equ LIB_RAM_START
BBUFSZ	.equ BBUFWB*BBUFHB

; Attribute buffer.
abuf	.equ bbuf+BBUFSZ
ABUFSZ	.equ BBUFWC*BBUFHC

; Table of tuples (screen addr, bbuf addr) for each pixel scanline
; and attribute line. It is divided in blocks of 8 pixel scanlines + 1
; attribute scanline.
bbuf_scr_t	.equ abuf+ABUFSZ
BBUF_SCRSZ	.equ (BBUFHB+BBUFHC)*4

; Rect list. Tuples of (b:width, b:height, w:address, b:value).
bbuf_reclst	.equ bbuf_scr_t+BBUF_SCRSZ
BBUF_RECLSTSZ	.equ 5*BBUF_MAXRECS

LIB_RAM_END	.equ bbuf_reclst+BBUF_RECLSTSZ

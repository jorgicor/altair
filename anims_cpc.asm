; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

ashot_am	.db 2
		.dw shot_it0
		.dw shot_it1

fire_am	.db 2
	.dw fire_it0
	.dw fire_it1

explosion_am	.db 5
		.dw explosion_it0
		.dw explosion_it1
		.dw explosion_it2
		.dw explosion_it1
		.dw explosion_it0

bird_grid_am	.db 2
		.dw bird_grid_it0
		.dw bird_grid_it1

bird_lwing_am	.db 2
		.dw bird_lwing0_it
		.dw bird_lwing1_it

bird_rwing_am	.db 2
		.dw bird_rwing0_it
		.dw bird_rwing1_it

alien_am0
alien_am1
alien_am2
alien_am3
alien_am4
alien_am5	.db 2
		.dw alient0 
		.dw alient1
alien_am6	.db 1
		.dw alient0

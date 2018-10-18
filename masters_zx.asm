; ----------------------------------------------------------------------------
; Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
; Amstrad CPC.
; ----------------------------------------------------------------------------

; Masters.

mstr_bird_sp
	; 1
	.dw bird_up_it
	.db 0, 0
	.dw RED
	.dw 0, 0, 0

	; 2
	.dw bird_grid_it0
	.db 8, 8
	.dw WHITE
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 3
	.dw bird_grid_it0
	.db 16, 8
	.dw WHITE
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 4
	.dw bird_grid_it0
	.db 24, 8
	.dw WHITE
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 5
	.dw bird_grid_it0
	.db 32, 8
	.dw WHITE
	.dw bird_grid_am
	.db 2, 2
	.db 0, 1

	; 6
	.dw bird_center_it
	.db 16, 16
	.dw bird_center_co
	.dw 0, 0, 0

	; 7
	.dw bird_left_it
	.db 0, 8
	.dw RED
	.dw 0, 0, 0

	; 8
	.dw bird_right_it
	.db 40, 8
	.dw RED
	.dw 0, 0, 0

	; 9
	.dw bird_bleft_it
	.db 8, 40
	.dw RED
	.dw 0, 0, 0

	; 10
	.dw bird_bright_it
	.db 32, 40
	.dw RED
	.dw 0, 0, 0

	; 11
	.dw bird_lwing0_it
	.db 8, 16
	.dw 0
	.dw bird_lwing_am
	.db 2, 2
	.db 0, 1

	; 12
	.dw bird_rwing0_it
	.db 32, 16
	.dw 0
	.dw bird_rwing_am
	.db 2, 2
	.db 0, 1

	; 13
	.dw bird_lshield_it
	.db 16, 40
	.dw WHITE
	.dw 0, 0, 0

	; 14
	.dw bird_rshield_it
	.db 24, 40
	.dw WHITE
	.dw 0, 0, 0

mstr_bird_ob	.dw birdf
		.dw bird_sp
		.dw 0

mstr_house_sp
	.dw house_it_0
	.db 0, 0
	.dw house_co_0
	.dw 0, 0, 0
	.dw house_it_1
	.db 0, HOUSE_YPOS
	.dw house_co_1
	.dw 0, 0, 0

mstr_house_ob
	.dw housef
	.dw house_sp_0
	.dw house_sp_1

mstr_ship_sp
	.dw ship_it
	.db 8, BBUFH-16
	.dw ship_co
	.dw 0, 0, 0
	.dw cnon_it
	.db 8, BBUFH-24
	.dw cnon_co
	.dw 0, 0, 0
	.dw lwng_it
	.db 0, BBUFH-16
	.dw wing_co
	.dw 0, 0, 0
	.dw rwng_it
	.db 16, BBUFH-16
	.dw wing_co
	.dw 0, 0, 0
	.dw fire_it0
	.db 8, BBUFH-8
	.dw RED
	.dw fire_am
	.db 2, 2
	.db 0, 1

mstr_ship_ob
	.dw shipf
	.dw ship_sp
	.dw 0

mstr_mine_sp
	.dw mine_it
	.db 0, 0
	.dw YELLOW
	.dw 0, 0, 0

mstr_ashot_sp
	.dw shot_it0
	.db 0, 0
	.dw WHITE
	.dw ashot_am
	.db 1, 1
	.db 0, 1

mstr_cross_ashot_sp
	.dw cross_shot_it
	.db 0, 0
	.dw YELLOW
	.dw 0
	.db 0, 0
	.db 0, 0

mstr_explosion_sp
	.dw 0
	.db 0, 0
	.dw 0
	.dw explosion_am
	.db 4, 4
	.db 0, 0

mstr_explosion_ob
	.dw explof
	.dw mstr_explosion_sp
	.dw 0

mstr_post_ob
	.dw postf
	.dw 0
	.dw 0

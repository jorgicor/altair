# ----------------------------------------------------------------------------
# Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
# Amstrad CPC.
# ----------------------------------------------------------------------------

base_sources = altair.asm \
	altair_cpc.asm \
	altair_snd.asm \
	altair_snd_zx.asm \
	altair_zx.asm \
	anim.asm \
	anims_cpc.asm \
	anims_zx.asm \
	attract_st.asm \
	ay.asm \
	ay_cpc.asm \
	ay_zx.asm \
	bbuf.asm \
	bbuf_cpc.asm \
	bbuf_zx.asm \
	c_config.asm \
	c_lib_cpc.asm \
	c_lib_zx.asm \
	const.asm \
	dedicate_st.asm \
	disclaimer_st.asm \
	drmach.asm \
	font_zx.asm \
	gameover_st.asm \
	gameplay_st.asm \
	hud.asm \
	images.asm \
	imtables_cpc.asm \
	imtables_zx.asm \
	interr.asm \
	killed_st.asm \
	lib.asm \
	lib_cpc.asm \
	lib_zx.asm \
	masters_cpc.asm \
	masters_zx.asm \
	menu_st.asm \
	name_st.asm \
	notes.asm \
	obfun.asm \
	options_st.asm \
	r_lib_cpc.asm \
	r_lib_zx.asm \
	ram.asm \
	rndnums.asm \
	round_st.asm \
	sound.asm \
	sound_cpc.asm \
	sound_zx.asm \
	states.asm \
	timer.asm \
	tone_ay.asm \
	tone_beep.asm \
	zxims.asm

zx_sources = altair_snd_zx.asm \
	altair_zx.asm \
	anims_zx.asm \
	ay_zx.asm \
	bbuf_zx.asm \
	c_lib_zx.asm \
	font_zx.asm \
	imtables_zx.asm \
	lib_zx.asm \
	masters_zx.asm \
	r_lib_zx.asm \
	sound_zx.asm \
	tone_beep.asm \
	zxims.asm

song_sources = songs/song_11.asm \
	songs/song_32.asm \
	songs/song_21.asm \
	songs/song_63.asm \
	songs/song_23.asm \
	songs/song_61.asm \
	songs/song_41.asm \
	songs/song_62.asm \
	songs/song_31.asm \
	songs/song_42.asm \
	songs/song_43.asm \
	songs/song_33.asm \
	songs/song_22.asm

cpc_sources = altair_cpc.asm \
	anims_cpc.asm \
	ay_cpc.asm \
	bbuf_cpc.asm \
	c_lib_cpc.asm \
	imtables_cpc.asm \
	lib_cpc.asm \
	masters_cpc.asm \
	r_lib_cpc.asm \
	sound_cpc.asm \
	tone_ay.asm

# ----------------------------------------------------------------------------
# Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
# Amstrad CPC.
# ----------------------------------------------------------------------------

bin2tap = tools/zx/zxspectrum-utils/bin/bin2tap

zx_cover_bin = data/zx/cover.bin
zx_cover_tap = release/zx/cover.tap
mmelody = tools/mmelody/mmelody
zx_gen_songs = song_11_zx.asm song_21_zx.asm song_22_zx.asm song_23_zx.asm \
	song_31_zx.asm song_32_zx.asm song_33_zx.asm \
	song_41_zx.asm song_42_zx.asm song_43_zx.asm \
	song_61_zx.asm song_62_zx.asm song_63_zx.asm

$(zx_cover_tap): $(zx_cover_bin)
	cp $(zx_cover_bin) release/zx && \
		cd release/zx && \
		../../$(bin2tap) -a 22528 cover.bin && \
		rm -f cover.bin

song_11_zx.asm: songs/song_11.asm
	$(mmelody) zx $? > $@

song_21_zx.asm: songs/song_21.asm
	$(mmelody) zx $? > $@

song_22_zx.asm: songs/song_22.asm
	$(mmelody) zx $? > $@

song_23_zx.asm: songs/song_23.asm
	$(mmelody) zx $? > $@

song_31_zx.asm: songs/song_31.asm
	$(mmelody) zx $? > $@

song_32_zx.asm: songs/song_32.asm
	$(mmelody) zx $? > $@

song_33_zx.asm: songs/song_33.asm
	$(mmelody) zx $? > $@

song_41_zx.asm: songs/song_41.asm
	$(mmelody) zx $? > $@

song_42_zx.asm: songs/song_42.asm
	$(mmelody) zx $? > $@

song_43_zx.asm: songs/song_43.asm
	$(mmelody) zx $? > $@

song_61_zx.asm: songs/song_61.asm
	$(mmelody) zx $? > $@

song_62_zx.asm: songs/song_62.asm
	$(mmelody) zx $? > $@

song_63_zx.asm: songs/song_63.asm
	$(mmelody) zx $? > $@

zx_songs: $(zx_gen_songs)

zxdef_clean:
	rm -f $(zx_cover_tap)

zxdef_distclean:
	rm -f $(zx_gen_songs)

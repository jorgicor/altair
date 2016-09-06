mmelody = tools/mmelody/mmelody
bmp2asm = tools/cpc/bmp2asm/bmp2asm
bmp2scr = tools/cpc/bmp2scr/bmp2scr

cpcdat_txt = data/cpc/cpcdat.txt
cpc_sprites_bmp = data/cpc/sprites.bmp
cpc_cover_bmp = data/cpc/cover.bmp
cpc_cover_bin = release/cpc/cover.bin
cpc_pal_bin = release/cpc/pal.bin
cpc_amscover_bin = release/cpc/amscover.bin
cpc_amspal_bin = release/cpc/amspal.bin

cpc_gen_songs = song_11_cpc.asm \
	song_21_cpc.asm song_22_cpc.asm song_23_cpc.asm \
	song_31_cpc.asm song_32_cpc.asm song_33_cpc.asm \
	song_41_cpc.asm song_42_cpc.asm song_43_cpc.asm \
	song_61_cpc.asm song_62_cpc.asm song_63_cpc.asm

song_11_cpc.asm: songs/song_11.asm
	$(mmelody) cpc $? > $@

song_21_cpc.asm: songs/song_21.asm
	$(mmelody) cpc $? > $@

song_22_cpc.asm: songs/song_22.asm
	$(mmelody) cpc $? > $@

song_23_cpc.asm: songs/song_23.asm
	$(mmelody) cpc $? > $@

song_31_cpc.asm: songs/song_31.asm
	$(mmelody) cpc $? > $@

song_32_cpc.asm: songs/song_32.asm
	$(mmelody) cpc $? > $@

song_33_cpc.asm: songs/song_33.asm
	$(mmelody) cpc $? > $@

song_41_cpc.asm: songs/song_41.asm
	$(mmelody) cpc $? > $@

song_42_cpc.asm: songs/song_42.asm
	$(mmelody) cpc $? > $@

song_43_cpc.asm: songs/song_43.asm
	$(mmelody) cpc $? > $@

song_61_cpc.asm: songs/song_61.asm
	$(mmelody) cpc $? > $@

song_62_cpc.asm: songs/song_62.asm
	$(mmelody) cpc $? > $@

song_63_cpc.asm: songs/song_63.asm
	$(mmelody) cpc $? > $@

cpc_songs: $(cpc_gen_songs)

cpc_data: cpcims.asm

cpcims.asm: $(cpc_sprites_bmp)
	$(bmp2asm) cpc16x2 tasm $(cpcdat_txt) $(cpc_sprites_bmp) > cpcims.asm

cpc_cover: $(cpc_amscover_bin)

$(cpc_cover_bin): $(cpc_cover_bmp)
	$(bmp2scr) cpc16x2 $(cpc_cover_bmp) $(cpc_cover_bin) $(cpc_pal_bin)

$(cpc_amscover_bin): $(cpc_cover_bin)
	$(amshead) $(cpc_cover_bin) $@ 0xc000 0xc000
	$(amshead) $(cpc_pal_bin) $(cpc_amspal_bin) 0xc7d0 0xc7d0

cpcdef_clean:
	rm -f $(cpc_amscover_bin) $(cpc_amspal_bin)

cpcdef_distclean:
	rm -f $(cpc_gen_songs) cpcims.asm $(cpc_cover_bin) $(cpc_pal_bin)


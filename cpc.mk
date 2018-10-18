# ----------------------------------------------------------------------------
# Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
# Amstrad CPC.
# ----------------------------------------------------------------------------

game = altair
main_asm = $(game).asm

# defaults
# Z80AS = tasm -80 -b
Z80AS = uz80as
GAMELANG = es
GAMELANG_MAC = LANG_ES

amshead = tools/cpc/amshead/amshead
xfs = tools/cpc/cpcfs/src/cpcfs

release_cpc = release/cpc
cpc_code_lang_bin = $(release_cpc)/code_$(GAMELANG).bin
cpc_amscode_lang_bin = $(release_cpc)/amscode_$(GAMELANG).bin
release_cpc_lang = $(release_cpc)/$(GAMELANG)
release_cpc_lang_nc = $(release_cpc)/$(GAMELANG)_nc
cpc_game_lang_nc_dsk = $(release_cpc)/$(game)_cpc_$(GAMELANG)_nc.dsk
cpc_final_dsk_name = $(game)_cpc_$(GAMELANG).dsk
cpc_game_lang_dsk = $(release_cpc)/$(cpc_final_dsk_name)
cpc_master_dsk = data/cpc/master.dsk

cpc_all: cpc_lang_nc

include sources.mk
include cpcdef.mk

cpc_lang_nc: $(cpc_game_lang_nc_dsk)
cpc_nc: cpc_lang_nc

cpc_lang: $(cpc_game_lang_dsk)
cpc: cpc_lang

$(cpc_code_lang_bin): cpc_songs cpc_data $(base_sources) $(cpc_sources)
	$(Z80AS) -dCPC -d$(GAMELANG_MAC) $(main_asm) $@

$(cpc_amscode_lang_bin): $(cpc_code_lang_bin)
	$(amshead) $(cpc_code_lang_bin) $@ 0x0040 0x0040

$(cpc_game_lang_nc_dsk): $(cpc_amscode_lang_bin)
	$(xfs) -f -nd $(cpc_game_lang_nc_dsk) && \
	mkdir -p $(release_cpc_lang_nc) && \
	cp $(cpc_amscode_lang_bin) $(release_cpc_lang_nc)/code.bin && \
	$(xfs) $(cpc_game_lang_nc_dsk) -b -f -p \
       		$(release_cpc_lang_nc)/code.bin && \
	rm -rf $(release_cpc_lang_nc)

$(cpc_game_lang_dsk): cpc_cover $(cpc_amscode_lang_bin)
	cp $(cpc_master_dsk) $(cpc_game_lang_dsk) && \
	mkdir -p $(release_cpc_lang) && \
	cp $(cpc_amscode_lang_bin) $(release_cpc_lang)/code.bin && \
	cp $(cpc_amscover_bin) $(release_cpc_lang)/cover.bin && \
	cp $(cpc_amspal_bin) $(release_cpc_lang)/pal.bin && \
	$(xfs) $(cpc_game_lang_dsk) -b -f -p $(release_cpc_lang)/code.bin && \
	$(xfs) $(cpc_game_lang_dsk) -b -f -p $(release_cpc_lang)/cover.bin && \
	$(xfs) $(cpc_game_lang_dsk) -b -f -p $(release_cpc_lang)/pal.bin && \
	rm -rf $(release_cpc_lang)

cpc_clean:
	rm -f $(cpc_game_lang_nc_dsk) $(cpc_game_lang_dsk) \
		$(cpc_code_lang_bin) $(cpc_amscode_lang_bin)

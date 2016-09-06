game = altair
main_asm = $(game).asm

# defaults
# Z80AS = tasm -80 -b
Z80AS = uz80as
GAMELANG = es
GAMELANG_MAC = LANG_ES

code_bin = code.bin

zx_code_lang_bin = release/zx/code_$(GAMELANG).bin
zx_code_lang_tap = release/zx/code_$(GAMELANG).tap
zx_game_lang_nc_tap = release/zx/$(game)_zx_$(GAMELANG)_nc.tap
zx_game_lang_tap = release/zx/$(game)_zx_$(GAMELANG)_final.tap
zx_master_tap = data/zx/master.tap
zx_lang_tmp = release/zx/$(GAMELANG)_tmp

zx_all: zx_lang_nc zx_lang

include zxdef.mk
include sources.mk

zx_lang_nc: $(zx_game_lang_nc_tap)
zx_nc: zx_lang_nc

zx_lang: $(zx_game_lang_tap)
zx: zx_lang

$(zx_code_lang_bin): zx_songs $(base_sources) $(zx_sources)
	$(Z80AS) -dZX -d$(GAMELANG_MAC) $(main_asm) $@

$(zx_game_lang_nc_tap): $(zx_code_lang_bin)
	$(bin2tap) -b -o $@ $(zx_code_lang_bin)

$(zx_game_lang_tap): $(zx_cover_tap) $(zx_code_lang_bin)
	mkdir -p $(zx_lang_tmp) && \
		cp $(zx_master_tap) $(zx_lang_tmp) && \
		cp $(zx_cover_tap) $(zx_lang_tmp) && \
		cp $(zx_code_lang_bin) $(zx_lang_tmp)/code.bin && \
		cd $(zx_lang_tmp) && \
		../../../$(bin2tap) code.bin && \
		cat master.tap cover.tap code.tap > \
			../$(game)_zx_$(GAMELANG)_final.tap && \
		cd .. && rm -rf $(GAMELANG)_tmp

zx_clean:
	rm -f $(zx_game_lang_tap) $(zx_game_lang_nc_tap) \
		$(zx_code_lang_tap) $(zx_code_lang_bin)

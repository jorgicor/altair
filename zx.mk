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
MODE = 48
MODE_MAC = ZX$(MODE)

code_bin = code.bin

zx_code_lang_bin = release/zx/code$(MODE)_$(GAMELANG).bin
zx_code_lang_tap = release/zx/code$(MODE)_$(GAMELANG).tap
zx_game_lang_nc_tap = release/zx/$(game)_zx$(MODE)_$(GAMELANG)_nc.tap
zx_final_tap_name = $(game)_zx$(MODE)_$(GAMELANG).tap
zx_game_lang_tap = release/zx/$(zx_final_tap_name)
zx_master_tap = data/zx/master.tap
zx_lang_tmp = release/zx/$(GAMELANG)$(MODE)_tmp

zx_all: zx_lang_nc zx_lang

include zxdef.mk
include sources.mk

zx_lang_nc: $(zx_game_lang_nc_tap)
zx_nc: zx_lang_nc

zx_lang: $(zx_game_lang_tap)
zx: zx_lang

$(zx_code_lang_bin): zx_songs $(base_sources) $(zx_sources)
	$(Z80AS) -dZX -d$(GAMELANG_MAC) -d$(MODE_MAC) $(main_asm) $@

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
			../$(zx_final_tap_name) && \
		cd .. && rm -rf $(GAMELANG)$(MODE)_tmp

zx_clean:
	rm -f $(zx_game_lang_tap) $(zx_game_lang_nc_tap) \
		$(zx_code_lang_tap) $(zx_code_lang_bin)

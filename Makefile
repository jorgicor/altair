# ----------------------------------------------------------------------------
# Altair, CIDLESA's 1981 arcade game remade for the ZX Spectrum and
# Amstrad CPC.
# ----------------------------------------------------------------------------

all: zx zx128 cpc

thetools:
	cd tools ; $(MAKE)

clean_thetools:
	cd tools ; $(MAKE) clean

dist_tar = altair_src.tar

mk_sources = Makefile zx.mk cpc.mk zxdef.mk cpcdef.mk forlangs.sh sources.mk \
	     README.md LICENSE.md ChangeLog .gitignore

release_sources = release/zx/altair_zx.pdf \
	       release/cpc/altair_cpc.pdf

include sources.mk

data_sources = data/cpc/cover.bmp \
	data/cpc/sprites.bmp \
	data/cpc/cpcdat.txt \
	data/cpc/master.dsk \
	data/cpc/altair_cpc.rtf \
	data/zx/font.sev \
	data/zx/bird.sev \
	data/zx/cover.scr \
	data/zx/master0.tap \
	data/zx/master.tap \
	data/zx/cover.bin \
	data/zx/altair_zx48.rtf

doc_sources = doc/cpc/cpc_pal.png \
	doc/zx/zx_pal.png \
	doc/files.txt \
	doc/pokes.txt

cpcfs_sources = tools/cpc/cpcfs/src/ui.c \
	tools/cpc/cpcfs/src/dos.h \
	tools/cpc/cpcfs/src/dos.c \
	tools/cpc/cpcfs/src/fs.c \
	tools/cpc/cpcfs/src/cpcfs.h \
	tools/cpc/cpcfs/src/makedoc.c \
	tools/cpc/cpcfs/src/match.h \
	tools/cpc/cpcfs/src/cpcfs.prj \
	tools/cpc/cpcfs/src/tools.c \
	tools/cpc/cpcfs/src/unix.c \
	tools/cpc/cpcfs/src/match.c \
	tools/cpc/cpcfs/src/Makefile \
	tools/cpc/cpcfs/src/cpcfs.c \
	tools/cpc/cpcfs/src/unix.h \
	tools/cpc/cpcfs/cpcfs.cfg \
	tools/cpc/cpcfs/cpcfs.doc \
	tools/cpc/cpcfs/README.md \
	tools/cpc/cpcfs/getcpm.bas \
	tools/cpc/cpcfs/LICENSE \
	tools/cpc/cpcfs/.gitignore \
	tools/cpc/cpcfs/cpcfs.hlp \
	tools/cpc/cpcfs/drop_tag.bat \
	tools/cpc/cpcfs/template.doc \
	tools/cpc/cpcfs/INTRO \
	tools/cpc/cpcfs/FILES \
	tools/cpc/cpcfs/README-altair.md

bin2tap_sources = tools/zx/zxspectrum-utils/src/tap2mbd.cpp \
	tools/zx/zxspectrum-utils/src/trdos_structure.h \
	tools/zx/zxspectrum-utils/src/endian-compat.h \
	tools/zx/zxspectrum-utils/src/makesna.cpp \
	tools/zx/zxspectrum-utils/src/tsttap.c \
	tools/zx/zxspectrum-utils/src/bin2mbd.c \
	tools/zx/zxspectrum-utils/src/lstbas.c \
	tools/zx/zxspectrum-utils/src/tzx2tap.c \
	tools/zx/zxspectrum-utils/src/createtrd.c \
	tools/zx/zxspectrum-utils/src/binto0.c \
	tools/zx/zxspectrum-utils/src/d802tap.cpp \
	tools/zx/zxspectrum-utils/src/tap2mbhdd.cpp \
	tools/zx/zxspectrum-utils/src/breplace.c \
	tools/zx/zxspectrum-utils/src/tap2d80.cpp \
	tools/zx/zxspectrum-utils/src/dirtap.c \
	tools/zx/zxspectrum-utils/src/hobto0.c \
	tools/zx/zxspectrum-utils/src/mbload.c \
	tools/zx/zxspectrum-utils/src/mb2tap.c \
	tools/zx/zxspectrum-utils/src/dirhob.c \
	tools/zx/zxspectrum-utils/src/tapto0.c \
	tools/zx/zxspectrum-utils/src/0tobin.c \
	tools/zx/zxspectrum-utils/src/permutor.c \
	tools/zx/zxspectrum-utils/src/hobeta2trd.c \
	tools/zx/zxspectrum-utils/src/dir0.c \
	tools/zx/zxspectrum-utils/src/0tohob.c \
	tools/zx/zxspectrum-utils/src/bin2tap.c \
	tools/zx/zxspectrum-utils/src/mbdir.c \
	tools/zx/zxspectrum-utils/src/lstrd.c \
	tools/zx/zxspectrum-utils/src/Makefile \
	tools/zx/zxspectrum-utils/src/tap2tzx.c \
	tools/zx/zxspectrum-utils/src/0totap.c \
	tools/zx/zxspectrum-utils/man/bin2mbd.1 \
	tools/zx/zxspectrum-utils/man/bin2tap.1 \
	tools/zx/zxspectrum-utils/LICENCE \
	tools/zx/zxspectrum-utils/bin/Makefile \
	tools/zx/zxspectrum-utils/DESCRIPTION \
	tools/zx/zxspectrum-utils/README \
	tools/zx/zxspectrum-utils/TODO \
	tools/zx/zxspectrum-utils/Makefile \
	tools/zx/zxspectrum-utils/INSTALL \
	tools/zx/zxspectrum-utils/makefile.mk \
	tools/zx/zxspectrum-utils/README-altair.md

tools_sources = tools/mmelody/manual.txt \
	tools/mmelody/makefile.mk \
	tools/mmelody/mmelody.c \
	tools/cpc/bmp/makefile.mk \
	tools/cpc/bmp/bmp.h \
	tools/cpc/bmp/bmp_load.c \
	tools/cpc/bmp2asm/manual.txt \
	tools/cpc/bmp2asm/makefile.mk \
	tools/cpc/bmp2asm/bmp2asm.c \
	tools/cpc/bmp2scr/manual.txt \
	tools/cpc/bmp2scr/bmp2scr.c \
	tools/cpc/bmp2scr/makefile.mk \
	tools/cpc/amshead/manual.txt \
	tools/cpc/amshead/amshead.c \
	tools/cpc/amshead/makefile.mk \
	tools/randff/randff.c \
	tools/randff/Makefile \
	tools/zx/beeper/manual.txt \
	tools/zx/beeper/Makefile \
	tools/zx/beeper/beeper.c \
	tools/ayfreq/manual.txt \
	tools/ayfreq/Makefile \
	tools/ayfreq/ayfreq.c \
	tools/Makefile

zx_es_nc:
	$(MAKE) MODE=48 GAMELANG=es GAMELANG_MAC=LANG_ES -f zx.mk zx_nc

zx_nc:
	MODE=48 ./forlangs.sh zx.mk zx_nc

zx:
	MODE=48 ./forlangs.sh zx.mk zx

zx128_es_nc:
	$(MAKE) MODE=128 GAMELANG=es GAMELANG_MAC=LANG_ES -f zx.mk zx_nc

zx128_nc:
	MODE=128 ./forlangs.sh zx.mk zx_nc

zx128:
	MODE=128 ./forlangs.sh zx.mk zx

cpc_es_nc:
	$(MAKE) GAMELANG=es GAMELANG_MAC=LANG_ES -f cpc.mk cpc_nc

cpc_nc:
	./forlangs.sh cpc.mk cpc_nc

cpc:
	./forlangs.sh cpc.mk cpc

clean:
	rm -f altair.lst altait.obj
	MODE=48 ./forlangs.sh zx.mk zx_clean
	MODE=128 ./forlangs.sh zx.mk zx_clean
	./forlangs.sh cpc.mk cpc_clean
	$(MAKE) -f zxdef.mk zxdef_clean
	$(MAKE) -f cpcdef.mk cpcdef_clean

distclean: clean_thetools clean
	$(MAKE) -f zxdef.mk zxdef_distclean
	$(MAKE) -f cpcdef.mk cpcdef_distclean

dist:
	rm -f $(dist_tar)
	tar -cf $(dist_tar) $(base_sources)
	tar -uf $(dist_tar) $(zx_sources)
	tar -uf $(dist_tar) $(cpc_sources)
	tar -uf $(dist_tar) $(song_sources)
	tar -uf $(dist_tar) $(data_sources)
	tar -uf $(dist_tar) $(doc_sources)
	tar -uf $(dist_tar) $(mk_sources)
	tar -uf $(dist_tar) $(release_sources)
	tar -uf $(dist_tar) $(tools_sources)
	tar -uf $(dist_tar) $(bin2tap_sources)
	tar -uf $(dist_tar) $(cpcfs_sources)
	mkdir -p altair_src
	cd altair_src ; tar -xf ../$(dist_tar) ; cd ..
	rm -f $(dist_tar)
	tar -cvzf $(dist_tar).gz altair_src
	rm -rf altair_src


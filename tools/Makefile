SHELL = /bin/sh

.SUFFIXES:
.SUFFIXES: .c .o

CC = cc
CFLAGS = -g

all: mmelody zx_bin2tap cpc_amshead cpc_bmp cpc_bmp2asm cpc_bmp2scr cpc_cpcfs

include mmelody/makefile.mk
include zx/zxspectrum-utils/makefile.mk
include cpc/amshead/makefile.mk
include cpc/bmp/makefile.mk
include cpc/bmp2asm/makefile.mk
include cpc/bmp2scr/makefile.mk

cpc_cpcxfs:
	cd cpc/cpcxfs/src; $(MAKE) -f makefile.lnx

cpc_cpcfs:
	cd cpc/cpcfs/src; $(MAKE)

clean_cpcxfs:
	cd cpc/cpcxfs/src; $(MAKE) -f makefile.lnx clean

clean_cpcfs:
	rm -f cpc/cpcfs/src/cpcfs cpc/cpcfs/src/makedoc cpc/cpcfs/src/*.o

clean: clean_mmelody clean_zx_bin2tap clean_cpc_amshead \
	clean_cpc_bmp clean_cpc_bmp2asm clean_cpc_bmp2scr \
	clean_cpcfs

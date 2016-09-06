zx_bin2tap: zx/zxspectrum-utils/bin/bin2tap

zx_bin2tap_OBJS = zx/zxspectrum-utils/src/bin2tap.o

zx/zxspectrum-utils/src/bin2tap.o: zx/zxspectrum-utils/src/bin2tap.c
	$(CC) $(CFLAGS) -c -o $@ $+

zx/zxspectrum-utils/bin/bin2tap: $(zx_bin2tap_OBJS)
	$(CC) $(CFLAGS) -o $@ $(zx_bin2tap_OBJS)

clean_zx_bin2tap:
	-rm -f zx/zxspectrum-utils/bin/bin2tap $(zx_bin2tap_OBJS)

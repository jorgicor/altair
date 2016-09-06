cpc_bmp2scr: cpc/bmp2scr/bmp2scr

cpc_bmp2scr_OBJS = cpc/bmp2scr/bmp2scr.o

cpc/bmp2scr/bmp2scr.o: cpc/bmp2scr/bmp2scr.c
	$(CC) $(CFLAGS) -c -o $@ -Icpc/bmp $+

cpc/bmp2scr/bmp2scr: $(cpc_bmp2scr_OBJS) $(cpc_bmp_OBJS)
	$(CC) $(CFLAGS) -o $@ $(cpc_bmp2scr_OBJS) $(cpc_bmp_OBJS)

clean_cpc_bmp2scr:
	-rm -f cpc/bmp2scr/bmp2scr $(cpc_bmp2scr_OBJS)

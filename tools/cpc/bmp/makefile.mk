cpc_bmp_OBJS = cpc/bmp/bmp_load.o

cpc_bmp: $(cpc_bmp_OBJS)

cpc_bmp_HEADERS = cpc/bmp/bmp.h

$(cpc_bmp_OBJS): $(cpc_bmp_HEADERS)

clean_cpc_bmp:
	-rm -f $(cpc_bmp_OBJS)

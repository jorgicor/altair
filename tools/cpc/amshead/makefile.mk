cpc_amshead: cpc/amshead/amshead

cpc_amshead_OBJS = cpc/amshead/amshead.o

cpc/amshead/amshead: $(cpc_amshead_OBJS)
	$(CC) $(CFLAGS) -o $@ $(cpc_amshead_OBJS)

clean_cpc_amshead:
	-rm -f cpc/amshead/amshead $(cpc_amshead_OBJS)

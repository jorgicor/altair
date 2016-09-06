cpc_bmp2asm: cpc/bmp2asm/bmp2asm

cpc_bmp2asm_OBJS = cpc/bmp2asm/bmp2asm.o

cpc/bmp2asm/bmp2asm.o: cpc/bmp2asm/bmp2asm.c
	$(CC) $(CFLAGS) -c -o $@ -Icpc/bmp $+

cpc/bmp2asm/bmp2asm: $(cpc_bmp2asm_OBJS) $(cpc_bmp_OBJS)
	$(CC) $(CFLAGS) -o $@ $(cpc_bmp2asm_OBJS) $(cpc_bmp_OBJS)

clean_cpc_bmp2asm:
	-rm -f cpc/bmp2asm/bmp2asm $(cpc_bmp2asm_OBJS)

#define FROM_SHORT(adr) \
	*((unsigned char *)adr) + \
	256 * *((unsigned char *)(adr + 1))
	
#define FROM_INT(adr) \
	*((unsigned char *)adr) + \
	256 * *((unsigned char *)(adr + 1)) + \
	65536 * *((unsigned char *)(adr + 2)) + \
	16777216 * *((unsigned char *)(adr + 3))

#define TO_SHORT(adr,value) \
	*((unsigned char *)adr) = (unsigned char)((value) % 256); \
	*((unsigned char *)(adr + 1)) = (unsigned char)((value) / 256)

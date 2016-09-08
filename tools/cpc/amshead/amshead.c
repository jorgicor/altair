/*
Copyright (c) 2014, 2016 Jorge Giner Cordero

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define NELEMS(a) (sizeof(a) / sizeof(a[0]))

/*
 * See firmware manual SOFT 968 Section 9 (AMSDOS) and Section 8 (The Cassette
 * Manager):
 * http://cpctech.cpc-live.com/docs/manual/s968se09.pdf
 * http://cpctech.cpc-live.com/docs/manual/s968se08.pdf
 * http://cpctech.cpc-live.com/docs/allhead.html
 */

#pragma pack(1)
struct header {
	/* User number, 0x00-0x0f. */
	unsigned char user_num;

	/* Padded with 0, not needed. */
	char filename[8];

	/* Filename extension, padded with 0, not needed. */
	char extension[3];

	/* Part of filename, always 0. */
	unsigned char filename_pad[4];

	/* Not used, 0. */
	unsigned char block_number;

	/* Not used, 0. */
	unsigned char last_block;

	/* Bit 0: 1 protected, 0 unprotected
	 * Bits 1-3: File type:
	 *	0 Basic
	 *	1 Binary
	 *	2 Screen image
	 *	3 ASCII
	 *	Rest unallocated.
	 * Bits 4-7: Version: 1 for ASCII files, 0 for the rest.
	 */
	unsigned char file_type;

	/* Number of bytes in the data record. Not needed. */
	unsigned short data_len;

	/* Address where to load file. */
	unsigned short load_addr;

	/* Set to 0xff. */
	unsigned char first_block;

	/* Length of the file without this 128 byte header. */
	unsigned short file_len;

	/* Address to call if file loaded with RUN. */
	unsigned short exec_addr;

	/* Unallocated. */
	unsigned char z1[36];

	/* This is actually a 24 bit number, but we will only use 16 bits,
	 * so we set one byte padding...
	 * Length of the file without this 128 byte header. */
	unsigned short headless_len;
	unsigned char z2;

	/* 16-bit sum of bytes 0-66. */
	unsigned short checksum;

	/* Header is 128 bytes. */
	unsigned char z3[59];
};
#pragma pack()

enum {
	MAX_LEN = 65536 - 128
};

static unsigned char data[MAX_LEN + 1];

static unsigned short calc_chksum(struct header *h)
{
	unsigned short sum;
	int i;

	sum = 0;
	for (i = 0; i < 67; i++) {
		sum += *(((unsigned char *) h) + i);
	}

	return sum;
}

static const char *s_help[] = {
"amshead binfile outfile load_address exec_address",
"",
"	Generates 'outfile' with an AMSDOS header plus the contents of",
"binfile. 'load_address' is a 16 bit address where the file will be loaded",
"if executing the BASIC LOAD or RUN command. 'exec_address' is the address",
"to call if exectuted with the BASIC RUN command."
};

static void print_help()
{
	int i;

	for (i = 0; i < NELEMS(s_help); i++)
	{
		printf("%s\n", s_help[i]);
	}
}

int main(int argc, char *argv[])
{
	struct header h;
	FILE *fin, *fout;
	long load_addr, exec_addr;
	char *p;
	int len;

	if (argc != 5) {
		print_help();
		return EXIT_FAILURE;
	}

	if ((fin = fopen(argv[1], "rb")) == NULL)
	{
		fprintf(stderr, "Cannot open %s.\n", argv[1]);
		return EXIT_FAILURE;
	}

	if ((fout = fopen(argv[2], "wb")) == NULL)
	{
		fprintf(stderr, "Cannot open %s.\n", argv[2]);
		return EXIT_FAILURE;
	}

	load_addr = strtol(argv[3], &p, 0); 
	if (p == argv[3] || load_addr < 0 || load_addr > 65535)
	{
		fprintf(stderr, "Bad loading address %s.\n", argv[3]);
		return EXIT_FAILURE;
	}

	exec_addr = strtol(argv[4], &p, 0);
	if (p == argv[4] || exec_addr < 0 || exec_addr > 65535)
	{
		fprintf(stderr, "Bad exec address %s.\n", argv[4]);
		return EXIT_FAILURE;
	}

	if ((len = fread(data, 1, MAX_LEN + 1, fin)) == MAX_LEN + 1)
	{
		fprintf(stderr, "Input file too long.\n");
		return EXIT_FAILURE;
	}

	memset(&h, 0, sizeof(h));
	h.first_block = 255;
	h.file_type = 1 << 1;
	h.file_len = (unsigned short) len;
	h.load_addr = (unsigned short) load_addr;
	h.exec_addr = (unsigned short) exec_addr;
	h.headless_len = h.file_len;

	h.checksum = calc_chksum(&h);

	fprintf(stderr, "File len: %d\n", h.file_len);
	fprintf(stderr, "Load addr: %d\n", h.load_addr);
	fprintf(stderr, "Exec addr: %d\n", h.exec_addr);
	fprintf(stderr, "Checksum: %d\n", h.checksum);

	fwrite(&h, sizeof(h), 1, fout);
	fwrite(data, len, 1, fout);

	fclose(fin);
	fclose(fout);
	return EXIT_SUCCESS;
}

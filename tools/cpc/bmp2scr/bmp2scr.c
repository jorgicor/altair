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

#include "bmp.h"

#include <stddef.h>
#include <stdlib.h>

#ifndef STDIO_H
#define STDIO_H
#include <stdio.h>
#endif

#include <string.h>

#define NELEMS(a) (sizeof(a) / sizeof(a[0]))

typedef void (*extract_fun_t)(FILE *out, struct bmp *bmp);
typedef void (*pal_extract_fun_t)(FILE *out, struct bmp *bmp);
typedef int (*check_fun_t)(struct bmp *bmp);

static void extract_cpc16x2(FILE *out, struct bmp *bmp)
{
	int i, j, b, x, bi;
	unsigned char pi;
	unsigned char pix;

	for (b = 0; b < 8; b++)
	{
		// extract block
		for (j = 0; j < 25; j++) {
			for (i = 0; i < 80; i++) {
				pix = 0;
				bi = ((b + j * 8) * 80 + i) * 4;
				for (x = 0; x < 2; x++) {
					pi = bmp->data[bi + x * 2];
					pix |= (pi & 1) << (7 - x);
					pix |= (pi & 2) << (2 - x);
					pix |= (pi & 4) << (3 - x);
					pix |= (pi & 8) >> (2 + x);						
				}
				fputc(pix, out);
			}
		}
		// fill extra bytes
		for (i = 0; i < 48; i++) {
			fputc(0, out);
		}
	}	
}

static int check_cpc16x2(struct bmp *bmp)
{
	if (bmp->width != 320)
		return 0;

	if (bmp->height < 25*8)
		return 0;

	if (bmp->pal == NULL)
		return 0;

	return 1;
}

static int reduce_cpc_color_component(int b)
{
	if (b < 64) {
		return 0;
	} else if (b < 192) {
		return 1;
	} else {
		return 2;
	}
}

static int find_cpc_fw_color(int rgb)
{
	int r, g, b;

	b = rgb & 255;
	g = (rgb >> 8) & 255;
	r = (rgb >> 16) & 255;

	// calc firmware color
	r = reduce_cpc_color_component(r) * 3;
	r += reduce_cpc_color_component(g) * 9;
	r += reduce_cpc_color_component(b);

	return r;
}

static void extract_cpc16x2_pal(FILE *out, struct bmp *bmp)
{
	int i, color, n;

	n = bmp->palsz;
	if (n > 16) {
		n = 16;
	}

	for (i = 0; i < n; i++) {
		color = find_cpc_fw_color(bmp->pal[i]);
		fputc(color, out);
	}
	while (n < 16) {
		/* black */
		fputc(0, out);
		n++;
	}
}

struct id_extract_fun {
	const char *id;
	check_fun_t chkfun;
	extract_fun_t efun;
	pal_extract_fun_t pefun;
};

static struct id_extract_fun s_id_extract_fun[] = {
	{ "cpc16x2", 
		&check_cpc16x2,
		&extract_cpc16x2,
		&extract_cpc16x2_pal },
};

static int find_mode(const char *mode)
{
	int i;

	for (i = 0; i < NELEMS(s_id_extract_fun); i++)
	{
		if (strcmp(mode, s_id_extract_fun[i].id) == 0) {
			return i;
		}
	}

	return -1;
}

static extract_fun_t get_extract_fun(int mode)
{
	return s_id_extract_fun[mode].efun;
}

static pal_extract_fun_t get_pal_extract_fun(int mode)
{
	return s_id_extract_fun[mode].pefun;
}

static check_fun_t get_check_fun(int mode)
{
	return s_id_extract_fun[mode].chkfun;
}

static const char *s_help[] = {
"bmp2scr mode bitmap output_scr output_pal",
"",
"	Given a .bmp file generates two binary files, 'output_scr' and",
"'output_pal'.  'output_scr' will be a binary file that can be loaded",
"directly to the cpc video memory (thus it will have a size of 16k).",
"'output_pal' will be a binary file with 16 bytes, each byte being the",
"firmware (basic) color to use for each INK.",
"",
"'mode' can be:",
"	cpc16x2		Amstrad CPC 16 colors doubled",
"",
"		This mode means that the original bitmap should have a width",
"of 320 pixels. Only pixels on an even x coordinate are taken, and each 2",
"pixels taken will form a byte in the final screen file. The height of the",
"bitmap must be at least 200 pixels. The bitmap must have palette."
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
	FILE *scr, *pal;
	struct bmp *bmp;
	int mode;

	if (argc != 5) {
		print_help();
		return EXIT_FAILURE;
	}

	if ((mode = find_mode(argv[1])) < 0) {
		fprintf(stderr, "Unknown mode %s.\n", argv[1]);
		return EXIT_FAILURE;
	}

	if ((bmp = load_bmp(argv[2])) == NULL) {
		fprintf(stderr, "Error opening %s.\n", argv[2]);
		return EXIT_FAILURE;
	}

	if (get_check_fun(mode)(bmp) == 0) {
		fprintf(stderr, "Incompatible input bitmap.\n");
		free_bmp(bmp, 1);
		return EXIT_FAILURE;
	}

	if ((scr = fopen(argv[3], "wb")) == NULL) {
		fprintf(stderr, "Cannot create %s.\n", argv[3]);
		free_bmp(bmp, 1);
		return EXIT_FAILURE;
	}

	if ((pal = fopen(argv[4], "wb")) == NULL) {
		fclose(scr);
		free_bmp(bmp, 1);
		fprintf(stderr, "Cannot create %s.\n", argv[3]);
		return EXIT_FAILURE;
	}

	get_extract_fun(mode)(scr, bmp);
	fclose(scr);

	get_pal_extract_fun(mode)(pal, bmp);
	fclose(pal);

	free_bmp(bmp, 1);
	return EXIT_SUCCESS;
}

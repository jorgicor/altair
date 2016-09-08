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

struct assembler {
	void (*print_label)(FILE *fp, const char *label);
	void (*print_db) (FILE *fp);
	void (*print_hexb) (FILE *f, unsigned char b);
};

static void tasm_print_label(FILE *fp, const char *label)
{
	fprintf(fp, "%s", label);
}

static void tasm_print_db(FILE *fp)
{
	fprintf(fp, ".db");
}

static void tasm_print_hexb(FILE *fp, unsigned char b)
{
	fprintf(fp, "$%02hhx", b);
}

static struct assembler tasm_asm = {
	&tasm_print_label,
	&tasm_print_db,
	&tasm_print_hexb
};

struct id_asm {
	const char *id;
	struct assembler *assembler;
};

static struct id_asm s_id_asm[] =  {
	{ "tasm", &tasm_asm }
};

typedef void (*extract_fun_t)(FILE *out, struct assembler *assembler,
    struct bmp *bmp, int x, int y, int w, int h);

typedef void (*font_extract_fun_t)(FILE *out, struct assembler *assembler,
    struct bmp *bmp, int x, int y, int c);

typedef void (*pal_extract_fun_t)(FILE *out, struct assembler *assembler,
    struct bmp *bmp);

static void extract_cpc16x2(FILE *out, struct assembler *assembler,
    struct bmp *bmp, int x, int y, int w, int h)
{
	int i;
	unsigned char pi;
	unsigned char pix;

	fprintf(out, "\t");
	assembler->print_db(out);
	fprintf(out, " %d,%d\n", (unsigned char) (w >> 2), (unsigned char) h);

	y = y * bmp->width + x;
	while (h--) {
		fprintf(out, "\t");
		assembler->print_db(out);
		fprintf(out, " ");
		for (i = 0, x = 0; i < w; i += 2, x ^= 1) {
			pi = bmp->data[y + i];			
			if (x == 0) {
				pix = 0;
			}
			pix |= (pi & 1) << (7 - x);
			pix |= (pi & 2) << (2 - x);
			pix |= (pi & 4) << (3 - x);
			pix |= (pi & 8) >> (2 + x);
			if (x != 0) {
				assembler->print_hexb(out, pix);
				if (i < w - 2) {
					fprintf(out, ",");
				} else {
					fprintf(out, "\n");
				}
			}
		}
		y += bmp->width;
	}	
}

 static void extract_cpc16x2_font(FILE *out, struct assembler *assembler,
    struct bmp *bmp, int x, int y, int c)
{
	unsigned char pix;
	int h;

	fprintf(out, "\t");
	assembler->print_db(out);
	fprintf(out, " ");

	h = 4;
	y = y * bmp->width + x;
	while (h--) {
		pix = (bmp->data[y] == c) << 7;
		pix |= (bmp->data[y + 2] == c) << 6;
		pix |= (bmp->data[y + 4] == c) << 5;
		pix |= (bmp->data[y + 6] == c) << 4;
		y += bmp->width;
		pix |= (bmp->data[y] == c) << 3;
		pix |= (bmp->data[y + 2] == c) << 2;
		pix |= (bmp->data[y + 4] == c) << 1;
		pix |= (bmp->data[y + 6] == c);
		y += bmp->width;
		assembler->print_hexb(out, pix);
		if (h > 0) {
			fprintf(out, ",");
		}
	}
	fprintf(out, "\n");
}

static char cpc_hw_color[] = {
	20, 4, 21, 28, 24,
	29, 12, 5, 13, 22,
	6, 23, 30, 0, 31,
	14, 7, 15, 18, 2,
	19, 26, 25, 27, 10,
	3, 11
};

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

static int find_cpc_hw_color(int rgb)
{
	int r, g, b;

	b = rgb & 255;
	g = (rgb >> 8) & 255;
	r = (rgb >> 16) & 255;

	// calc firmware color
	r = reduce_cpc_color_component(r) * 3;
	r += reduce_cpc_color_component(g) * 9;
	r += reduce_cpc_color_component(b);

	return cpc_hw_color[r] + 64;
}

static void extract_cpc16x2_pal(FILE *out, struct assembler* assembler,
    struct bmp *bmp)
{
	int i, color, n;

	if (bmp->pal != NULL)
	{
		n = bmp->palsz;
		if (n > 16) {
			n = 16;
		}

		fprintf(out, "\t");
		assembler->print_db(out);
		fprintf(out, " ");
		for (i = 0; i < n; i++) {
			color = bmp->pal[i];
			color = find_cpc_hw_color(color);
			assembler->print_hexb(out, color);
			if (i < 15) {
				fprintf(out, ",");
			}
		}
		while (n < 16) {
			/* black */
			assembler->print_hexb(out, 20 + 64);
			n++;
			if (n < 16) {
				fprintf(out, ",");
			}
		}
		fprintf(out, "\n");
	}
}

struct id_extract_fun {
	const char *id;
	extract_fun_t efun;
	font_extract_fun_t fefun;
	pal_extract_fun_t pefun;
};

static struct id_extract_fun s_id_extract_fun[] = {
	{ "cpc16x2", 
		&extract_cpc16x2,
		&extract_cpc16x2_font,
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

static font_extract_fun_t get_font_extract_fun(int mode)
{
	return s_id_extract_fun[mode].fefun;
}

static pal_extract_fun_t get_pal_extract_fun(int mode)
{
	return s_id_extract_fun[mode].pefun;
}

static struct assembler *get_assembler(const char *asmid)
{
	int i;

	for (i = 0; i < NELEMS(s_id_asm); i++)
	{
		if (strcmp(asmid, s_id_asm[i].id) == 0) {
			return s_id_asm[i].assembler;
		}
	}

	return NULL;
}

static void extract_normal(FILE *fp, struct bmp *bmp, int line, FILE *out,
    struct assembler *assembler, extract_fun_t extract_fun)
{
	char name[65];
	int x, y, w, h;

	if (fscanf(fp, " %64s %d %d %d %d ", &name, &x, &y, &w, &h) != 5)
	{
		fprintf(stderr, "Sytax error line %d.\n", line);
		exit(EXIT_FAILURE);
	}

	if (x < 0 || y < 0 || w <= 0 || h <= 0 ||
	    x + w > bmp->width || y + h > bmp->height)
	{
		fprintf(stderr, "Bad parameters for %s\n.", name);
		fprintf(out, "; Bad parameters for %s\n.", name);
	} else {
		assembler->print_label(out, name);
		fprintf(out, "\n");
		extract_fun(out, assembler, bmp, x, y, w, h);
	}
}

static void extract_font(FILE *fp, struct bmp *bmp, int line, FILE *out,
    struct assembler *assembler, font_extract_fun_t font_extract_fun)
{
	char name[65];
	int x, y, c;

	if (fscanf(fp, " %64s %d %d %d ", &name, &x, &y, &c) != 4) {
		fprintf(stderr, "Sytax error line %d.\n", line);
		exit(EXIT_FAILURE);
	}
	
	if (x < 0 || y < 0 || x + 8 > bmp->width || y + 8 > bmp->height) {
		fprintf(stderr, "Bad parameters for %s\n.", name);
		fprintf(out, "; Bad parameters for %s\n.", name);
	} else {
		assembler->print_label(out, name);
		fprintf(out, "\n");
		font_extract_fun(out, assembler, bmp, x, y, c);
	}
}

static void extract_pal(FILE *fp, struct bmp *bmp, int line, FILE *out,
    struct assembler *assembler, pal_extract_fun_t pal_extract_fun)
{
	char name[65];

	if (fscanf(fp, " %64s ", &name) != 1) {
		fprintf(stderr, "Sytax error line %d.\n", line);
		exit(EXIT_FAILURE);
	}
	
	assembler->print_label(out, name);
	fprintf(out, "\n");
	pal_extract_fun(out, assembler, bmp);
}

static const char *s_help[] = {
"bmp2asm mode assembler spec bitmap [output_file_name]",
"",
"	This programs is used to extract pixel data from a .bmp file 'bitmap'",
"in assemler format. It uses a text based 'spec' file that specifies how to",
"extract the data. The bitmap must have palette. 'assembler' specifies for",
"which assembler are we generating the data. If 'ouput_file_name' is not",
"specified, data is generated on the standard output (console).",
"",
"'mode' can be:",
"",
"	cpc16x2		Amstrad CPC 16 colors doubled",
"",
"		This mode means that the in the original bitmap each 2 pixels",
"	forms a pixel on the amstrad, thus we only take the even horizontal",
"	pixels from the bitmap (odd horizontal pixels are ignored). Then the",
"	pixels are extracted to form pixel data for an Amstrad CPC in mode 0",
"	(16 colors per pixel).",
"",
"'assembler' can be:",
"",
"	tasm		Telemark Cross Assembler",
"",
"The 'spec' file is a text file and each line is a command that instructs what",
"to extract. These are the commands allowed:",
"",
"	0 name x y w h",
"		Extracts an sprite with label 'name'. We will extract the",
"		pixels from the bitmap starting at x,y coordinates and with",
"		dimensions w,h (width, height). The output format depends on",
"		'mode'.",
"	1 name x y color",
"		Extracts a font character with a label 'name' from the pixel",
"		coordinates x,y. A font character is 8x8 pixels. Color is a",
"		palette index in the original bitmap. We only extract pixels",
"		with that color, the rest are considered transparent. The",
"		output format depends on 'mode'.",
"	2 name",
"		The palette is extracted with label 'name'. How many colors are",
"		extracted depends on 'mode'. The colors are in hardware units",
"		and with 64 added. For example, 20 is black in hardware units",
"		(in firmware units it is 0), so we extract 84 for that color.",
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
	FILE *fp, *out;
	struct assembler *assembler;
	struct bmp *bmp;
	int line, mode, t;

	if (argc != 5 && argc != 6) {
		print_help();
		return EXIT_FAILURE;
	}

	if ((mode = find_mode(argv[1])) < 0) {
		fprintf(stderr, "Unknown mode %s.\n", argv[1]);
		return EXIT_FAILURE;
	}

	if ((assembler = get_assembler(argv[2])) == NULL) {
		fprintf(stderr, "Unknown assembler %s.\n", argv[2]);
		return EXIT_FAILURE;
	}
	
	if ((fp = fopen(argv[3], "r")) == NULL) {
		fprintf(stderr, "Cannot open %s.\n", argv[3]);
		return EXIT_FAILURE;
	}

	if (argc == 6) {
		if ((out = fopen(argv[5], "w")) == NULL) {
			free(fp);
			fprintf(stderr, "Cannot create %s.\n", argv[5]);
			return EXIT_FAILURE;
		}
	} else {
		out = stdout;
	}

	if ((bmp = load_bmp(argv[4])) == NULL) {
		if (out != stdout) {
			fclose(out);
		}
		fclose(fp);
		fprintf(stderr, "Error opening %s.\n", argv[4]);
		return EXIT_FAILURE;
	}

	line = 0;
	while (fscanf(fp, " %d ", &t) == 1) {
		switch (t) {
		case 0:
			extract_normal(fp, bmp, line, out, assembler,
			    get_extract_fun(mode));
			break;
		case 1:
			extract_font(fp, bmp, line, out, assembler,
			    get_font_extract_fun(mode));
			break;
		case 2:
			extract_pal(fp, bmp, line, out, assembler,
			    get_pal_extract_fun(mode));
			break;
		default:
			fprintf(stderr, "Syntax error on line %d.\n", line);
			return EXIT_FAILURE;
		}

		line++;
	}

	free_bmp(bmp, 1);
	if (out != stdout) {
		fclose(out);
	}
	fclose(fp);

	return EXIT_SUCCESS;
}

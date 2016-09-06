/**
The MIT License (MIT)

Copyright (c) 2014 Jorge Giner Cordero

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

#ifndef BMP_H
#define BMP_H 

#ifndef STDIO_H
#define STDIO_H
#include <stdio.h>
#endif

/**
 * A bitmap.
 *
 * If pal is not NULL, then data contains indexes into pal, which contains
 * rgb colors. palsz is the number of colors in palette.
 *
 * If pal is NULL, data should be considered as (unsigned int *) and
 * contains 32 bit rgb colors. palsz will be 0.
 */
struct bmp {
	int width;
	int height;
	unsigned int *pal;
	unsigned char *data;
	unsigned short palsz;
};

#ifdef __cplusplus
extern "C" {
#endif

struct bmp *load_bmp(const char *fname);
struct bmp *load_bmp_fp(FILE *fp);
void free_bmp(struct bmp *bmp, int free_pal);

#ifdef __cplusplus
}
#endif

#endif

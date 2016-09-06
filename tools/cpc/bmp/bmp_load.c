/*
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

#include "bmp.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/**
 * A bitmap file consists of:
 *
 *	- A BITMAPFILEHEADER.
 *	- A BITMAPCOREHEADER or a BITMAPINFOHEADER or
 *	  BITMAPV4HEADER or a BITMAPV5HEADER.
 *	- bitmap data.
 */

/* We define several BMP headers and symbols here instead of including windows
 * headers, to make this independent.*/

#define BI_RGB        0L
#define BI_RLE8       1L
#define BI_RLE4       2L
#define BI_BITFIELDS  3L
#define BI_JPEG       4L
#define BI_PNG        5L

typedef unsigned long	DWORD;
typedef unsigned char	BYTE;
typedef unsigned short	WORD;
typedef long		LONG;

#pragma pack(1)
typedef struct {
        BYTE    rgbtBlue;
        BYTE    rgbtGreen;
        BYTE    rgbtRed;
} RGBTRIPLE;
#pragma pack()

typedef struct {
        BYTE    rgbBlue;
        BYTE    rgbGreen;
        BYTE    rgbRed;
        BYTE    rgbReserved;
} RGBQUAD;

typedef struct {
	DWORD bcSize;
	WORD  bcWidth;
	WORD  bcHeight;
	WORD  bcPlanes;
	WORD  bcBitCount;
} BITMAPCOREHEADER;

#pragma pack(2)
typedef struct {
        WORD    bfType;
        DWORD   bfSize;
        WORD    bfReserved1;
        WORD    bfReserved2;
        DWORD   bfOffBits;
} BITMAPFILEHEADER;
#pragma pack()

typedef struct {
        DWORD      biSize;
        LONG       biWidth;
        LONG       biHeight;
        WORD       biPlanes;
        WORD       biBitCount;
        DWORD      biCompression;
        DWORD      biSizeImage;
        LONG       biXPelsPerMeter;
        LONG       biYPelsPerMeter;
        DWORD      biClrUsed;
        DWORD      biClrImportant;
} BITMAPINFOHEADER;

typedef long FXPT2DOT30;

typedef struct {
        FXPT2DOT30 ciexyzX;
        FXPT2DOT30 ciexyzY;
        FXPT2DOT30 ciexyzZ;
} CIEXYZ;

typedef struct {
        CIEXYZ  ciexyzRed;
        CIEXYZ  ciexyzGreen;
        CIEXYZ  ciexyzBlue;
} CIEXYZTRIPLE;

typedef struct {
        DWORD        bV4Size;
        LONG         bV4Width;
        LONG         bV4Height;
        WORD         bV4Planes;
        WORD         bV4BitCount;
        DWORD        bV4V4Compression;
        DWORD        bV4SizeImage;
        LONG         bV4XPelsPerMeter;
        LONG         bV4YPelsPerMeter;
        DWORD        bV4ClrUsed;
        DWORD        bV4ClrImportant;
        DWORD        bV4RedMask;
        DWORD        bV4GreenMask;
        DWORD        bV4BlueMask;
        DWORD        bV4AlphaMask;
        DWORD        bV4CSType;
        CIEXYZTRIPLE bV4Endpoints;
        DWORD        bV4GammaRed;
        DWORD        bV4GammaGreen;
        DWORD        bV4GammaBlue;
} BITMAPV4HEADER;

typedef struct {
        DWORD        bV5Size;
        LONG         bV5Width;
        LONG         bV5Height;
        WORD         bV5Planes;
        WORD         bV5BitCount;
        DWORD        bV5Compression;
        DWORD        bV5SizeImage;
        LONG         bV5XPelsPerMeter;
        LONG         bV5YPelsPerMeter;
        DWORD        bV5ClrUsed;
        DWORD        bV5ClrImportant;
        DWORD        bV5RedMask;
        DWORD        bV5GreenMask;
        DWORD        bV5BlueMask;
        DWORD        bV5AlphaMask;
        DWORD        bV5CSType;
        CIEXYZTRIPLE bV5Endpoints;
        DWORD        bV5GammaRed;
        DWORD        bV5GammaGreen;
        DWORD        bV5GammaBlue;
        DWORD        bV5Intent;
        DWORD        bV5ProfileData;
        DWORD        bV5ProfileSize;
        DWORD        bV5Reserved;
} BITMAPV5HEADER;

/**
 * Creates a 32 bit bitmap of width by height dimensions.
 *
 * Returns NULL on failure.
 */
static struct bmp *create_bmp(int width, int height, int pal_size)
{
	struct bmp *im;

	im = malloc(sizeof(*im));
	if (im == NULL)
		return NULL;

	im->pal = NULL;
	if (pal_size > 0) {
		if ((im->pal = malloc(pal_size * 4)) == NULL)
			goto freim;
	}

	if (pal_size == 0)
		im->data = malloc(width * height * 4);
	else
		im->data = malloc(width * height);
	if (im->data == NULL)
		goto frepal;

	im->palsz = pal_size;
	im->width = width;
	im->height = height;
	return im;

frepal:	if (im->pal != NULL)
		free(im->pal);
freim:	free(im);
	return NULL;
}

/**
 * Loads the palette of a bitmap from file 'fp', if any, into a 'pal' array
 * with capacity up to 'maxcolors'.
 * Uses 'ih' to discriminate between RGBTRIPLE palettes and RGBQUAD palettes.
 */
static int bmp_load_pal(BITMAPV5HEADER *ih, RGBQUAD *pal, int maxcolors,
    FILE *fp)
{
	RGBTRIPLE cpal[256];
	int ncolors;
	size_t n;

	if (ih->bV5ClrUsed == 0) {
		ncolors = maxcolors;
	} else if (ih->bV5ClrUsed <= (unsigned int) maxcolors) {
		ncolors = ih->bV5ClrUsed;
	} else {
		return -1;
	}

	if (ih->bV5Size != sizeof(BITMAPCOREHEADER)) {
		n = fread(pal, sizeof(*pal) * ncolors, 1, fp);
		return (n == 1) ? 0 : -2;
	}

	/* Core header palette is based on triplets. */
	n = fread(cpal, sizeof(cpal[0]) * ncolors, 1, fp);
	if (n == 0)
		return -2;

	/* Transform to quads. */
	while (ncolors--) {
		pal[ncolors].rgbBlue = cpal[ncolors].rgbtBlue;
		pal[ncolors].rgbGreen = cpal[ncolors].rgbtGreen;
		pal[ncolors].rgbRed = cpal[ncolors].rgbtRed;
		pal[ncolors].rgbReserved = 0;
	}

	return 0;
}

/* Number of bytes in a row padded to 4 bytes. */
static int padded_row_len(int width, int bitcnt)
{
	return ((width * bitcnt + 31) / 32) * 4;
}

/* Number of bytes with significant info. */
static int filled_bytes(int width, int bitcnt)
{
	return (width * bitcnt + 7) / 8;
}

static unsigned char *bmp_load_data(int nbytes, FILE *fp)
{
	unsigned char *data;

	data = malloc(nbytes);
	if (data == NULL)
		return NULL;

	if (fread(data, nbytes, 1, fp) == 0) {
		free(data);
		return NULL;
	}

	return data;
}

static void expand_4bpp_rgb(unsigned char *dst, unsigned char *src, int w,
    int h, int pad)
{
	int i, j, p, q, s;
	unsigned char k;

	p = q = 0;
	for (j = 0; j < h; j++) {
		s = 1;
		for (i = 0; i < w; i++) {
			if (s == 1)
				k = src[p] >> 4;
			else
				k = src[p] & 15;
			dst[q++] = k;
			s ^= 1;
			p += s;
		}
		p += pad + (s ^ 1);
	}
}

static void expand_4bpp_rle(unsigned char *dst, unsigned char *src, int srclen,
    int w, int h)
{
	unsigned char c;
	int stat, n, s;
	unsigned char *end;
	unsigned char *dstend;
	int x;
	int pad;

	end = src + srclen;
	dstend = dst + (w * h);
	stat = 0;
	x = 0;
	while (src != end) {
		switch (stat) {
		case 0:
			if (dst == dstend)
				return;
			c = *src++;
			if (c != 0) {
				n = c;
				s = 1;
				stat = 1;
			} else {
				stat = 2;
			}
			break;
		case 1:
			while (x < w && n--) {
				if (s == 1)
					*dst++ = *src >> 4;
				else
					*dst++ = *src & 15;
				x++;
				s ^= 1;
			}
			src++;
			stat = 0;
			break;
		case 2:
			c = *src;
			if (c == 0) {
				/* End of line. */
				x = 0;
				src++;
				stat = 0;
			} else if (c == 1) {
				/* End of bitmap. */
				return;
			} else if (c == 2) {
				/* Delta. */
				src++;
				stat = 4;
			} else {
				s = 1;
				n = c;
				/* How many bytes we fill? If not multiple
				   of 2 needs padding. */
				pad = ((n * 4 + 7) / 8) & 1;
				stat = 3;
				src++;
			}
			break;
		case 3:
			if (x < w) {
				if (s == 1)
					*dst++ = *src >> 4;
				else
					*dst++ = *src & 15;
				x++;
			}
			s ^= 1;
			src += s;
			if (--n == 0) {
				src += (s ^ 1);
				if (pad)
					stat = 6;
				else
					stat = 0;
			}
			break;
		case 4:
			n = *src++;
			while (x < w && n-- > 0) {
				*dst++ = 0;
				x++;
			}
			stat = 5;
			break;
		case 5:
			n = *src++;
			n *= w;
			while (dst != dstend && n--) {
				*dst++ = 0;
			}
			stat = 0;
			break;
		case 6:
			src++;
			stat = 0;
			break;
		}
	}
}

static struct bmp *load_4bpp_bmp(BITMAPV5HEADER *ih, FILE *fp)
{
	RGBQUAD pal[16];
	int rowlen, pad;
	struct bmp *im;
	unsigned char *data;
	int err;

	im = NULL;
	if (ih->bV5Compression != BI_RGB && ih->bV5Compression != BI_RLE4) {
		// L"bad compression for 4bpp bitmap"
		goto error;
	}

	err = bmp_load_pal(ih, pal, 16, fp);
	if (err) {
		// L"error loading palette"
		goto error;
	}

	if (ih->bV5Compression == BI_RGB) {
		rowlen = padded_row_len(ih->bV5Width, ih->bV5BitCount);
		data = bmp_load_data(rowlen * abs(ih->bV5Height), fp);
	} else {
		/* BI_RLE4 */
		data = bmp_load_data(ih->bV5SizeImage, fp);
	}

	if (data == NULL) {
		// L"error loading image data"
		goto error;
	}

	im = create_bmp(ih->bV5Width, abs(ih->bV5Height), 16);
	if (im == NULL) {
		// L"error allocating image"
		goto freedata;
	}
	
	memcpy(im->pal, pal, sizeof(pal));
	if (ih->bV5Compression == BI_RGB) {
		pad = rowlen - filled_bytes(ih->bV5Width, ih->bV5BitCount);
		expand_4bpp_rgb(im->data, data, im->width, im->height, pad);
	} else {
		/* BI_RLE4 */
		expand_4bpp_rle(im->data, data, ih->bV5SizeImage, im->width,
		    im->height);
	}

freedata:
	free(data);
error:
	return im;
}

static void expand_8bpp_rle(unsigned char *dst, unsigned char *src, int srclen,
    int w, int h)
{
	unsigned char c;
	int stat, n, s;
	unsigned char *end;
	unsigned char *dstend;
	int x;
	int pad;

	end = src + srclen;
	dstend = dst + (w * h);
	stat = 0;
	x = 0;
	while (src != end) {
		switch (stat) {
		case 0:
			if (dst == dstend)
				return;
			c = *src++;
			if (c != 0) {
				n = c;
				stat = 1;
			} else {
				stat = 2;
			}
			break;
		case 1:
			c = *src;
			while (x < w && n--) {
				*dst++ = c;
				x++;
			}
			src++;
			stat = 0;
			break;
		case 2:
			c = *src;
			if (c == 0) {
				/* End of line. */
				x = 0;
				src++;
				stat = 0;
			} else if (c == 1) {
				/* End of bitmap. */
				return;
			} else if (c == 2) {
				/* Delta. */
				src++;
				stat = 4;
			} else {
				s = 1;
				n = c;
				/* How many bytes we fill? If not multiple
				   of 2 needs padding. */
				pad = ((n * 8 + 7) / 8) & 1;
				stat = 3;
				src++;
			}
			break;
		case 3:
			if (x < w) {
				*dst++ = *src++;
				x++;
			}
			if (--n == 0) {
				if (pad)
					stat = 6;
				else
					stat = 0;
			}
			break;
		case 4:
			n = *src++;
			while (x < w && n-- > 0) {
				*dst++ = 0;
				x++;
			}
			stat = 5;
			break;
		case 5:
			n = *src++;
			n *= w;
			while (dst != dstend && n--) {
				*dst++ = 0;
			}
			stat = 0;
			break;
		case 6:
			src++;
			stat = 0;
			break;
		}
	}
}

static void expand_8bpp_rgb(unsigned char *dst, unsigned char *src, int w, int h,
    int pad)
{
	int tmp;

	while (h--) {
		tmp = w;
		while (w--)
			*dst++ = *src++;
		w = tmp;
		src += pad;
	}
}

static struct bmp *load_8bpp_bmp(BITMAPV5HEADER *ih, FILE *fp)
{
	RGBQUAD pal[256];
	int rowlen, pad;
	struct bmp *im;
	unsigned char *data;
	int err;

	im = NULL;
	if (ih->bV5Compression != BI_RGB && ih->bV5Compression != BI_RLE8) {
		// L"bad compression for 8bpp bitmap"
		goto error;
	}

	err = bmp_load_pal(ih, pal, 256, fp);
	if (err) {
		// L"error loading palette"
		goto error;
	}

	if (ih->bV5Compression == BI_RGB) {
		rowlen = padded_row_len(ih->bV5Width, ih->bV5BitCount);
		data = bmp_load_data(rowlen * abs(ih->bV5Height), fp);
	} else {
		/* BI_RLE8 */
		data = bmp_load_data(ih->bV5SizeImage, fp);
	}

	if (data == NULL) {
		// L"error loading image data"
		goto error;
	}

	im = create_bmp(ih->bV5Width, abs(ih->bV5Height), 256);
	if (im == NULL) {
		// L"error allocating image"
		goto fredat;
	}
		
	memcpy(im->pal, pal, sizeof(pal));
	if (ih->bV5Compression == BI_RGB) {
		pad = rowlen - filled_bytes(ih->bV5Width, ih->bV5BitCount);
		expand_8bpp_rgb(im->data, data, im->width, im->height, pad);
	} else {
		/* BI_RLE8 */
		expand_8bpp_rle(im->data, data, ih->bV5SizeImage, im->width,
		    im->height);
	}

fredat:	free(data);
error:	return im;
}

static void expand_1bpp_rgb(unsigned char *dst, unsigned char *src, int w,
    int h, int pad)
{
	int i, j, p, q;
	unsigned char s;

	p = q = 0;
	for (j = 0; j < h; j++) {
		s = 128;
		for (i = 0; i < w; i++) {
			dst[q++] = (src[p] & s) != 0;
			s >>= 1;
			if (s == 0) {
				s = 128;
				p++;
			}
		}
		p += pad + (s < 128);	/* TODO: we can always know this. */
	}
}

static struct bmp *load_1bpp_bmp(BITMAPV5HEADER *ih, FILE *fp)
{
	RGBQUAD pal[2];
	int rowlen, pad;
	struct bmp *im;
	unsigned char *data;
	int err;

	im = NULL;
	if (ih->bV5Compression != BI_RGB) {
		// "bad compression for 1bpp bitmap"
		goto error;
	}

	err = bmp_load_pal(ih, pal, 2, fp);
	if (err) {
		// L"error loading palette"
		goto error;
	}

	rowlen = padded_row_len(ih->bV5Width, ih->bV5BitCount);
	data = bmp_load_data(rowlen * abs(ih->bV5Height), fp);

	if (data == NULL) {
		// L"error loading image data"
		goto error;
	}

	im = create_bmp(ih->bV5Width, abs(ih->bV5Height), 2);
	if (im == NULL) {
		// L"error allocating image"
		goto fredat;
	}
	
	memcpy(im->pal, &pal, sizeof(pal));
	pad = rowlen - filled_bytes(ih->bV5Width, ih->bV5BitCount);
	expand_1bpp_rgb(im->data, data, im->width, im->height, pad);

fredat:	free(data);
error:	return im;
}

static void expand_24bpp_rgb(unsigned int *dst, unsigned char *src, int w,
    int h, int pad)
{
	unsigned int pix;
	int tmp;

	while (h--) {
		tmp = w;
		while (w--) {
			pix = *src++;
			pix |= *src++ << 8;
			pix |= *src++ << 16;
			*dst++ = pix;
		}
		w = tmp;
		src += pad;
	}
}

static struct bmp *load_24bpp_bmp(BITMAPV5HEADER *ih, FILE *fp)
{
	int rowlen, pad;
	struct bmp *im;
	unsigned char *data;

	im = NULL;
	if (ih->bV5Compression != BI_RGB) {
		// "bad compression for 24bpp bitmap"
		goto error;
	}

	rowlen = padded_row_len(ih->bV5Width, ih->bV5BitCount);
	data = bmp_load_data(rowlen * abs(ih->bV5Height), fp);
	if (data == NULL) {
		// L"error loading image data"
		goto error;
	}

	im = create_bmp(ih->bV5Width, abs(ih->bV5Height), 0);
	if (im == NULL) {
		// L"error allocating image"
		goto freedata;
	}
		
	pad = rowlen - filled_bytes(ih->bV5Width, ih->bV5BitCount);
	expand_24bpp_rgb((unsigned int *) im->data, data, im->width, im->height,
	    pad);

freedata:
	free(data);
error:
	return im;
}

/* Returns the number of bits that are 1 in x. */
static int count_bits_set(int x)
{
	int b;

	for (b = 0; x != 0; x &= (x - 1))
		b++;

	return b;
}

/**
 * Counts the number of bits that are zero in x from the less significative
 * to the first that is 1.
 */
static int count_left_zero_bits(int x)
{
	int n;

	for (n = 0; n < 32 && !(x & 1); n++)
		x >>= 1;

	return n;
}

static void expand_16bpp_rgb(unsigned int *dst, unsigned char *src, int w,
    int h, int pad, unsigned int rmask, unsigned int gmask,
    unsigned int bmask)
{
	int i, j;
	unsigned int pix;
	unsigned short *wsrc;
	int bshr, gshr, rshr;
	int bmul, gmul, rmul;
	int bits;

	bits = count_bits_set(bmask);
	bshr = count_left_zero_bits(bmask);
	if (bits > 8) {
		bshr += bits - 8;
		bmul = 256;
	} else {
		bmul = (255 << 8) / (bmask >> bshr);
	}

	bits = count_bits_set(gmask);
	gshr = count_left_zero_bits(gmask);
	if (bits > 8) {
		gshr += bits - 8;
		gmul = 256;
	} else {
		gmul = (255 << 8) / (gmask >> gshr);
	}

	bits = count_bits_set(rmask);
	rshr = count_left_zero_bits(rmask);
	if (bits > 8) {
		rshr += bits - 8;
		rmul = 256;
	} else {
		rmul = (255 << 8) / (rmask >> rshr);
	}

	wsrc = (unsigned short *) src;
	for (j = 0; j < h; j++) {
		for (i = 0; i < w; i++) {
			pix = (((*wsrc & bmask) >> bshr) * bmul) >> 8;
			pix |= ((((*wsrc & gmask) >> gshr) * gmul) >> 8)
			    << 8;
			pix |= ((((*wsrc++ & rmask) >> rshr) * rmul) >> 8)
			    << 16;
			*dst++ = pix;
		}
		wsrc = (unsigned short *) (((unsigned char *) wsrc) + pad);
	}
}

static struct bmp *load_16bpp_bmp(BITMAPV5HEADER *ih, FILE *fp)
{
	int rowlen, pad;
	struct bmp *im;
	unsigned char *data;
	unsigned int rmask, gmask, bmask;

	im = NULL;
	if (ih->bV5Compression != BI_RGB &&
	    ih->bV5Compression != BI_BITFIELDS) {
		// L"bad compression for 24bpp bitmap\n"
		goto error;
	}

	if (ih->bV5Compression == BI_RGB && ih->bV5ClrUsed > 0) {
		/* discard palette if any */
		if (fseek(fp, ih->bV5ClrUsed * 4, SEEK_CUR) != 0) {
			// L"bad palette\n"
			goto error;
		}
	}

	if (ih->bV5Compression == BI_BITFIELDS) {
		rmask = ih->bV5RedMask;
		gmask = ih->bV5GreenMask;
		bmask = ih->bV5BlueMask;
	} else {
		bmask = 0x01f;
		gmask = 0x03e0;
		rmask = 0x07c00;
	}

	rowlen = padded_row_len(ih->bV5Width, ih->bV5BitCount);
	data = bmp_load_data(rowlen * abs(ih->bV5Height), fp);
	if (data == NULL) {
		// L"error loading image data\n"
		goto error;
	}

	im = create_bmp(ih->bV5Width, abs(ih->bV5Height), 0);
	if (im == NULL) {
		// L"error allocating image"
		goto freedata;
	}
		
	pad = rowlen - filled_bytes(ih->bV5Width, ih->bV5BitCount);
	expand_16bpp_rgb((unsigned int *) im->data, data, im->width, im->height,
	    pad, rmask, gmask, bmask);

freedata:
	free(data);
error:
	return im;
}

static void expand_32bpp_rgb(unsigned int *dst, unsigned char *src, int w,
    int h, int pad, unsigned int rmask, unsigned int gmask,
    unsigned int bmask)
{
	int i, j;
	unsigned int pix;
	unsigned int *dwsrc;
	int bshr, gshr, rshr;
	int bmul, gmul, rmul;
	int bits;

	bits = count_bits_set(bmask);
	bshr = count_left_zero_bits(bmask);
	if (bits > 8) {
		bshr += bits - 8;
		bmul = 256;
	} else {
		bmul = (255 << 8) / (bmask >> bshr);
	}

	bits = count_bits_set(gmask);
	gshr = count_left_zero_bits(gmask);
	if (bits > 8) {
		gshr += bits - 8;
		gmul = 256;
	} else {
		gmul = (255 << 8) / (gmask >> gshr);
	}

	bits = count_bits_set(rmask);
	rshr = count_left_zero_bits(rmask);
	if (bits > 8) {
		rshr += bits - 8;
		rmul = 256;
	} else {
		rmul = (255 << 8) / (rmask >> rshr);
	}

	dwsrc = (unsigned int *) src;
	for (j = 0; j < h; j++) {
		for (i = 0; i < w; i++) {
			pix = (((*dwsrc & bmask) >> bshr) * bmul) >> 8;
			pix |= ((((*dwsrc & gmask) >> gshr) * gmul) >> 8)
			    << 8;
			pix |= ((((*dwsrc++ & rmask) >> rshr) * rmul) >> 8)
			    << 16;
			*dst++ = pix;
		}
		dwsrc = (unsigned int *) (((unsigned char *) dwsrc) + pad);
	}
}

static struct bmp *load_32bpp_bmp(BITMAPV5HEADER *ih, FILE *fp)
{
	int rowlen, pad;
	struct bmp *im;
	unsigned char *data;
	unsigned int rmask, gmask, bmask;

	im = NULL;
	if (ih->bV5Compression != BI_RGB &&
	    ih->bV5Compression != BI_BITFIELDS) {
		// L"bad compression for 32bpp bitmap\n"
		goto error;
	}

	if (ih->bV5Compression == BI_RGB && ih->bV5ClrUsed > 0) {
		/* discard palette if any */
		if (fseek(fp, ih->bV5ClrUsed * 4, SEEK_CUR) != 0) {
			// L"bad palette\n"
			goto error;
		}
	}

	if (ih->bV5Compression == BI_BITFIELDS) {
		rmask = ih->bV5RedMask;
		gmask = ih->bV5GreenMask;
		bmask = ih->bV5BlueMask;
	} else {
		bmask = 0x0ff;
		gmask = 0x0ff00;
		rmask = 0x0ff0000;
	}

	rowlen = padded_row_len(ih->bV5Width, ih->bV5BitCount);
	data = bmp_load_data(rowlen * abs(ih->bV5Height), fp);
	if (data == NULL) {
		// L"error loading image data\n"
		goto error;
	}

	im = create_bmp(ih->bV5Width, abs(ih->bV5Height), 0);
	if (im == NULL) {
		// L"error allocating image"
		goto fredat;
	}
		
	pad = rowlen - filled_bytes(ih->bV5Width, ih->bV5BitCount);
	expand_32bpp_rgb((unsigned int *) im->data, data, im->width, im->height,
	    pad, rmask, gmask, bmask);

fredat:	free(data);
error:	return im;
}

static void vflip_bmp32(struct bmp *im)
{
	unsigned int tmp;
	int i, j, w, h;
	unsigned int *data;
	
	data = (unsigned int *) im->data;
	w = im->width;
	h = im->height;
	for (j = 0; j < h / 2; j++) {
		for (i = 0; i < w; i++) {
			tmp = data[j * w + i];
			data[j * w + i] =
			    data[(h - j - 1) * w + i];
			data[(h - j - 1) * w + i] = tmp;
		}
	}
}

static void vflip_bmp8(struct bmp *im)
{
	unsigned int tmp;
	int i, j, w, h;
	unsigned char *data;
	
	data = im->data;
	w = im->width;
	h = im->height;
	for (j = 0; j < h / 2; j++) {
		for (i = 0; i < w; i++) {
			tmp = data[j * w + i];
			data[j * w + i] =
			    data[(h - j - 1) * w + i];
			data[(h - j - 1) * w + i] = tmp;
		}
	}
}

/* Given a bitmap, flips it in vertical. */
static void vflip_bmp(struct bmp *im)
{
	if (im->pal == NULL)
		vflip_bmp32(im);
	else
		vflip_bmp8(im);
}

static struct bmp *bmp_load_on_type(BITMAPV5HEADER *ih, FILE *fp)
{
	struct bmp *im;

	im = NULL;
	if (ih->bV5Compression == BI_PNG || ih->bV5Compression == BI_JPEG) {
		// L"Compression not supported\n"
		return NULL;
	}

	if (ih->bV5BitCount == 1) {
		im = load_1bpp_bmp(ih, fp);
	} else if (ih->bV5BitCount == 4) {
		im = load_4bpp_bmp(ih, fp);
	} else if (ih->bV5BitCount == 8) {
		im = load_8bpp_bmp(ih, fp);
	} else if (ih->bV5BitCount == 16) {
		im = load_16bpp_bmp(ih, fp);
	} else if (ih->bV5BitCount == 24) {
		im = load_24bpp_bmp(ih, fp);
	} else if (ih->bV5BitCount == 32) {
		im = load_32bpp_bmp(ih, fp);
	} else {
		// L"Unsupported bmp bitcount\n"
		return NULL;
	}

	if (im == NULL)
		return NULL;

	if (ih->bV5Height > 0)
		vflip_bmp(im);

	return im;
}

struct bmp *load_bmp_fp(FILE *fp)
{
	size_t n;
	BITMAPFILEHEADER fh;
	BITMAPV5HEADER ih;
	BITMAPCOREHEADER ch;

	n = fread(&fh, sizeof(fh), 1, fp);
	if (n == 0) {
		// L"error loading header\n"
		return NULL;
	}

	if (fh.bfType != 0x4d42) {
		// L"type does not match\n"
		return NULL;
	}

	n = fread(&ch, sizeof(ch), 1, fp);
	if (n == 0) {
		// L"bad core header\n"
		return NULL;
	}

	memset(&ih, 0, sizeof(ih));
	if (ch.bcSize == sizeof(ch)) {
		ih.bV5Size = ch.bcSize;
		ih.bV5Width = ch.bcWidth;
		ih.bV5Height = ch.bcHeight;
		ih.bV5Planes = ch.bcPlanes;
		ih.bV5BitCount = ch.bcBitCount;
	} else if (ch.bcSize == sizeof(BITMAPINFOHEADER) ||
	    ch.bcSize == sizeof(BITMAPV4HEADER) ||
	    ch.bcSize == sizeof(BITMAPV5HEADER)) {
		memcpy(&ih, &ch, sizeof(ch));
		n = fread(((char *) &ih) + sizeof(ch),
		    ih.bV5Size - sizeof(ch), 1, fp);
		if (n == 0) {
			// L"bad info header\n"
			return NULL;
		}
	} else {
		// L"bad info header\n"
		return NULL;
	}

	if (ih.bV5Size == sizeof(BITMAPINFOHEADER) &&
	    ih.bV5Compression == BI_BITFIELDS)
	{
		/* Read 3 color masks. */
		n = fread(((char *) &ih) + sizeof(BITMAPINFOHEADER),
		    sizeof(ih.bV5BlueMask) * 3, 1, fp);
		if (n == 0) {
			// L"bad info header\n"
			return NULL;
		}
	}

	return bmp_load_on_type(&ih, fp);
}

/**
 * Loads a .bmp file into a 'struct bmp'.
 *
 * Allowed formats are: 1 bpp, 4 bpp, 4 bpp rle, 8 bpp, 8 bpp rle, 16 bpp,
 * 24 bpp, 32 bpp.
 *
 * JPEG or PNG embedded formats not supported.
 *
 * Opens fname using 'open_file()'. The length of 'fname' must be less
 * than OPEN_FILE_MAX_PATH_LEN.
 */
struct bmp *load_bmp(const char *fname)
{
	FILE *fp;
	struct bmp *im;

	fp = fopen(fname, "rb");
	if (fp == NULL) {
		// L"file not found\n"
		return NULL;
	}

	im = load_bmp_fp(fp);

	fclose(fp);
	return im;
}

void free_bmp(struct bmp *bmp, int free_pal)
{
	if (bmp != NULL) {
		if (bmp->data != NULL) {
			free(bmp->data);
			bmp->data = NULL;
		}
		if (free_pal && bmp->pal != NULL) {
			free(bmp->pal);
			bmp->pal = NULL;
		}
		free(bmp);
	}
}


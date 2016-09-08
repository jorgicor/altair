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

#include <stdlib.h>
#include <stdio.h>

// Generates a Z80 asembler file called rndnums.asm with 256 unique 8 bit
// numbers in a random sequence.
int main(void)
{
	unsigned char values[256];
	char marks[256];
	unsigned char a, b;
	int i, j;
	unsigned char p, q;
	FILE *fp;

	fp = fopen("rndnums.asm", "w");
	if (fp == NULL)
	{
		fprintf(stderr, "Couldn't create 'rndnums.asm'\n");
		return EXIT_FAILURE;
	}

	a = 0;
	for (i = 0; i < 256; i++) {
		marks[i] = 0;
		b = a;
		a += a;
		a += a;
		a += b;
		a++;
		values[i] = a;
		// printf("%d ", a);
	}

	for (i = 0; i < 256; i++) {
		for (j = 0; j < 256; j++) {
			if (values[j] == (unsigned char) i) {
				marks[i] = 1;
				break;
			}
		}
	}


	for (i = 0; i < 256; i++) {
		if (marks[i] == 0) {
			printf("value %d not found\n", i);
		}
	}

	p = 0;
	q = 1;
	for (i = 0; i < 256; i++) {
		unsigned char tmp;

		tmp = values[p];
		values[p] = values[q];
		values[q] = tmp;
		p++;
		q = tmp;
	}

	//printf("\n");
	//for (i = 0; i < 256; i++) {
	//	printf("%d ", (values[i] & 15));
	//}


	fprintf(fp, "randt");
	for (i = 0; i < 256; i++) {
		if ((i & 15) == 0)
			fprintf(fp, "\n\t.db ");
		else
			fprintf(fp, ",");
		fprintf(fp, "%d", values[i]);
	}
	fclose(fp);

	return 0;
}

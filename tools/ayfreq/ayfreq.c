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

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

/* Calculates the periods for the AY-3-8912 tone registers.
 * The formula is ay_chip_hz / (freq * 16) as the chips counts 16 first then
 * counts the period passed.
 *
 * The CPC AY runs at 1MHz.
 * The ZX Spectrum AY runs at 1,7734 MHz.

 * Each note in the western 12 equal temperament is at a factor of 2^(1/12)
 * from the previous. A4 is 440Hz. The frequency one octave note is exactly
 * the double of the previous octave note frequency.
 */

#define NELEMS(a) (sizeof(a) / sizeof(a[0]))

static const char *s_help[] = {
"ayfreq freq",
"",
"	Given a 'freq' in Hz, which is the frequency at which the AY-3-8912",
"works for a given computer, calculates the period for each musical note that",
"can be passed to the chip tone registers, and generates it on the console.",
"",
"For the CPC, pass 1000000. For the ZX Spectrum, pass 1773400.",
};

static void print_help()
{
	int i;

	for (i = 0; i < NELEMS(s_help); i++)
	{
		printf("%s\n", s_help[i]);
	}
}

static const char* notes[] = {
	"A", "AS", "B", "C", "CS", "D", "DS", "E", "F", "FS", "G", "GS"
};

int main (int argc, const char *argv[])
{
	double freq;
	double interval;
	double afreq;
	int note;
	int octave;
	int val, lastval;
	int hz;
	char *p;

	if (argc != 2)
	{
		print_help();
		return EXIT_FAILURE;
	}

	hz = strtol(argv[1], &p, 0); 
	if (p == argv[1] || hz < 0)
	{
		fprintf(stderr, "Bad input Hz.");
		print_help();
		return EXIT_FAILURE;
	}

	interval = pow(2., 1 / 12.);

	note = 0;
	octave = 0;
	afreq = 27.50;	/* A0 */
	freq = afreq;
	lastval = -1;
	for (;;) {
		/* we are rounding, this is round(hz / (freq * 16)) */
		val = (int) (0.5 + hz / (freq * 16));
		if (val <= 0) {
			break;
		}
		lastval = val;
		printf("Y%s%d\t.equ %d\n", notes[note], octave, val);
		freq *= interval;
		note++;
		if (note == 3) {
			octave++;
		} else if (note == 12) {
			note = 0;
			afreq *= 2;
			freq = afreq;
		}
	}
	
	return 0;
}

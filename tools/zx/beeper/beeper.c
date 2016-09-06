/*
The MIT License (MIT)

Copyright (c) 2014 inmensabolademanteca@gmail.com

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

/* Calculates the periods for the ZX Spectrum beeper routine.
 * The formula is 437500 / note_freq - 29.5 (the ROM BEEP routine
 * uses 437500 / note_freq - 30.125).
 *
 * Each note in the western 12 equal temperament is at a factor of 2^(1/12)
 * from the previous. A4 is 440Hz. The frequency one octave note is exactly
 * the double of the previous octave note frequency.
 */

static const char* notes[] = {
	"A", "AS", "B", "C", "CS", "D", "DS", "E", "F", "FS", "G", "GS"
};

int main(void)
{
	double freq;
	double interval;
	double afreq;
	int note;
	int octave;
	int val, lastval;

	interval = pow(2., 1 / 12.);

	note = 0;
	octave = 0;
	afreq = 27.50;	/* A0 */
	freq = afreq;
	lastval = -1;
	for (;;) {
		/* we are rounding, this is round(437500 / freq - 29.5) =
		 * floor(437500 / freq - 29.5 + 0.5)
		 */
		val = (int) (437500. / freq - 29.);
		if (val == lastval || val <= 0)	{
			break;
		}
		lastval = val;
		printf("%s%d\t.equ %d\n", notes[note], octave, val);
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
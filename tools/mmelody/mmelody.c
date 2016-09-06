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

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#define NELEMS(a) (sizeof(a) / sizeof(a[0]))

#define MAX_OCTAVE	16

static int get_note_num(int note)
{
	switch (note)
	{
	case 'C': return 0;
	case 'D': return 2;
	case 'E': return 4;
	case 'F': return 5;
	case 'G': return 7;
	case 'A': return 9;
	case 'B': return 11;
	default: return -1;
	}
}

static int code_note(int sharp, int note, int octave)
{
	note = get_note_num(note) + sharp;
	if (note == 12)
	{
		octave++;
		note = 0;
	}	
	return note + octave * 12;
}

static int decode_octave(int note)
{
	return note / 12;
}

static int decode_note(int note)
{
	return note % 12;
}

/* Returns a coded note. Coded notes can be compared for pitch.
 * Returns -1 on EOF.
 */
static int get_note(FILE *fp)
{
	int note, sharp, octave, digit, c;

	note = EOF;
	for (;;) {
		c = fgetc(fp);
		if (c == EOF)
			return -1;
		if (note == EOF) {
			if (get_note_num(c) != -1) {
				note = c;
				sharp = -1;
				octave = 0;
				digit = 0;
			}
		} else if (sharp == -1) {
			if (c == 'S') {
				sharp = 1;
			} else if (isdigit(c)) {
				digit = 1;
				sharp = 0;
				ungetc(c, fp);
			} else {
				note = EOF;
			}
		} else if (isdigit(c)) {
			digit = 1;
			octave = octave * 10 + (c - '0');
		} else {
			if (!digit) {
				note = EOF;
			} else {
				ungetc(c, fp);
				if (octave > MAX_OCTAVE || octave < 0)
					octave = MAX_OCTAVE;
				return code_note(sharp, note, octave);
			}
		}
	}
}

static const char* notes[] = {
	"C", "CS", "D", "DS", "E", "F", "FS", "G", "GS", "A", "AS", "B"
};


/* note distance in semitones between notea and noteb. */
static int note_distance(int notea, int noteb)
{
	return noteb - notea;
}

static void print_note(int cnote)
{
	printf("%s", notes[decode_note(cnote)]);
	printf("%d", decode_octave(cnote));
}

static void lower_song(FILE *fp, int semitones, int clamp_note)
{
	int note, sharp, octave, digit, cnote, c;
	int a9 = code_note(0, 'A', 9);

	note = EOF;
	for (;;) {
		c = fgetc(fp);
		if (c == EOF)
			return;
		if (note == EOF) {
			if (get_note_num(c) != -1) {
				note = c;
				sharp = -1;
				octave = 0;
				digit = 0;
			} else
				putc(c, stdout);
		} else if (sharp == -1) {
			if (c == 'S') {
				sharp = 1;
			} else if (isdigit(c)) {
				digit = 1;
				sharp = 0;
				ungetc(c, fp);
			} else {
				putc(note, stdout);
				putc(c, stdout);
				note = EOF;
			}
		} else if (isdigit(c)) {
			digit = 1;
			octave = octave * 10 + (c - '0');
		} else {
			if (!digit) {
				putc(note, stdout);
				if (sharp)
				{
					putc('S', stdout);
				}				
			} else {
				if (octave > MAX_OCTAVE || octave < 0)
					octave = MAX_OCTAVE;
				cnote = code_note(sharp, note, octave);
				cnote -= semitones;
				if (cnote > clamp_note)
					cnote = clamp_note;
				print_note(cnote);
			}
			ungetc(c, fp);
			note = EOF;
		}
	}
}

enum {
	ZX,
	CPC,
};

static const char *s_help[] = {
"mmelody mode asmfile",
"",
"	'mode' is 'zx' or 'cpc'.",
"",
"	Takes 'asmfile' and takes all the notes it can find. Notes any text",
"that starts with a note name (ABCDEFG), an optional 'S' character for",
"one semitone up, and a octave number. Then the program finds the highest",
"and lowest pitch. Then, outputs to console the same asmfile, but all the",
"notes are changed to a lower pitch or higher pitch if the highest pitch",
"is too high or the lowest pitch is too low for the architecture. That is",
"all the song pitch is raised or lowered."
};

static void print_help()
{
	int i;

	for (i = 0; i < NELEMS(s_help); i++)
	{
		printf("%s\n", s_help[i]);
	}
}

int main (int argc, char *argv[])
{
	FILE *fp;
	int note, min_note, max_note;
	int clamp_note, a0, semitones;

	if (argc != 3) {
		fprintf(stderr, "Wrong number of arguments.");
		print_help();
		return EXIT_FAILURE;
	} else if (strcmp(argv[1], "zx") == 0)	{
		clamp_note = code_note(1, 'C', 9);
	} else if (strcmp(argv[1], "cpc") == 0) {
		clamp_note = code_note(1, 'G', 8);
	} else {
		fprintf(stderr, "Bad mode %s.", argv[1]);
		print_help();
		return EXIT_FAILURE;
	}

	if ((fp = fopen(argv[2], "r")) == NULL)
	{
		fprintf(stderr, "Couldn't open %s.", argv[2]);
		print_help();
		return EXIT_FAILURE;
	}

	min_note = INT_MAX;
	max_note = -1;
	for (;;) {
		note = get_note(fp);
		if (note == -1)
			break;

		if (note < min_note)
		{
			min_note = note;
		}
		if (note > max_note)
		{
			max_note = note;
		}
	}

	rewind(fp);

	a0 = code_note(0, 'A', 0);
	semitones = note_distance(clamp_note, max_note);
	if (semitones < 0)
		semitones = 0;

	if (min_note - semitones < a0) {
		semitones -= (a0 - (min_note - semitones)); 
	}

	printf("; max is ");
	print_note(max_note);
	printf("\n; lowering %d semitones\n\n", semitones);

	lower_song(fp, semitones, clamp_note);

	fclose(fp);
	
	return 0;
}

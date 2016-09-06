/*
* This file is part of LSTRD.
*
* Copyright (C) 2003 Pavel Cejka <pavel.cejka at kapsa.club.cz>
*
* Modifications (C) 2015 ub880d <ub880d@users.sf.net> (mainly for pedantic compile)
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or (at
* your option) any later version.
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
* USA
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "trdos_structure.h"

#define VERSION			"0.5b beta"

void create (char *filename, char *diskname, int diskformatcode)
{
	int i;
	trdos_sector empty_sector;
	trdos_track track;
	int number_of_tracks;
	FILE *f;

	// inicializace tracku
	for (i = 0; i < SEC_SIZE; i++) empty_sector.byte[i] = 0;
	for (i = 0; i < 16; i++) track.sector[i] = empty_sector;

	// tvorba 8. sektoru èíslo 7
/*	track.sector[INFO_SEC].byte[OFFSET_FIRSTSECTOR] = 0;		// není potøeba zapisovat*/
	track.sector[INFO_SEC].byte[OFFSET_FIRSTTRACK] = 1;
	track.sector[INFO_SEC].byte[OFFSET_DISKFORMAT] = diskformatcode;
	switch (diskformatcode)
	{
		case 22: // 80DS
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] = 240;
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1] = 9;
			number_of_tracks = 80*2-1;
			break;
		case 23: // 40DS
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] = 240;
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1] = 4;
			number_of_tracks = 40*2-1;
			break;
		case 24: // 80SS
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] = 240;
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1] = 4;
			number_of_tracks = 80-1;
			break;
		case 25: // 40SS
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] = 112;
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1] = 2;
			number_of_tracks = 40-1;
			break;
		default:
			printf ("ERROR: internal error, bad type od disk image format %i\n", diskformatcode);
			exit (-1);
			break;
	}
/*	track.sector[INFO_SEC].byte[OFFSET_FILES] = 0;		// není potøeba zapisovat*/
	track.sector[INFO_SEC].byte[OFFSET_TRDOSIDENT] = 16;
/*	track.sector[INFO_SEC].byte[OFFSET_PASSWORD] = 0;		// není potøeba zapisovat
	track.sector[INFO_SEC].byte[OFFSET_DELETEDFILES] = 0;		// není potøeba zapisovat*/
	i = 0;
	while ((diskname != NULL) && (diskname[i] != 0) && (i < 10))
	{
		track.sector[INFO_SEC].byte[OFFSET_DISKNAME+i] = diskname[i];
		i++;
	}
	
	// vytvoøit soubor a ohlásit chybu, kdy¾ se to nepovede
	f = fopen (filename, "w");
	if (f == NULL) 
	{
		printf ("ERROR: file open failed.\n");
		exit (-1);
	}
	// zapsat první track
	fwrite (&track, sizeof(trdos_track), 1, f);
	// vynulovat systémový sektor (u¾ nebude potøeba a promìnnou pro track pou¾iju jinak) a zapsat tracky pro data
	track.sector[INFO_SEC] = empty_sector;
	for (i = 0; i < number_of_tracks; i++) fwrite (&track, sizeof(trdos_track), 1, f);
	// zavøít soubor
	fclose (f);
}

void version ()
{
	printf ("%s \n", VERSION);
}

void help ()
{
	printf ("CREATETRD is simple utility for creating TRDOS disk empty image files.\n");
	printf ("Usage:   CREATETRD [OPTIONS] [CREATED FILENAME]\n");
	printf ("Example: createtrd -n MUJPOKUS -f 80DS mujpokus.trd\n");
	printf ("  -f, --format     disk format (40SS, 40DS, 80SS, 80DS)\n");
	printf ("  -n, --diskname   disk name long max. 10 characters (default name is empty)\n");
	printf ("  -h, --help       this text\n");
	printf ("  -v, --version    version\n");
}

int main(int argc, char *argv[])
{
	char *filename;
	char *diskname;
	int parsermode;
	int counter;
	int switches;
	int correct;
	int diskformatcode;

	switches = 1;		// poèet pøepínaèù
	parsermode = 0;		// 0 - ètení voleb (options), 1 - ètení formátu, 2 - ètení jména trdosové diskety (trdos floppy disk name)
	diskformatcode = 22;	// implicitnì 80DS
	diskname = NULL;
	for (counter = 1; counter < argc; counter++)
	{
//		printf ("++DEBUG++ %i ++ %s \n",counter, argv[counter]);
		correct=0;
		switch (parsermode)
		{
			case 2:
				if ((argv[counter][0]) != '-')
				{
					parsermode = 0;
					switches++;
					correct = 1;
					diskname = argv [counter];

				}
				if (correct == 0)
				{
					printf ("ERROR: Missing TRDOS diskname, option %s detected instead.\n", argv[counter]);
					help ();
					return (-1);
				}
			break;
			case 1:
				if (!strcmp(argv[counter],"80DS"))
				{
					parsermode = 0;
					diskformatcode = 22;
					switches++;
					correct = 1;
				}
				if (!strcmp(argv[counter],"40DS"))
				{
					parsermode = 0;
					diskformatcode = 23;
					switches++;
					correct = 1;
				}
				if (!strcmp(argv[counter],"80SS"))
				{
					parsermode = 0;
					diskformatcode = 24;
					switches++;
					correct = 1;
				}
				if (!strcmp(argv[counter],"40SS"))
				{
					parsermode = 0;
					diskformatcode = 25;
					switches++;
					correct = 1;
				}
				if (correct == 0)
				{
					printf ("ERROR: Unknown format argument \"%s\". Please use 40SS, 80SS, 40DS or 80DD.\n", argv[counter]);
					help ();
					return (-1);
				}
			break;
			case 0:
				if (!strcmp(argv[counter],"-h") || (!strcmp(argv[counter],"--help")))
				{
	    				help ();
					switches++;
					correct = 1;
					return (0);
				}
				if (!strcmp(argv[counter],"-v") || (!strcmp(argv[counter],"--version")))
				{
					version ();
					switches++;
					correct = 1;
					return (0);
				}
				if (!strcmp(argv[counter],"-f") || (!strcmp(argv[counter],"--format")))
				{
					parsermode = 1;
					switches++;
					correct = 1;
				}
				if (!strcmp(argv[counter],"-n") || (!strcmp(argv[counter],"--diskname")))
				{
					parsermode = 2;
					switches++;
					correct = 1;
				}
				if ((correct == 0) && (counter != (argc-1)))
				{
					// poslední parametr bude jméno diskety
					printf ("ERROR: unknown parametr - \"%s\"\n", argv[counter]);
					help ();
					return (-1);
				}
			break;
			default:
				printf ("ERROR: unknown parsermode - %d\n", parsermode);
			break;
		}
	}

	filename = argv[argc-1];

	if (switches != argc-1)
	{
		printf ("ERROR: Diskname missing.\n");
		return (-1);
	}
	else
	{
		create (filename, diskname, diskformatcode);
		return (0);
	}
}

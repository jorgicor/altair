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

#define VERSION			"0.2beta"

// Hobeta head offsets - nelze jinak, proto¾e kompiler GCC zarovnává na 2 byty a to se kvùli 9 bytovému názvu silnì nehodí
#define HH_FILENAME	0
#define HH_EXTENSION	8
#define HH_ADDRESS	9
#define HH_LENGTH	11
#define HH_TR		13
#define HH_SECTORS	14
#define HH_CRC		15

typedef struct {
	unsigned char byte[17];
} hobetahead;

// globální parametry
int	verbose = 0;
int	force = 0;

/*unsigned int CheckSum;
int i;

CheckSum=0;
for (i=0; i<=14; CheckSum = CheckSum + (header.head[i] * 257) + i, i++);
header.tr_head.tr_crc = CheckSum;*/

int convert (char* source_filename, char* target_filename)
{
//	unsigned char directory [9*SEC_SIZE];	//not used
	hobetahead header;
//	unsigned char memory [65536];	//not used
	FILE *inputfile;
	FILE *outputfile;
	int i;//,c; //not used
	trdos_sector sector;
	trdos_track track;
	int sector_number;
	int track_number;
	int freesectors;
	int directory_offset;
	int fatal_error_found;
	int dir_sector;
	
	inputfile = fopen (source_filename,"r");
	if (inputfile == NULL)
	{	
		printf ("Error: Can't open input file %s.\n",source_filename);
		exit (-1);
	}
	
	outputfile = fopen (target_filename,"ra+");
	if (outputfile == NULL)
	{	
		printf ("Error: Can't open output file %s.\n",target_filename);
		exit (-1);
	}

	// pøeèti hlavièku souboru formátu "hobeta"
	if (fread (&header, sizeof (hobetahead), 1, inputfile) == 1)
	{	
		// pøeèti direktoráø souboru formátu "trdos image"
		if (fread (&track, sizeof (trdos_track), 1, outputfile) == 1)
		{	
			// Zkontroluj správnost souborù
			fatal_error_found = 0;
			if ((track.sector[INFO_SEC].byte[OFFSET_TRDOSIDENT] != 16) && (!force))
			{
				printf ("Missing TRDOS identification in target file, you can try -f (force) parameter, but only if you know what you are doing. You are warned.\n");
				fatal_error_found = 1;
			}
			if (0  && (!force)) // doplnit!!!
			{
				printf ("Wrong CRC in source Hobeta file.\n");
				fatal_error_found = 1;
			}
			if (track.sector[INFO_SEC].byte[OFFSET_FILES] == 128)
			{
				printf ("Directory is full, no space to write any file.\n");
				fatal_error_found = 1;
			}
			if ((track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] == 0) && (track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1] == 0))
			{
				printf ("Disk is full, no space to write any file.\n");
				fatal_error_found = 1;
			}
			if (header.byte[HH_SECTORS] > (track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] + track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1]*256))
			{
				printf ("Hobeta's file is bigger than free space.\n");
				fatal_error_found = 1;
			}
			if (fatal_error_found)
			{
				fclose (inputfile);
				fclose (outputfile);
				exit (-1);
			}
			// Vypi¹ parametry - pokud verbose
			if (verbose)
			{
				// source
				printf ("Hobeta file: %s\n", source_filename);
				for (i = 0; i < 8; i++) printf ("%c",header.byte[HH_FILENAME+i]);
				printf (".%c %u, %u, ",header.byte[HH_EXTENSION], header.byte[HH_ADDRESS]+header.byte[HH_ADDRESS+1]*256, header.byte[HH_LENGTH]+header.byte[HH_LENGTH+1]*256);
				printf ("%u (CRC %u)\n", header.byte[HH_SECTORS], header.byte[HH_CRC]+header.byte[HH_CRC+1]*256);
				// target
				printf ("TRDOS image: %s\n", target_filename);
				printf ("Free %u sectors, Files %u, Deleted %u\n",track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1]*256+track.sector[INFO_SEC].byte[OFFSET_FREESECTORS], track.sector[INFO_SEC].byte[OFFSET_FILES], track.sector[INFO_SEC].byte[OFFSET_DELETEDFILES]);
			}
			// DATA SOUBORU
			// najít první volný sektor a stopu, zaseekovat v cílovém souboru a plnit jeden sektor za druhým dokud jsou 
			// data na vstupu
			// soubor hobeta je v¾dy dlouhý 256*n+17 bytù, kde n se mìní podle poètu sektorù na TRDOSové disketì, které 
			// soubor obsazoval/obsadí => je mo¾no naèítat a zapisovat pøímo po sektorech
			sector_number = track.sector[INFO_SEC].byte[OFFSET_FIRSTSECTOR];
			track_number = track.sector[INFO_SEC].byte[OFFSET_FIRSTTRACK];
			freesectors = track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1]*256+track.sector[INFO_SEC].byte[OFFSET_FREESECTORS];
			fseek (inputfile, 17, SEEK_SET);
			fseek (outputfile, sector_number*SEC_SIZE+track_number*TRK_SIZE*SEC_SIZE, SEEK_SET);
			while (fread (&sector, sizeof (trdos_sector), 1, inputfile) == 1)
			{
				if (verbose) printf ("[%u,%u] ", track_number, sector_number);
				sector_number++;
				if (sector_number>15)
				{
					sector_number = 0;
					track_number++;
				}
				freesectors--;
				if (freesectors < 0)
				{
					printf ("Fatal error, out of disk space.\n");
					fclose (inputfile);
					fclose (outputfile);
					exit (-1);
				}
				// DEBUG for (i = 0; i < 16; i++) printf ("%u ", sector.byte[i]); printf ("\n");
				// zapi¹ sektor (pøedpokládám, ¾e se vejde, proto¾e si to spoèítám a zkontroluju pøedem)
				if (fwrite (&sector, sizeof (trdos_sector), 1, outputfile) != 1)	// ZÁPIS
				{
					printf ("Sector writing in %s failed.\n", target_filename);
					fclose (inputfile);
					fclose (outputfile);
					exit (-1);
				}
			}
			// ADRESÁØ
			fseek (outputfile, 0, SEEK_SET);
			dir_sector = track.sector[INFO_SEC].byte[OFFSET_FILES] / 16;		// zjisti kam zapsat jméno souboru
			directory_offset = (track.sector[INFO_SEC].byte[OFFSET_FILES] % 16)*16;	// vèetnì polo¾ky v sektoru
			// tvorba hlavièky souboru v adresáøi (pøenesu jméno+pøípona+adresa+délka - v¹e najednou, proto¾e to jde)
			for (i = 0; i < 13; i++) track.sector[dir_sector].byte[directory_offset+i] = header.byte[HH_FILENAME+i];
			track.sector[dir_sector].byte[directory_offset+13] = header.byte[HH_SECTORS];
			track.sector[dir_sector].byte[directory_offset+14] = track.sector[INFO_SEC].byte[OFFSET_FIRSTSECTOR];
			track.sector[dir_sector].byte[directory_offset+15] = track.sector[INFO_SEC].byte[OFFSET_FIRSTTRACK];
			// provedení potøebných zmìn v systémovém sektoru TRDOSu (9. sektor èíslo 8)
			if (verbose) printf ("\nNew first track and sector %u, %u\n", track_number, sector_number); // první volný sektor a track ...
			track.sector[INFO_SEC].byte[OFFSET_FIRSTSECTOR] = sector_number;		// zapi¹ èísla prvních volných sek. a tr.
			track.sector[INFO_SEC].byte[OFFSET_FIRSTTRACK] = track_number;
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS] = freesectors % 256;		// zapi¹ zbývající volné místo na disku
			track.sector[INFO_SEC].byte[OFFSET_FREESECTORS+1] = freesectors / 256;
			track.sector[INFO_SEC].byte[OFFSET_FILES]++;					// zvy¹ poèet souborù o právì zapsaný
			if (fwrite (&track, sizeof (trdos_track), 1, outputfile) != 1)		// ZÁPIS
			{
				printf ("Track writing in %s failed.\n", target_filename);
				fclose (inputfile);
				fclose (outputfile);
				exit (-1);
			}
			if (verbose) printf ("Free: %i\nO.K.\n", freesectors);
		}
		else
		{
			printf ("Error: Reading from file %s failed.\n",target_filename);
			fclose (inputfile);
			fclose (outputfile);
			exit (-1);
		}
	}
	else
	{
		printf ("Error: Reading from file %s failed.\n",source_filename);
		fclose (inputfile);
		exit (-1);
	}
	// data zkonvertována, kdyby nastala chyba skonèila by funkce døíve
	return 0;
}

void version ()
{
	printf ("%s \n", VERSION);
}

void help ()
{
	printf ("HOBETA2TRD is a special utility for copy HOBETA files to TRDOS disk image.\n");
	printf ("Usage: HOBETA [OPTIONS] [SOURCE] [TARGET]\n");
	printf ("[SOURCE] must be any hobeta file\n");
	printf ("[TARGET] must be TRDOS disk image\n");
	printf ("  -V, --verbose    increase verbosity level\n");
	printf ("  -f, --force      force\n");
	printf ("  -h, --help       this text\n");
	printf ("  -v, --version    version\n");
}

int main(int argc, char *argv[])
{
	char *source_filename;
	char *target_filename;
	int counter;
	int switches;
	int correct;

	// vstupní soubor je to co není jiným parametrem, výstupní soubor není
	// printf ("DEBUG: argc - %i\n", argc);

	switches = 1;
	for (counter=1; counter<argc; counter++)
	{
//		printf ("++ %i ++ %s \n",counter, argv[counter]);
		correct = 0;

		if (!strcmp(argv[counter], "-h") || (!strcmp(argv[counter], "--help")))
		{
			help ();
			switches++;
			correct = 1;
			return (0);
		}
		if (!strcmp(argv[counter], "-v") || (!strcmp(argv[counter], "--version")))
		{
			version ();
			switches++;
			correct = 1;
			return (0);
		}
		if (!strcmp(argv[counter], "-V") || (!strcmp(argv[counter], "--verbose")))
		{
			verbose = 1;
			switches++;
			correct = 1;
		}
		if (!strcmp(argv[counter], "-f") || (!strcmp(argv[counter], "--force")))
		{
			force = 1;
			switches++;
			correct = 1;
		}
		if ((correct==0) && !((counter==(argc-1)) || (counter==(argc-2))))
		{
			// poslední parametr jméno cíle
			// pøedposlední parametr jméno zdroje
			printf ("ERROR: unknown parametr - \"%s\"\n", argv[counter]);
			help ();
			return (-1);
		}
	}

	source_filename=argv[argc-2];
	target_filename=argv[argc-1];

	if (verbose) printf ("[SOURCE] %s -> [TARGET] %s \n", source_filename, target_filename);

	if (switches!=argc-2)
	{
		printf ("ERROR: Any filename is missing.\n");
		return (-1);
	}
	else
	{
		return (convert (source_filename, target_filename));
	}
}


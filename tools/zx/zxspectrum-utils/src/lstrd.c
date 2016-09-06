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
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include "trdos_structure.h"

#define VERSION			"1.0"

void printalignednumber (int number, int width, char *filler)
{
	int i,n;

	n = 1;
	for (i = 0; i < width; i++)
	{
		if ((number < n) && !((i == 0) && (number == 0))) printf (filler);
		n *= 10;
	}
	printf ("%i",number);
}

int lstrdos (char *filename, int listmode)
{
	unsigned char directory [9*SEC_SIZE];
	int inputfile;
	char *trdosfilename;
	char *trdosdiskname;
	char *trdospassword;
	int freesectors;
	int i;
//	char *diskformat; //not used yet
	int trdosfile;
	
	inputfile=open (filename,0);
	if (!inputfile)
	{	
		printf ("Error: Can't open input file %s.\n",filename);
		close (inputfile);
		return (-1);
	}
	
	
	if (read (inputfile, directory,9*SEC_SIZE)==9*SEC_SIZE)
	{	
		// soubor otevøen a naèten v pamìti, teï by nemìlo být mo¾né, aby nastala chyba
		trdosdiskname=(char*)malloc (11);
		for (i=0; i<10; i++)
		{
		        trdosdiskname[i]=directory[INFO_SEC*SEC_SIZE + OFFSET_DISKNAME+i];
		}
		trdosdiskname[10]=0;

		trdospassword=(char*)malloc (9);
		for (i=0; i<7; i++)
		{
		        trdospassword[i]=directory[INFO_SEC*SEC_SIZE + OFFSET_PASSWORD+i];
		}
		trdospassword[9]=0;
		
		freesectors=directory[INFO_SEC*SEC_SIZE + OFFSET_FREESECTORS]+256*directory[INFO_SEC*SEC_SIZE + OFFSET_FREESECTORS+1];
		trdosfilename=(char*)malloc (8);
			
		// Výpis
		switch (listmode)
		{
			case 2:
				// re¾im EXTRA SHORT (haven't equivalent in real TRDOS, but may be usefull for
				//  *nix operating systems for batch operations with files
				for (trdosfile=0; trdosfile<directory[INFO_SEC*SEC_SIZE + OFFSET_FILES]; trdosfile++)
				{
					// jméno souboru
					for (i=0; i<8; i++)
					{
						trdosfilename[i]=directory[i+16*trdosfile];
					}
					trdosfilename[8]=0;
					printf ("%s.%c\n",trdosfilename,directory[trdosfile*16+8]);
				}
				break;
			case 1:
				// re¾im CAT
				printf ("Title:  %s\n",trdosdiskname);
				printf ("%i File(s)\n",directory[INFO_SEC*SEC_SIZE + OFFSET_FILES]);
				printf ("%i Deleted File(s)\n\n",directory[INFO_SEC*SEC_SIZE + OFFSET_DELETEDFILES]);

				int lichy;
				lichy=0;

				for (trdosfile=0; trdosfile<directory[INFO_SEC*SEC_SIZE + OFFSET_FILES]; trdosfile++)
				{
					// jméno souboru
					for (i=0; i<8; i++)
					{
						trdosfilename[i]=directory[i+16*trdosfile];
					}
					trdosfilename[8]=0;
					printf ("%s <%c> ",trdosfilename,directory[trdosfile*16+8]);
					// délka v sektorech
					printalignednumber (directory[trdosfile*16+13], 3, " ");
					
					if (lichy==1) { printf ("\n"); lichy=0; } else { printf ("  "); lichy=1;}
				}

				if (lichy==1) printf ("\n");
				printf ("\n%i Free\n",directory[INFO_SEC*SEC_SIZE + OFFSET_FREESECTORS]+256*directory[INFO_SEC*SEC_SIZE + OFFSET_FREESECTORS+1]);
				break;
			case 0:
			default:
				// re¾im LIST
				printf ("Diskname: %s\n",trdosdiskname);
    				printf ("Password: %s\n",trdospassword);
				switch (directory[INFO_SEC*SEC_SIZE + OFFSET_DISKFORMAT])
				{
		    			case 22:
						printf("80 Tracks, Double Side, capacity 640kB\n");
		    				break;
		    			case 23:
	    		    			printf("40 Tracks, Double Side, capacity 320kB\n");
		    				break;
		    			case 24:
						printf("80 Tracks, Single Side, capacity 320kB\n");
		    				break;
		    			case 25:
						printf("40 Tracks, Single Side, capacity 160kB\n");
		    				break;
					default:
						printf("UNKNOWN FORMAT!\n");
						break;
				}
				printf ("Number of files/deleted: %i/%i\n", directory[INFO_SEC*SEC_SIZE + OFFSET_FILES], directory[INFO_SEC*SEC_SIZE + OFFSET_DELETEDFILES]);
				printf ("Free sectors/bytes:      %i/%i\n", freesectors, freesectors*256);
				printf ("First free sector/track: %i/%i\n\n", directory[INFO_SEC*SEC_SIZE + OFFSET_FIRSTSECTOR], directory[INFO_SEC*SEC_SIZE + OFFSET_FIRSTTRACK]);
				
				printf ("FILENAME      TYPE         SECTORS ADDRESS LENGTH TRACK SECTOR \n");
				printf ("--------------------------------------------------------------\n");
				for (trdosfile=0; trdosfile<directory[INFO_SEC*SEC_SIZE + OFFSET_FILES]; trdosfile++)
				{
					// jméno souboru
					for (i=0; i<8; i++)
					{
						trdosfilename[i]=directory[i+16*trdosfile];
					}
					trdosfilename[8]=0;
					printf ("%s <%c>  ",trdosfilename,directory[trdosfile*16+8]);
					// typ souboru
					switch (directory[trdosfile*16+8])
					{
						case 'b':
						case 'B':
							printf ("BASIC PROGRAM");
							break;
						case 'c':
						case 'C':
							printf ("CODE (BYTES) ");
							break;
						case 'd':
						case 'D':
							printf ("DATA         ");
							break;
						case 'F':
							printf ("VPL ANIMATION");
							break;
						case 'G':
							printf ("CYGNUS PLUGIN");
							break;
						case 'M':
							printf ("SOUNDTRACKER ");
							break;
						case '#':
							printf ("STREAM       ");
							break;
						default:
							printf ("UNKNOWN      ");
							break;
					}
					// délka v sektorech
					printalignednumber (directory[trdosfile*16+13], 5, " ");
					printf ("  ");
					switch (directory[trdosfile*16+8])
					{
						case 'b':
						case 'B':
							// délka basicu
							printalignednumber (directory[trdosfile*16+11]+256*directory[trdosfile*16+12], 6, " ");
							// délka basicu bez promìnných
							printalignednumber (directory[trdosfile*16+9]+256*directory[trdosfile*16+10], 7, " ");
							break;
						default:
							// adresa kam se soubor nahraje do RAM, není-li explicitnì urèeno jinak
							printalignednumber (directory[trdosfile*16+9]+256*directory[trdosfile*16+10], 6, " ");
							// délka v bytech
							printalignednumber (directory[trdosfile*16+11]+256*directory[trdosfile*16+12], 7, " ");
							break;
					}
					printf ("   ");
					// první stopa zabraná souborem
					printalignednumber (directory[trdosfile*16+15], 3, " ");
					printf ("    ");
					// první sektor zabraný souborem
					printalignednumber (directory[trdosfile*16+14], 3, " ");
					printf ("\n");
				}
				break;
		}
	}
	else
	{
		printf ("Error: Reading from file %s failed.\n",filename);
		close (inputfile);
		return (-1);
	}
	close (inputfile);
	return (0);
}

void version ()
{
	printf ("%s \n", VERSION);
}

void help ()
{
	printf ("LSTRD is a special utility for examine TR-DOS image files.\n");
	printf ("Usage: lstrd [OPTIONS]... [FILENAME]...\n");
	printf ("If the filename missing or any option is incorrect, this help will printed.\n");
	printf ("  -c, --cat     use a short listing format, same as command CAT in original TRDOS\n");
	printf ("  -h, --help    display this help and exit\n");
	printf ("  -l, --list    use a long listing format, similar to command LIST in original TRDOS\n");
	printf ("  -v, --version    version\n");
}

int main(int argc, char *argv[])
{
	int counter;
	int listmode=0;
	char *filename;
	int switches;
	int correct;

	// vstupní soubor je to co není jiným parametrem, výstupní soubor není
	// printf ("DEBUG: argc - %i\n", argc);

	switches=1;
	for (counter=1; counter<argc; counter++)
	{
//		printf ("++ %i ++ %s \n",counter, argv[counter]);
		correct=0;
		
		if (!strcmp(argv[counter],"-h") || (!strcmp(argv[counter],"--help")))
		{
			help ();
			switches++;
			correct=1;
			return (0);
		}
		if (!strcmp(argv[counter],"-v") || (!strcmp(argv[counter],"--version")))
		{
			version ();
			switches++;
			correct=1;
			return (0);
		}
		if (!strcmp(argv[counter],"-l") || (!strcmp(argv[counter],"--list")))
		{
			listmode=0;
			switches++;
			correct=1;
		}
		if (!strcmp(argv[counter],"-c") || (!strcmp(argv[counter],"--cat")))
		{
			listmode=1;
			switches++;
			correct=1;
		}
		if (!strcmp(argv[counter],"-s") || (!strcmp(argv[counter],"--short")))
		{
			listmode=2;
			switches++;
			correct=1;
		}
		if ((correct==0) && (counter!=(argc-1)))
		{
			// nepochopitelný parametr je tolerován jen jako poslední, to toti¾ musí být
			// jméno souboru, jestli je platné, to se uká¾e pozdìji, pokud by byl nepochopitelný 
			// parametr nalezen døíve ne¾ na posledním místì, bude zobrazena nápovìda
			printf ("ERROR: incorrect parametr - \"%s\"\n", argv[counter]);
			printf ("Hint: Filename must be last parameter.\n");
			help ();
			return (-1);
		}
	}

	filename=argv[argc-1];

	// printf ("DEBUG: switches - %i \n", switches);

	if (switches!=argc-1)
	{
		printf ("ERROR: Filename missing.\n");
		return (-1);
	}
	else
	{
		lstrdos (filename, listmode);
		return (0);
	}
}

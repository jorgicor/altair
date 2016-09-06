/* This file is part of breplace.
 *
 * breplace is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * breplace is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with epocemx; see the file COPYING.  If not, write to
 * the Free Software Foundation, 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <stdio.h>

#define PRGAUTHOR "Poke aka Petr Petyovsky 2006"
#define PRGNAME   "breplace"
#define PRGVER    "0.03"

#define BUFFER_SIZE 2048 /* size of static array of char used for block file access */

int verbose = 0; /* if set verbose mode enabled */
int store = 0; /* if set store original content of replaced bytes */

int FileSeek(FILE *afile, char *aname, unsigned long apos)
	{
	if(fseek(afile, apos, SEEK_SET))
		{
		fprintf(stderr, PRGNAME":%s:%#010lx: error: File seek failed.\n", aname, apos);
		return(0); /* File Seek failed */
		}
	if((unsigned long)ftell(afile) != apos)
		{
		fprintf(stderr, PRGNAME":%s:%#010lx: error: File seek failed.\n", aname, apos);
		return(0); /* File Seek failed */
		}
	return(1);
	}

void DisplayInfo(void)
	{
	printf(
		"GNU Binary replace ver."PRGVER" by: "PRGAUTHOR"\n\n"
		"Usage: "PRGNAME" [-sOrig_file][-v][-h][-L] position patch_file patched_file\n"
		"Options:\n"
		"  -s\tStore original content of replaced bytes to the Orig_file\n"
		"  -v\tMore output (be verbose)\n" 
		"  -h\tThis help text, then exit\n"
		"  -L\tDisplay software license, then exit\n"
		"\n"
		"Position can be in the hexadecimal(0x12) or decimal(18) base."
		"\n"
		"Report bugs to <pety@cis.vutbr.cz>.\n"
		);
	}

void DisplayLicense(void)
	{
	printf(
PRGNAME" ver."PRGVER", build ("__DATE__","__TIME__").\n"
"   Author: "PRGAUTHOR".\n"
"   This program is free software; you can redistribute it and/or modify\n"
"   it under the terms of the GNU General Public License as published by\n"
"   the Free Software Foundation; either version 2, or (at your option)\n"
"   any later version.\n"
"\n");
	printf(
"   This program is distributed in the hope that it will be useful,\n"
"   but WITHOUT ANY WARRANTY; without even the implied warranty of\n"
"   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n"
"   GNU General Public License for more details.\n"
"\n"
"   You should have received a copy of the GNU General Public License\n"
"   along with this program; if not, write to the Free Software\n"
"   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.\n"
	);
	}

int main(int argn, char *argv[])
	{
	FILE *fpatch, *fdst, *fstore = NULL;
	int arg;
	unsigned long pos = 0, tmppos = 0;
	char *namestore = NULL;
	char buffer[BUFFER_SIZE];
	char storebuffer[BUFFER_SIZE];
	int readcnt, storereadcnt;
	int err_p = 0, err_f = 0, err_s = 0;

	if(argn < 2) 
		{
		DisplayInfo();
		return(1);
		}
	for(arg=1; arg < argn; arg++)
		{
		if(argv[arg][0] != '-') 
			break;
		switch(argv[arg][1])
			{
			case('s'):
				store = 1;
				namestore = argv[arg]+2;
				if((fstore=fopen(namestore,"wb")) == NULL)
					{
					store = 0;
					fprintf(stderr, PRGNAME": error: Cannot open store file: %s !\n", namestore);
					}
			break;
			case('v'):
				verbose = 1;
			break;
			case('h'):
				DisplayInfo();
				return(0);
			case('L'):
				DisplayLicense();
				return(0);
			default:
				printf("Unknown option switch: %s\n",argv[arg]);
				return(2);
			}
		}
	if(arg > (argn-3))
		{
		DisplayInfo();
		return(1);
		}

	if((sscanf(argv[arg],"0x%lx",&pos)) != 1)
		if((sscanf(argv[arg],"%lu",&pos)) != 1)
			{
			fprintf(stderr, PRGNAME": error: Parameter: %s must be number constant!\n", argv[arg]);
			return(2); /* File not found */
			}

	if((fpatch=fopen(argv[arg+1],"rb")) == NULL)
		{
		if(store) fclose(fstore);
		fprintf(stderr, PRGNAME": error: Cannot open patch file: %s !\n", argv[arg+1]);
		return(3); /* File not found */
		}

	if((fdst=fopen(argv[arg+2],"rb+")) == NULL)
		{
		fprintf(stderr, PRGNAME": error: Cannot open file: %s !\n", argv[arg+2]);
		fclose(fpatch);
		if(store) fclose(fstore);
		return(4); /* File not found */
		}

	if(verbose) 
		printf("%s <= %s:\n",argv[arg+2], argv[arg+1]);

	if(!FileSeek(fdst, argv[arg+2], pos) )
		{
		fclose(fdst);
		fclose(fpatch);
		if(store) fclose(fstore);
		return(5); /* File Seek failed */
		}

	while((readcnt = fread(buffer, 1, BUFFER_SIZE, fpatch)) != 0)
		{
		if(store)
			{
			tmppos = (unsigned long)ftell(fdst);
			storereadcnt = fread(storebuffer, 1, readcnt, fdst);
			if(fwrite(storebuffer, 1, storereadcnt, fstore) != storereadcnt)
				{
				fprintf(stderr, PRGNAME":warning: Cannot write to the store file: %s !\n", namestore);
				err_s = 1;
				break;
				}
			if(!FileSeek(fdst, argv[arg+2], tmppos) )
				{
				err_p = 1;
				break;
				}
			}
			
		if(fwrite(buffer, 1, readcnt, fdst) != readcnt)
			{
			fprintf(stderr, PRGNAME":warning: Cannot write to the patched file: %s !\n", argv[arg+2]);
			err_p = 1;
			break;
			}
		} /* while */

	if(verbose) 
		{
		tmppos = ftell(fdst);
		printf("\t%#010lx - %#010lx replaced. Length: %#010lx.\n\n", 
			pos, tmppos, tmppos - pos);
		}

	if(fclose(fpatch))
		{
		fprintf(stderr, PRGNAME":warning: Cannot close patch file: %s !\n", argv[arg+1]);
		err_p = 1;
		}
	if(fclose(fdst))
		{
		fprintf(stderr, PRGNAME":warning: Cannot close output file: %s !\n", argv[arg+2]);
		err_f = 1;
		}
	if(store)
		if(fclose(fstore))
			{
			fprintf(stderr, PRGNAME":warning: Cannot close store file!\n");
			err_s = 1;
			}

	if(err_p || err_f || err_s)
		{
		fprintf(stderr, PRGNAME":error: Replace process failed.\n");
		return(6); /* Replace process failed */
		}
	printf(PRGNAME":Replacing process successfully done.\n");
	return(0);
	}

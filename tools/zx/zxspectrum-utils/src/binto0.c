/*****************************************************************
** 28.05.1996 // binto0 // Busy soft: BIN -> 000 konvertor 1.04 **
*****************************************************************/

#include<unistd.h>
#include<ctype.h>
#include<stdio.h>
#include<fcntl.h>
#include<stdlib.h>
#include<string.h>

#define lenbuf 16384
unsigned char body[lenbuf+2];

void pomoc(int x)
{
	printf(
			"\nZX Spectrum BIN=>000 format convertor 1.04 (c) 1996 Busy soft\n"
			"\nLinux port                                 (c) 2014 mike/zeroteam\n"
	      );
	if ((x<3) || (x>5))
	{
		printf(
			/***********  0      1         2    3    4 */
			"\n Usage: BINto0 input_file TYP [ADD [BAS]]\n"
			"   Converts binary input file into 000 file format\n"
			"   (makes 000 format header for plain binary input file).\n"
			"   Extension of output file will be three-digit number.\n"
			"   Meaning of numbers TYP,ADD,BAS for making header information:\n"
			"     TYP = type of file (0=basic,1=numb.data,2=char.data,3=bytes)\n"
			"     ADD = start line of basic, address of bytes, variable of data\n"
		      );
		printf(
			"     BAS = length of basic without variables (other types not need)\n"
			"   If you specified typ=4 then it makes headerless with flagbyte ADD.\n"
			"   Parameters ADD and BAS are optional. Not specified ADD is 32768\n"
			"   for TYP=basic,data,bytes and 255 for TYP=headerless. Not specified\n"
			"   BAS is total length of basic (without variables) and 32768 for other.\n\n"
		      );

		printf(
			"This program is free software; you can redistribute it and/or modify it under\n"
			"the terms of the GNU General Public License as published by the Free Software\n"
			"Foundation; either version 2 of the License, or (at your option) any later\n"
			"version.\n\n"
			"This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
			"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
			"PARTICULAR PURPOSE.\n"
			"See the GNU General Public License for more details (http://www.gnu.org/).\n"
		      );

		exit(1);
	}
}

/******** Zapis do suboru a test spravnosti zapisu ********/
int zapis(FILE *fd, unsigned char *buff, int kolko, char *subor)
{
	if (fwrite(buff, 1, kolko, fd) == kolko)
		return 0;
	else
	{
		printf("Error: Can't write into %s\n", subor);
		return 1;
	}
}

/******** Test spravnosti otvorenia suboru ****************/
void testopen(FILE *fd, char *subor)
{
	if (fd == NULL)
       	{
		printf("Error: Can't open %s\n", subor);
		exit(1);
	}
}

/******** Test spravnosti zatvorenia suboru ***************/
void testclose(int fd, char *subor)
{
	if (fd != 0)
	       printf("Error: Can't close %s\n", subor);
}

/********** Vytvori novy subor MENO.XYZ, xyz=000..999 *****/
FILE* novysubor (char *meno)
{
	int a;
	FILE *b = NULL;
	char *mm;
	mm = meno + strlen(meno);
	for (a = 0; a < 1000 && b == NULL; a++)
	{
		sprintf(mm, ".%03d", a);
		printf("nove meno: %s\n", meno);
		b = fopen(meno, "r");
		if (b == NULL) {
			b = fopen(meno, "wb");
		} else {
			fclose(b);
			b = NULL;
		}
	}
	if (a > 999)
		testopen(NULL, meno);
	return b;
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
	unsigned char parita, head[30];
	char zmaz, *mm, *nam, meno[100], subor[100];
	FILE *fd1, *fd2;
	int b, c;
	unsigned len, typ, add, bas = 32768u;
	long ll;

	pomoc(argc);

	nam = argv[1];
	typ = atoi(argv[2]);
	add = (typ == 4) ? 255 : 32768u;
	if (argc > 3)
		add = (unsigned)atoi(argv[3]);
	if (argc > 4)
		bas = (unsigned)atoi(argv[4]);

	if ((typ < 0) || (typ > 4))
	{
		puts("Type must be 0,1,2,3,4 !");
		exit(1);
	}

	strcpy(subor, nam);
	for(mm = subor + strlen(subor); (mm != subor) && (*mm != '\\') && (*mm != ':'); mm--);
	if ((*mm == '\\') || (*mm == ':'))
		mm++;
	strcpy(meno, mm);

	/* Zbavenie mena koncovky */
	mm = strchr(meno, '.');
	if (mm)
		*mm=0;
	/* ext=meno+strlen(meno);
	 * while((ext!=meno)&&(*ext!='.')&&(*ext!='\\')) ext--;
	 * if (*ext!='.') ext=meno+strlen(meno);
	 * *ext=0;
	 */

	/* Vytvorenie ZX nazvu  */
	strcpy((char*)head + 4, meno);
	strcat((char*)head + 4, "          ");

	testopen(fd1 = fopen(nam,"rb"), nam);
	fseek(fd1, 0, SEEK_END);
	ll = ftell(fd1);
	rewind(fd1);
	if (ll > 65535l)
	{
		printf("Error: File %s is too long.\n", nam);
		exit(1);
	}
	len = (unsigned) ll;

	fd2 = novysubor(meno);
	printf("Converting %s => %s (", nam, meno);

	if (typ == 4)
	{
		parita = add;
		printf("flagbyte=%u, length=%u)\n", parita, len);
		head[0] = 255;
		head[1] = parita;
		zmaz = zapis(fd2, head, 2, meno);
	}
	else
	{
		if (argc < 5 && typ == 0)
			bas=len;

		head[1] = 0;
		head[2] = 0;
		head[3] = typ;
		*((unsigned char*)(head + 14)) = len % 256;
		*((unsigned char*)(head + 15)) = len / 256;
		*((int*)(head + 16)) = add % 256;
		*((int*)(head + 17)) = add / 256;
		*((int*)(head + 18)) = bas % 256;
		*((int*)(head + 19)) = bas / 256;

		printf("%u:", head[3]);
		for(b = 4; b < 14; b++)
			if (head[b] < 32)
				putchar(4);
			else
				putchar(head[b]);
		printf(":%u:%u:%u)\n", *((unsigned*) (head + 14)) & 0xffff,
				*((unsigned*) (head + 16)) & 0xffff,
				*((unsigned*) (head + 18)) & 0xffff);
		parita = 0;
		for (b = 1; b < 20; b++)
			parita ^= head[b];
		head[20] = parita;
		parita = 255;
		head[21] = parita;
		zmaz = zapis(fd2, head + 1, 21, meno);
	}

	while(len)
	{
		c = len > lenbuf ? lenbuf : len;
		b = fread(body, 1, c, fd1);
		if (b < c)
		{
			printf("Error: Can't read from %s\n", nam);
			zmaz = 1;
			break;
		}
		zmaz |= zapis(fd2, body, b, meno);
		if (zmaz)
			break;
		for (b = 0; b < c; b++)
			parita ^= body[b];
		len -= c;
	}
	if (!zmaz)
		zmaz |= zapis(fd2, &parita, 1, meno);
	testclose(fclose(fd2), meno);
	testclose(fclose(fd1), nam);
	if (zmaz)
		unlink(meno);

	return 0;
}


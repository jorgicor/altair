/***********************************************************************
** 28.05.1996 // Dir0 // Busy soft: 000 analyzer [vypis obsahu] 1.04a **
***********************************************************************/

/*
This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.
See the GNU General Public License for more details (http://www.gnu.org/).
*/

#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include "endian-compat.h"

#define lenbuf 16384
typedef unsigned char byte;
byte buffer[lenbuf+2];

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum 000 format analyzer 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction (c) 2002 Tritol\n\n");

if(x<2){printf(
"  Usage: %s [-p] file1 [file2 ...] [> outfile.lst]\n"
"    Prints header information of input files in 000 format.\n"
"    Option: -p ... additional parity tester [not correcter]\n"
"    You can use wildcards '*' and '?' in filename parameters.\n"
"  If you use parameter \">outfile.lst\" for redirect standart output,\n"
"  all information will be printed to file outfile.lst as plain text.\n\n", name);

printf("This program is free software; you can redistribute it and/or modify it under\n"
"the terms of the GNU General Public License as published by the Free Software\n"
"Foundation; either version 2 of the License, or (at your option) any later\n"
"version.\n\n");

printf("This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
"PARTICULAR PURPOSE.\n"
"See the GNU General Public License for more details (http://www.gnu.org/).\n");

exit(1);}}

/******** Chybove hlasenia *******************************/
void uneof(void)
  {printf("Unexpected EOF\n");}

/******** Vypis hlavicky tabulky *************************/
void hlava(char head, char test)
{
  char *nic = "";
  char *sum = test ? "Sum " : nic;
  char *lin = test ? "--- " : nic;
  if (head) printf(
  "File         Type Name       Length Start Basic %sLength Flg %s\n",sum,sum);
  printf(
  "------------ ---- ---------- ------ ----- ----- %s------ --- %s\n",lin,lin);
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  byte parita,varx,vary;
  char testuj,match;
  int a,b,c,args;
  FILE *fdi;
  unsigned len,healen,bodlen;
  int ll,fillen,parerr,ffok,fftot,sumfil,sumhea,sumbod;
  char *mm,subor[100];
  struct stat filestat;

  pomoc(argc, argv[0]);

  args=1;testuj=0;
  if (!strcmp(argv[1],"-p")) {args=2;testuj=1;}
  parerr=0; ffok=0; fftot=0; sumfil=0; sumhea=0; sumbod=0;

  hlava(1,testuj);
  for (a=args;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    fftot++; healen=0; bodlen=0;
    printf("%-12s ",mm);      /* Test vstupneho suboru */
    fdi=fopen(subor,"rb");
    if (fdi==NULL) {printf("Can't open\n");continue;}
    if (stat (subor, &filestat)) {printf("Can't get size\n");fclose(fdi);continue;}
    fillen = (int)filestat.st_size;
    buffer[2]=127;
    b=fread(buffer,1,2,fdi);
    if (b<0) {printf("Can't read\n");fclose(fdi);continue;}
    if (b<1) {printf("Empty file\n");fclose(fdi);continue;}
    if (b<2) {printf("Too short\n");fclose(fdi);continue;}
    if (((buffer[0]!=0)&&(buffer[0]!=255)) ||
        ((buffer[0]==0)&&(buffer[1]!=0)))
          {printf("Format not valid\n");fclose(fdi);continue;}
    if (buffer[0])
      {
      match=0;
      printf(".... .......... ...... ..... ..... ");
      if (testuj) printf("    ");
      }
    else
      {
      match=1;
      strcpy((char*)buffer+3,"          ");
      b = fread(buffer+2,1,19,fdi);
      if (b < 1) {uneof();fclose(fdi);continue;}
      switch(buffer[2])
        {
        case 0: printf("Prog");break;
        case 1: printf("Numb");break;
        case 2: printf("Char");break;
        case 3: printf("Code");break;
        default: printf("[%02X]",buffer[2]);
        }
      printf(" ");
      if (b < 2) {uneof();fclose(fdi);continue;}
      for(c=3;c<13;c++) printf("%c", buffer[c]<32 ? '.' : buffer[c]);
      printf(" ");
      if (b < 13) {uneof();fclose(fdi);continue;}
      printf("%6u ",healen=FROM_SHORT(buffer+13));
      if (b < 15) {uneof();fclose(fdi);continue;}
      if ((buffer[2]!=1)&&(buffer[2]!=2))
        printf("%5u ",FROM_SHORT(buffer+15));
      else
        {
        vary = '?';
        varx = buffer[16];
        if ((varx>=0x80)&&(varx<0xA0)) vary=' ';
        if ((varx>=0xC0)&&(varx<0xE0)) vary='$';
        varx &= 0x1F ; varx |= 0x40;
        if ((varx<'A')||(varx>'Z')) varx='?';
        printf("   %c%c ",varx,vary);
        }
      if (b < 17) {uneof();fclose(fdi);continue;}
      printf("%5u ",FROM_SHORT(buffer+17));
      if (b < 18) {uneof();fclose(fdi);continue;}
      for (parita=0,c=1;c<20;c++) parita^=buffer[c];
      if (testuj) printf("%s ",parita ? "BAD":"ok ");
      if (testuj && parita) parerr++;
      if (b < 19) {printf("Missing body\n");fclose(fdi);continue;}
      buffer[1]=buffer[20];
      }
    b = fread(buffer+21,1,1,fdi);
    if (b < 1) {printf("     ? %3u Damaged body\n",buffer[1]);fclose(fdi);continue;}
    ll = (int)filestat.st_size - (int)ftell(fdi);
    bodlen = len = (unsigned)ll;
    printf("%6d %3u ",ll,buffer[1]);
    if (ll > 65535l) {printf("Too long\n");fclose(fdi);continue;}
    if (testuj)
      {
      parita = buffer[1] ^ buffer[21];
      while(len)
        {
        c = len>lenbuf ? lenbuf : len;
        b = fread(buffer,1,c,fdi);
        if (b < c) {uneof();break;}
        len -= c;
        for (b=0;b<c;b++) parita ^= buffer[b];
        }
      if (len) {fclose(fdi);continue;}
      if (parita) parerr++;
      printf("%s ",parita ? "BAD":"ok ");
      }
    if (match && (healen!=bodlen)){printf("Not match\n");fclose(fdi);continue;}
    printf("\n");
    fclose(fdi);
    ffok++;
    sumfil+=fillen;
    sumhea+=healen;
    sumbod+=bodlen;
    }
  hlava(0,testuj);
  if (ffok > 1)
    printf("%-7d ** Total summary ** %7d            %s %6d Files:%d\n",
            sumfil,           sumhea, testuj?"    ":"",sumbod,      ffok);

  if ((ffok > 1) && ((parerr>0) || (ffok<fftot))) printf("\n");
  if (parerr > 0) printf("Found %d block(s) with bad parity.\n",parerr);
  if (ffok < fftot)
     printf("Found %d good files(s) and %d files(s) with error.\n",
                   ffok,               fftot-ffok             );
  return (0);
}

/****************************************************************************
** 28.05.1996 // DirHOB // Busy soft: Hobeta analyzer [vypis obsahu] 1.04a **
****************************************************************************/

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
#include "endian-compat.h"

typedef unsigned char byte;

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum Hobeta format analyzer 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction   (c) 2002 Tritol\n"
"Fixed by UB880D @2011\n\n");

if(x<2){printf(
"  Usage: %s file1 [file2 ...] [> outfile.lst]\n"
"    Prints header information of input files in Hobeta format.\n"
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
char *riadok="------------ --- -------- --- ----- ------ ------ -------\n";

/******** Chybove hlasenia *******************************/
void uneof(void)
  {printf("Unexpected end of file\n");}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  byte varx,vary,head[30];
  char znacka;
  int a,b,i;
  FILE *fdi;
  unsigned short c;
  unsigned len,sec,ffok,fftot;
  char *mm,subor[100];

  pomoc(argc, argv[0]);

  printf("File             Filename Ext Start Length SecLen Run/Var\n");
  printf("%s", riadok);ffok=0;fftot=0;

  for (a=1;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    fftot++; znacka=0;
    printf("%-12s ... ",mm);      /* Test vstupneho suboru */
    fdi=fopen(subor,"rb");
    if (fdi==NULL) {printf("can't open\n");continue;}
    b=fread(head,1,17,fdi);
    if (b<17) {uneof();fclose(fdi);continue;}
    for (c=0,i=0;i<=14;c+=head[i],i++);
    c*=257;c+=105;b=FROM_SHORT(head+15);
    if (b!=c)
      {printf("bad check sum in header\n");fclose(fdi);continue;}
    
    for(b=0;b<8;b++) printf("%c", head[b]<32 ? '.' : head[b]); printf(" ");
    switch(head[8])
      {
      case 'B': b=9; break;
      case '#': b=13; break;
      default: b = 11;
      }
    len = FROM_SHORT (head+b);
    sec = FROM_SHORT (head+13);

    if ((head[8]=='B')||(head[8]=='D'))
      {
      znacka = head[8];
      fseek(fdi,len,SEEK_CUR);
      b=fread(head+18,1,4,fdi);
      if (b<4) {uneof();fclose(fdi);continue;}
      if ((head[18]!=0x80)||(head[19]!=0xAA))
        {printf("not valid %s\n",znacka=='B' ? "autostart":"variable name");
      fclose(fdi);continue;}
      }

    fclose(fdi);
    /* Subor je v poriadku, prikrocime k vypisu */

    printf(" %c  %5u  %5u  %5u",head[8]<32 ? '?' : head[8],
      FROM_SHORT (head+9), FROM_SHORT (head+11), sec);
    switch (head[8])
      {
      case 'B': printf("  %5u",FROM_SHORT (head+20));break;
      case 'D':
        vary = '?';
        varx = head[21];
        if ((varx>=0x80)&&(varx<0xA0)) vary=' ';
        if ((varx>=0xC0)&&(varx<0xE0)) vary='$';
        varx &= 0x1F ; varx |= 0x40;
        if ((varx<'A')||(varx>'Z')) varx='?';
        printf("    %c%c ",varx,vary); break;
      default: printf("    ...");
      }
    b = znacka ? 4:0;
    TO_SHORT(head,len + 17 + b);
    if (head[0]) {head[0]=0;head[1]++;}
    if ( (FROM_SHORT(head)) < sec )
    printf("  Overlays %u",sec-len-b);
    printf("\n"); ffok++;
    }
  printf("%s", riadok);
  if (ffok==fftot) printf("Found %u file(s).\n",ffok);
  else printf("Found %u good and %u bad file(s).\n",ffok,fftot-ffok);
  return(0);
}

/*
// 00-07 - meno
// 08    - typ
// 09-0A - Start
// 0B-0C - Length
// 0D-0E - pocet sektorov
// 0F-10 - CRC suma
//
// <predat0r> BUSY: filenameB,START,LENGHT,how many sectors,
//            first sector, first track
// <predat0r> in filenameB - filename with extension B
//            (locates 9 bytes (8 for name and 1 for extension))
// <predat0r> in START - lenght of basic file + lenght of variables (2 bytes)
// <predat0r> in LENGHT - only lenght of basic programm
// <predat0r> in HOW MANY SECTORS - how many sectors this programm
//            locates on disk
// <predat0r> in FIRST sector - first sector (file position on disk)
// <predat0r> in FIRST TRACK - first track (file position on disk)
// <predat0r> busy: yes IN end of each basic file is 4 bytes for it
// <predat0r> #80,#aa then autostart line
// */

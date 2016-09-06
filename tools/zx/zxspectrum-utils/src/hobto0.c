/*********************************************************************
** 28.05.1996 // HOBto0 // Busy soft: 000 -> Hobeta konvertor 1.04a **
*********************************************************************/

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
byte body[lenbuf+2];

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum Hobeta=>000 format convertor 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction         (c) 2002 Tritol\n\n");

if(x<2){printf(
"  Usage: %s file1 [file2 ...]\n"
"    Converts input files in Hobeta format into 000 file format.\n"
"    You can use wildcards '*' and '?' in filename parameters.\n"
"    Extension of output files will be three-digit number.\n\n", name);

printf("This program is free software; you can redistribute it and/or modify it under\n"
"the terms of the GNU General Public License as published by the Free Software\n"
"Foundation; either version 2 of the License, or (at your option) any later\n"
"version.\n\n");

printf("This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
"PARTICULAR PURPOSE.\n"
"See the GNU General Public License for more details (http://www.gnu.org/).\n");

exit(1);}}

/******** Zapis do suboru a test spravnosti zapisu ********/
int zapis(FILE *fd, unsigned char *buff, int kolko, char *subor)
{
  if (fwrite(buff,1,kolko,fd) == kolko) return 0;
  else {printf("Can't write into %s\n",subor);return 1;}
}

/******** Test spravnosti zatvorenia suboru ***************/
void testclose(int fd, char *subor)
{if (fd!=0) printf("Error: Can't close %s\n",subor);}

/********** Vytvori novy subor MENO.XYZ, xyz=000..999 *****/
FILE* novysubor (char *meno)
{
  int a;
  FILE *b;
  char *mm;
  mm=meno+strlen(meno);
  for (a=0,b=NULL;(a<1000)&&(b==NULL);a++)
    {
    sprintf(mm,".%03d",a);
    b=fopen(meno,"wb");
    }
  return(b);
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  byte head[30];
  char znacka,zmaz,*ext,meno[100];
  unsigned char parita;
  int a,b,i,files;
  FILE *fdi, *fdo;
  unsigned short len,c;
  int ll;
  char *mm,subor[100];
  struct stat filestat;

  pomoc(argc, argv[0]);

  files = 0;
  for (a=1;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    znacka=0;zmaz=0;
    strcpy(meno,mm);      /* Zbavenie mena koncovky */
    ext=meno+strlen(meno);
    while((ext!=meno)&&(*ext!='.')&&(*ext!='/')) ext--;
    if (*ext!='.') ext=meno+strlen(meno);
    *ext = 0;

    printf("%-12s ... ",mm);      /* Test vstupneho suboru */
    fdi=fopen(subor,"rb");
    if (fdi==NULL) {printf("Can't open file %s\n",subor);continue;}
    if (stat (subor, &filestat))
      {printf("Can't get size of %s, skipping\n",subor);fclose(fdi);continue;}
    ll = (int)filestat.st_size;
    if (ll > 65535l)
      {printf("File is too long\n");fclose(fdi);continue;}
    b=fread(head,1,17,fdi);
    if (b<17)
      {printf("File is too short\n");fclose(fdi);continue;}
    for (c=0,i=0;i<=14;c+=head[i],i++);
    c*=257;c+=105;b=FROM_SHORT(head+15);
    if (b!=c)
      {printf("Format not valid\n");fclose(fdi);continue;}
    if ((head[8]=='B')||(head[8]=='D'))
      {
      znacka = head[8];
      b = znacka=='B' ? 9 : 11;
      len=FROM_SHORT(head+b);
      fseek(fdi,(int)len,SEEK_CUR);
      b=fread(head+18,1,4,fdi);
      fseek(fdi,17,SEEK_SET);
      if ((b<4)||(head[18]!=0x80)||(head[19]!=0xAA))
        {printf("Not valid autostart or variable name\n");fclose(fdi);continue;}
      }

    /* Subor je v poriadku, prikrocime ku konverzii */
    memcpy(body+3,head,8);
    body[0]=0;body[1]=0;body[11]=32;body[12]=32;

    switch (head[8])
      {
      case 'Z':
        printf("(mrs src)   ");
        body[2]=3;
        body[13]=head[11];body[14]=head[12];
        body[15]=head[ 9];body[16]=head[10];
        body[17]=255;     body[18]=255;break;
      case 'C':
        printf("(code)      ");
        body[2]=3;
        body[13]=head[11];body[14]=head[12];
        body[15]=head[ 9];body[16]=head[10];
        body[17]=0;       body[18]=128;break;
      case 'B':
        printf("(basic)     ");
        body[2]=0;
        body[13]=head[ 9];body[14]=head[10];
        body[15]=head[20];body[16]=head[21];
        body[17]=head[11];body[18]=head[12];break;
      case 'D':
        body[ 2]=head[21]<0xC0 ? 1 : 2;
        printf("(%s.data) ",body[2]==1 ? "numb":"char");
        body[13]=head[11];body[14]=head[12];
        body[15]=head[20];body[16]=head[21];
        body[17]=0;       body[18]=128;break;
      case '#':
        printf("(sequence)  ");
        body[2]=3;
        body[13]=head[13];body[14]=head[14];
        body[15]=head[11];body[16]=head[12];
        body[17]='#';     body[18]=0xFC;break;
      default:
        if (head[8]=='O') printf("(overlays)  ");
        else printf("(unknown)   ");
        body[2]=3;
        body[13]=head[11];body[14]=head[12];
        body[15]=head[ 9];body[16]=head[10];
        body[17]=head[ 8];body[18]=0xFC;
      }

    len = FROM_SHORT(body+13);
    if (len+17 > ll)
      {
      printf("Incomplete file\n");
      fclose(fdi);continue;
      }
    fdo = novysubor(meno);
    if (fdo==NULL)
      {
      strcpy(ext,".???");
      printf("Can't open %s\n",meno);
      fclose(fdi);continue;
      }
    printf("=> %s (%u)\n",meno,len);

    for (parita=0,b=1;b<19;b++) parita^=body[b];
    body[19]=parita;parita=255;body[20]=parita;
    zmaz |= zapis(fdo,body,21,meno);

    while(len)                /* Skopirovanie samotneho obsahu */
      {
      c = len>lenbuf ? lenbuf: len;
      b = fread(body,1,c,fdi);
      if (b < c)
        {printf("Error: unexpected end of file in %s",mm);zmaz=1;break;}
      zmaz |= zapis(fdo,body,b,meno); if (zmaz) break;
      for (b=0;b<c;b++) parita^=body[b];
      len -= c;
      }
    zmaz |= zapis(fdo,(unsigned char*)&parita,1,meno);
    testclose(fclose(fdo),meno);
    if (zmaz) {remove(meno);fclose(fdi);continue;} else files++;

    /*** OverLays ***/

    if (znacka) fseek(fdi,4,SEEK_CUR);
    len = (unsigned short) (ll - (int)ftell(fdi));
    if (len >= 256)
      {
      printf("%-12s ... (overlays)  ",mm);
      memcpy(body+3,head,8);
      body[0]=0;body[1]=0;body[2]=3;
      body[11]='O';body[12]='!';
      TO_SHORT(body+13,len);
      TO_SHORT(body+15,ftell(fdi)-17);
      body[17]='O';body[18]=0xFC;

      *ext = 0;
      fdo = novysubor(meno);
      if (fdo==NULL)
        {
        strcpy(ext,".???");
        printf("Can't open %s\n",meno);
        fclose(fdi);continue;
        }
      printf("=> %s (%u)\n",meno,len);

      for (parita=0,b=1;b<19;b++) parita^=body[b];
      body[19]=parita;parita=255;body[20]=parita;
      zmaz = zapis(fdo,body,21,meno);

      while(len)                /* Skopirovanie obsahu overlaysu */
        {
        c = len>lenbuf ? lenbuf: len;
        b = fread(body,1,c,fdi);
        if (b < c)
          {printf("Error: unexpected end of file in %s",mm);zmaz=1;break;}
        zmaz |= zapis(fdo,body,b,meno); if (zmaz) break;
        for (b=0;b<c;b++) parita^=body[b];
        len -= c;
        }

      zmaz |= zapis(fdo,(unsigned char*)&parita,1,meno);
      testclose(fclose(fdo),meno);
      if (zmaz) remove(meno); else files++;

      /*** OverEnds ***/
      }
    testclose(fclose(fdi),mm);
    }
  printf("\nDone. There was convert %d file(s).\n",files);
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
// <predat0r> #80,#aa then aytostart line
*/

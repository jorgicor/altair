/*********************************************************************
** 28.05.1996 // 0toHOB // Busy soft: 000 -> Hobeta konvertor 1.04a **
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
unsigned char body[lenbuf+2];
unsigned int out_len = 0;

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum 000=>Hobeta format convertor 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction         (c) 2002 Tritol\n"
"Fixed by UB880D @2011\n\n");

if(x<2){printf(
"  Usage: %s file1 [file2...]\n"
"    Converts input files in 000 format into Hobeta file format.\n"
"    You can use wildcards '*' and '?' in filename parameters.\n"
"    Extension of output files will be .$T where T is file type.\n\n", name);

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
  out_len += kolko;
  if (fwrite(buff,1,kolko,fd) == kolko) return 0;
  else {printf("Can't write into %s\n",subor);return 1;}
}
/******** Test spravnosti zatvorenia suboru ***************/
void testclose(int fd, char *subor)
{if (fd!=0) printf("Error: Can't close %s\n",subor);}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  byte bajt,head[30],nuly[256];
  char zmaz,znend,*ext,meno[100];
  int a,b,c,i,files;
  FILE *fdi, *fdo;
  unsigned short len;
  int ll;
  char *mm,subor[100];
  struct stat filestat;

  pomoc(argc, argv[0]);

  umask(S_IWGRP | S_IWOTH);

  for(i=0;i<256;i++) nuly[i]=0;

  files = 0;
  for (a=1;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    zmaz=0;
    strcpy(meno,mm);      /* Zbavenie mena koncovky */
    ext=meno+strlen(meno);
    while((ext!=meno)&&(*ext!='.')&&(*ext!='/')) ext--;
    if (*ext!='.') ext=meno+strlen(meno);
    strcpy(ext,".$");ext+=2;ext[1]=0;

    printf("%-12s ... ",mm);      /* Test vstupneho suboru */
    fdi=fopen(subor,"rb");
    if (fdi==NULL) {printf("Can't open file %s\n",subor);continue;}
    if (stat (subor, &filestat))
      {printf("Can't get size of %s, skipping\n",subor);fclose(fdi);continue;}
    ll = (int)filestat.st_size;
    if (ll > 65535l){printf("File is too long\n");fclose(fdi);continue;}
    head[2]=127;
    b=fread(head,1,21,fdi);
    if (b<0){printf("Can't read from %s\n",subor);fclose(fdi);continue;}
    if (((head[0]!=0)&&(head[0]!=255)) ||
        ((head[0]==0)&&(head[1]!=0)&&(head[2]>3)))
          {printf("Format not valid\n");fclose(fdi);continue;}
    if (head[0]||head[1])
      {printf("Can't convert headerless");fclose(fdi);continue;}
    if (b<21){printf("File is too short\n");fclose(fdi);continue;}
    len = FROM_SHORT(head+13);
    if ((len+22) > ll)
      {printf("Incomplete file\n");fclose(fdi);continue;}

    /* Subor je v poriadku, prikrocime ku konverzii */

    memcpy(body,head+3,8);
    body[13]=0;body[14]=0;
    znend=4;
    head[22]=0x80;
    head[23]=0xAA;
    head[24]=head[15];
    head[25]=head[16];

    switch (head[2])
      {
      case 0:
        printf("(basic) ... ");
        body[8]='B';
        body[ 9]=head[13];body[10]=head[14];
        body[11]=head[17];body[12]=head[18];
        break;
      case 1:
      case 2:
        printf("(%s.data) ... ",head[2]==1 ? "numb":"char");
        body[8]='D';
        body[ 9]=0       ;body[10]=0;
        body[11]=head[13];body[12]=head[14];
        break;
      case 3:
        printf("(code)  ... ");
        body[8]='C';znend=0;
        body[ 9]=head[15];body[10]=head[16];
        body[11]=head[13];body[12]=head[14];
        if ((head[17]==255)&&(head[18]==255)) body[8]='Z';
        if (head[18]==0xFC) body[8]=head[17];
        if (body[8]=='#')
          {
          body[ 9]=0       ;body[10]=0x20;
          body[11]=head[15];body[12]=head[16];
       /* body[13]=head[13];body[14]=head[14]; */
          }
        break;
      default:
        printf("unknown type 0x%02X of file\n",head[2]);fclose(fdi);continue;
      }

    TO_SHORT(body+13, len+(unsigned short)znend);
    if (body[13]) {body[13]=0;body[14]++;}
	
    for (c=0,i=0;i<=14;c+=body[i],i++);
    c*=257;c+=105;
    TO_SHORT(body+15, c);

    *ext = body[8];

    if ( (*ext<33)
      || (*ext>126)
      || (strchr("*\"+,./:;<=>?[\\]|",*ext)) ) *ext='_';

    fdo = fopen(meno,"wb");
    if (fdo==NULL){printf("Can't open %s\n",meno);fclose(fdi);continue;}
    printf("=> %s (%u)\n",meno,len);

    zmaz |= zapis(fdo,body,17,meno);

    while(len)                /* Skopirovanie samotneho obsahu */
      {
      c = len>lenbuf ? lenbuf : len;
      b = fread(body,1,c,fdi);
      if (b < c)
        {printf("Error: unexpected end of file in %s",mm);zmaz=1;break;}
      zmaz |= zapis(fdo,body,b,meno);
      len -= c;
      }
    if (znend) zmaz |= zapis(fdo,head+22,4,meno);

    /**************************************************
    **** Zaokruhi dlzku na najblizsie vescie #XX11 ****
    ***************************************************
    ** len = hil - len - znend;
    ** if (len) zmaz |= zapis(fdo,nuly,len,meno);
    **************************************************/
    if (stat (meno, &filestat))
      {printf("Can't get size of %s\n",meno);fclose(fdi);fclose(fdo);continue;}
    /*bajt = 17-(unsigned char)filestat.st_size;*/
    bajt = 17-(unsigned char)out_len;
    len = ((unsigned short) (*((unsigned char *)&bajt)));
    if (len) zmaz |= zapis(fdo,nuly,len,meno);
    /*************************************************/

    testclose(fclose(fdi),mm);
    testclose(fclose(fdo),meno);
    if (zmaz) remove(meno); else files++;
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

/******************************************************************
** 28.05.1996 // 0tobin // Busy soft: 000 -> BIN konvertor 1.04a **
******************************************************************/

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
"\nZX Spectrum 000=>BIN format convertor 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction      (c) 2002 Tritol\n"
"Fixed by UB880D @2011\n\n");

if(x<2) {printf(
"  Usage: %s [-l] file1 [file2...]\n"
"    Converts input files in 000 format into plain raw\n"
"    Option: -l ... creates long filenames\n"
"    binary files without any additional format headers.\n"
"    You can use wildcards '*' and '?' in filename parameters.\n"
"    Extension of output binary files will be:\n"
"      bas for basic program   dat for number or character array\n"
"      cod for bytes           bin for headerless or unknown type\n\n", name);

printf("This program is free software; you can redistribute it and/or modify it under\n"
"the terms of the GNU General Public License as published by the Free Software\n");
printf("Foundation; either version 2 of the License, or (at your option) any later\n"
"version.\n\n"

"This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
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

/******** Prevod ZX mena na PC meno ***********************/
void zxtopc(unsigned char *name, int longnames)
{
  unsigned char *nn;
  /* Nahrada koncovych medzier nulami */
  for (nn=name+(longnames?9:7),*(nn+1)=0;(name!=nn)&&(*nn==32);nn--) *nn=0;
  /* Nahrada nahrada nekoncovych nul medzerami */
  for (;nn>=name;nn--) if (*nn==0) *nn=32;
  /* Filtracia ilegalnych znakov */
  for (nn=name;*nn;nn++)
    if  ((*nn<33)
      || (*nn>126)
      || (strchr("*\"+,./:;<=>?[\\]|",*nn)) ) *nn='_';
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  byte head[30];
  char zmaz,*ext,*kon,meno[100];
  int a,b,c,files;
  FILE *fdi, *fdo;
  unsigned short len;
  int ll,bytes;
  char *mm,subor[100];
  struct stat filestat;
  int args,longnames;

  umask(S_IWGRP | S_IWOTH);

  pomoc(argc, argv[0]);

  args=1;longnames=0;
  if (!strcmp(argv[1],"-l")) {args=2;longnames=1;}

  files = 0; bytes = 0l;
  for (a=args;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    zmaz=0;
    strcpy(meno,mm);        /* Zbavenie mena koncovky */
    ext=meno+strlen(meno);
    while((ext!=meno)&&(*ext!='.')&&(*ext!='/')) ext--;
    if (*ext!='.') ext=meno+strlen(meno);
    strcpy(ext,".bin");      /* defaultna koncovka .bin */

    printf("%-12s ... ",mm);      /* Test vstupneho suboru */
    fdi=fopen(subor,"rb");
    if (fdi==NULL) {printf("Can't open file %s\n",subor);continue;}
    if (stat (subor, &filestat))
      {printf("Can't get size of %s, skipping\n",subor);fclose(fdi);continue;}
    ll = (int)filestat.st_size;
    if (ll > 65535l){printf("File is too long\n");fclose(fdi);continue;}
    head[0]=127;head[1]=127;
    b=fread(head,1,2,fdi);
    if (b<2){printf("Can't read from %s\n",subor);fclose(fdi);continue;}
    if (((head[0]!=0)&&(head[0]!=255)) ||
        ((head[0]==0)&&(head[1]!=0)))
          {printf("Format not valid\n");fclose(fdi);continue;}

    /* Subor je v poriadku, prikrocime ku konverzii */
    /* Najprv treba suboru vymysliet meno */

    if (head[0])  /* Pre headerlessy */
      {
      len = (unsigned short)ll - 3;
      printf("headerless");
      }
    else      /* Pre hlavicky */
      {
      b=fread(head+2,1,19,fdi);
      if (b<17){printf("File is too short\n");fclose(fdi);continue;}
      len = FROM_SHORT(head+13);
      if (len+22 > ll){printf("Incomplete file\n");fclose(fdi);continue;}
      for(b=3;b<13;b++) putchar(head[b]<32 ? '.' : head[b]);
      memcpy(meno,head+3,10);
      zxtopc((byte*)meno,longnames);
      switch (head[2])
        {
        case  0: kon=".bas";break;
        case  1:
        case  2: kon=".dat";break;
        case  3: kon=".cod";break;
        default: kon=".bin";
        }
      strcat(meno,kon);
      }

    /* A zase hless a hlavicky spolu */
    fdo = fopen(meno,"wb");
    if (fdo==NULL){printf(" Can't open %s\n",meno);fclose(fdi);continue;}
    printf(" => %s (%u)\n",meno,len);
    ll = len;

    while(len)                /* Skopirovanie samotneho obsahu */
      {
      c = len>lenbuf ? lenbuf : len;
      b = fread(body,1,c,fdi);
      if (b < c){printf("Error: unexpected end of file in %s",mm);zmaz=1;break;}
      zmaz |= zapis(fdo,body,b,meno); if (zmaz) break;
      len -= c;
      }
    testclose(fclose(fdi),mm);
    testclose(fclose(fdo),meno);
    if (zmaz) remove(meno); else {files++;bytes+=ll;};
    }
  printf("\nDone. There was convert %d byte(s) in %d file(s).\n",bytes,files);
  return(0);
}

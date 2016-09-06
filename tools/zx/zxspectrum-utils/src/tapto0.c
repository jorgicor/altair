/******************************************************************
** 28.05.1996 // taptp0 // Busy soft: TAP -> 000 konvertor 1.04a **
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
unsigned char body[lenbuf+2];

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum TAP=>000 format convertor 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction      (c) 2002 Tritol\n");

if(x<2){printf(
"\n  Usage: %s [-l] [-f] file1 [file2 ...]\n"
"    Converts input files in TAP format into 000 file format.\n"
"    Option: -l ... creates long filenames\n"
"            -f ... force overwrite existing files\n"
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

/******** Chybove hlasenia *******************************/
void uneof(void)
  {printf("Error: unexpected end of file.\n");}
void cantread(void)
  {printf("Error: Can't read\n");}
int testclose(FILE *fd,char *meno)
  {int fdx;
	  fdx = fclose(fd);if (fdx!=0) printf("Error: Can't close file %s\n",meno);
  return(fdx);}

/******** Zapis do suboru a test spravnosti zapisu ********/
int zapis(FILE *fd, unsigned char *buff, int kolko, char *subor)
{
  if (fwrite(buff,1,kolko,fd) == kolko) return 0;
  else {printf("Can't write into %s\n",subor);return 1;}
}

/******** Prevod ZXmena na PCmeno *************************/
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

/********** Vytvori novy subor MENO.XYZ, xyz=000..999 *****/
FILE* novysubor (char *meno, int overwrite)
{
  int a;
  FILE *b;
  char *mm;
  struct stat s;
  
  mm=meno+strlen(meno);
  for (a=0,b=NULL;(a<1000)&&(b==NULL);a++)
    {
    sprintf(mm,".%03d",a);
    if (!overwrite && !stat(meno,&s)) continue;
    b=fopen(meno,"wb");
    }
  return(b);
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  unsigned char head[30];
  char chyba,meno[100];
  int a,b,c,tapfiles,nulfiles,zmaz;
  FILE *fdi, *fdo;
  unsigned len,hll;
  int ls,taplen,poz;
  char *mm,subor[100];
  struct stat filestat;
  int args,longnames,overwrite;

  pomoc(argc, argv[0]);
 
  args=1;longnames=0;overwrite=0;
  while (argv[args][0]=='-' && argv[args][1] && !argv[args][2]) {
    switch (argv[args][1]) {
      case 'l': longnames=1; break;
      case 'f': overwrite=1; break;
      default: printf("Warning! Unknown switch %c\n", argv[args][1]);
    }
    args++;
  }
  
  tapfiles=0;nulfiles=0;
  for (a=args;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    fdi=fopen(subor,"rb");
    if (fdi==NULL) {printf("Can't open file %s\n",subor);continue;}
    if (stat (subor, &filestat))
      {printf("Can't get size of %s, skipping\n",subor);fclose(fdi);continue;}
    chyba=0;
    tapfiles++;
    taplen = (int)filestat.st_size;
    printf("\nConverting file: %s (length %d bytes)\n",mm,taplen);

    while(taplen > (poz = (int)ftell(fdi)))
      {
      printf("%6d\t",poz);
      b = fread(head,1,3,fdi);
      if (b < 3) {uneof();chyba=1;break;}
      len = FROM_SHORT(head);
      ls = poz-1l+len;
      if (ls > taplen) {uneof();chyba=1;break;}
      if (len < 2)
        {printf("Error: Data integrity corrupted\n");chyba=1;break;}

      if ((len!=19)||(head[2])!=0)           /* Bezhlavickove telo */
        {
        printf("headerless ... %5u ",len-2); len--;
        strcpy(meno,"headless");
        fdo = novysubor(meno, overwrite);
        if (fdo==NULL)
          {
          printf("Can't open %s\n",meno);
          fseek(fdi,len,SEEK_CUR);continue;
          }
        printf("=> %s (%u)\n",meno,len+2);
        head[1]=255;
        zmaz = zapis(fdo,head+1,2,meno);
        }
      else                    /* Telo s hlavickou */
        {
        b = fread(head+3,1,18,fdi);
        if (b < 18) {uneof();chyba=1;break;}
        for(b=4;b<14;b++) putchar(head[b]<32 ? '.' : head[b]);
        hll = FROM_SHORT(head+14);
        printf(" ... %5u ",hll);
        ls = (int)ftell(fdi);
        b = fread(body,1,3,fdi);
        if (b < 3) {uneof();chyba=1;break;}
        len = FROM_SHORT(body);
        if ((hll != len-2)||(body[2] != 255))
          {
          puts("Error: Not match with body");
          fseek(fdi,ls,SEEK_SET);continue;
          }
        len--;
        ls = (int)ftell(fdi)+len;
        if (ls > taplen) {uneof();chyba=1;break;}
        memcpy(meno,head+4,10);
        zxtopc((unsigned char *)meno,longnames);
        fdo = novysubor(meno, overwrite);
        if (fdo==NULL)
          {
          printf("Can't open %s\n",meno);
          fseek(fdi,len,SEEK_CUR);continue;
          }
        printf("=> %s (%u)\n",meno,len+21);
        head[1]=0;head[21]=body[2];
        zmaz = zapis(fdo,head+1,21,meno);
        }         /* Koniec velkeho ifu */

      while(len)      /* Skopirovanie samotneho obsahu */
        {
        c = len>lenbuf ? lenbuf : len;
        b = fread(body,1,c,fdi);
        if (b < c) {uneof();chyba=1;zmaz=1;break;}
        zmaz |= zapis(fdo,body,b,meno);
        len -= c;
        }
      zmaz |= len;
      zmaz |= testclose(fdo,meno);
      if (zmaz) remove(meno); else nulfiles++;
      }
    if (!chyba) printf("%6d\tEnd of file %s\n",(int)ftell(fdi),mm);
    fclose(fdi);
    }
  printf("\nDone. There was convert %d TAP file(s) into %d file(s) 000.\n", tapfiles,nulfiles);
  return(0);
}

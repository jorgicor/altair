/******************************************************************
** 28.05.1996 // 0totap // Busy soft: 000 -> TAP konvertor 1.04a **
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
"\nZX Spectrum 000=>TAP format convertor 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction      (c) 2002 Tritol\n"
"Fixed by UB880D\n\n");

if(x<2){printf(
"  Usage: %s file1 [file2 ...]\n"
"         %s [-o outfile.[tap]] file1 [file2 ...]\n"
"         %s [-a outfile.[tap]] file1 [file2 ...]\n"
"    Converts one or more input files into one file outfile.tap\n"
"    Input files must be in 000 format and outfile will be in TAP format.\n"
"    You can use wildcards '*' and '?' in parameters for input files.\n", name, name, name);
printf("    Options: -o ... overwrites old outfile.tap (if exists)\n"
"             -a ... appends new information at end of outfile.tap\n"
"    If -o or -a is not specified then name of output file will be\n"
"    the same as first converted input file and extension will be \"TAP\".\n\n");

printf("This program is free software; you can redistribute it and/or modify it under\n"
"the terms of the GNU General Public License as published by the Free Software\n"
"Foundation; either version 2 of the License, or (at your option) any later\n"
"version.\n\n"

"This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
"PARTICULAR PURPOSE.\n"
"See the GNU General Public License for more details (http://www.gnu.org/).\n");

exit(1);}}

/******** Chybove hlasenia *******************************/
void panic (void)
  {printf("\nPanic error: ");}
void conabo (void)
  {printf(", converting aborted.\n");}
void uneof(void)
  {panic();printf("unexpected end of file");conabo();}
void modif(void)
  {panic();printf("file is modified");conabo();}

void tstpp(byte parity)
{
  printf("OK");
  if (parity) printf(" (Warning: Bad parity %u)",parity);
  printf("\n");
}

/******** Zapis do suboru a test spravnosti zapisu ********/
void zapis(FILE *fd, unsigned char *buff, int kolko, char *subor)
{
  if (fwrite(buff,1,kolko,fd) < kolko)
    {printf("\nError: Can't write into %s",subor);
    conabo();fclose(fd);remove(subor);exit(1);}
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  byte parity,head[30];
  char tapename,*nam,*ext,meno[100];
  int a,b,c,arg0,files;
  FILE *fdi, *fdo;
  unsigned short len;
  int ll;
  char *mm,subor[100];
  struct stat filestat;

  pomoc(argc, argv[0]);

  umask(S_IWGRP | S_IWOTH);

  strcpy(meno,"outfile");
  nam=argv[1];
  tapename=0;arg0=3;c=0;files=0;
  if ((strcmp(nam,"-o") && strcmp(nam,"-O")
    && strcmp(nam,"-a") && strcmp(nam,"-A"))) arg0=1;

  if ((arg0==3)&&(argc==2)) {printf("Error: Missing name of TAP file.\n");c=1;}
  if ((arg0==3)&&(argc >2)) {strcpy(meno,argv[2]);tapename=1;}

  if (strchr(meno,'*') || strchr(meno,'?'))
   {printf("Error: Wildcards in TAP filename are not allowed.\n");exit(1);}

  printf("Testing input file(s)\n");
  for (a=arg0;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    files++;
    if (!tapename) {strcpy(meno,mm);tapename=1;}  /* meno TAP suboru */
    printf("%-12s ... ",mm);
    fdi=fopen(subor,"rb");
    if (fdi==NULL){printf("Can't open file %s\n",subor);c++;continue;}
    if (stat (subor, &filestat))
      {printf("Can't get size of %s, skipping\n",subor);fclose(fdi);c++;continue;}
    ll = (int)filestat.st_size;
    if (ll > 65533l){printf("File is too long\n");fclose(fdi);c++;continue;}
    head[2]=127;
    b=fread(head,1,3,fdi);
    if (b<1){printf("Can't read from %s\n",subor);fclose(fdi);c++;continue;}
    if (b<3){printf("File is too short\n");fclose(fdi);c++;continue;}
    if (((head[0]!=0)&&(head[0]!=255)) ||
        ((head[0]==0)&&(head[1]!=0)&&(head[2]>3)))
          {printf("Format not valid\n");fclose(fdi);c++;continue;}
    if (!head[0])
      {
      b=fread(head+3,1,18,fdi);
      if (b<18){printf("Incomplete head\n");fclose(fdi);c++;continue;}
      len = FROM_SHORT(head+13);
      if (len+22 > ll){printf("Incomplete body\n");fclose(fdi);c++;continue;}
      }
    printf("Ok\n");fclose(fdi);
    }
  if (!files) {printf("Error: No input files for convert.\n");c++;}
  if (c) {printf("Found %d error(s)\n",c);conabo();exit(1);}

  /* Vsetky subory 000 vyzeraju byt ok a mozeme prikrocit ku konverzii */

  /* Zbavenie TAP mena koncovky */
  ext=meno+strlen(meno);
  while((ext!=meno)&&(*ext!='.')&&(*ext!='/')) ext--;
  if (*ext!='.') ext=meno+strlen(meno);
  strcpy(ext,".tap");

  fdo = NULL;
  a = strcmp(nam,"-a") && strcmp(nam,"-A"); /* Ak -a tak potom a=0 */
  if (!a)
    {
    fdo=fopen(meno,"wb+");
    if (fdo!=NULL)
      fseek(fdo,0,SEEK_END);
    else
      {
      fdo=fopen(meno,"rb");
      if (fdo!=NULL) {printf("Error: %s is read only",meno);conabo();exit(1);}
      a=1;
      }
    }
  if (a) fdo=fopen(meno,"wb+");
  if (fdo==NULL) {printf("Error: Can't open output file %s",meno);conabo();exit(1);}

  printf("Converting %d file(s) into %s\n",files,meno);

  for (a=arg0;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;

    fdi=fopen(subor,"rb");
    fseek(fdo, 0, SEEK_CUR);
    printf("%6d\t%-12s ",(int)ftell(fdo),mm);
    if (fdi==NULL) {modif();fclose(fdo);remove(meno);exit(1);}
    if (stat (subor, &filestat))
      {printf("Can't get size of %s\n",subor);modif();fclose(fdo);remove(meno);exit(1);}
    ll = (int)filestat.st_size;
    if (ll > 65533l) {modif();fclose(fdo);remove(meno);exit(1);}
    len = (unsigned short) ll;

    b = fread(head+1,1,2,fdi);
    if (b < 2) {uneof();fclose(fdo);remove(meno);exit(1);}
    b = head[1];
    if ((b>0)&&(b<255)) {modif();fclose(fdo);remove(meno);exit(1);}

    if (b)
      {
      len-=1;
      body[2]=head[2];
      printf("%03u..%05u ",body[2],len-2);
      }
    else
      {
      b = fread(head+3,1,19,fdi);
      if (b < 19) {uneof();fclose(fdo);remove(meno);exit(1);}

      for(b=4;b<14;b++) putchar(head[b]<32 ? '.' : head[b]); putchar(' ');
      for (parity=0,b=2;b<21;b++) parity ^= head[b]; tstpp(parity);

      fseek(fdo, 0, SEEK_CUR);
      printf("%6d\t%-12s %03u..%05u ",
        (int)ftell(fdo)+21,mm,head[21],len-22);

      /* dlzka hlavicky /// flagbajt tela */
      head[0]=19;head[1]=0;head[2]=0;body[2]=head[21];
      zapis(fdo,head,21,meno);
      len-=20;
      }
    TO_SHORT(body, len);
    zapis(fdo,body,3,meno);len--;

    parity = body[2];
    while(len)
      {
      c = len>lenbuf ? lenbuf : len;
      b = fread(body,1,c,fdi);
      if (b < c) {uneof();fclose(fdo);remove(meno);exit(1);}
      zapis(fdo,body,b,meno);
      for (c=0;c<b;c++) parity^=body[c];
      len -= b;
      }
    fclose(fdi); tstpp(parity);
    }
  b=fclose(fdo);
  if (stat (meno, &filestat))
    {printf("Can't get size of %s\n",meno);modif();fclose(fdo);remove(meno);exit(1);}
  ll = (int)filestat.st_size;
  if (b<0) printf("Warning: Can't close %s\n",meno);
  printf("Done. Output file %s is %d bytes length.\n",meno,ll);
  return(0);
}

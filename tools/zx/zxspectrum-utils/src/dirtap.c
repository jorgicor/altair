/*************************************************************************
** 28.05.1996 // dirtap // Busy soft: TAP analyzer [vypis obsahu] 1.04a **
*************************************************************************/

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
"\nZX Spectrum TAP format analyzer 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction (c) 2002 Tritol\n"
"Fixed by UB880D @2011\n");

if(x<2){printf(
"\n  Usage: %s [options] file1.tap [file2.tap ...] [> outfile.lst]\n"
"    Prints contens of TAP input files.\n"
"    Options: -h ... only headers will be displayed\n"
"             -p ... additional parity tester [not correcter]\n"
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

char *riadok=" ------- ------- --- ---- ---------- ------ ----- -----\n";

/******** Chybove hlasenia *******************************/
void zle(void)
  {printf("(error)\n%s\nError: ",riadok);}
void uneof(void)
  {zle();printf("unexpected end of file, ");}
void nemam(unsigned aa)
  {uneof();printf("missing %u byte(s)\n",aa);}
void cantread(void)
  {uneof();printf("can't read the file");}
int tstpp(int x)
  {if (x) {printf("Warning: bad parity");return 1;} else return 0;}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  unsigned char varx,vary,parity,buffer[24];
  char testuj,telo,chyba;
  int a,b,c,args;
  FILE *fd;
  int lenall,obsah,poc,poz,siz,dif;
  int files,totfil,totall,totlen,totpoc,totite,totlna,parerr;
  unsigned len,dlz;
  char *mm,subor[100];
  struct stat filestat;

  pomoc(argc, argv[0]);

  args=1; telo=1; testuj=0;
  while(args<argc)
    {
    if (!strcmp(argv[args],"-h")) telo=0;
    else if (!strcmp(argv[args],"-p")) testuj=1;
    else break;
    args++;
    }
  if (args>=argc)
    printf("To get help, run %s without any parameters.\n", argv[0]);

  totfil=0; totall=0; totlen=0; files=0;
  totpoc=0; totite=0; totlna=0; parerr=0;

  for (a=args;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
    totfil++;
    printf("\nFile: %s",mm);
    fd = fopen(subor,"rb");
    if (fd == NULL) {printf("  can't open, skipping\n");continue;}
    if (stat (subor, &filestat))
      {printf("  can't get size, skipping\n");fclose(fd);continue;}
    siz = (int)filestat.st_size;
    printf("  (length %d bytes)\n",siz);

    poc=0;lenall=0;obsah=0;chyba=0;

    printf("  Offset     Len Flg Type Name          Len   Add   Bas\n");
    printf("%s", riadok);

    while(siz > (poz = (int)ftell(fd)))
      {
      poc++;
      if (telo) printf(" %7d ",poz);
        buffer[2]=0;
      b = fread(buffer,1,3,fd);
      if (b < 1) {cantread();chyba=1;break;}
      if (b < 2) {uneof();printf("useless one byte");chyba=1;break;}
      len = FROM_SHORT(buffer); lenall+=len;
      if (telo) printf("  %5u ",len-2);
      if (b < 3) {nemam(len);chyba=1;break;}
      if (telo) printf("%3u ",buffer[2]);
      if (len < 2)
        {zle();printf("bad data integrity\n");chyba=1;break;}

      if ((len!=19)||(buffer[2])!=0)
        {
        if (telo) printf("body ");
        dif = poz + 2 + len - siz;
        if (dif > 0) {nemam(FROM_SHORT(&dif));fclose(fd);chyba=1;break;}
        obsah += len-2;
        if (!testuj) fseek(fd,len-1,SEEK_CUR);
        else
          {
          parity = buffer[2]; dlz=len-1;
          while (dlz)
            {
            c = dlz>lenbuf ? lenbuf : dlz;
            b = fread(body,1,c,fd);
            if (b < c) {cantread();chyba=1;break;}
            dlz -= b;
            for (b=0;b<c;b++) parity ^= body[b];
            }
          if (chyba) break;
          if (telo) {printf (".......... ...... ..... ..... ");
             tstpp(parity);}
          if (parity) parerr++;
          }
        if (telo) putchar('\n');
        }
      else
        {
        if (!telo) printf(" %7d   %5u %3u ",poz,len-2,buffer[2]);
        strcpy((char*)buffer+4,"          ");
        b = fread(buffer+3,1,18,fd);
        if (b < 1) {nemam(18);chyba=1;break;}
        switch(buffer[3])
          {
          case 0: printf("prog");break;
          case 1: printf("numb");break;
          case 2: printf("char");break;
          case 3: printf("code");break;
          default: printf("[%02X]",buffer[3]);
          }
        putchar(' ');
        if (b < 2) {nemam(18-b);chyba=1;break;}
        for(c=4;c<14;c++) putchar(buffer[c]<32 ? '.' : buffer[c]);
        putchar(' ');
        if (b < 13) {nemam(18-b);chyba=1;break;}
        printf(" %5u ",FROM_SHORT(buffer+14));
        if (b < 15) {nemam(18-b);chyba=1;break;}
        if ((buffer[3]!=1)&&(buffer[3]!=2))
          printf("%5u ",FROM_SHORT(buffer+16));
        else
          {
          vary = '?';
          varx = buffer[17];
          if ((varx>=0x80)&&(varx<0xA0)) vary=' ';
          if ((varx>=0xC0)&&(varx<0xE0)) vary='$';
          varx &= 0x1F ; varx |= 0x40;
          if ((varx<'A')||(varx>'Z')) varx='?';
          printf("   %c%c ",varx,vary);
          }
        if (b < 17) {nemam(18-b);chyba=1;break;}
        printf("%5u ",FROM_SHORT(buffer+18));
        if (b < 18) {nemam(18-b);chyba=1;break;}
        for (parity=0,b=2;b<21;b++) parity^=buffer[b];
        if (testuj) parerr += tstpp(parity);
        putchar('\n');
        }
      totite++;
      }
    fclose(fd);
    if (!chyba)
      {
      files++;
      totpoc += poc;
      totlen += obsah;
      totlna += lenall;
      totall += siz;
      printf("%s", riadok);
      printf(" %7d %7d End of %-12s%7d Items:%d\n",
      poz,lenall,mm,obsah,poc);
      }
    }

  if (totfil > 1)
    {
    printf("\nTotal summary of %d item(s) in %d file(s):\n",totpoc,files);
    if (files > 1)
      {
      printf("%s", riadok);
      printf(" %7d %7d                    %7d\n",totall,totlna,totlen);
      printf("%s", riadok);
      }
    if (parerr) printf("Found %d item(s) with bad parity. "
                       "[Use TSTTAP.EXE to repair]\n",parerr);
    if ((totfil != files) || (totite != totpoc))
      printf("Found %d item(s) in %d good files and %d item(s) in %d "
             "error file(s).\n",totpoc,files,totite-totpoc,totfil-files);
    }
  return (0);
}

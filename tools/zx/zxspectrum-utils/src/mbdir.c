/************************************************************************
** 25.03.2000 - 24.04.2000 ** Busy soft: Vypis adresarov MB-02 diskety **
************************************************************************/

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

#include<stdio.h>
#include<fcntl.h>
#include<ctype.h>
#include<errno.h>
#include<stdlib.h>
#include<string.h>
#include"endian-compat.h"

unsigned char boot[1024];
unsigned char dirs[1024];
unsigned char subs[1024];
unsigned char fats[4096];

FILE *ff;
char *meno;
unsigned int aa,bb,cc,dd;

void getsec(unsigned int sektor, unsigned char *buffer)
{
  #ifdef DBG
  printf(" Getsec:%04X ",sektor);
  #endif

  if (fseek(ff,(unsigned long)sektor*1024l,SEEK_SET))
     {fprintf(stderr,"Seek error %s\n",meno);exit(1);}
  if (fread(buffer,1,1024,ff)<1024)
     {fprintf(stderr,"Error reading %s\n",meno);exit(1);}
}

void textdisp(int dlzka, unsigned char *text)
{
  char znak;
  while(dlzka)
   {
   znak = *text;
   if ((!znak) || (znak==7) || (znak==9) || (znak==10) || (znak==13)) znak='~';
   putchar(znak); dlzka--; text++;
   }
}

int main(int pocet, char **parametre)
{

  puts("\nBusy soft: MB-02 disk image analyser 1.01\n"
  "Linux port and safe endian correction by Tritol");

  if (pocet != 2)
    {
    puts("\nUse: mbdir MB02DiskImage\n\n"
	"This program is free software; you can redistribute it and/or modify it under\n"
	"the terms of the GNU General Public License as published by the Free Software\n"
	"Foundation; either version 2 of the License, or (at your option) any later\n"
	"version.\n\n");
    puts("This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
	"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
	"PARTICULAR PURPOSE.\n"
	"See the GNU General Public License for more details (http://www.gnu.org/).\n");
    exit(1);
    }
  putchar('\n');

  memset(fats,255,4096);

  meno = parametre[1];
  ff = fopen(meno,"rb");
  if (ff==NULL) {perror(meno);exit(1);}

  getsec(0,boot);
  printf("Disk "); textdisp(0x0A,boot+0x26);
  putchar(' ');    textdisp(0x10,boot+0x30);
  printf("\n  %u tracks, %u sec/track, %u surfaces,"
    " %u sec/cluster, %u sec/FAT\n",
    FROM_SHORT(boot+0x04),
    FROM_SHORT(boot+0x06),
    FROM_SHORT(boot+0x08),
    FROM_SHORT(boot+0x0A),
    FROM_SHORT(boot+0x0E));

  aa = (FROM_SHORT(boot+0x12))|0xC000;
  for(bb=0;(aa>=0xC000)&&(bb<4096);bb+=1024)
    {
    getsec(aa&0x3FFF,fats+bb);
    #ifdef DBG
    printf(" Fat[%04X]",aa);
    #endif
    aa = FROM_SHORT(fats+2*(aa&0x3FFF));
    #ifdef DBG
    printf("=%04X ",aa);
    #endif
    }
  #ifdef DBG
  putchar('\n');
  #endif

  getsec(FROM_SHORT(boot+0x0C),dirs);
  puts("\n  Directories");
  for(aa=0;aa<256;aa++) if((dirs[4*aa])&0x80)
    {
    getsec((FROM_SHORT(dirs+4*aa+2))&0x3FFF,subs);
    printf("    %3u. ",aa);
    textdisp(0x0A,subs+0x06); putchar(' ');
    textdisp(0x10,subs+0x10); putchar('\n');
    }

  for(aa=0;aa<256;aa++) if((dirs[4*aa])&0x80)
    {
    bb = 0;
    cc = (FROM_SHORT(dirs+4*aa+2))|0xC000;
    getsec(cc&0x3FFF,subs);
    printf("\n  Directory %3u. ",aa);
    textdisp(0x0A,subs+0x06); putchar(' ');
    textdisp(0x10,subs+0x10); putchar('\n');
    while((cc>=0xC000)&&(bb<0xFF00))
      {
      getsec(cc&0x3FFF,subs);
        #ifdef DBG
        putchar('\n');
        #endif
      for(dd=0;dd<1024;dd+=32)
        {
        if (*(subs+dd)>0x80)
           {
           printf("    %5u:%u:",bb,*(subs+dd+0x05));
           textdisp(0x0A,subs+dd+0x06);
           printf(":%5u:%u\n",
           FROM_SHORT(subs+dd+0x12),
           FROM_SHORT(subs+dd+0x18));
           }
        bb++;
        }
          #ifdef DBG
          printf("\n Fat[%04X]",cc);
          #endif
      cc = FROM_SHORT(fats+2*(cc&0x3FFF));
          #ifdef DBG
          printf("=%04X ",cc);
          #endif
      }
    }
  fclose(ff);
    #ifdef DBG
    putchar('\n');
    #endif

  return(0);
}

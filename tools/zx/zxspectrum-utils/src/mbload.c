/***************************************************************************
** 20.04.2000 - 20.04.2000 ** Busy soft: Loadnutie suboru z MB-02 diskety **
***************************************************************************/

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
unsigned char fats[4096];
unsigned char dirs[1024];
unsigned char subs[1024];
unsigned char buff[1024];

FILE *ffii,*ffoo;
char *meno,*ciel;
unsigned long len;
unsigned int dir,sub;
unsigned int aa,bb;

void getsec(unsigned int sektor, unsigned char *buffer)
{
  #ifdef DBG
  printf(" Getsec:%04X ",sektor);
  #endif

  if (fseek(ffii,(unsigned long)sektor*1024l,SEEK_SET))
     {fprintf(stderr,"Seek error %s\n",meno);exit(1);}
  if (fread(buffer,1,1024,ffii)<1024)
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

  puts("\nBusy soft: MB-02 disk image file loader 1.00\n"
  "Linux port and safe endian correction by Tritol");

  if (pocet != 5)
    {
    puts("\nUse: mbload MB02DiskImage DirectoryNumber FileNumber OutputFilename\n\n"
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
  dir = atoi(parametre[2]);
  sub = atoi(parametre[3]);
  ciel = parametre[4];

  printf("Disk image: %s\n",meno);
  ffii = fopen(meno,"rb");
  if (ffii==NULL) {perror(meno);exit(1);}

  getsec(0,boot);
  printf("Disk name: ");
  textdisp(0x0A,boot+0x26); putchar(' ');
  textdisp(0x10,boot+0x30); putchar('\n');

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
  printf("Directory %d: ",dir);
  if (dir>255) {puts("[out of range]");exit(1);}
  if (!(dirs[4*dir]&0x80)) {puts("[not found]");exit(1);}
  aa=FROM_SHORT(dirs+4*dir+2);
  getsec(aa&0x3FFF,subs);
  textdisp(0x0A,subs+0x06); putchar(' ');
  textdisp(0x10,subs+0x10); putchar('\n');

  for(bb=sub>>5;bb>0;bb--)
    {
      #ifdef DBG
      printf(" Fat[%04X]",aa);
      #endif
    aa = FROM_SHORT(fats+2*(aa&0x3FFF));
      #ifdef DBG
      printf("=%04X ",aa);
      #endif
    if (aa<0x8000) {puts("FAT integrity error");exit(1);}
    }
  getsec(aa&0x3FFF,subs);

    #ifdef DBG
    putchar('\n');
    #endif

  printf("File %d: ",sub);
  aa = (sub&0x1F)<<5;
  if (subs[aa]<0x80) {puts("[not found]");exit(1);}
  len = FROM_SHORT(subs+aa+0x18);
  printf(" %u:",subs[aa+0x05]);
  textdisp(0x0A,subs+aa+0x06);
  printf(":%5u:%lu\n",
  FROM_SHORT(subs+aa+0x12),len);
  if (!(subs[aa]&0x20)) {puts("Can't loading file without body.");exit(1);}
  if (!len) {puts("No file data to load (zero length)");exit(1);}

  #ifdef DBG
  printf(" Begin sector: %04X\n",FROM_SHORT(subs+aa+0x1E));
  #endif

  ffoo = fopen(ciel,"wb");
  if (ffoo==NULL) {perror(ciel);exit(1);}
  printf("Loading to file: %s  ",ciel);

  aa=(FROM_SHORT(subs+aa+0x1E))|0xC000;
  while((aa>0xC000) && len)
    {
    getsec(aa&0x3FFF,buff); putchar('.');
      #ifdef DBG
      printf(" Fat[%04X]",aa);
      #endif
    aa = FROM_SHORT(fats+2*(aa&0x3FFF));
      #ifdef DBG
      printf("=%04X ",aa);
      #endif
    bb = (len>1024) ? 1024:(unsigned int)len;
    if (fwrite(buff,1,bb,ffoo) < bb) {perror(ciel);exit(1);}
    if (len<=1024) break;
    len-=1024;
    }
  putchar(' ');putchar(' ');

  #ifdef DBG
  printf("\n End: len=%04X fat=%04X\n",(unsigned int)len,aa);
  #endif

  if (aa<0x8000) {puts("FAT integrity error");exit(1);}
  if ((aa>0xBFFF) || (len>1024) || ((aa&0x3FFF) != len))
     {puts("Length integrity error");exit(1);}

  if(fclose(ffoo)) {perror(ciel);exit(1);}
  if(fclose(ffii)) {perror(meno);exit(1);}
  puts("done");
  return(0);
}

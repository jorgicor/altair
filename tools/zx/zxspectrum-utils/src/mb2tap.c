/*******************************************
** Busy soft **** 24.04.2000 - 24.04.2000 **
** Konverzia adresara MB-02 do TAP suboru **
*******************************************/

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
unsigned int dir;
unsigned int aa,bb,cc,dd,ee,ff;
unsigned long len;
unsigned char info,pari;
char *meno,*ciel;

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

  puts("\nBusy soft: MB-02 disk image directory loader 1.00\n"
  "Linux port and safe endian correction by Tritol\n"
  "Fixed by UB880D @2011");

  if (pocet != 4)
    {
    puts("\nUse: mb2tap MB02DiskImage DirectoryNumber OutputFilename.tap\n\n"
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
  ciel = parametre[3];

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

    #ifdef DBG
    printf(" Begin sector: %04X\n",aa);
    #endif

  ffoo = fopen(ciel,"wb");
  if (ffoo==NULL) {perror(ciel);exit(1);}
  printf("Output TAP file: %s\n",ciel);

  bb=0; aa|=0xC000;
  while((aa>=0xC000)&&(bb<0xFF00))
    {
    getsec(aa&0x3FFF,subs);
      #ifdef DBG
      putchar('\n');
      #endif
    for(dd=0;dd<1024;dd+=32,bb++)
      {
      info = subs[dd];
      if (info>0x80)
        {
        len = FROM_SHORT(subs+dd+0x18);
        printf("%5u:%u:",bb,*(subs+dd+0x05));
        textdisp(0x0A,subs+dd+0x06);
        printf(":%5u:%lu ... ",FROM_SHORT(subs+dd+0x12),len);
        if (info&0x10) /* Ulozenie hlavicky */
          {
          buff[0]=19;
          buff[1]=0;
          buff[2]=0;
          memcpy(buff+3,subs+dd+0x05,17);
          for(pari=0,cc=3;cc<20;cc++) pari^=buff[cc];
          buff[20]=pari;
          if (fwrite(buff,1,21,ffoo) < 21) {puts("error");perror(ciel);exit(1);}
          }
        if (info&0x20) /* Ulozenie tela */
          {
          if (len > 65533l) {puts("length too big");continue;}
          TO_SHORT(buff,len+2);
          pari=*(subs+dd+0x1C);
          buff[2]=pari;
          if (fwrite(buff,1,3,ffoo) < 3) {puts("error");perror(ciel);exit(1);}
          ee=FROM_SHORT(subs+dd+0x1E);
            #ifdef DBG
            printf(" Begin sector: %04X\n",ee);
            #endif
          ee|=0xC000;
          while((ee>0xC000) && len)
            {
            getsec(ee&0x3FFF,buff);
              #ifdef DBG
              printf(" Fat[%04X]",ee);
              #endif
            ee = FROM_SHORT(fats+2*(ee&0x3FFF));
              #ifdef DBG
              printf("=%04X ",ee);
              #endif
            cc = (len>1024) ? 1024:(unsigned int) len;
            if (fwrite(buff,1,cc,ffoo) < cc) {perror(ciel);exit(1);}
            for(ff=0;ff<cc;ff++) pari^=buff[ff];
            if (len<=1024) break;
            len-=1024;
            }
          if (fwrite(&pari,1,1,ffoo) < 1) {puts("error");perror(ciel);exit(1);}
            #ifdef DBG
            printf("\n End: len=%04X fat=%04X\n",(unsigned int)len,ee);
            #endif
          if (ee<0x8000) {puts("FAT integrity error");exit(1);}
          if ((ee>0xBFFF) || (len>1024) || ((ee&0x3FFF) != len))
             {puts("Length integrity error");exit(1);}
          }
        puts("ok");
        }
      }
    #ifdef DBG
    printf("\n Fat[%04X]",aa);
    #endif
    aa = FROM_SHORT(fats+2*(aa&0x3FFF));
    #ifdef DBG
    printf("=%04X ",aa);
    #endif
    }
  #ifdef DBG
  putchar('\n');
  #endif

  if(fclose(ffoo)) {perror(ciel);exit(1);}
  if(fclose(ffii)) {perror(meno);exit(1);}

  puts("All done.");
  return(0);
}

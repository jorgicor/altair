/***************************************************************
** 28.05.1996 // tsttap // Busy soft: TAP parity tester 1.04a **
***************************************************************/

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

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum TAP format parity tester 1.04a (c) 1996 Busy soft\n"
"Linux port and safe endian correction     (c) 2002 Tritol\n");

if(x<2){printf(
"\n  Usage: %s [-a|-s] file1 [file2 ...]\n"
"    Test and repair parity check sum in TAP files.\n"
"    You can use wildcards '*' and '?' in filename parameters.\n", name);
printf("    Options (for non-interative mode):\n"
"      -a ... repairs all bad parity without question\n"
"      -s ... do not repairs all bad parity (only testing)\n"
"    %s needs write access into file for repair bad parity.\n"
"  Note: When you use %s with redirected standart output,\n"
"  it's recomended to use it with option for non-interactive mode.\n\n", name, name);

printf("This program is free software; you can redistribute it and/or modify it under\n"
"the terms of the GNU General Public License as published by the Free Software\n"
"Foundation; either version 2 of the License, or (at your option) any later\n"
"version.\n\n");

printf("This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
"PARTICULAR PURPOSE.\n"
"See the GNU General Public License for more details (http://www.gnu.org/).\n");

exit(1);}}

#define lenbuf 16384
char body[lenbuf];

/******** Chybove hlasenia *******************************/
void zle(void)
  {printf("Error: unexpected end of file, ");}
void nemam(unsigned aa)
  {zle();printf("missing %u byte(s)\n",aa);}
void cantread(void)
  {printf("Error: Can't read\n");}
void cantclose(char *meno)
  {printf("Can't close file %s !!!\n",meno);}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  unsigned char parita,buffer[24];
  char *nam,chyba,znacka,rdonly;
  int fdx,a,argt,files;
  FILE *fd;
  int poz,siz;
  size_t len,b,c;
  char *mm,subor[100];
  struct stat filestat;

  pomoc(argc, argv[0]);
  znacka = 'b';

  nam=argv[1];
  if ((strcmp(nam,"-s") && strcmp(nam,"-a")
    && strcmp(nam,"-S") && strcmp(nam,"-A")))
    argt=1;
  else
    {argt=2;znacka=nam[1];}

  if ((argt==2)&&(argc==2)) {printf("Error: Missing name of TAP file\n");exit(1);}

  files=0;
  for (a=argt;a<argc;a++)
    {
    strcpy(subor,argv[a]);
    for(mm=subor+strlen(subor);(mm!=subor)&&(*mm!='/');mm--);
    if (*mm=='/') mm++;
      rdonly = 0;
      fd=fopen(subor,"rb+");
      if (fd==NULL)
        {
        fd=fopen(subor,"rb");
        if (fd==NULL) {printf("Can't open file %s\n",subor);continue;}
        rdonly = 1;
        }
      files++;chyba=0;
      if (stat (subor, &filestat))
        {printf("Can't get size of %s, skipping\n",subor);fclose(fd);continue;}
      siz = (int)filestat.st_size;
      printf("\nTesting file: %s (length %d bytes)\n",mm,siz);
      if (rdonly) printf("[Warning: File is read only!]\n");

      printf("Offset Contens Info         Parity\n");

      while(siz > (poz = (int)ftell(fd)))
        {
        printf("%6d\t",poz);
        b = fread(buffer,1,3,fd);
        if (b == 0) {cantread();break;}
        if (b < 2) {zle();printf("useless one byte\n");chyba=1;break;}
        len = FROM_SHORT(buffer);
        if (b < 3) {nemam(len);chyba=1;break;}
        if (len < 2) {printf("Error: Data integrity corrupted "
                             "(lenght=%d)\n",(int)(len-2));chyba=1;break;}

        if ((len!=19)||(buffer[2])!=0)
          {
          printf("Body - %03u..%05u",(unsigned)(buffer[2]),(unsigned)(len-2));
          parita = buffer[2]; len--;
          while(len)
            {
            c = len>lenbuf ? lenbuf : len;
            b = fread(body,1,c,fd);
            if (b == 0) {cantread();chyba=1;break;}
            len -= b;
            if (b < c)
              {printf(" - ???\n%6d\t",(int)ftell(fd));nemam(len);chyba=1;break;}
            for (b=0;b<c;b++) parita ^= body[b];
            }
          if (len) {chyba=1;break;}
          }
        else
          {
          printf("Head - ");
          b = fread(buffer+3,1,18,fd);
          if (b == 0) {cantread();chyba=1;break;}
          if (b < 18) {nemam(18-b);chyba=1;break;}
          for(b=4;b<14;b++)
            if (buffer[b]<32) putchar('.');
            else putchar(buffer[b]);
          for (parita=0,b=2;b<21;b++) parita ^= buffer[b];
          }
        if (parita)
          {
          printf(" - bad (%u)\t",parita);
          if ((strchr("bnyNY",znacka))&&(!rdonly))
            {
            printf("Reapir ? [y,n,a,s,e] ");
            do
              {
              znacka=getchar();
              if (strchr("nysaeNYSAE",znacka)) break;
              while (znacka != '\n') znacka=getchar();
              printf("\n\7Y=Yes  N=No  A=All  S=Skip  E=Exit ");
              }
            while (1);
            /* putchar('\t'); */
            if (strchr("eE",znacka))
              {
              printf("[exit]\n");
              fdx=fclose(fd);
              if (fdx!=0) cantclose(subor);
              exit(0);
              }
            }
          else
            printf ("\n");
          if (strchr("ayAY",znacka))
            {
            fseek(fd,-1,SEEK_CUR);                  /* oprava parity */
            b = fread(buffer,1,1,fd);
            fseek(fd,-1,SEEK_CUR);
            buffer[0] ^= parita;
            if (b<1) cantread();
            else b = fwrite(buffer,1,1,fd);
            if (b<1) {printf("\nError: Can't write into file\n");break;}
            printf("[corrected]\n");
            }
            else printf(rdonly ? "" : "[not corrected]\n");
          }
        else printf(" - OK\n");
        }
      if (!chyba) printf("%6d\tEnd of file %s\n",(int)ftell(fd),mm);
      fdx = fclose(fd);
      if (fdx!=0) cantclose(subor);
    }
  printf("\nDone. There was tested %d file(s).\n",files);
  return(0);
}

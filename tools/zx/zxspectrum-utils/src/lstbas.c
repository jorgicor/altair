/***************************************************************
** 08.07.2001 // LSTBAS // Busy soft: Basicovy prikaz LIST 01 **
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

#include <math.h>
#include <ctype.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include "endian-compat.h"

#define lenbuf 49152u
typedef unsigned char byte;
static byte buffer[lenbuf];

void pomoc(int x, char *name)
{printf(
"\nZX Spectrum LIST command 01           (c) 2001 Busy soft\n"
"Linux port and safe endian correction (c) 2002 Tritol\n");

if (x<2) {printf(
"\n  Usage: %s [options] filename.bas [>outfile.lst]\n"
"    List of basic program and variables in filename.bas\n"
"    Options: -c ... display control codes (characters 0-31)\n"
"             -n ... display value of each number (after code 14)\n"
"             -s ... display contens of simple strings (in variables)\n"
"             -h ... display basic listing in html format (with <TABLE>)\n", name);
printf("    If you use parameter \">outfile.lst\" for redirect standart output,\n"
"    all information will be printed to outfile.lst as plain or html text.\n"
"    Filename.bas must be plain binary file without any format headers.\n"
"    You can use 0tobin to make this filename.bas (for example).\n\n");

printf("This program is free software; you can redistribute it and/or modify it under\n"
"the terms of the GNU General Public License as published by the Free Software\n"
"Foundation; either version 2 of the License, or (at your option) any later\n"
"version.\n\n");

printf("This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
"WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
"PARTICULAR PURPOSE.\n"
"See the GNU General Public License for more details (http://www.gnu.org/).\n");

exit(1);}}

static char codes,nums,strs,html;
static char *tok[]={"RND","INKEY$","PI","FN ","POINT ","SCREEN$ ","ATTR ",
"AT ","TAB ","VAL$ ","CODE ","VAL ","LEN ","SIN ","COS ","TAN ","ASN ","ACS ",
"ATN ","LN ","EXP ","INT ","SQR ","SGN ","ABS ","PEEK ","IN ","USR ","STR$ ",
"CHR$ ","NOT ","BIN "," OR "," AND ","<=",">=","<>"," LINE "," THEN "," TO ",
" STEP "," DEF FN "," CAT "," FORMAT "," MOVE "," ERASE "," OPEN #"," CLOSE #",
" MERGE "," VERIFY "," BEEP "," CIRCLE "," INK "," PAPER "," FLASH "," BRIGHT ",
" INVERSE "," OVER "," OUT "," LPRINT "," LLIST "," STOP "," READ "," DATA ",
" RESTORE "," NEW "," BORDER "," CONTINUE "," DIM "," REM "," FOR "," GO TO ",
" GO SUB "," INPUT "," LOAD "," LIST "," LET "," PAUSE "," NEXT "," POKE ",
" PRINT "," PLOT "," RUN "," SAVE "," RANDOMIZE "," IF "," CLS "," DRAW ",
" CLEAR "," RETURN "," COPY "};

/************* Vypisy oddelovacich znakov *****************/
void beg(void) {printf(html?"<I>[":"\x11");}
void end(void) {printf(html?"]</I>":"\x10");}
void zac(void) {printf(html?"<I>[":"\xF3");}
void kon(void) {printf(html?"]</I>":"\xF2");}

/******** Vypis bezparametroveho riadiaceho kodu **********/
void kode(char*mm)
{if (codes) {zac(); printf("%s",mm); kon();}}

/******** Vypis jednoparametroveho riadiaceho kodu ********/
void kodik(char*mm,byte *bb)
{if (codes) {zac(); printf("%s %u",mm,*bb); kon();}}

/************* Vypis cisla z 5 bajtov *********************/
void number(unsigned char *ptr)
{
  unsigned char mem[5];
  int i;
  for (i=4;i>=0;i--) mem[i]=*(ptr+4-i);

  if (mem[4])
    {
    if (mem[3]>128) putchar('-');
    mem[3]|=0x80;
    printf("%.9g", (double)(FROM_INT(mem) * pow(2,mem[4]-160)));
    }
  else
    {
    mem[0]=ptr[2];
    mem[1]=ptr[3];
    mem[2]=ptr[1];
    mem[3]=ptr[1];
    printf("%d",FROM_INT(mem));
    }
}

/******** Vypis basic programu a premennych ************************/
void list(byte *bufzac, unsigned len, char *nazov)
{
  unsigned ee,lines,prems;
  byte *bb,*nn,dd,cc,pp,ss,vv;
  char *tt,pole[20];

  if (html) printf(
  "\n\n<HTML><HEAD><TITLE>%s</TITLE></HEAD>\n"
  " <BODY bgcolor=\"#E0E0E0\" text=\"#000000\"\n"
  " link=\"#0000FF\" vlink=\"#800000\" alink=\"#FF0000\">\n"
  " <font face=\"Courier New\">\n\n"
  " <TABLE border=0 cellspacing=4 cellpadding=0>\n",nazov);

  bb=bufzac;lines=0;prems=0;
  vv=1;
  while((*bb < 64) && (bb < bufzac+len))
    {
    if (vv) {putchar('\n');vv=0;}
    bb[2]=bb[0];bb++;
    printf(html?"<TR><TD valign=\"top\" align=\"right\">%u</TD><TD>\n":
                "%6u ",FROM_SHORT(bb));
    lines++;bb+=3;ss=0;
    while((cc=*(bb++))!=13)
      {
      switch(cc)
        {
        case 14:    /*** Cislo po kode 14 ***/
          if (nums) {beg();number(bb);end();}
          bb+=5;break;
        case 23:    /*** TAB riadiaci znak ***/
          if (codes) {zac();printf("tab %u",FROM_SHORT(bb));kon();}
          bb+=2;break;
        case 22:        /*** AT riadiaci znak ***/
          if (codes) {zac();printf("at %u,%u",*bb,*(bb+1));kon();}
          bb+=2;break;
        case 21: kodik("over",bb++);break;
        case 20: kodik("inverse",bb++);break;
        case 19: kodik("bright",bb++);break;
        case 18: kodik("flash",bb++);break;
        case 17: kodik("paper",bb++);break;
        case 16: kodik("ink",bb++);break;
        case 13: kode("enter");break;
        case  9: kode("right");break;
        case  8: kode("left");break;
        case  6: kode("comma");ss=0;break;
        case 127: printf("(c)");ss=1;break;
        case '&': if (html) {printf("&amp;");ss=1;break;}
        case '<': if (html) {printf("&lt;");ss=1;break;}
        case '>': if (html) {printf("&gt;");ss=1;break;}
        case 199: if (html) {printf("&lt;=");ss=1;break;}
        case 201: if (html) {printf("&lt;&gt;");ss=1;break;}
        case 200: if (html) {printf("&gt;=");ss=1;break;}
        default:
          {
          if (cc<32)
              {
              sprintf (pole, "%10d", cc);
              kode(pole);
              }
          else
            {
            if (cc<128) {putchar(cc);ss=1;}
            else if (cc<165) {putchar('\xFE');ss=1;}
            else
              {
              tt=tok[cc-165];
              if (*tt==32)
                {
                if (ss) putchar(' ');
                tt++;
                }
              printf("%s",tt);
              if (tt[strlen(tt)-1]==32) ss=0; else ss=1;
              }
            }
          }
        }
      }
    printf(html?"\n</TD></TR>":"\n");
    }

  if (html) printf("</TABLE></HTML>\n");

  vv=1;
  while (bb < bufzac+len)
    {
    if (vv) {printf("\nVariables:\n");vv=0;}
    prems++;
    ee = FROM_SHORT(bb+1);
    cc = *bb;
    pp = (cc & 0x1F) | 0x40;
    if ((pp<0x41)||(pp>0x5A)) cc=0;
    printf("  %c",pp);
    dd = bb[3];
    switch (cc & 0xE0)
      {
      case 0xE0:    /* FOR-NEXT cislo ********/
        printf("  (for-next ctrl)  Loop line=%u Stat=%u ",
        FROM_SHORT(bb+16),*((char*)(bb+18)));
        printf(" Value=");number(++bb);
        printf(" Limit=");number(bb+5);
        printf(" Step=");number(bb+10);
        putchar('\n');bb+=18;break;

      case 0xC0:    /* znakove pole **********/
        bb+=4;nn=bb--;bb+=ee;
        printf("$ (strings array)  DIM %c$(",pp);
        while(dd) {dd--;printf("%u%s",FROM_SHORT(nn),dd? "," :")\n");nn+=2;}
        break;

      case 0xA0:    /* viacpismenove cislo ***/
        bb++; do putchar ((*bb & 0x7f) - 0x20); while(*bb++ < 128);
        printf(" (simple number)  Value = ");
        number(bb);putchar('\n');bb+=5;break;

      case 0x80:    /* ciselne pole **********/
        bb+=4;nn=bb--;bb+=ee;
        printf("  (numbers array)  DIM %c(",pp);
        while(dd) {dd--;printf("%u%s",FROM_SHORT(nn),dd? "," :")\n");nn+=2;}
        break;

      case 0x60:    /* jednopismenove cislo **/
        printf("  (simple number)  Value = ");
        number(++bb);putchar('\n');bb+=5;break;

      case 0x40:    /* znakovy retazec *******/
        printf("$ (simple string)  Len=%u",ee);bb+=3;
        if (!strs) bb+=ee;
        else {
          printf(" \"");
          while(ee) {ee--;cc=*bb++;(cc>32)?putchar(cc):putchar('?');}
          putchar('"');}
        putchar('\n');break;

      default: /* datova nekonzistencia */
        printf("? - Unknown variable type 0x%02X\n",*bb);
        bb = bufzac+len+1;
      }
    }
  if (bb > bufzac+len) printf("  Data sequence corrupted\n");

  printf("\nEnd of list. Program has %u line(s)"
         " and %u variable(s).\n",lines,prems);
}

/******** Hlavna funkcia programu *************************/
int main(int argc, char *argv[])
{
  unsigned len,aa;
  long fdx,ll;
  int args;
  FILE *fd;
  char *nam;
  struct stat filestat;

  pomoc(argc, argv[0]);

  args=1; codes=0; nums=0; html=0;
  while(args<argc)
    {
    nam = argv[args];
    if (!strcmp(nam,"-c")) codes=1;
    else if (!strcmp(nam,"-n")) nums=1;
    else if (!strcmp(nam,"-s")) strs=1;
    else if (!strcmp(nam,"-h")) html=1;
    else break;
    args++;
    }
  if (args+1 != argc)
    {printf("To get help, run %s without any parameters.", argv[0]);exit(1);}

  nam = argv[args];
  printf("\nList of \"%s\"\n",nam);
  fd = fopen(nam,"rb");
  if (fd == NULL) {printf("Error: Can't open input file\n");exit(1);}
  if (stat (nam, &filestat)){printf("Can't get size\n");exit(1);}
  ll = (int)filestat.st_size;
  printf("(length:%ld)\n",ll);
  if (ll > lenbuf) {printf("Error: input file too long\n");exit(1);}
  len = ll;
  aa = fread(buffer,1,len,fd);
  if (aa < len) {printf("Error: Can't read input file\n");exit(1);}
  if (fclose(fd) != 0) {printf("Error: Can't close input file\n");exit(1);}

  for (fdx=len;fdx<len+20;fdx++) buffer[fdx]=0x80;
  buffer[len+10]=13;buffer[len+18]=13;
  list(buffer,len,nam);
  return(0);
}

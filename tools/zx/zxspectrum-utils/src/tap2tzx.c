/******************************************************************************
** TAP to TZX converter
**                                                                       v0.12b
** (c) 1997 Tomaz Kac
**
** Watcom C 10.0+ specific code... Change file commands for other compilers

**
**Amiga version compiled by Andrew Barker - andrew.barker@sunderland.ac.uk
**Compile: sc link uchar TAP2TZX.c
**
**Linux little modification by Tritol - ditol@email.cz
**Compile: gcc -Wall -o tap2tzx tap2tzx.c (or use suplied Makefile)
*/

#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

FILE *fhi, *fho;
long flen;
unsigned char *mem;
char buf[256];
long pos;
int len;
int block;
unsigned char tzxbuf[10] = {'Z', 'X', 'T', 'a', 'p', 'e', '!', 0x1A, 1, 3};

long FileLength (FILE* fh);
void Error (char *errstr);
void ChangeFileExtension (char *str, char *ext);


int main (int argc, char *argv[])
{
  printf ("\nZXTape Utilities - TAP to TZX Converter v0.12b\n");

  if (argc < 2 || argc > 3)
    {
    printf ("\nUsage: tap2tzx input.tap [output.tzx]\n");
    exit (0);
    }

  if (argc == 2) 
    {   
    strcpy (buf, argv[1]); 
    ChangeFileExtension (buf, "tzx"); 
    }
  else
    strcpy (buf, argv[2]);

  if ((fhi = fopen (argv[1], "rb")) == NULL) 
    Error ("Can't read file!");

  if ((fho = fopen(buf, "wb")) == NULL) 
    Error ("Can't create file!");

  flen = FileLength (fhi);

  if ((mem = (unsigned char *) malloc (flen)) == NULL) 
    Error ("Not enough memory to load input file!");

  if (fread (mem, 1, flen, fhi) != flen)
    Error ("Read error!");
  
  if (fwrite (tzxbuf, 1, 10, fho) != 10)
    Error ("Write error!");
  
  pos = block = 0;
  len = 1;
  buf[0] = 0x10;
  buf[1] = (unsigned char)0xE8;
  buf[2] = 0x03;

  while (pos < flen && len)
    {
    len = mem[pos + 0] + mem[pos + 1] * 256;
    pos += 2;
    if (len)
      {
      if (pos + len >= flen) buf[1] = buf[2] = 0; 
      buf[3] = len & 0xff;
      buf[4] = len >> 8;
      if (fwrite (buf, 1, 5, fho) != 5)
        Error ("Write error!");
      if (fwrite (&mem[pos], 1, len, fho) != len)
        Error ("Write error!");
      }
    pos += len;
    block++;
    }
  printf ("\nSuccesfully converted %d blocks!\n", block);
  fclose (fhi);
  fclose (fho);
  free (mem);
  return (0);
}

/* Changes the File Extension of String *str to *ext */
void ChangeFileExtension (char *str, char *ext)
{
  int n;
  
  n = strlen(str); 

  while (str[n] != '.') 
    n--;

  n++; 
  str[n] = 0;
  strcat (str, ext);
}

/* Determine length of file */
long FileLength (FILE* fh)
{
  long curpos, size;
  
  curpos = ftell(fh);
  fseek (fh, 0, SEEK_END);
  size = ftell(fh);
  fseek (fh, curpos, SEEK_SET);
  return (size);
}

/* exits with an error message *errstr */
void Error (char *errstr)
{
  printf ("\n-- Error: %s ('%s')\n", errstr, strerror (errno));
  exit (0);
}

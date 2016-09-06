/******************************************************************************
** TZX to TAP converter
**                                                                       v0.13b
** (c) 1997 Tomaz Kac
**
** Watcom C 10.0+ specific code... Change file commands for other compilers

**
**Amiga version compiled by Andrew Barker - andrew.barker@sunderland.ac.uk
**Compile: sc link uchar math=ieee TZX2TAP.c
**
**Linux little modification by Tritol - ditol@email.cz
**Compile: gcc -Wall -o tzx2tap tzx2tap.c (or use suplied Makefile)
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#define MAJREV 1        /* Major revision of the format this program supports */
#define MINREV 3        /* Minor revision -||- */

FILE *fhi, *fho;
long flen;
unsigned char *mem;
char buf[256];
long pos;
int len;
int block;
int longer, custom, only, dataonly, direct, not_rec;
unsigned char tzxbuf[10] = {'Z', 'X', 'T', 'a', 'p', 'e', '!', 0x1A, 1, 0};

int Get2 (unsigned char *mem) {return (mem[0] + (mem[1] * 256));}
int Get3 (unsigned char *mem) {return (mem[0] + (mem[1] * 256) + (mem[2] * 256 * 256));}
int Get4 (unsigned char *mem) {return (mem[0] + (mem[1] * 256) + (mem[2] * 256 * 256) + (mem[3] * 256 * 256 * 256));}

long FileLength (FILE* fh);
void Error (char *errstr);
void ChangeFileExtension (char *str, char *ext);


int main (int argc, char *argv[])
{
  printf ("\nZXTape Utilities - TZX to TAP Converter v0.13b\n");

  if (argc < 2 || argc > 3)
    {
    printf ("\nUsage: tzx2tap input.tzx [output.tap]\n");
    exit (0);
    }

  if (argc == 2) 
    {  
    strcpy (buf, argv[1]); 
    ChangeFileExtension (buf, "tap");
    }
  else      
    strcpy (buf, argv[2]);

  if ((fhi = fopen (argv[1], "rb")) == NULL) 
    Error ("Can't read file!");

  if ((fho = fopen (buf, "wb")) == NULL) 
    Error ("Can't create file!");

  flen = FileLength (fhi);

  if ((mem = (unsigned char *) malloc (flen)) == NULL) 
    Error ("Not enough memory to load input file!");

  if (fread (mem, 1, 10, fhi) != 10)
    Error ("Read error!");

  mem[7] = 0;

  if (strcmp ((char *)mem, "ZXTape!")) 
    { 
    free (mem);
    Error ("File is not in ZXTape format!");
    }

  printf ("\nZXTape file revision %d.%02d\n", mem[8], mem[9]);

  if (!mem[8]) 
    Error ("Development versions of ZXTape format are not supported!");

  if (mem[8] > MAJREV) 
    printf ("\n-- Warning: Some blocks may not be recognised and used!\n");

  if (mem[8] == MAJREV && mem[9] > MINREV) 
    printf ("\n-- Warning: Some of the data might not be properly recognised!\n");

  if (fread (mem, 1, flen - 10, fhi) != (flen - 10))
    Error ("Read error!");

  pos = block = longer = custom = only = dataonly = direct = not_rec = 0;

  while (pos < flen - 10)
    {
    pos++;
    switch (mem[pos - 1])
      {
      case 0x10: len = Get2(&mem[pos + 0x02]);
                 if (fwrite (&mem[pos + 0x02], 1, 2, fho) != 2)
                   Error ("Write error!");
                 if (fwrite (&mem[pos + 0x04], 1, len, fho) != len)
                   Error ("Write error!");
                 pos += len + 0x04;
                 block++;
                 break;
      case 0x11: len = Get3 (&mem[pos + 0x0F]);
                 if (len < 65536)
                   {
                   if (fwrite (&mem[pos + 0x0F], 1, 2, fho) != 2)
                     Error ("Write error!");
                   if (fwrite (&mem[pos + 0x12], 1, len, fho) != len)
                     Error ("Write error!");
                   block++;
                   }
                 else 
                   longer = 1;
                 custom = 1;
                 pos += len + 0x12;
                 break;
      case 0x12: only = 1;
                 pos += 0x04;
                 break;
      case 0x13: only = 1;
                 pos += (mem[pos + 0x00] * 0x02) + 0x01;
                 break;
      case 0x14: len = Get3 (&mem[pos + 0x07]);
                 if (len < 65536)
                   {
                   if (fwrite (&mem[pos + 0x07], 1, 2, fho) != 2)
                     Error ("Write error!");
                   if (fwrite (&mem[pos + 0x0A], 1, len, fho) != len)
                     Error ("Write error!");
                   block++;
                   }
                 else 
                   longer = 1;
                 dataonly = 1;
                 pos += len + 0x0A;
                 break;
      case 0x15: direct = 1;
                 pos += Get3 (&mem[pos + 0x05]) + 0x08;
                 break;
      case 0x20: pos += 0x02; break;
      case 0x21: pos += mem[pos + 0x00] + 0x01; break;
      case 0x22: break;
      case 0x23: pos += 0x02; break;
      case 0x30: pos += mem[pos + 0x00] + 0x01; break;
      case 0x31: pos += mem[pos + 0x01] + 0x02; break;
      case 0x32: pos += Get2 (&mem[pos + 0x00]) + 0x02; break;
      case 0x33: pos += (mem[pos + 0x00] * 0x03) + 0x01; break;
      case 0x34: pos += 0x08; break;
      case 0x35: pos += Get4 (&mem[pos + 0x10]) + 0x14; break;
      case 0x40: pos += Get3 (&mem[pos + 0x08]) + 0x0B; break;
      case 0x5A: pos += 0x09; break;
      default:   pos += Get4 (&mem[pos + 0x00] + 0x04);
                 not_rec = 1;
      }
    }

  printf ("\n");

  if (custom) 
    printf ("-- Warning: Custom Loading blocks were converted!\n");

  if (longer) 
    printf ("-- Warning: Over 64k long Custom Loading blocks were *not* converted!\n");

  if (only) 
    printf ("-- Warning: Some Pure Tone and/or Sequence of Pulses blocks encountered!\n");

  if (dataonly) 
    printf ("-- Warning: Data Only blocks were converted!\n");

  if (direct) 
    printf ("-- Warning: Direct Recording blocks were encountered!\n");

  if (not_rec) 
    printf ("-- Warning: Some blocks were NOT recognised !\n");

  printf ("Succesfully converted %d blocks!\n", block);
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
  
  curpos = ftell (fh);
  fseek (fh, 0, SEEK_END);
  size = ftell (fh);
  fseek (fh, curpos, SEEK_SET);
  return (size);
}

/* exits with an error message *errstr */
void Error (char *errstr)
{
  printf ("\n-- Error: %s ('%s')\n", errstr, strerror (errno));
  exit (0);
}


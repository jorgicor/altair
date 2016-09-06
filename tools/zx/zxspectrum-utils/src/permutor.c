/* 
 * Copyright (C) 2013 UB880D
 * Email: ub880d@users.sf.net
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version. See the file COPYING. 
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

/* $Rev: 20 $ */

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>

#define MAXEEPROMLEN 65536

#define DIVIDE_ADDR "B6249A857310C"
#define DIVIDE_DATA "54320761"


int hextodec(char ch) {
  if (ch>='0' && ch<='9') return ch-'0';
  if (ch>='A' && ch<='F') return ch-'A'+10;
  if (ch>='a' && ch<='f') return ch-'a'+10;
  return -1;
}

int validate_hex(char *ptr, int maxlen) {
  int l,i;
  l=strlen(ptr);
  
  if (l>maxlen) return -1;
  
  while (*ptr) {
    i=hextodec(*ptr);
    if (i<0 || i>=l) return -1;
    ptr++;
  }
  return 0;
}

/* dir = direction 0-normal 1-reverse */
int scramble_value(char *perm, int val, int dir) {
  int i,l,ret;
  char *ptr = perm;
  
  l = strlen(ptr) - 1;
  
  if (l<1) return val;
  
  ret = 0;
  
  if (!dir) {
    for (i = l; i >= 0; i--, ptr++)
      ret |= ((( val >> hextodec(*ptr) ) & 1) << i );
  } else {
    for (i = l; i >= 0; i--, ptr++)
      ret |= ((( val >> i ) & 1) << hextodec(*ptr) );
  }
  
  return ret;
}

int main(int argc, char **argv) {
  unsigned char buffer[MAXEEPROMLEN];
  unsigned char buffer2[MAXEEPROMLEN];
  
  char *str_data, *str_addr;
  int len, addr, dir, ok, farg;
  FILE *fd;
  
  /* defaults */
  str_data = (char *)DIVIDE_DATA;
  str_addr = (char *)DIVIDE_ADDR;
  dir=0; /* direction (for divide predefined values) */
  farg=3; /* first filename argument */
  ok=0;
  
  /* test if there is permutation on cmdline */
  if (argc==5 && !validate_hex(argv[1], 8) && !validate_hex(argv[2], 16)) {
    str_data = argv[1];
    str_addr = argv[2];
    ok=1;
  }
  
  /* test if we want to use predefined scramble permutation */
  if (argc==4 && !strcmp(argv[1], "--divide")) {
    farg=2;
    ok=1;
  }
  
  /* test if we want to use predefined reverse scramble permutation */
  if (argc==5 && !strcmp(argv[1], "--divide") && !strcmp(argv[2], "--reverse")) {
    dir=1;
    ok=1;
  }
  
  if (!ok) {
    printf("Usage: %s <datastring> <addrstring> <infile> <outfile>\n", argv[0]);
    printf("   or: %s \"--divide\" [\"--reverse\"] <infile> <outfile>\n", argv[0]);
    return 1;
  }
  
  if ((fd = fopen(argv[farg], "rb")) == NULL) {
    printf("%s: %s\n", argv[farg], strerror(errno));
    return 1;
  }
  
  /* address permutation string tells us how big memory we need */
  if ((len = fread(buffer, 1, (1 << strlen(str_addr)), fd )) != (1 << strlen(str_addr))) {
    printf("No enough data\n");
    fclose(fd);
    return 1;
  }
  
  fclose(fd);
  
  if ((fd = fopen(argv[farg+1], "wb")) == NULL) {
    printf("%s: %s\n", argv[farg], strerror(errno));
    return 1;
  }
  
  /* scramble file */
  for (addr = 0; addr < len; addr++)
    buffer2[ scramble_value(str_addr, addr, dir) ] = scramble_value(str_data, buffer[addr], dir);

  /* write the same amount of data */
  if ((len = fwrite(buffer2, 1, (1 << strlen(str_addr)), fd )) != (1 << strlen(str_addr))) {
    printf("No all data written\n");
    fclose(fd);
    return 1;
  }
  
  fclose(fd);
  return 0;
}


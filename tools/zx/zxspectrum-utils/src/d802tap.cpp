/*******************************************************************************
*                                D802TAP                                       *
********************************************************************************
* Description:                                                                 *
*     Transform data from MDOS image file to ZX Spectrup TAP file.             *
*------------------------------------------------------------------------------*
* Version: 1.3 stable                                                          *
*------------------------------------------------------------------------------*
* Developer:                                                                   *
*     Ing. Marek Zima, Slovak Republic, marek_zima@yahoo.com or zimam@host.sk  *
* Bugfixers:                                                                    *
*     Lubomir Blaha (tritol@trilogic.cz) @2005, Poke @2004, MikeZT @2007                                        *
*------------------------------------------------------------------------------*
* License:                                                                     *
*     GNU License                                                              *
*------------------------------------------------------------------------------*
* Programmed in:                                                               *
*     GNU C with libC (Dev-C++ 4.0)                                            *
*------------------------------------------------------------------------------*
* Building:                                                                    *
*     g++ -o d802tap d802tap.cpp                                               *
*******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define VERSION "1.3 stable" // Version identifier. (Change after changes!)

#define FALSE 0
#define TRUE !FALSE

#define BYTE unsigned char
#define WORD unsigned short int

#define DISKSECTORS 10
#define DISKTRACKS 94
#define DISKLENGTH DISKTRACKS*DISKSECTORS*2*512 //94 tracks*10 sectors*2 sides*512B  sec. length
#define SEKTORLENGTH 512
#define FATADDR 512     //0x200 - 1st sector
#define BOOTSECTORDATA 0x80

typedef struct {                          // Header in TAP file
                WORD headerlength;
                BYTE flag;
                BYTE type;
                BYTE filename[10];
                WORD blocklength;
                WORD param1;
                WORD param2;
                BYTE checksum;
               } HEADER;

typedef struct {                          // MDOS boot sector
//                BYTE nothing[128];        // nothing inside this array ;)
                BYTE unknown[48];         // I really don't know, what's inside!!!
                BYTE mark;                // ??? 0x81 - mark ????
                BYTE disktype;            // type of disk
                BYTE numoftrack;          // number of tracks per side
                BYTE numofsec;            // number of sectors per track
                BYTE zero;                // always 0
                BYTE copyofdisktype;      // copy of type of disk
                BYTE copyofnumoftrack;    // copy of number of tracks per side
                BYTE copyofnumofsec;      // copy of number of sectors per track
                BYTE empty[8];            // zeros ;)
                BYTE nameofdisk[10];      // Name od disk
                BYTE random[2];           // Random numbers - for unique disk
                BYTE identificaton[4];    // Identification of disk
               } BOOTSEC;

typedef struct {                          // ITEM record
                BYTE extention;           // Extention (P,B,N,C,S,Q)
                BYTE filename[10];        // Filename
                BYTE length[2];           // file length
                BYTE startaddr[2];        // start address or start line for BASIC
                BYTE BASIClength[2];      // lenght of BASIC program without variables
                BYTE firstsec[2];         // fist sektor that file occupies
                BYTE zero;                // always 0
                BYTE attributes;          // file attributes
                BYTE morelenght;          // 3rd byte of file length if > 65535
                BYTE filledwithE5[10];    // filled by 0xE5
               } ITEMREC;


// boot sector from image file
BOOTSEC bootsektor;


// ------------------ Global variable definitions ------
FILE *in,*out;                       // file descriptors for input/output files
BYTE *diskimg;                       // pointer to memory, where we read image
long fileoffset;                     // offset inside input file

// ------------------ Functions declarations ------
BYTE d802tap (void);
void readdiskimg (void);
BYTE checkimage(void);
WORD getFATnum (WORD sector);
BYTE copydata(ITEMREC *);
BYTE checksum (BYTE *, WORD);
void freediskimg (void);
BYTE extention(BYTE);
void zerotospace(BYTE *);
BYTE pause(char *);

int main(int argc,char *argv[])
{
 int retval = 0;       // Suppose, everything will be OK
 BYTE pausereq = FALSE;// PAUSE request
 printf(">>> D802TAP %s - @2002 by Marek Zima <<<\n",VERSION);
 printf("Fixed by Tritol @2005, Poke @2004, MikeZT @2007\n\n");
 if( ((argc<3) || (argc>4)) || ((argc==4) && ((pausereq=pause(argv[3]))==FALSE)) ){
   printf("Syntax: d802tap <d80file.d80> <tapfile.tap> [p/P]\n");
   printf("        [p/P] - PAUSE\n");
   return(1);
 }
 in = fopen(argv[1],"rb");                // open input file
 if (in !=NULL)                           // if successfull
 {
  readdiskimg();                          // read image file to memory
  switch (checkimage()){                  // Check If it's SDOS disk image
   case 0:
    if((out=fopen(argv[2],"ab")) != NULL){  // Create/Append output file
      if(d802tap()){   // transfer data from TAP to image in memory
        printf("Finished successfull.\n");  // if successful write memory to image file
      }                                     // if everything is OK, display information
      fclose(out);                          // close output file
    } else {
      printf("Can't create TAP file '%s'!\n",argv[2]);
    }
    break;
   case 1:                                // It's not SDOS disk image
    printf("'%s' is not D80 disk image!\n",argv[2]);
    retval=3;
    break;
   default:                               // SDOS image has not supported format
    printf("Existing D80 image in '%s' is not supported!\n",argv[2]);
    retval=4;
  }
  freediskimg();                          // free allocated memory
  fclose(in);                             // close input TAP file
 }
 else                                     // if input file was not opened
 {
  printf("Can't open input D80 image file '%s'!\n",argv[1]);
  retval=2;
 }
 printf("\n");                            // Make one empty line
 if(pausereq == TRUE){                    // if user want PAUSE
   printf("Press ENTER to continue . . .\n");
   getchar();
 }
 return(retval);                          // Return result of transfer.
}

// ------------------- Heart of transfer MDOS to TAP -----------
BYTE d802tap (void)
{
 HEADER header;
 ITEMREC itemrec;
 WORD blocklength;
 int i;
 BYTE *fileindir,datablock=0xFF;
 BYTE dirsektors[8] = {6,8,10,12,7,9,11,13};
 BYTE index;

 for (index=0;index<8;index++){
  fileindir = diskimg+(dirsektors[index]*SEKTORLENGTH); // first file in dir sector
  while (fileindir < diskimg+(dirsektors[index]*SEKTORLENGTH)+SEKTORLENGTH){
   memcpy(&itemrec,fileindir,sizeof(ITEMREC));          // read file info
   if (itemrec.extention != 0xE5) {    // VALID FILE
       printf("Processing >>> ");
       i=0;
       while((i<10) && (itemrec.filename[i] != '\0')){   // write the file name
         printf("%c",itemrec.filename[i]);
         i++;
       }
       if (extention(itemrec.extention) != 0xFF) {       // File for transform
         printf(".%c - %d bytes\n",itemrec.extention,(itemrec.length[0] + 256 * itemrec.length[1]));
         if(itemrec.extention != 'H'){      // WE NEED CREATE A HEADER
           header.headerlength = 0x0013;
           header.flag = 0x00;
           header.type = extention(itemrec.extention);
           memcpy(header.filename,itemrec.filename,16);
           zerotospace(header.filename);
           header.checksum = checksum(&header.flag,18);
           fwrite(&header,1,header.headerlength+2,out);
         } else {
           datablock = itemrec.zero;         // Here is flag for HEADERLESS
         }
         blocklength = (itemrec.length[0]+256*itemrec.length[1])+2;
         fwrite(&blocklength,1,2,out);   // Block length
         fwrite(&datablock,1,1,out);     // 0xFF - Data block
         if ((blocklength == 2)          // Empty file - length == 0
            || (getFATnum(itemrec.firstsec[0]+256*itemrec.firstsec[1])==0xC00)){  // FAT record == 0xC00
           fwrite(&datablock,1,1,out);   // 0xFF - CRC for empty block
         } else {
           if(copydata(&itemrec) == 0){  // if error during copy
             printf("Disk error!!!\n");
             return(0);
           }
         }
       } else {
         printf(" - SKIPED\n");
       }
   }
   fileindir += sizeof(ITEMREC);
  }
 }
 return(1);
}

// ------------------- Disk image functions -----------

void readdiskimg (void)
{
 diskimg = (BYTE *)malloc(DISKLENGTH); // Get memory
    memset(diskimg,0,DISKLENGTH);      // set by 0 (clear)
 if(diskimg != NULL){
    fread(diskimg,1,DISKLENGTH,in);    // read image file to memory
    memcpy(&bootsektor,diskimg+BOOTSECTORDATA,sizeof(BOOTSEC)); // read boot sector
 }else{
    printf("Can't alloc memory for disk image!\n");
    fclose(in);                             // close input TAP file
    exit(2);
 }
}

BYTE checkimage (void)        // Check disk image for MDOS disk
{
 BYTE retval;
 if(strncmp((char*)bootsektor.identificaton,"SDOS",4) == 0){
   retval = 0;
 } else {
   retval = 1;
 }
 if (retval == 0){            // If image is correct SDOS (MDOS)
                              // check it for 2 sides, 80 track per side,
                              // 9 sectors per track
   if((bootsektor.numoftrack <= DISKTRACKS) && (bootsektor.numofsec <= DISKSECTORS)){
     retval = 0;
   } else{
     retval = 2;
   }
 }
 return(retval);
}

// ------------------- Working with FAT -----------
WORD getFATnum (WORD sector)        // Get value from FAT according sector
{

  WORD retval,secinfatsector;
  WORD *offset;
  secinfatsector=sector%341;
  offset=(WORD *)(diskimg+FATADDR+(sector/341*SEKTORLENGTH)+(secinfatsector*3/2));  // Get offset
  if (secinfatsector%2 == 0){              // Even sector
    retval = *offset & 0x00FF;
    retval = retval | ((*offset>>4) & 0x0F00);
  } else{                                  // Odd sector
    retval = ((*offset>>8) | (*offset << 8)) & 0x0FFF;
  }
  return(retval);
}

// ------------------- Working with directory -----------
BYTE copydata (ITEMREC *itemrec)    // transfer data from TAP block to disk image
{
 BYTE *offset,CRC;
 WORD sektor,sektorvalue;
 if (itemrec->extention == 'H'){     // For HEADERLESS blocks
   CRC = itemrec->zero;              // is flag here
 } else {                            // else there are data after HEADER
   CRC=0xFF;                         // Start with data type
 }
 sektor = itemrec->firstsec[0]+256*itemrec->firstsec[1];
 while((sektorvalue=getFATnum(sektor)) < 0xE00)  // While not last sektor
 {
   if (sektorvalue == 0xDFF) return(0);          // Vadny sektor (disk image)
   offset = diskimg+(sektor*SEKTORLENGTH);
   fwrite(offset,1,SEKTORLENGTH,out);
   CRC ^= checksum(offset,SEKTORLENGTH);
   sektor = sektorvalue;
 }
 offset = diskimg+(sektor*SEKTORLENGTH);
 if(sektorvalue == 0xE00){                        // Last sektor
   fwrite(offset,1,SEKTORLENGTH,out);
   CRC ^= checksum(offset,SEKTORLENGTH);
 } else if (sektorvalue > 0xE00){
   fwrite(offset,1,sektorvalue & 0x01FF,out);
   CRC ^= checksum(offset,sektorvalue & 0x01FF);
 }
 fwrite(&CRC,1,1,out);
 return(1);
}

// ------------------- Tools -----------
BYTE checksum (BYTE *ptr, WORD len)    // check sum for directory name
{                                      // simple XOR through bytes
 int i;
 BYTE xorval=0;
 for (i=0;i<len;i++){
   xorval^= *(ptr+i);       // XOR
 }
 return (xorval);
}

void freediskimg (void)  // free memory occuped by image
{
 if (diskimg != NULL){
    free(diskimg);
 }
}

BYTE extention (BYTE value)      // Transform extention type from TAP to D80
{
 BYTE retval;
 switch (value){
   case 'P': retval=0; break;
   case 'C': retval=1; break;
   case 'N': retval=2; break;
   case 'B': retval=3; break;
   case 'H': retval=4; break;
   default:
           retval=0xFF;          // Don't transform this file to TAP
 }
 return(retval);
}

void zerotospace (BYTE *filename)   // Change zeros in string to spaces
{
 BYTE *str;
 str=filename+9;
 while (*str == '\0'){
   *str = ' ';       // change SPACE to " "
   str--;
 }
}

BYTE pause (char *param)      // Pause requested?
{
 if ((strcmp(param,"P") == 0) || (strcmp(param,"p") == 0)){
   return(TRUE);
 } else {
   return(FALSE);
 }
}

/*******************************************************************************
*                               END OF FILE                                    *
*******************************************************************************/


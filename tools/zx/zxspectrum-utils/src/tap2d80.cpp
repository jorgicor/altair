 /*******************************************************************************
*                                TAP2D80                                       *
********************************************************************************
* Description:                                                                 *
*     Transform data from ZX Spectrum TAP file to new or existing MDOS image   *
*     file.                                                                    *
*------------------------------------------------------------------------------*
* Version: 1.2 stable                                                          *
*------------------------------------------------------------------------------*
* Developer:                                                                   *
*     Ing. Marek Zima, Slovak Republic, marek_zima@yahoo.com or zimam@host.sk  *
* Bugfixer:                                                                    *
*     Lubomir Blaha (tritol@trilogic.cz) @2005, Poke @2011, UB880D @2011                   *
*------------------------------------------------------------------------------*
* License:                                                                     *
*     GNU License                                                              *
*------------------------------------------------------------------------------*
* Programmed in:                                                               *
*     GNU C with libC (Dev-C++ 4.0)                                            *
*------------------------------------------------------------------------------*
* Building:                                                                    *
*     g++ -o tap2d80 tap2d80.cpp                                               *
*******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define VERSION "1.2 stable" // Version identifier. (Change after changes!)

#define FALSE 0
#define TRUE !FALSE

#define BYTE unsigned char
#define WORD unsigned short int

#define DISKLENGTH 737280L
#define SEKTORLENGTH 512
#define FATADDR 512     //0x200 - 1st sector
#define DIRSECTORADDR 0xC00
#define BOOTSECTORDATA 0x80
#define DEFAULTNAME "BODY     "

typedef struct {
                WORD blocklength;
                BYTE flag;
                BYTE type;
               } BLOCKINFO;

typedef struct {                          // Header in TAP file
                BLOCKINFO blockinfo;
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


// boot sector for new image file
BOOTSEC bootsektor =   {
                        { 0x81,0x18,0x50,0x09,0x00,0x18,0x50,0x09,   // BIG MESS
                        0x00,0x00,0x00,0x00,0x01,0x14,0x50,0x28,
                        0x00,0x14,0x28,0x09,0x00,0x00,0x00,0x00,
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 },
                        0x81,
                        0x18,                    // 2 sides, 40 tracks drive
                        0x50,                    // 0x50 tracks per side
                        0x09,                    // 0x09 sectors per track
                        0x00,                    // always 0
                        0x18,                    // copy of type of disk
                        0x50,                    // copy of tracks per side
                        0x09,                    // copy of sectors per track
                        { 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 },  // empty
                        { 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00 }, // name of disk
                        { 0x00,0x00 },   // random numbers - filled by program
                        { 'S','D','O','S' }  // disk identification
                       };


// ------------------ Global variable definitions ------
FILE *in,*out;                       // file descriptors for input/output files
BYTE *diskimg;                       // pointer to memory, where we read image
long fileoffset;                     // offset inside input file
BYTE numofheaderless;                // number of headerless blocks

// ------------------ Functions declarations ------
BYTE tap2d80 (void);
void preparediskimg (void);
void readdiskimg (void);
void makesystemident(void);
BYTE checkimage(void);
void initFAT (void);
void updateFAT (WORD,WORD);
WORD getFATnum (WORD sector);
WORD notusedsecfromFAT (WORD);
BYTE createitem(ITEMREC *);
BYTE copydata(ITEMREC *);
BYTE writeD80 (char *);
void freediskimg (void);
void preparediskname(char*);
BYTE extention(BYTE);
void spacetozero(BYTE *);
BYTE pause(char *);

int main(int argc,char *argv[])
{
 int retval = 0;        // Suppose, everything will be OK
 BYTE pausereq = FALSE; // PAUSE request
 printf(">>> TAP2D80 %s - @2002 by Marek Zima <<<\n",VERSION);
 printf("Fixed by Tritol @2005, Poke @2011, UB880D @2011\n\n");
 if( ((argc<3) || (argc>4)) || ((argc==4) && ((pausereq=pause(argv[3]))==FALSE)) ){
   printf("Syntax: tap2d80 <tapfile.tap> <d80file.d80> [p/P]\n");
   printf("        [p/P] - PAUSE\n");
   return(1);
 }
 in = fopen(argv[1],"rb");                // open input file
 if (in !=NULL)                           // if successfull
 {
  if((out=fopen(argv[2],"rb")) == NULL){  // if output file doesn't exist
    preparediskname(argv[2]);             // Prepare name for disk
    preparediskimg();                     // create empty MDOS disk image
  }else{                                  // if output file exists (do APPEND)
    readdiskimg();                        // read image file to memory
    fclose(out);                          // close output file
  }
  numofheaderless=0;                      // No headerless block yet
  switch (checkimage()){                  // Check If it's SDOS disk image
   case 0:
    if(tap2d80() && writeD80(argv[2])){   // transfer data from TAP to image in memory
      printf("Finished successfull.\n");  // if successful write memory to image file
    }                                     // if everything is OK, display information
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
  printf("Can't open input file '%s'!\n",argv[1]);
  retval=2;
 }
 printf("\n");                            // Make one empty line
 if(pausereq == TRUE){                    // if user want PAUSE
   printf("Press ENTER to continue . . .\n");
   getchar();
 }
 return(retval);                          // Return result of transfer.
}

// ------------------- Heart of transfer TAP to MDOS -----------
BYTE tap2d80 (void)
{
 BYTE oldflag = 0xFF;            // Previous record was header or data ?
 HEADER header;
 ITEMREC itemrec;
// long blocklen;
 int i;
 char defaultname[11];

 fileoffset=0;            // start from begining of file
 while (fread(&header.blockinfo,1,sizeof(BLOCKINFO),in)){     // read block info
       printf("Processing >>> ");
       if ((header.blockinfo.flag == 0) && (header.blockinfo.blocklength == 0x0013)){
          printf("HEADER: length=%d bytes, flag=0x%x, name: ",header.blockinfo.blocklength,header.blockinfo.flag);
          fread(&header.filename,1,sizeof(HEADER)-sizeof(BLOCKINFO),in);  // read header
          for(i=0;i<10;i++){                      // write the name from header
            printf("%c",header.filename[i]);
          }
          printf("\n");
          memset(&itemrec,0,sizeof(ITEMREC));               // prepare item to dir
          itemrec.extention=extention(header.blockinfo.type);  // extention
          memcpy(&itemrec.filename[0],&header.filename[0],16); // copy header
          spacetozero(&itemrec.filename[0]);
#ifdef DEBUG
          printheader(&header);
#endif
          oldflag=header.blockinfo.flag;       // remember flag
       }else{
          printf("DATABLOCK: length=%d bytes, flag=0x%x\n",header.blockinfo.blocklength-2,header.blockinfo.flag);
          if(oldflag != 0){
            memset(&itemrec,0,sizeof(ITEMREC));               // prepare item to dir
            itemrec.extention='H';  // extention for HEADERLESS block
            itemrec.zero=header.blockinfo.flag; // Flag byte
            sprintf(defaultname,"%s%c",DEFAULTNAME,'A'+(numofheaderless++));
            memcpy(&itemrec.filename[0],defaultname,10); // copy header

	    i=header.blockinfo.blocklength-2; // data length
            itemrec.length[0] = i % 256;
	    itemrec.length[1] = i / 256;
          }
          oldflag=header.blockinfo.flag;           // remember flag
	  i=notusedsecfromFAT(0);   // get available sector from FAT
          itemrec.firstsec[0] = i % 256;
	  itemrec.firstsec[1] = i / 256;
          itemrec.attributes=0x0F;
          memset(&itemrec.filledwithE5[0],0xE5,10);
#ifdef DEBUG
          printitemrec(&itemrec);
#endif
          if(createitem(&itemrec)== 0){                  // Not place for record
            printf("Directory full!!!\n");               // so disk is full
            return(0);
          }
          fseek(in,-1,SEEK_CUR);         // one BYTE back (type), data block hasn't it
          if(copydata(&itemrec) == 0){   // if is no place for data
            printf("Disk full!!!\n");    // disk is really full
            return(0);
          }
       }
       fileoffset+=header.blockinfo.blocklength+2;    // set positon in
       fseek(in,fileoffset,SEEK_SET);                 // input file
 }
 return(1);
}

// ------------------- Disk image functions -----------
void preparediskimg (void)
{
 diskimg = (BYTE *)malloc(DISKLENGTH); // Get memory
    memset(diskimg,0,DIRSECTORADDR);   // set by 0 (clear) (boot,fat)
    memset(diskimg+DIRSECTORADDR,0xE5,DISKLENGTH-DIRSECTORADDR); // set by 0xE5 (dir, data)
    makesystemident();                 // Disk ident
 if(diskimg != NULL){                  // create empty disk image
    memcpy(diskimg+BOOTSECTORDATA,&bootsektor,sizeof(BOOTSEC));   // copy boot sector
    initFAT();                                     // init FAT
 }else{
    printf("Can't alloc memory for disk image!\n");
    fclose(in);                             // close input TAP file
    exit(2);
 }
}

void readdiskimg (void)
{
 diskimg = (BYTE *)malloc(DISKLENGTH); // Get memory
    memset(diskimg,0,DISKLENGTH);      // set by 0 (clear)
 if(diskimg != NULL){
    fread(diskimg,1,DISKLENGTH,out);   // read image file to memory
    memcpy(&bootsektor,diskimg+BOOTSECTORDATA,sizeof(BOOTSEC)); // read boot sector
 }else{
    printf("Can't alloc memory for disk image!\n");
    fclose(in);                             // close input TAP file
    exit(2);
 }
}

void makesystemident(void)    // Generate system identification for disk image.
{                             // Generate 32 random numbers
 int i;
 srand(time(0));
 for (i=0;i<2;i++){
  bootsektor.random[i]=rand()%256;
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
   if((bootsektor.disktype & 0x10) && (bootsektor.numoftrack == 0x50)
       && (bootsektor.numofsec == 0x09)){
     retval = 0;
   } else{
     retval = 2;
   }
 }
 return(retval);
}

// ------------------- Working with FAT -----------
void initFAT (void)        // Create FAT for empty disk image
{
 WORD i;
 BYTE *offset;
 for (i=0;i<(DIRSECTORADDR - FATADDR)/SEKTORLENGTH;i++){
   offset=diskimg+FATADDR+((i+1)*SEKTORLENGTH)-1;  // Get offset to FAT sektor end
   *offset = (*offset & 0xF0) | 0x0D;              // crank FAT
 }
 for (i=0;i<14;i++){       // Set 14 sectors to reserved (BOOT,FAT,DIR)
   updateFAT(i,0x0DDD);
 }
 for (i=DISKLENGTH/SEKTORLENGTH;i<((DIRSECTORADDR - FATADDR)*2/3)-1; i++){ // sectors above DISKLENGHT
   updateFAT(i,0x0DDD);                                          // set to unused
 }
}

void updateFAT (WORD sektor,WORD value)   // Write value to FAT according sektor
{
// BYTE hibyte;
 BYTE *offset;
 WORD secinfatsector;
 secinfatsector=sektor%341;
 offset=diskimg+FATADDR+(sektor/341*SEKTORLENGTH)+(secinfatsector*3/2);  // Get offset
 if (secinfatsector%2 == 0){              // Even sector
    *offset=(BYTE)(value&0x00FF);         // Low byte
    *(offset+1)= (*(offset+1)&0x0F) | (BYTE)((value & 0x0F00) >> 4); // Hi byte to high part
 } else{                                  // Odd sector
    *(offset+1)=(BYTE)(value&0x00FF);     // Low byte
    *(offset)= (*(offset)&0xF0) | (BYTE)((value & 0x0F00) >> 8); // Hi byte to high part
 }
}

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

WORD notusedsecfromFAT (WORD used)   // Get available sector from FAT
{
 WORD sektor=1, maxsektor;
 maxsektor = DISKLENGTH/SEKTORLENGTH;
 while (((getFATnum(sektor) != 0) || (sektor == used))
       && (sektor < maxsektor))  sektor++;
 if (sektor >= maxsektor){
   sektor = 0;
 }
 return(sektor);
}

// ------------------- Working with directory -----------
BYTE createitem (ITEMREC *itemrec)   // Create item in directory
{
 BYTE *start,*end,*rootdir;
 BYTE retval = 1;
 BYTE dowhile=TRUE;
 BYTE dirsektors[8] = {6,8,10,12,7,9,11,13};
 BYTE index=0;

 while(dowhile){
   start=diskimg+(dirsektors[index]*SEKTORLENGTH); // offset to "index" dir sector
   rootdir=start;
   end=start+SEKTORLENGTH;                // end of "index" dir sector
   // look for empty space
   while((*rootdir != 0xE5) && (*rootdir != 0x00) && (rootdir < end))
     rootdir+=sizeof(ITEMREC);
   if (rootdir < end){                        // if empty space found
      memcpy(rootdir,itemrec,sizeof(ITEMREC));    // write item do dir
      dowhile=FALSE;
   }else{                                   // if empty space didn't find
        index++;                            // try next sector
        if(index >= 8){                     // if there is not available space
          retval=0;                         // directory is really full ;)
          dowhile=FALSE;
        }
   }
 }
 return(retval);
}

BYTE copydata (ITEMREC *itemrec)    // transfer data from TAP block to disk image
{
 unsigned offset,counter=0;
 WORD length,totallength;
 WORD used,notused;
 length=itemrec->length[0]+256*itemrec->length[1];
				    // length of data to be trasfered
 totallength=length;                // remember total langth
 used=itemrec->firstsec[0]+256*itemrec->firstsec[1];
 				    // get 1st sector for data
 offset=used*SEKTORLENGTH;          // offset to this sector in disk image
 if(length == 0){                   // if empty bloch
   updateFAT(used,0xC00);           // update FAT, (empty block)
 }
 while(length > 0)                  // (don't transfer 0 bytes ;)
 {
  if(length > SEKTORLENGTH){        // if data length is higher than sector length
    fread(diskimg+offset,1,SEKTORLENGTH,in); // copy data for sector
    notused=notusedsecfromFAT(used);         // look for next available sector
    offset=notused*SEKTORLENGTH;             // offset to this sector in disk image
    if(offset == 0) return(0);               // available sector didn't find. Disk is really full ;)
    updateFAT(used,notused);                 // else, update FAT, curent sector shows to new sector
    used=notused;                            // if next copy to new sector, set new sector as used
    length-=SEKTORLENGTH;                    // decrement data length
  }else{                            // data could be stored in one sector
    fread(diskimg+offset,1,length,in);      // Copy data.
    updateFAT(used,(totallength%SEKTORLENGTH)+0xE00);  // update FAT, (end of file)
    memset(diskimg+offset+length,0,SEKTORLENGTH-length); // set by 0 (clear)
    length=0;                               // set lenght to 0
  }
  counter++;
 }
 return(1);
}

// ------------------- Tools -----------
void preparediskname (char *in)         // Set dirname according name of input file
{                                      // by cutting extention
  int count=0;
  while ((*in != '\0') && (*in != '.') && (count < 10)){   // check also for length (10)
   bootsektor.nameofdisk[count++] = *(in++);
  }
}

void freediskimg (void)  // free memory occuped by image
{
 if (diskimg != NULL){
    free(diskimg);
 }
}

BYTE writeD80 (char *outfile)    // write disk image from memory to file
{
 BYTE retval=1;
 out=fopen(outfile,"wb");        // Try to create file
 if (out != NULL){               // file created
    fwrite(diskimg,1,DISKLENGTH,out);      // write data to file
    fclose(out);
 }else{                          // if file wasn't create
    printf("Can't create D80 image file '%s'!\n",outfile);
    retval=0;
 }
 return(retval);
}

BYTE extention (BYTE value)      // Transform extention type from TAP to D80
{
 BYTE retchar;
 switch (value){
   case 0: retchar='P'; break;
   case 1: retchar='C'; break;
   case 2: retchar='N'; break;
   case 3: retchar='B'; break;
   default:
           retchar='B';
 }
 return(retchar);
}

void spacetozero (BYTE *filename)   // Change spaces in string to 0
{
 BYTE *str;
 str=filename+9;
 while (*str == ' '){
   *str = 0;       // change SPACE to "\0"
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


/*******************************************************************************
*                                TAP2MBHDD                                     *
********************************************************************************
* Description:                                                                 *
*     Modified version of TAP2MBD (version 1.2 stable, by Ing. Marek Zima)     *
*------------------------------------------------------------------------------*
* Version: 0.0 beta                                                            *
*------------------------------------------------------------------------------*
* Developer:                                                                   *
*     Dusan Gallo aka UB880D, dusky@hq.alert.sk                                           *
*------------------------------------------------------------------------------*
* License:                                                                     *
*     GNU License                                                              *
*------------------------------------------------------------------------------*
* Building:                                                                    *
*     g++ -o tap2mbd tap2mbd.cpp                                               *
*******************************************************************************/
/*******************************************************************************
*                                TAP2MBD                                       *
********************************************************************************
* Description:                                                                 *
*     Transform data from ZX Spectrum TAP file to new or existing MB-02 image  *
*     file.                                                                    *
*------------------------------------------------------------------------------*
* Version: 1.2 stable                                                          *
*------------------------------------------------------------------------------*
* Developer:                                                                   *
*     Ing. Marek Zima, Slovak Republic, marek_zima@yahoo.com or zimam@host.sk  *
* Bugfixer:                                                                    *
*     Lubomir Blaha, tritol@trilogic.cz                                        *
*------------------------------------------------------------------------------*
* License:                                                                     *
*     GNU License                                                              *
*------------------------------------------------------------------------------*
* Programmed in:                                                               *
*     GNU C with libC (Dev-C++ 4.0)                                            *
*------------------------------------------------------------------------------*
* Building:                                                                    *
*     g++ -o tap2mbd tap2mbd.cpp                                               *
*******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MY_VERSION "0.0 beta"    // Version identifier (tap2mbd2). (Change after changes!)
#define VERSION "1.2 stable"       // Version identifier (tap2mbd). (Change after changes!)

#define FALSE 0
#define TRUE !FALSE

#define BYTE unsigned char
#define WORD unsigned short int
#define SEKTORLENGTH 1024
#define DISKLENGTH 128*8*2*SEKTORLENGTH // cylynders*sectors*sides*bytes
#define DATAFAT 0x100    // At first, look for available sectors from this
                         // position and than in DIRs array

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

typedef struct {                          // MB-02 boot sector
                WORD jump;                // Jump to boot routine
                BYTE unused;
                BYTE mark1;               // 1st mark for MB-02
                WORD numofcyl;            // Number of cylinders per disk
                WORD numofsec;            // Number of sectors per track
                WORD numofhead;           // Number of head per disk
                WORD secpercluster;       // Number of sectors per cluster
                WORD secdirs;             // Logic sector for DIRS
                WORD secperfat;           // Number of sectors per FAT
                WORD fatlength;           // FAT length
                WORD secFAT1;             // Logic number for 1st sector 1st FAT
                WORD secFAT2;             // Logic number for 1st sector 2nd FAT

                BYTE unknown[10];
                BYTE mark2;               // 2. mark for MB-02
                BYTE date[2];             // date and time, when MB-02 was created
                BYTE time[2];
                BYTE mark3;               // 3. mark for MB-02
                BYTE diskname[10];
                BYTE disknameextend[16];
                BYTE systemidentificaton[32];
                BYTE bootcode[88];
               } BOOTSEC;

typedef struct {                          // DIRS record
                BYTE ident;
                BYTE namexor;
                WORD firstsec;
               } DIRSREC;

typedef struct {                          // ITEM record (Records in directory)
                BYTE ident;
                BYTE date[2];
                BYTE time[2];
                BYTE tapheader[17];
                WORD bodyaddr;
                unsigned long bodylength;
                BYTE bodyflag;
                BYTE attr;
                WORD firstsec;
               } ITEMREC;

// boot sector for new image file (with slovak comments)
BOOTSEC bootsektor =   {0x7E18,     // Skok na systemovy zavadzac
                        0x80,       // 0x80 - nepouzite
                        0x02,       // 1. znacka MB-02
                        0x007f,     // Pocet fyzickych stop na disku (82)
                        0x0008,     // Pocet sektorov na stope (11)
                        0x0002,     // Pocet povrchov na disku (2)
                        0x0001,     // Pocet sektorov na cluster (1)
                        0x000A,     // Logicke cislo sektora DIRs (10)
                        0x0004,     // Pocet sektorov FAT (4)
                        0x1000,     // Dlzka FAT (4096 bytov)
                        0x0002,     // Logicke cislo prveho sektora prvej FAT (2)
                        0x0006,     // Logicke cislo prveho sektora druhej FAT (6)
                        {0x00,0xFF,0x1E,0x00,0x03,0x07,0x04,0x08,0x05,0x09}, // unknown
                        0x00,       // 2. znacka MB-02
                        {0x02,0x01},{0x00,0x00}, // datum a cas formatovania (vytvorenia)
                        0x00,       // 3. znacka MB-02
                        {'N','a','m','e','O','f','D','i','s','k'},
                        {0,'F','0','2','-','V','3','0',0,0,0,0,0,0,0,0}, // Rosirene meno diskety
                        // Systemova identifikacia diskety
                        {0x2c,0x1f,0x74,0x5d,0xcb,0xea,0x59,0x50,0x8b,0x4b,
                        0xa7,0xc2,0x94,0x8f,0x22,0xf0,
                        
                        0x59,0x6a,0x01,0x28,0xbe,0x9f,0x2c,0x25,0xfe,0x3e,
                        0xd2,0xb7,0xe1,0xfa,0x57,0x85},
                        
                        //0x69,0xCC,0x74,0xE0,0xD3,0xFA,0x0F,0x4F,0x1C,0x15,
                        //0x2A,0x4C,0x78,0xC0,0x10,0x6A,
                        
                        //0x1C,0xB9,0x01,0x95,0xA6,0x8F,0x7A,0x3A,0x69,0x60,
                        //0x5F,0x39,0x0D,0xB5,0x65,0x1F,
                        // Systemovy zavadzac
                        //0,'M','B','-','0','2',' ','w','i','t','h',' ',
                        //'B','S',' ','D','O','S',' ','b','y',' ',
                        //'M','A','R','E','K','Z','I','M','A',0,
                        
                        {
                        0,'M','B','-','0','2',' ','w','i','t','h',' ',
                        'B','S',' ','D','O','S',' ','b','y',' ',
                        't','a','p','2','m','b','d',' ','2',0,
                        0xAF,0xD3,0xFE,0x3E,0x03,0x21,0x00,0x40,
                        0x11,0x01,0x40,0x01,0x00,0x01,0x75,0xED,
                        0xB0,0x06,0x06,0x36,0x7e,0xED,0xB0,0x04,
                        0x75,0xED,0xB0,0x3D,0x20,0xED,0x44,0x4D,
                        0x29,0x29,0x29,0x09,0x01,0x0C,0x00,0x09,
                        0x7C,0xE6,0x03,0xF6,0x58,0x67,0xEB,0xED,
                        0xA0,0xEB,0x06,0x20,0x10,0xFE,0x18,0xE6
                        } };


// ------------------ Global variable definitions ------
FILE *in,*out;                       // file descriptors for input/output files
BYTE *diskimg;                       // pointer to memory, where we read image
long fileoffset;                     // offset inside input file
BYTE noname[11] = {"..noname.."};
BYTE dirname[11];                    // array for directory name
WORD numofdir;                       // number of directory from command line

// ------------------ Functions declarations ------
void readblock (void);
BYTE tap2mdb (void);
void preparediskimg (void);
void readdiskimg (void);
void makesystemident(void);
BYTE checkimage(void);
void createdir (BYTE *);
void updateFAT (WORD,WORD);
void FATCRC (void);
WORD getFATnum (WORD sector);
WORD notusedsecfromFAT (WORD,BYTE);
BYTE createitem(ITEMREC *);
BYTE copydata(ITEMREC *);
void freediskimg (void);
void initFAT (void);
BYTE writeMDB (char *);
BYTE checksum (BYTE *, BYTE);
WORD getnumdir(char *);
void checkdirvalid(void);
void preparedirname(char*);

int main(int argc,char *argv[])
{
 int retval = 0;                        // Suppose everything will be OK
 printf(">>> TAP2MBHDD, version %s @2007 by UB880D <<<\n",MY_VERSION);
 printf(">>> based on TAP2MBD - %s @2002 by Marek Zima <<<\n\n", VERSION);
 if(argc!=4){
   printf("Syntax: %s <tapfile.tap> <number of directory> <mbdfile.mbd>\n", argv[0]);
   return(1);
 }
 numofdir=getnumdir(argv[2]);
 if((numofdir == 0xFFFF) || (numofdir >= 256)){   // 255? dirs are maximum !!!
   printf("Wrong number of directory!!!\n");
   return(1);
 }
 in = fopen(argv[1],"rb");                // open input file
 if (in !=NULL)                           // if successfull
 {
  preparedirname(argv[1]);                // take input file name and cut extention
  if((out=fopen(argv[3],"rb")) == NULL){  // if output file doesn't exist
    preparediskimg();                     // create empty MB-02 disk image
    createdir(dirname);                   // create directory for data from TAP
  }else{                                  // if output file exists (do APPEND)
    readdiskimg();                        // read image file to memory
    fclose(out);                          // close output file
  }
  switch(checkimage()){                   // check if it is MB-02+ disk image
   case 0:
    checkdirvalid();                      // check number of directory from cmd line
    if(tap2mdb() && writeMDB(argv[3])){   // transfer data from TAP to image in memory
      printf("Finished successfull.\n");  // if successful write memory to image file
    }                                     // if everything is OK, display information
    break;
   case 1:                                // It's not MB-02+ image
    printf("Input file '%s' is not MB-02+ image!\n",argv[3]);
    retval = 3;
    break;
   case 2:                                // Not supported MB-02+ image
    printf("Existing MB-02+ image in '%s' is not supported!\n",argv[3]);
    retval = 4;
  }
  freediskimg();                          // free allocated memory
  fclose(in);                             // close input TAP file
 }
 else                                     // if input file was not opened
 {
  printf("Can't open input file '%s'!\n",argv[1]);
  retval = 2;
 }
 return(retval);                          // return - return code ;)
}

// ------------------- Heart of transfer TAP to MB-02 -----------
BYTE tap2mdb (void)
{
 BYTE oldflag = 0;            // Previous record was header or data ?
 HEADER header;
 ITEMREC itemrec;
 // long blocklen;
 int i;

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
          itemrec.ident=0xB0;         // file with header and body
          memcpy(&itemrec.tapheader[0],&header.blockinfo.type,17);
          itemrec.bodyaddr=0x4001;    // Doesn't matter (Bulgar constant ;)
          itemrec.bodylength=(unsigned long)header.blocklength;  // body length
#ifdef DEBUG
          printheader(&header);
#endif
          oldflag=header.blockinfo.flag;       // remember flag
       }else{
          printf("DATABLOCK: length=%d bytes, flag=0x%x\n",header.blockinfo.blocklength-2,header.blockinfo.flag);
          if(oldflag != 0){
            memset(&itemrec,0,sizeof(ITEMREC));
            itemrec.ident=0xA0;         // file just with body
            itemrec.tapheader[0]=0x04;  // !!! CONTINUE (Bulgar constant ;) !!!
            memcpy(&itemrec.tapheader[1],noname,10);
            itemrec.bodyaddr=0x4001;    // Doesn't matter (Bulgar constant ;)
            itemrec.bodylength=(unsigned long)header.blockinfo.blocklength-2; // data length
          }
          oldflag=header.blockinfo.flag;           // remember flag
          itemrec.bodyflag=header.blockinfo.flag;
          itemrec.firstsec=notusedsecfromFAT(0,FALSE);   // get available sector from FAT
#ifdef DEBUG
          printitemrec(&itemrec);
#endif
          if(itemrec.firstsec == 0){                     // not place in DATA FAT
            itemrec.firstsec=notusedsecfromFAT(0,TRUE);  // then try to look intu DIRs array
            if(itemrec.firstsec == 0){                   // if not place again
              printf("FAT full!!!\n");                   // so it's really full ;)
              return(0);
            }
          }
          if(createitem(&itemrec)== 0){                  // Not place for record
            printf("Root full!!!\n");                    // so disk is full
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
 FATCRC();                           // If transfer is success store FAT CRC
 return(1);
}

// ------------------- Disk image functions -----------
void preparediskimg (void)
{
 diskimg = (BYTE *)malloc(DISKLENGTH); // Get memory
 memset(diskimg,0,DISKLENGTH);         // set by 0 (clear)
 if(diskimg != NULL){                  // create empty disk image
    makesystemident();  // Generate system identification for disk image.
    // store checksum for system identification data
    bootsektor.unknown[0]=checksum(&bootsektor.systemidentificaton[0],32);
    memcpy(diskimg,&bootsektor,sizeof(BOOTSEC));   // copy boot sector
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
 memset(diskimg,0,DISKLENGTH);         // set by 0 (clear)
 if(diskimg != NULL){
    fread(diskimg,1,DISKLENGTH,out);   // read image file to memory
    memcpy(&bootsektor,diskimg,sizeof(BOOTSEC));  // read boot sector
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
 for (i=0;i<32;i++){
  bootsektor.systemidentificaton[i]=rand()%256;
 }
}

BYTE checkimage (void)        // Check existing image is MB-02+ image
{
 BYTE retval;                 // check image
 if((bootsektor.mark1 == 2) && (bootsektor.mark2 == 0) && (bootsektor.mark3 == 0)) {
   retval = 0;                // It is MB-02+ image
 } else {
   retval = 1;                // It's not MB-02+ image
 }
 if(retval == 0){             // if it is MB-02+ image, check his params
   if ((bootsektor.numofcyl == 0x007f) && (bootsektor.numofsec == 0x0008)
      && (bootsektor.numofhead == 0x0002) && (bootsektor.secpercluster == 0x0001)){
     retval = 0;                // We know work with this image
   } else {
     retval = 2;                // Different image, not supported ( use old tap2mbd for now ;])
   }
 }
 return(retval);
}

// ------------------- Working with FAT -----------
void initFAT (void)        // Create FAT for empty disk image
{
 int numofrec;             // how many logic sectors disk realy can have
 long firstfatoff,secondfatoff;
 firstfatoff=bootsektor.secFAT1*SEKTORLENGTH;   // calculate offset to 1st FAT
 secondfatoff=bootsektor.secFAT2*SEKTORLENGTH;  // calculate offset to 2nd FAT
 numofrec=DISKLENGTH/SEKTORLENGTH;              // how many logic sectors disk realy can have
 // set higher sectors to 0xFF (not available)
 memset(diskimg+firstfatoff+(numofrec*2),0xFF,(bootsektor.secperfat*SEKTORLENGTH)-(numofrec*2));
 memset(diskimg+secondfatoff+(numofrec*2),0xFF,(bootsektor.secperfat*SEKTORLENGTH)-(numofrec*2));
 // 1st FAT
 *((WORD *)(diskimg+firstfatoff))=0x0000;    // increment and CRC byte
 *((WORD *)(diskimg+firstfatoff+2))=0xFF00;  // backup sector (1st)
 *((WORD *)(diskimg+firstfatoff+4))=0xC003;  // 1st FAT sectors
 *((WORD *)(diskimg+firstfatoff+6))=0xC004;
 *((WORD *)(diskimg+firstfatoff+8))=0xC005;
 *((WORD *)(diskimg+firstfatoff+10))=0x8400;
 *((WORD *)(diskimg+firstfatoff+12))=0xC007;  // 2nd FAT sectors
 *((WORD *)(diskimg+firstfatoff+14))=0xC008;
 *((WORD *)(diskimg+firstfatoff+16))=0xC009;
 *((WORD *)(diskimg+firstfatoff+18))=0x8400;
 *((WORD *)(diskimg+firstfatoff+20))=0x8400; // DIRS sektor
 // 2nd FAT
 *((WORD *)(diskimg+secondfatoff))=0x0000;    // increment and CRC byte
 *((WORD *)(diskimg+secondfatoff+2))=0xFF00;  // backup sector (1st)
 *((WORD *)(diskimg+secondfatoff+4))=0xC003;  // 1st FAT sectors
 *((WORD *)(diskimg+secondfatoff+6))=0xC004;
 *((WORD *)(diskimg+secondfatoff+8))=0xC005;
 *((WORD *)(diskimg+secondfatoff+10))=0x8400;
 *((WORD *)(diskimg+secondfatoff+12))=0xC007; // 2nd FAT sectors
 *((WORD *)(diskimg+secondfatoff+14))=0xC008;
 *((WORD *)(diskimg+secondfatoff+16))=0xC009;
 *((WORD *)(diskimg+secondfatoff+18))=0x8400;
 *((WORD *)(diskimg+secondfatoff+20))=0x8400; // DIRS sektor
}

void updateFAT (WORD sektor,WORD value)   // Write value to FAT according sektor
{
 WORD *offset;
 offset=(WORD *)(diskimg+(bootsektor.secFAT1*SEKTORLENGTH)+(sektor*2)); // 1.FAT
 *offset=value;
 offset=(WORD *)(diskimg+(bootsektor.secFAT2*SEKTORLENGTH)+(sektor*2)); // 2.FAT
 *offset=value;
}

WORD notusedsecfromFAT (WORD usingsec,BYTE fordir)   // Get available sector from FAT
{
 WORD *fatoffset,*fatstart,*fatend,*usingoffset;
 WORD notusedsec;
 fatstart=(WORD *)(diskimg+(bootsektor.secFAT1*SEKTORLENGTH));  // offset to 1st FAT
 usingoffset=(WORD *)(diskimg+(bootsektor.secFAT1*SEKTORLENGTH)+(usingsec*2)); // Not yet marked using sector
 if(fordir == FALSE){                                // start from DATA FAT
   fatoffset=(WORD *)((BYTE*)(fatstart)+DATAFAT);
 }else{                                              // start from DIRS array
   fatoffset=(WORD *)((BYTE*)(fatstart)+2);      // 1st record in FAT is FAT CRC
 }
 fatend=(WORD *)(diskimg+(bootsektor.secFAT1*SEKTORLENGTH)+(bootsektor.secperfat*SEKTORLENGTH)); // end of 1st FAT
 while(((BYTE*)fatoffset==(BYTE*)usingoffset) || (((*(fatoffset)&0x8000) != 0)   // Search
         && ((BYTE*)fatoffset < (BYTE*)fatend))){
  fatoffset++;
 }
 if ((BYTE*)fatoffset < (BYTE*)fatend){                  // it found available sector
    notusedsec=((BYTE*)fatoffset-(BYTE*)fatstart)/2;
 }else{
    notusedsec=0;                                        // FAT full
 }
 return(notusedsec);
}

WORD getFATnum (WORD sector)        // Get value from FAT according sector
{
  WORD retval;
  retval= *(WORD*)(diskimg+(bootsektor.secFAT1*SEKTORLENGTH)+(sector*2)); // Read from 1st FAT !!!
  return(retval);
}

void FATCRC (void)                  // Calculate and store FAT CRC
{
 BYTE *fatoffset,*fatstart,*fatend;
 long sum;
 BYTE crc;
 fatstart=diskimg+(bootsektor.secFAT1*SEKTORLENGTH);  // offset to 1st FAT
 fatoffset=fatstart+2;                    // 2nd record from FAT (1st is CRC)
 fatend=diskimg+(bootsektor.secFAT1*SEKTORLENGTH)+(bootsektor.secperfat*SEKTORLENGTH);  // end of 1st FAT
 sum=0;
 crc=0;
 while(fatoffset < fatend){
   sum+= *(fatoffset++);                  // Summary
 }
 crc=sum%256;                             // CRC = sum (mod) 256
 *(fatstart+1)=crc;                       // Write to 1st FAT
 fatstart=diskimg+(bootsektor.secFAT2*SEKTORLENGTH);
 *(fatstart+1)=crc;                       // Write to 2nd FAT
}

// ------------------- Working with directory -----------
void createdir (BYTE *name)       // Create DIR in disk image
{
 DIRSREC rootrec;
 ITEMREC rootitem;
 memset(&rootitem,0,sizeof(ITEMREC));
 rootrec.ident = 0x80;      // valid item
 rootrec.namexor = checksum(name,10);   // calculate checksum of directory name
 rootrec.firstsec = notusedsecfromFAT(0,TRUE) | 0x8000; // 0x8000 - ident & (HIBYTE)firstsec has to be 0x80
 memcpy(diskimg+(bootsektor.secdirs*SEKTORLENGTH)+(numofdir*sizeof(DIRSREC)),&rootrec,sizeof(DIRSREC));  // write
 updateFAT(rootrec.firstsec&0x3FFF,0x8400); // Not available, last, 0x400 bytes
 rootitem.ident = 0x80;    // 0 record in directory is his name
 memcpy(&rootitem.tapheader[1],name,10);   // copy name to record
 memcpy(diskimg+((rootrec.firstsec&0x3FFF)*SEKTORLENGTH),&rootitem,sizeof(ITEMREC));  // write record to image
}

void checkdirvalid(void)       // Check if requested direcntory (from command line)
{                              // already exists or not
 DIRSREC dirrec;
 memcpy(&dirrec,diskimg+(bootsektor.secdirs*SEKTORLENGTH)+(numofdir*sizeof(DIRSREC)),sizeof(DIRSREC)); // read DIRS rec
 if(dirrec.ident != 0x80){     // if DIRS rec is empty or invalid
   createdir(dirname);         // create dir
 }
}

BYTE createitem (ITEMREC *itemrec)   // Create item in directory
{
 BYTE *start,*end,*rootdir;
 DIRSREC rootsec;
 WORD FATrec;
 WORD sector,tmpsector;
 BYTE retval = 1;
 BYTE dowhile=TRUE;
 // read requested DIRS rec
 memcpy(&rootsec,diskimg+(bootsektor.secdirs*SEKTORLENGTH)+(numofdir*sizeof(DIRSREC)),sizeof(DIRSREC));
 sector=(rootsec.firstsec&0x3FFF);   // get 1st sector of directory

 while(dowhile){
   start=diskimg+(sector*SEKTORLENGTH);   // offset to X dir sector
   rootdir=start;
   end=start+SEKTORLENGTH;                // end of X dir sector
   // look for empty space
   while(((*rootdir == 0x80) || (*rootdir == 0xB0) || (*rootdir == 0xA0) ||
          (*rootdir == 0x90)) && (rootdir < end)) rootdir+=sizeof(ITEMREC);
   if (rootdir < end){                        // if empty space found
      memcpy(rootdir,itemrec,sizeof(ITEMREC));    // write item do dir
      dowhile=FALSE;
   }else{                                     // if empty space didn't find
      FATrec=getFATnum(sector);               // get number form FAT
      if ((FATrec & 0xC000) == 0xC000){       // if it's not last
        sector=FATrec & 0x3FFF;               // take number to next sektor
      }else{                                  // if number is last
        tmpsector=notusedsecfromFAT(0,TRUE);  // look for available sektor in FAT
        if(tmpsector == 0){                   // if there is not available sector
          retval=0;                              // disk is really full ;)
          dowhile=FALSE;
        }
        if(tmpsector != 0){                      // available sektor found ;D
          updateFAT(sector,tmpsector|0xC000);    // update FAT, curent sector shows to new sector
          updateFAT(tmpsector,0x8400);           // valid, last, 0x400 bytes
          sector=tmpsector;
        }
      }
   }
 }
/* memcpy(diskimg+(1*SEKTORLENGTH), // 1. sektor je BACKUP (we don't have to use it)
        diskimg+((rootsec.firstsec&0x3FFF)*SEKTORLENGTH),SEKTORLENGTH);*/
 return(retval);
}

BYTE copydata (ITEMREC *itemrec)    // transfer data from TAP block to disk image
{
 unsigned offset;
 long length;
 WORD used,notused;
 length=itemrec->bodylength;        // length of data to be trasfered
 used=itemrec->firstsec;            // get 1st sector for data
 offset=used*SEKTORLENGTH;          // offset to this sector in disk image
 while(length > 0)                  // (don't transfer 0 bytes ;)
 {
  if(length > SEKTORLENGTH){        // if data length is higher than sector length
    fread(diskimg+offset,1,SEKTORLENGTH,in);   // copy data for sector
    notused=notusedsecfromFAT(used,FALSE);     // look for next available sector
    if (notused == 0){                         // available sektor didn't find
      notused=notusedsecfromFAT(used,TRUE);  // so try to search in DIRS array
    }
    offset=notused*SEKTORLENGTH;             // offset to this sector in disk image
    if(offset == 0) return(0);               // available sector didn't find. Disk is really full ;)
    updateFAT(used,notused|0xC000);          // else, update FAT, curent sector shows to new sector
    length-=SEKTORLENGTH;                    // decrement data length
  }else{                            // data could be stored in one sector
    if (length == SEKTORLENGTH){            // full sector?
      fread(diskimg+offset,1,length,in);    // Copy only data.
    } else {
      fread(diskimg+offset,1,length+1,in);  // Copy data. (copy also CRC)
    }
    updateFAT(used,length|0x8000);          // update FAT, sector valid, last with length bytes inside
    length=0;                               // set lenght to 0
  }
  used=notused;                             // if next copy to new sector, set new sector as used
 }
 return(1);
}

// ------------------- Tools -----------
BYTE checksum (BYTE *name, BYTE len)   // check sum for directory name
{                                      // simple XOR through bytes
 int i;
 BYTE xorval=0;
 for (i=0;i<len;i++){
   xorval^= *(name+i);       // XOR
 }
 return (xorval);
}

void preparedirname (char *in)         // Set dirname according name of input file
{                                      // by cutting extention
  int count=0;
  while ((*in != '\0') && (*in != '.') && (count < 10)){   // check also for length (10)
   dirname[count++] = *(in++);
  }
}

WORD getnumdir (char *numstr)    // Check number of directory from command line
{
 WORD retval=0;
 while (*numstr != '\0'){
  if ((*numstr >= '0') && (*numstr <='9')){    // it must be a decimal number
    retval=(retval*10) + *numstr-'0';
    numstr++;
  } else {
    return(0xFFFF);      // Set error if number is not decimal number
  }
 }
 return(retval);
}

void freediskimg (void)  // free memory occuped by image
{
 if (diskimg != NULL){
    free(diskimg);
    diskimg = NULL;
 }
}

BYTE writeMDB (char *outfile)    // write disk image from memory to file
{
 BYTE retval=1;
 out=fopen(outfile,"wb");        // Try to create file
 if (out != NULL){               // file created
    fwrite(diskimg,1,DISKLENGTH,out);      // write data to file
    fclose(out);
 }else{                          // if file wasn't create
    printf("Can't create MB-02 image file '%s'!\n",outfile);
    retval=0;
 }
 return(retval);
}

/*******************************************************************************
*                               END OF FILE                                    *
*******************************************************************************/


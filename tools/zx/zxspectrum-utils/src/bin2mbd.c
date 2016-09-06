/* bin2mbd utility */

/* defaults */
#define	ADDRESS		32768
#define	CLEAR		24575
#define	RUN		32768
#define	MAX_LEN		65535
#define	DISK_SIZE_STD	1847296
#define	FILE_SIZE	1716224
#define	FAT_LEN		2048
#define	FAT_FILE	0x80
#define	FAT_ITEM_FAT	0x80
#define	FAT_ITEM_DIRS	0x20
#define	VERSION		"bin2mbd v.1.0"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

struct s_boot
{
	unsigned char bootloader[2];
	unsigned char not_used;
	unsigned char mark_1;
	unsigned char tracks[2];
	unsigned char sectors[2];
	unsigned char cylinders[2];
	unsigned char sec2cluster[2];
	unsigned char dirs[2];
	unsigned char fat_sectors[2];
	unsigned char fat_len[2];
	unsigned char sec_fat1[2];
	unsigned char sec_fat2[2];
	unsigned char syst_ident_xor;

	unsigned char not_used2[9];

	unsigned char mark_2;
	unsigned char time[4];
	unsigned char mark_3;
	unsigned char disc_name[10];
	unsigned char disc_name_ext[16];
	unsigned char syst_ident[32];
};
/* boot sector 
	#00-#01 ... Skok na systemovy zavadzac
	#02 ....... nepouzite, obycajne je tu #80
	#03 ....... tu musi byt #02 (znacka MB-02)
	#04-#05 ... pocet fyzickych stop na disku (vacsinou 80 alebo 82)
	#06-#07 ... pocet sektorov na stope (pocitaju sa od 1)
	#08-#09 ... pocet povrchov na disku (standartne 2)
	#0A-#0B ... pocet sektorov na cluster (standartne 1)
	#0C-#0D ... logicke cislo sektora DIRS
	#0E-#0F ... pocet sektorov FAT (1 az 4)
	#10-#11 ... dlzka FAT (#400 * pocet sektorov FAT)
	#12-#13 ... logicke cislo prveho sektora prvej FAT
	#14-#15 ... logicke cislo prveho sektora druhej FAT
	#16 ....... xor systemovej identifikacie disku
	#17 ....... nepodstatné, default #FF
	#18-#19 ... verzia formátovača, FF17-V30 nastaví word 30
	#1A ....... logicke cislo druheho sektora prvej FAT, zvacsa #3
	#1B ....... logicke cislo druheho sektora druhej FAT, zvacsa #7
	#1C ....... logicke cislo tretieho sektora prvej FAT, zvacsa #4
	#1D ....... logicke cislo tretieho sektora druhej FAT, zvacsa #8
	#1E ....... logicke cislo stvrteho sektora prvej FAT, zvacsa #5
	#1F ....... logicke cislo stvrteho sektora druhej FAT, zvacsa #9

	#20 ....... tu musi byt #00 (znacka MB-02)
	#21-#24 ... datum a cas formatovania (kodovanie ako PC)
	#25 ....... tu musi byt #00 (znacka MB-02)
	#26-#2F ... meno diskety
	#30-#3F ... rozsirenie mena diskety
	#40-#5F ... systemova identifikacia diskety
*/

unsigned char boot_c[] = "\x18\x7E\x80\2\x52\0\x0B\0\2\0\1\0\x0A\0\4\0\x18\x0E\2\0\6\0"
		"\0\xFF\x1E\0\3\7\4\x08\5\x09"
		"\0\1\1\0\0\0bin2mbd1.0by mike/zeroteam\0"
		"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
		"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0";

struct s_dirs
{
	unsigned char ident;
	unsigned char name_xor;
	unsigned char sector[2];
};
/* DIRS sector
	#00 ....... identifikacia polozky
		#80 = platna polozka a adresar existuje
		ine = adresar neexistuje a neplatna polozka
	#01 ....... xor mena adresara (koli rychlejsiemu hladaniu)
	#02,#03 ... logicke cislo prveho sektora adresara (len bity 0-13)
*/

struct s_dir
{
	unsigned char ident;
	unsigned char time[4];

	/* zx header */
	unsigned char h_type;
	unsigned char h_name[10];
	unsigned char h_len[2];
	unsigned char h_param1[2];
	unsigned char h_param2[2];

	unsigned char address[2];
	unsigned char lenght[4];
	unsigned char flag;
	unsigned char attribs;
	unsigned char sector[2];
};
/* directory sectors
	#00 ....... identifikacia polozky
		#90 = subor obsahuje iba hlavicku
		#A0 = subor obsahuje iba telo
		#B0 = subor obsahuje aj hlavu aj telo
		#80 = subor neobsahuje hlavu ani telo (nestava sa casto)
		Ine hodnoty znamenaju neplatnu adresarovu polozku.
	#01-#04 ... datum a cas vytvorenia suboru
	#05-#15 ... klasicka magnetofonova hlavicka
	#16-#17 ... adresa tela
	#18-#1B ... dlzka tela (#18=najnizsi, #1B=najvyssi bajt)
	#1C ....... flagbajt tela
	#1D ....... atributy suboru
	#1E-#1F ... logicke cislo prveho sektora tela (iba bity 0-13)
*/

struct s_dir0
{
	unsigned char ident;
	unsigned char time[4];
	unsigned char parent;
	char name[10];
	char ext_name[16];
};
/*
	#00 ....... identifikator (vecsinou #80)
	#01-#04 ... datum a cas vytvorenia adresara
	#05 ....... cislo nad-adresara (do ktoreho patri tento adresar)
	#06-#0f ... meno adresara
	#10-#1f ... rozsirenie mena adresara
*/

unsigned char fat_c[] = "\x3B\x74\0\xFF";

int str2int (char *str, int *num)
{
	int i=0;
	*num = 0;
	while (str[i] != 0)
	{
		if (str[i] <= '9' && str[i] >= '0')
		{
			*num *= 10;
			*num += str[i++] - '0';
		}
		else
			return 1;
	}
	return 0;
}

void version(void)
{
	printf(VERSION"\nCopyright (C) 2009 mike/zeroteam\n");
}

void usage(void)
{
	version();
	printf("Usage: bin2mbd [options] [file.bin]\n"
		"Options:\n"
		"  -nt <arg>	no. of tracks, default 82\n"
		"  -ns <arg>	no. of sectors, default 11\n"
		"  -nsur	<arg>	no. of surfaces, default 2\n"
		"  -d <arg>	no. of directory, default 0\n"
		"  --dir <arg>	same as -d\n"
		"  -a <arg>	starting address of binary file\n"
		"  -o <file>	set output file\n"
		"  -h		show this text\n"
		"  --help	same as -h\n"
		"  -v		show version\n"
		"  --version	same as -v\n");
}

void l_copy (unsigned char* tap, unsigned char* loader, int* tap_index, int* checksum, int len)
{
	int i;
	for (i = 0; i < len; i++)
		*(checksum) ^= tap[(*tap_index)++] = *(loader++);
}

/* return no. of free bytes on image */
/* len is in sectors */
int free_bytes(unsigned char* fat, int len)
{
	int i, ret = 0;

	for (i = 1; i < len * 1024; i += 2)
		if (!(*(fat + i) & 0x80))
			ret ++;

	ret *= 1024;

	return ret;
}

int get_free_sec(unsigned char* fat, int len)
{
	int i, ret = -1;

	for (i = 3; i < len * 1024; i += 2)
		if (!(*(fat + i) & 0x80))
		{
			ret = (i - 1) / 2;
			break;
		}
	
	return ret;
}

void set_fat_checksum(unsigned char* fat, int len)
{
	int i;
	unsigned char sum;

	sum = fat[2];
	for (i = 3; i < len * 1024; i++)
		sum += fat[i];
	fat[0] = 1;
	fat[1] = sum;
	memcpy(fat + len * 1024, fat, len * 1024);
}

int main(int argc, char* argv[])
{
	int i, no, len, val, found, dirsec;	/* general purpose variables */
	long input_len;				/* lenght of input file */
	int finname_i = 0;			/* arguments index of input file */
	int foutname_i = 0;			/* arguments index of output file */
	int ntracks = 82;			/* no. of tracks on disc */
	int nsectors = 11;			/* no. of sectors per track */
	int nsurfaces = 2;			/* no. of surfaces on disc */
	int address = ADDRESS;			/* start adress*/
	char foutname[255];			/* output file name */
	FILE *finput, *foutput;			/* finput - input file descriptor
						   foutput - output file descriptor */
	long disk_size;				/* size of disk image */
	unsigned char *disk_image;			/* pointer to disk image */
	struct s_boot *image_boot;
	struct s_dirs *image_dirs;
	struct s_dir0 *image_dir0;
	struct s_dir *image_dir;
	unsigned char *p, *s;				/* pointers into disk image */
	int ndir = 0;				/* no. of directory in image */

	for (i = 0; i < argc; i++)
	{
		if (!strcmp(argv[i], "-nt"))
		{
			if (str2int(argv[++i], &ntracks))
			{
				fprintf(stderr, "Invalid no. of tracks!\n");
				return 1;
			}
			continue;
		}

		if (!strcmp(argv[i], "-ns"))
		{
			if (str2int(argv[++i], &nsectors))
			{
				fprintf(stderr,
					"Invalid no. of sectors per track!\n");
				return 1;
			}
			continue;
		}

		if (!strcmp(argv[i], "-nsur"))
		{
			if (str2int(argv[++i], &nsurfaces))
			{
				fprintf(stderr, "Invalid no. of surfaces!\n");
				return 1;
			}
			continue;
		}

		if (!strcmp(argv[i], "-d") || !strcmp(argv[i], "--dir"))
		{
			if (str2int(argv[++i], &ndir))
			{
				fprintf(stderr, "Invalid directory number!\n");
				return 1;
			}
			continue;
		}

		if (!strcmp(argv[i], "-a"))
		{
			if (str2int(argv[++i], &address) || address > 65535)
			{
				fprintf(stderr, "Invalid starting address!\n");
				return 1;
			}
			continue;
		}

		if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help"))
		{
			usage();
			return 0;
		}

		if (!strcmp(argv[i], "-v") || !strcmp(argv[i], "--version"))
		{
			version();
			return 0;
		}

		if (!strcmp(argv[i], "-o"))
		{
			if (foutname_i)
			{
				fprintf(stderr, "Set only one output file!\n");
				return 1;
			}
			else
			{
				foutname_i = ++i;
				continue;
			}
		}

		if (finname_i)
		{
			fprintf(stderr, "Set only one input file!\n");
			return 1;
		}
		else
		{
			/* input file name can't start with '-' */
			if (argv[i][0] == '-')
			{
				fprintf(stderr, "Invalid parameter %s\n", argv[i]);
				return 1;
			}
			finname_i = i;
		}
	}	/* arguments */

	if (!finname_i && !foutname_i)
	{
		fprintf(stderr, "Invalid input arguments!\n"
			"Try `bin2mbd --help` for help.\n");
		return 1;
	}

	if (!foutname_i)
	{
		strncpy(foutname, argv[finname_i], 255 - 5);
		foutname[254 - 5] = '\0';
		i = strlen(foutname);
		no = 0;
		i--;
		while ((no < 4) && (i - no > 0))
		{
			if (foutname[i - no] == '.')
			{
				foutname[i - no] = '\0';
				break;
			}
			++no;
		}
		strcat(foutname, ".mbd");
	}
	else
	{
		strncpy(foutname, argv[foutname_i], 254);
		foutname[254] = '\0';
	}

	foutput = fopen(foutname, "ab+");
	if (!foutput)
	{
		fprintf(stderr, "Output file open failed!\n");
		return 2;
	}

	if (fseek(foutput, 0, SEEK_END) != 0)
	{
		fprintf(stderr, "Disk reading error!\n");
		return 2;
	}

	disk_size = ftell(foutput);

	if (disk_size == 0L)	/* creating new output file */
	{
		no = ntracks * nsectors * nsurfaces;
		disk_size = no * 1024L;
		disk_image = malloc((size_t)disk_size);
		if (!disk_image)
		{
			fprintf(stderr,
				"Can't allocate memory for disk image.\n");
			return 2;
		}
		memset(disk_image, 0, disk_size);
		memcpy(disk_image, (void*)boot_c, sizeof(boot_c));
		image_boot = (void*)disk_image;
		image_boot->tracks[0] = ntracks % 256;
		image_boot->tracks[1] = ntracks / 256;
		image_boot->sectors[0] = nsectors % 256;
		image_boot->sectors[1] = nsectors / 256;
		image_boot->cylinders[0] = nsurfaces % 256;
		image_boot->cylinders[1] = nsurfaces / 256;
		image_boot->fat_sectors[0] =
			no / 512 + ((no % 512 == 0) ? 0 : 1);
		image_boot->fat_sectors[1] = 0;
		image_boot->fat_len[0] = 0; /* spodny bajt je 0 (*1024 % 256) */
		image_boot->fat_len[1] =
			(image_boot->fat_sectors[0] * 1024) / 256;
		image_boot->sec_fat1[0] = 2;
		image_boot->sec_fat1[1] = 0;
		image_boot->sec_fat2[0] = 2 + image_boot->fat_sectors[0];
		image_boot->sec_fat2[1] = 0;
		image_boot->dirs[0] = image_boot->sec_fat2[0] +
					image_boot->fat_sectors[0];
		image_boot->dirs[1] = 0;
		val = 0;
		for (i = 0; i < 32; i++)
		{
			image_boot->syst_ident[i] = rand() % 256;
			val ^= image_boot->syst_ident[i];
		}
		image_boot->syst_ident_xor = (unsigned char)(val % 256);
		p = disk_image + image_boot->sec_fat1[0] * 1024;
		no *= 2;
		memset(p, 0, no);
		memset(p + no, 0xFF, image_boot->fat_sectors[0] * 1024 - no);
		memcpy(p, fat_c, sizeof(fat_c));
		p += 4;
		for (i = 0; i < image_boot->fat_sectors[0]; i++)
		{
			if (i == image_boot->fat_sectors[0] - 1)
			{
				*p++ = 0;
				*p++ = 0x84;
			}
			else
			{
				*p++ = i + 3;
				*p++ = 0xC0;
			}
		}
		for (i = 0; i < image_boot->fat_sectors[0]; i++)
		{
			if (i == image_boot->fat_sectors[0] - 1)
			{
				*p++ = 0;
				*p++ = 0x84;
			}
			else
			{
				*p++ = i + 7;
				*p++ = 0xC0;
			}
		}

		*p++ = 0;
		*p = 0x84;	/* DIRS sector in FAT */

		p = disk_image + image_boot->sec_fat1[0] * 1024;
		no = 0;
		for (i = 2; i < image_boot->fat_sectors[0] * 1024; i++)
			no += *(p + i);
		(*p)++;
		*(p + 1) = no % 256;

		p = disk_image + image_boot->dirs[0] * 1024;

		memcpy(disk_image + image_boot->sec_fat2[0] * 1024,
			disk_image + image_boot->sec_fat1[0] * 1024,
			image_boot->fat_sectors[0] * 1024);

		/*
		 *  3129   1cb2 cd971c            call tstfat
		 *  3130   1cb5 2b                dec  hl
		 *  3131   1cb6 77                ld   (hl),a
		 *  3132   1cb7 2b                dec  hl
		 *  3133   1cb8 34                inc  (hl)
		 *  --
		 *  3117   1c97 210224     tstfat ld   hl,fat+2
		 *  3118   1c9a 01fe0f            ld   bc,#0ffe
		 *  3119   1c9d af                xor  a
		 *  3120   1c9e e5                push hl
		 *  3121   1c9f 86         tstf1  add  a,(hl)
		 *  3122   1ca0 eda1              cpi
		 *  3123   1ca2 ea9f1c            jp   pe,tstf1
		 *  3124   1ca5 e1                pop  hl
		 *  3125   1ca6 c9                ret
		 */

		/*
		 * YYYYYYYM MMMDDDDD HHHHHMMM MMMSSSSS
		 * YYYYYYY + 1980
		 * SSSSS * 2
		 */
	}
	else			/* opening existing output file */
	{
		disk_image = malloc((size_t)disk_size);
		if (fseek(foutput, 0, SEEK_SET) != 0)
		{
			fprintf(stderr, "Can't read output file!\n");
			return 1;
		}
		fread(disk_image, 1, disk_size, foutput);
		image_boot = (void*)disk_image;
	}

	len = free_bytes(disk_image + image_boot->sec_fat1[0] * 1024,
		image_boot->fat_sectors[0]);

	if (!finname_i)
		goto skip_input;

	finput = fopen(argv[finname_i], "rb");
	if (!finput)
	{
		fprintf(stderr, "Input file open failed!\n");
		return 2;
	}

	if (fseek(finput, 0, SEEK_END) != 0)
	{
		fprintf(stderr, "Input file reading error!\n");
		return 2;
	}
	input_len = ftell(finput);
	rewind(finput);

	if (input_len > len)
	{
		fprintf(stderr, "No free space at output image!\n");
		return 2;
	}

	image_dirs = (void*)(disk_image + image_boot->dirs[0] * 1024
		+ ndir * 4);
	if (image_dirs->ident != 0x80)	/* create new directory */
	{
		image_dirs->ident = 0x80;
		i = get_free_sec(disk_image + image_boot->sec_fat1[0] * 1024,
			image_boot->fat_sectors[0]);
		image_dirs->sector[0] = i % 256;
		image_dirs->sector[1] = 0x80;
		if (i == -1)
		{
			fprintf(stderr, "No space for new directory!\n");
			return 2;
		}
		s = disk_image + image_boot->sec_fat1[0] * 1024 + i * 2;
		*(s++) = 0;
		*s = 0x84;
		/* vytvorit adresar (polozka v DIRe a v novom sektore) */
		image_dir0 = (void*)(disk_image + i * 1024);
		image_dir0->ident = 0x80;
		image_dir0->time[0] = 0;
		image_dir0->time[1] = 0;
		image_dir0->time[2] = 0;
		image_dir0->time[3] = 0;
		image_dir0->parent = 0;
		strncpy(image_dir0->name, "bin2mbd\0\0\0", 10);
		strncpy(image_dir0->ext_name,
			"\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 16);
		/* zapise XOR mena adresara do DIRS sektora */
		no = 0;
		for (i = 0; i < 10; i++)
			no ^= image_dir0->name[i];
		image_dirs->name_xor = (unsigned char)no;
	}

	/* najdi volne miesto v adresari a vytvor novu polozku */
	found = 0;
	dirsec = image_dirs->sector[0];
	while (found == 0)
	{
		image_dir = (void*)(disk_image + dirsec * 1024);
		for (i = 0; i < 1024 / 32; i++)
		{
			if ((image_dir->ident != 0x80) &&
				(image_dir->ident != 0x90) &&
				(image_dir->ident != 0xA0) &&
				(image_dir->ident != 0xB0))
			{
				image_dir->ident = 0xB0;
				image_dir->time[0] = image_dir->time[1] =
					image_dir->time[2] = image_dir->time[3] = 0;
				image_dir->h_type = 3;	/* BYTES */
				memcpy(image_dir->h_name, foutname, 10);
				for (no = 0; no < 10; no++)
					if (image_dir->h_name[no] == 0 ||
						image_dir->h_name[no] == '.')
				{
					while(no < 10)
						image_dir->h_name[no++] = ' ';
					break;
				}
				no = input_len % 65536;
				image_dir->h_len[0] = no % 256;
				image_dir->h_len[1] = no / 256;
				image_dir->h_param1[0] = image_dir->h_param2[0] = 0;
				image_dir->h_param1[1] = image_dir->h_param2[1] = 0x80;
				image_dir->address[0] = address % 256;
				image_dir->address[1] = address / 256;
				image_dir->lenght[0] = input_len & 0x000000FF;
				image_dir->lenght[1] = (input_len & 0x0000FF00) >> 8;
				image_dir->lenght[2] = (input_len & 0x00FF0000) >> 16;
				image_dir->lenght[3] = (input_len & 0xFF000000) >> 24;
				image_dir->flag = 0xFF;
				image_dir->attribs = 0;
				no = get_free_sec(disk_image + image_boot->sec_fat1[0] *
					1024, image_boot->fat_sectors[0]);
				len = 0;
				image_dir->sector[0] = no % 256;
				image_dir->sector[1] = no / 256;
				do
				{
					fread(disk_image + no * 1024, 1, 1024, finput);
					p = disk_image + image_boot->sec_fat1[0] * 1024
						+ 2 * no;
					if (len == input_len / 1024)
					{
						val = input_len % 1024 | 0x8000;
						*p = val % 256;
						*(p + 1) = val / 256;
					}
					else
					{
						*(p + 1) = 0x80;
						no = get_free_sec(disk_image +
							image_boot->sec_fat1[0] * 1024,
							image_boot->fat_sectors[0]);
						val = no | 0xC000;
						*p = val % 256;
						*(p + 1) = val / 256;
					}
				} while (len++ < input_len / 1024);
				found = 1;
				break;
			}
			image_dir++;
		}
		if (i == 1024 / 32)
		{
			p = disk_image + image_boot->sec_fat1[0] * 1024 + 2 * dirsec;
			if (*(p + 1) & 0x40)	/* ak nie je posledny sektor adresara */
				dirsec = (*(p + 1) & 0x3F) * 256 + *p;
			else			/* posledny sektor adresara */
			{
				dirsec = get_free_sec(disk_image +
					image_boot->sec_fat1[0] * 1024,
					image_boot->fat_sectors[0]);
				if (dirsec != -1)
				{
					no = dirsec & 0xC0;
					*p = no % 256;
					*(p + 1) = no / 256;
					p = disk_image + image_boot->sec_fat1[0] * 1024
						+ 2 * dirsec;
					*p = 0;
					*(p + 1) = 0x84;
				}
				else
				{
					fprintf(stderr,
						"No more space for directory entry!\n");
					return 2;
				}
			}
		}
	}


	fclose(finput);
skip_input:
	set_fat_checksum(disk_image + image_boot->sec_fat1[0] * 1024,
		image_boot->fat_sectors[0]);
	fwrite(disk_image, 1, disk_size, foutput);
	fclose(foutput);
	free(disk_image);

	return 0;
}

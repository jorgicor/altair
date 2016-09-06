
/*					Time-stamp: <98/01/10 15:52:20 derik>
------------------------------------------------------------------------------

	=====
	CPCFS  --   u i . c  --  Main program, and Text Interface
	=====

	Version 0.85                    (c) February '96 by Derik van Zuetphen
------------------------------------------------------------------------------
*/


#include "cpcfs.h"


/*********************************************************************
			    Auxilaries
 *********************************************************************/

int cmd_error (const char *msg) {
/*  ^^^^^^^^^ */
	return errorf(FALSE,"Use: %s",msg);
}


int	saved_fo, saved_mo;

void set_force_mode(int fo, int mo) {
/*   ^^^^^^^^^^^^^^
Save global <force> and <mode> and set them to <fo> and <mo> (unless 9999)*/
	saved_fo = force;
	saved_mo = mode;
	if (fo!=9999) force = fo;
	if (mo!=9999) mode = mo;
}

void restore_force_mode() {
/*   ^^^^^^^^^^^^^^^^^^ */
	force = saved_fo;
	mode = saved_mo;
}


/* Relationship between <optind> and <nbof_args>:
  if (optind > nbof_args) 	no non-option
  if (optind == nbof_args)	exactly one non-option arg[optind]
  if (optind < nbof_args)	non-options at arg[optind..nbof_args]
*/

#define REMAINING_ARGS (nbof_args-optind+1)

/*********************************************************************
				Commands
 *********************************************************************/

int cmd_attrib() {
/*  ^^^^^^^^^^ */
int	set_mask = 0;
int	reset_mask = 0;
int	mask;
bool 	set;
int	i;
char	*pattern;
const char errmsg[] = "ATTRIB <attribute>... <cpm-filespec>...";
int	first_file = 0;		/* 0 = reading attributes, >0 files found */

	if (nbof_args==0) return cmd_error(errmsg);

	for (i=1;i<=nbof_args;i++) {
		if (first_file == 0) {
			if (arg[i][0]=='-') {
				if (parse_attr(arg[i]+1,&mask,&set)) {
					return errorf(FALSE,
					  "Illegal attribute \"%s\"",arg[i]);
				}
				if (set)	set_mask |= mask;
				else		reset_mask |= mask;
			} else {
				first_file = i;
			}
		} else {
			if (arg[i][0]=='-')
				return errorf(FALSE,
					"FIRST attributes, THEN filenames");
		}
	}

	for (i=first_file;i<=nbof_args;i++) {
		pattern = arg[i];
		if (change_attrib(pattern,set_mask,reset_mask))
			return 0;
	}

	return 0;
}


int cmd_close() {
/*  ^^^^^^^^^ */
	if (nbof_args!=0) 	return cmd_error("CLOSE");

	close_image();
	return 0;
}


int cmd_cls() {
/*  ^^^^^^^ */
	if (nbof_args!=0) 	return cmd_error("CLS");

	clrscr();
	return 0;
}


int cmd_comment() {
/*  ^^^^^^^^^^^ */
int	i;
time_t	now;
const char original_text[] = "EMU Disk-File\r\nDisk-Info\r\n";
char buf[256]; /* 3 lines should be enough */
const char errmsg[] = "COMMENT [ -d | -n | <string> ]";

	if (inactive()) return -1;
	if (nbof_args==0) {
		printm(0,"Comment is \"");
		for (i=0;i<40;i++) {
			if (*(disk_header.tag+8+i)==0) break;
			putcharm(0,*(disk_header.tag+8+i));
		}
		printm(0,"\"\n");
		return 0;
	}

	if (nbof_args!=1) return cmd_error(errmsg);
	
	if (arg[1][0]=='-') {
		switch (tolower(arg[1][1])) {
		case 'd':
			comment_image(original_text);
			break;
		case 'n':
			now = time(NULL);
			strcpy(buf,"EMU / ");	/* 6 bytes */
			strftime(buf+6,20,"%d %b %y %H:%M",localtime(&now));
			buf[26]=0;
			comment_image(buf);
			break;
		default:  return cmd_error(errmsg);
		}
	} else {
		expand_percent(arg[1],buf,256);
		comment_image(buf);
	}
	return 0;
}


int cmd_copy() {
/*  ^^^^^^^^
Copies one or more files to another file or in another user.
*/

int	trg_user;
int	i;
char	root[INPUTLEN], ext[INPUTLEN];

const char errmsg[] = "\tCOPY [-f | -t | -b] <form-cpmname> <to-cpmname>\n"
		      "\tCOPY [-f | -t | -b] <form-cpmspec>.. <userarea>";
int	local_force, local_mode;
char	optchar;

	if (inactive()) return 0;
	if (nbof_args==0)
		return cmd_error(errmsg);

/* parse options */
	local_force = force;
	local_mode = mode;
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"ftb"))!= EOF) {
		switch (optchar) {
		case 'f':	local_force = TRUE;	break;
		case 't':	local_mode = M_TEXT;	break;
		case 'b':	local_mode = M_BIN;	break;
		case '?':	return cmd_error(errmsg);
		}
	}
	if (REMAINING_ARGS < 2)
		return cmd_error(errmsg);

	set_force_mode(local_force,local_mode);

	parse_cpm_filename(arg[nbof_args],&trg_user,root,ext);
	if (*root==0) {
		if (trg_user==-1) trg_user = cur_user;
		if (trg_user==-2)
			return errorf(FALSE,"No wildcards allowed in user");
		for (i=optind;i<nbof_args;i++) {
			copy_wild(arg[i],trg_user);
		}
	} else {
		if (REMAINING_ARGS!=2) return cmd_error(errmsg);
		upper(arg[optind]);
		copy_file(arg[optind],arg[optind+1]);
	}	

	restore_force_mode();
	return 0;
}


int cmd_dir() {
/*  ^^^^^^^ */
char	pattern[INPUTLEN] = "";
int	what=DIR_DOUBLE;	/* see DIR_* in cpcfs.h */
int	how=DIR_SORT;
char	optchar;
const char errmsg[] = "DIR [-l | -a | -w] [-u] [<cpm-filespec>]";

	if (inactive()) return 0;

/* parse options */
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"awlu"))!= EOF) {
		switch (optchar) {
		case 'a':	what = DIR_AMSHEAD;	break;
		case 'l':	what = DIR_LONG;	break;
		case 'w':	what = DIR_WIDE;	break;
		case 'u':	how &= ~DIR_SORT;	break;
		case '?':	return cmd_error(errmsg);
		}
	}

	if (REMAINING_ARGS==0)	strcpy(pattern,"*.*");
	if (REMAINING_ARGS==1)	strcpy(pattern,arg[optind]);
	if (REMAINING_ARGS>1)	return cmd_error(errmsg);

	dir(pattern,what|how);
	return 0;
}


int cmd_dira() {
/*  ^^^^^^^^ */
	execute_cmd("dump -d");
	printm(1,"\nDIRA will be obsolete in future versions! "
		 "Use DUMP -D instead!\n");
	return 0;
}


int cmd_dpb() {
/*  ^^^^^^^ */
	if (inactive())	return 1;
	if (nbof_args!=0)	return cmd_error("DPB");

	printm(0,"Standard Disk Parameter Block:\n");
	printm(0,"%s\n",repstr(hori,79));	
	
	printm(0,"SPT = 0x%-2X = %-3u   \trecords per track\n",
		dpb->SPT,dpb->SPT);
        printm(0,"BSH = 0x%1X = %-3u   \t2^BSH = records/block \n",
		dpb->BSH,dpb->BSH);
        printm(0,"BLM = 0x%1X = %-3u   \tBLM+1 = records/block \n",
		dpb->BLM,dpb->BLM);
	printm(0,"EXM = 0x%1X = %-3u   \tEXM+1 = extents/entry\n",
		dpb->EXM,dpb->EXM);
	printm(0,"DSM = 0x%-2X = %-3u   \tDSM+1 = total number of blocks\n",
		dpb->DSM,dpb->DSM);
	printm(0,"DRM = 0x%-2X = %-3u   \tDRM+1 = entries/directory\n",
		dpb->DRM,dpb->DRM);
	printm(0,"AL0 = 0x%1X = %-3u   \tfirst eight bit of allocation map\n",
		dpb->AL0,dpb->AL0);
	printm(0,"AL1 = 0x%1X = %-3u   \tsecond eight bit of allocation map\n",
		dpb->AL1,dpb->AL1);
	printm(0,"CKS = 0x%-2X = %-3u   \trecords/directory \n",
		dpb->CKS,dpb->CKS);
	printm(0,"OFS = 0x%-2X = %-3u   \treserved tracks for system (offset)\n",
		dpb->OFS,dpb->OFS);

	putcharm(0,10);
	printm(0,"Additional info:\n");
	printm(0,"%s\n",repstr(hori,79));

	printm(0,"Heads = %d, ",dpb->HDS);
	printm(0,"Tracks = %d, ",dpb->TRKS);
	printm(0,"Sectors = %d\n",dpb->SECS);
	printm(0,"Number of first sector = 0x%-2X\n",dpb->SEC1);
	printm(0,"Bytes/sector           = %d\n",dpb->BPS);
	printm(0,"Bytes/blocks           = %d\n",dpb->BLS);
	printm(0,"Blocks/directory       = %d\n",dpb->DBL);

	return 0;
}


int cmd_dump() {
/*  ^^^^^^^^ */

int	blk[2], hd[2], trk[2], sec[2];
int	what=0;	/* 0=blkdump, 1=secdump, 2=dirdump, 3=map */
int	how=1;	/* 0=on stdout, 1=on pager, 2=on file */
int	ind=0;
char	name[INPUTLEN] = "";
char	optchar;
FILE	*file;
int	i,j,k;
const char errmsg[] = "DUMP (-d | -m | (-b#|-h#|-t#|-s#|-1|-2)... ) "
						"[-f<dos-filename> | -c] ";

	if (inactive()) return 0;
	if (nbof_args==0)	return cmd_error(errmsg);

	blk[0] = hd[0] = trk[0] = sec[0] = 0;
	blk[1] = hd[1] = trk[1] = sec[1] = -1;


/* parse options */
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"b:h:t:s:f:cdm12"))!= EOF) {
		switch (optchar) {
		case 'b':	blk[ind]=atoxi(optarg);	what=0;	break;
		case 'h':	hd[ind]=atoxi(optarg);	what=1;	break;
		case 't':	trk[ind]=atoxi(optarg);	what=1;	break;
		case 's':	sec[ind]=atoxi(optarg);	what=1;	break;
		case 'f':	strcpy(name,optarg);	how=2;	break;
		case 'c':	how=0;	break;
		case 'd':	what=2;	break;
		case 'm':	what=3;	break;
		case '1':	ind=0;	break;
		case '2':	ind=1;	break;
		case ':':
		case '?':	return cmd_error(errmsg);
		}
	}

	if (REMAINING_ARGS>0)
		return cmd_error(errmsg);

/* prepare the output medium */
	switch (how) {
	case 0:		/* stdout */
		file=stdout;/*fdopen(1,"w");*/
		break;
	case 1:		/* pager */
		tmp_nam(name);
		file = fopen(name,"w");		
    		if (file==NULL) {
			return errorf(TRUE,"Cannot open temporary file \"%s\" "
							"for writing ",name);
		}
	case 2:		/* file */
		file = fopen(name,"w");
    		if (file==NULL) {
			return errorf(TRUE,"Cannot open \"%s\" for writing ",
									name);
		}
	}
	
/* adjust addresses */
	blk[0] = max(0,blk[0]);
	hd[0]  = max(0,hd[0]);
	trk[0] = max(0,trk[0]);
	sec[0] = max(0,sec[0]);

	blk[1] = min(dpb->DSM,blk[1]);
	hd[1]  = min(dpb->HDS-1,hd[1]);
	trk[1] = min(dpb->TRKS-1,trk[1]);
	sec[1] = min(dpb->SECS-1,sec[1]);
	
	if (blk[1]==-1) blk[1]=blk[0];
	if (hd[1]==-1)  hd[1] =hd[0];	
	if (trk[1]==-1)
		if (hd[1]==hd[0]) trk[1]=trk[0];
		else		  trk[1]=dpb->TRKS-1;
	if (sec[1]==-1)
		if (trk[1]==trk[0]) sec[1]=sec[0];
		else		    sec[1]=dpb->SECS-1;
	
/* do the output */
	switch (what) {
	case 0:		/* blkdump */
		for (i=blk[0];i<=blk[1];i++) {
			if (Break_Wish) {
				if (how!=0) fclose(file);
				do_break();
			}
			if (dump(file,i,-1,-1,-1)) break;
		}
		break;
	case 1:		/* secdump */
		i=hd[0]; j=trk[0]; k=sec[0];
		for (;;) {
			if (Break_Wish) {
				if (how!=0) fclose(file);
				do_break();
			}
			if (dump(file,-1,i,j,k)) break;
			if (i==hd[1] && j==trk[1] && k==sec[1]) break;
			next_sector(&i,&j,&k);
		}
		break;
	case 2:		/* dirdump */
		dumpdir(file);
		break;
	case 3:		/* map */
		map(file);
		break;
	}
	
	fflush(file);
	if (how!=0) fclose(file);	/* do not close stdout */
	if (how==1) {
		if (pager(name)) {
			unlink(name);
			return errorf(TRUE,"DUMP");
		}
		unlink(name);
	}
	
	return 0;
}


int cmd_echo () {
/*  ^^^^^^^^ */
	if (nbof_args>1) {
		return cmd_error("ECHO <string>");
	}

	if (nbof_args == 1)  {
		echom(0,arg[1]);	
	}
	putcharm(0,10);
	return 0;
}


int cmd_era() {
/*  ^^^^^^^ */
long	freed = 0;
int	files = 0;
int	i;
char	optchar;
int	local_force;
const char errmsg[] = "(DEL|ERA) [-f] <cpm-filespec>...";

	if (inactive()) return 0;
	if (nbof_args==0) 	return cmd_error(errmsg);

/* parse options */
	local_force = force;
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"f"))!= EOF) {
		switch (optchar) {
		case 'f':	local_force = TRUE;	break;
		case '?':	return cmd_error(errmsg);
		}
	}

	if (REMAINING_ARGS==0)
		return cmd_error(errmsg);

	set_force_mode(local_force,9999);
	for (i=optind;i<=nbof_args;i++) {
		freed += delete(FALSE,arg[i]);
		files++;	/* actually filespecs, not files!! */
	}
	printm(2,"Total: %ld Bytes\n",freed);

	restore_force_mode();
	put_directory();
	return 0;
}


int cmd_exit() {
/*  ^^^^^^^ */
	close_image();
	exit(0); return 0;
}


int cmd_force() {
/*  ^^^^^^^^^ */
	if (nbof_args > 0 ) return cmd_error("FORCE");

	force = !force;

	printm(2,"Force is switched ");
	if (force) {printm(2,"*ON*!\n");}
	else	   {printm(2,"-off-!\n");}

	return 0;
}


int cmd_get() {
/*  ^^^^^^^ */
char	trg[INPUTLEN];
int	user;
int	drive;
char	path[INPUTLEN];
char	root[INPUTLEN];
char	ext[INPUTLEN];
long	done;
char	*src;
int	i;
const char errmsg[] = "\tGET [-f | -t | -b] <cpm-filename> [<dos-filename>]\n"
		      "\tGET [-f | -t | -b] <cpm-filename>... <dos-path>";
int	local_force, local_mode;
char	optchar;

	if (inactive()) return 0;
	if (nbof_args==0) {
		return cmd_error(errmsg);
	}

/* parse options */
	local_force = force;
	local_mode = mode;
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"ftb"))!= EOF) {
		switch (optchar) {
		case 'f':	local_force = TRUE;	break;
		case 't':	local_mode = M_TEXT;	break;
		case 'b':	local_mode = M_BIN;	break;
		case '?':	return cmd_error(errmsg);
		}
	}
	if (REMAINING_ARGS==0)
		return cmd_error(errmsg);

	set_force_mode(local_force,local_mode);

/* last arg end with backslash */
	if (REMAINING_ARGS > 1
		&& arg[nbof_args][strlen(arg[nbof_args])-1]==DIRSEPARATOR) {
		parse_filename(arg[nbof_args],&drive,path,root,ext);
		if (*root) {
			cmd_error(errmsg);
			restore_force_mode();
			return 1;
		}
		for (i=optind;i<nbof_args;i++) {
			parse_cpm_filename(arg[i],&user,root,ext);		
			build_cpm_name(src,user,root,ext);

			if (drive>0)	{trg[0] = drive+'@'; trg[1]=0;}
			else		{trg[0]=0;}
			strcat(trg,path);
			strcat(trg,root);
			if (*ext)	{strcat(trg,"."); strcat(trg,ext);}
		
			printm(2,"Getting \"%s\": ",src);
			done = get (src,trg);
			if (done>=0)
				printm(2,"%ld Bytes\n",done);
			else
				printm(2,"[skipped]\n");
		}					
		
	} else {	/* one or two args */
		src = arg[optind];
		if (REMAINING_ARGS==1) {
			parse_cpm_filename(src,&user,trg,ext);
			if (ext[0]!=0) {
				strcat(trg,".");
				strcat(trg,ext);
			}
			lower(trg);
		} else
			strcpy(trg,arg[optind+1]);
	
		printm(2,"Getting \"%s\": ",src);
		done = get (src,trg);
		if (done>=0)
			printm(2,"%ld Bytes\n",done);
		else
			printm(2,"[skipped]\n");
	}


	restore_force_mode();
	return 0;
}


int cmd_help() {
/*  ^^^^^^^^
Writes a part of CPCFS.HLP to stdout.
*/
char	topic[20];
char	line[INPUTLEN];
FILE	*file;
bool	found = FALSE;
bool	ok = FALSE;

	if (nbof_args>1) return cmd_error("HELP or HELP <topic>");
	else if (nbof_args==0) strcpy(topic,"~nothing~");
	else {
		strcpy(topic,"~");
		strcat(topic,arg[1]);
		strcat(topic,"~");
	}
	lower(topic);

	strcpy(line,installpath);
	strcat(line,HELPFILE);
	file = fopen(line,"r");
	if (file==NULL) return errorf(TRUE,"I cannot read \"%s\"",line);

/* Scans for a line with ~<topic>~, puts the lines until the next ~ is reached */

	while (fgets(line,INPUTLEN,file)!=NULL) {
		if (found && line[0]!='~') {printm(0,"\r%s",line); ok = TRUE;}
		if (found && line[0]=='~') {found=FALSE; continue;}
		if (!found&& line[0]!='~') continue;
		if (!found&& line[0]=='~') found = (strstr(line,topic)!=NULL);
	}
	
	fclose(file);

	if (!ok) {
		topic[0]='"';
		topic[strlen(topic)-1]='"';
		return errorf(FALSE,"No help for %s",topic);
	}
	return 0;
}


int cmd_lcd() {
/*  ^^^^^^^ */
char	buf[PATH_MAX];
int	err;
#if DOS
char	*p;
#endif

	if (nbof_args==0)
		printm(0,"Working directory is \"%s\"\n",getwd(buf));
	else if (nbof_args>1) {
		return cmd_error("(CD|LCD) <dos-drive&directory>");
	} else {
#if DOS
		if (arg[1][1]==':') {
			setdisk(toupper(arg[1][0])-'A');
			p=arg[1]+2;
		} else {
			p=arg[1];
		}
		if (p[1]!=0 && p[strlen(p)-1]==DIRSEPARATOR) {
			p[strlen(p)-1] = 0;
		}
		err = *p==0? 0 : chdir(p);
#else
		if (arg[1][1]!=0 && arg[1][strlen(arg[1])-1]==DIRSEPARATOR) {
			arg[1][strlen(arg[1])-1] = 0;
		}
		err = chdir(arg[1]);
#endif
		if (err) {
			return errorf (FALSE,"I cannot cd to \"%s\"!",arg[1]);
		}
		printm(2,"Working directory is now \"%s\"\n",getwd(buf));
	}
	return 0;
}


int cmd_ldir() {
/*  ^^^^^^^^ */
char	buf[INPUTLEN];
int	i;
	*buf = 0;
	strcat(buf,LDIRCOMMAND);
	for (i=1;i<=nbof_args;i++) {
		strcat(buf," ");
		strcat(buf,arg[i]);
	}
	if (system (buf)) {
		return errorf(TRUE,"Error executing \"%s\"",buf);
	}
	return 0;
}


int cmd_map() {
/*  ^^^^^^^ */
	execute_cmd("dump -m");
	printm(1,"\nMAP will be obsolete in future versions! "
		 "Use DUMP -M instead!\n");
	return 0;
}


int cmd_mget() {
/*  ^^^^^^^^ */
char	src[INPUTLEN];
char	trg[INPUTLEN];
int	ent;
int	i;
int	files=0;
long	done=0,
	total=0;
const char errmsg[] = "MGET [-f | -t | -b] <cpm-filespec>...";
int	local_force, local_mode;
char	optchar;

	if (nbof_args==0) 	return cmd_error(errmsg);

/* parse options */
	local_force = force;
	local_mode = mode;
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"ftb"))!= EOF) {
		switch (optchar) {
		case 'f':	local_force = TRUE;	break;
		case 't':	local_mode = M_TEXT;	break;
		case 'b':	local_mode = M_BIN;	break;
		case '?':	return cmd_error(errmsg);
		}
	}
	if (REMAINING_ARGS==0)
		return cmd_error(errmsg);

	set_force_mode(local_force,local_mode);
	
	for (i=optind;i<=nbof_args;i++) {
		ent = glob_cpm_file(arg[i]);
		if (ent<0) {
			return errorf(FALSE,"\"%s\" not found",arg[i]);
			continue;
		}
		while (ent>=0) {
/* prepare CP/M name */
			sprintf(src,"%u:%s",directory[ent].user,
							directory[ent].name);

/* prepare DOS name */
			strcpy(trg,(signed char*)directory[ent].name);
			lower(trg);
			if (trg[strlen(trg)-1]=='.') trg[strlen(trg)-1]=0;

			printm(2,"Getting \"%s\": ",src);
			glob_env++;	/* <get> itself uses <glob_cpm_*> */
			done = get(src,trg);
			glob_env--;

			if (done>=0) {
				printm(2,"%ld Bytes\n",done);
				files++;
				total += done;
			} else
				printm(2,"[skipped]\n");

			ent = glob_cpm_next();
		}
	} /* for i */

	printm(2,"Total: %ld Bytes, %d file%s\n", total, files, plural(files));
	restore_force_mode();
	return 0;
}


int cmd_mode() {
/*  ^^^^^^^^ */
	if (nbof_args == 0) {
		printm(0,"Mode is %s\n",show_mode(mode));
		return 0;
	}
	if (nbof_args> 1 ) {
		return cmd_error("MODE bin | text | auto");
	}

	switch (tolower(arg[1][0]))  {
	case 'b':
		mode = M_BIN;
		break;
	case 't':
		mode = M_TEXT;
		break;
	case 'a':
		mode = M_AUTO;
		break;
	default:
		return errorf(FALSE,"Unrecognized mode \"%s\". "
			"Valid are Auto, Bin, and Text; or A, B, T.\n",arg[1]);
	}
	printm(2,"Mode set to %s\n",show_mode(mode));
	return 0;
}


int cmd_mput() {
/*  ^^^^^^^^ */
char	trg[13];
char	*src;
int	files;
int	total_files = 0;
long	done=0,
	total=0;
int	drive;
char	path[INPUTLEN];
char	rootname[INPUTLEN];
char	extension[INPUTLEN];
const char errmsg[] = "MPUT [-f | -t | -b] <dos-filespec>...";
int	local_force, local_mode;
char	optchar;
int	i;

	if (inactive()) return 0;
	if (nbof_args==0)  {
		return cmd_error(errmsg);
	}

/* parse options */
	local_force = force;
	local_mode = mode;
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"ftb"))!= EOF) {
		switch (optchar) {
		case 'f':	local_force = TRUE;	break;
		case 't':	local_mode = M_TEXT;	break;
		case 'b':	local_mode = M_BIN;	break;
		case '?':	return cmd_error(errmsg);
		}
	}
	if (REMAINING_ARGS==0)
		return cmd_error(errmsg);

	set_force_mode(local_force,local_mode);


	for (i=optind;i<=nbof_args;i++) {
		src = glob_file(arg[i]);
		files = 0;
		while (src!=NULL) {
			parse_filename(src,&drive,path,rootname,extension);
			strcpy(trg,rootname);
			if (*extension) {
				strcat(trg,".");
				strcat(trg,extension);
			}
	
			printm(2,"Putting \"%s\": ",src);
			done = put(src,trg);
			if (done>=0) {
				printm(2,"%ld Bytes\n",done);
				total += done;
				files++;
			} else if (done==-1)
				printm(2,"[skipped]\n");
			else {	/* done==-2 */
				printm(2,"[aborted]\n");
				restore_force_mode();
				return 1;
			}

			src=glob_next();
		}
		if (files==0)  {
			printm(1,"\"%s\" not found!\n",arg[i]);
		} else {
			total_files += files;
		}

	} /* for i*/

	printm(2,"Total: %ld Bytes, %d file%s\n",total,total_files,
							plural(total_files));
	restore_force_mode();
	return 0;
}


int cmd_new() {
/*  ^^^^^^^ */
DPB_type *dpb;
char	name[INPUTLEN];
const char errmsg[] = "(NEW|FORMAT) [-s | -d | -i | -v]  <imagename>";
char	optchar;

	if (nbof_args==0) {
		return cmd_error(errmsg);
	}

/* parse options */
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	dpb = &DPB_store[DATA_DPB];
	while ((optchar=getopt(nbof_args+1,arg,"sdiv"))!= EOF) {
		switch (optchar) {
		case 's':	dpb = &DPB_store[SYSTEM_DPB]; break;
		case 'd':	dpb = &DPB_store[DATA_DPB]; break;
		case 'i':	dpb = &DPB_store[IBM_DPB]; break;
		case 'v':	dpb = &DPB_store[VORTEX_DPB]; break;
		case '?':	return cmd_error(errmsg);
		}
	}
	if (REMAINING_ARGS!=1)
		return cmd_error(errmsg);

	close_image();
	strcpy(name,arg[optind]);
	append_suffix(name,"dsk");

	if (access(name,F_OK)==0) {
		if (Verb > 0) {
			printm(1,"\"%s\" already exists! Overwrite? ",name);
			if (!confirmed())  {
				return 0;
			}
		}
	}

	if (format(name,dpb)) return 0;

	open_image(name);	/* reopen and initialize */
	return 0;
}


int cmd_open() {
/*  ^^^^^^^^ */
char	buf[INPUTLEN];


	if (nbof_args==0) {
		if (*disk_header.tag)
			printm(0,"Image in use is \"%s\"\n",imagename);
		else
			printm(0,"No Image loaded!\n");
	}
	else if (nbof_args>1) {
		return cmd_error("OPEN <image-file>");
	}
	else {
		strcpy(buf,arg[1]);
		append_suffix(buf,"dsk");
		open_image(buf);
	}
	return 0;
}


int cmd_page()  {
/*  ^^^^^^^^ */
	if (nbof_args>1)  return cmd_error("PAGE <number-of-lines>");

	if (nbof_args==0)
		printm(0,"Page length is  %d\n",pagelen);
	else {
		pagelen = atoxi(arg[1]);
		printm(2,"Page length set to %d\n",pagelen);
	}
	return 0;
}


int cmd_prompt() {
/*  ^^^^^^^^^^ */
	if (nbof_args == 0) {
		printm(0,"Prompt is \"%s\"\n",prompt);
		return 0;
	}
	if (nbof_args>1) {
		return cmd_error("PROMPT <string>");
	}

	strcpy(prompt,arg[1]);
	return 0;
}


int cmd_put() {
/*  ^^^^^^^ */
char	trg[INPUTLEN];		/* CP/M name */
long	done;
int     drive;
char    path[INPUTLEN];
char    rootname[INPUTLEN];
char    extension[INPUTLEN];
const char errmsg[] = "\tPUT [-f | -t | -b] <dos-filename> [<cpm-filename>]\n"
		      "\tPUT [-f | -t | -b] <dos-filename> [<userarea>]\n";
int	local_force, local_mode;
char	optchar;

	if (inactive()) return 0;
	if (nbof_args==0)  {
		return cmd_error(errmsg);
	}

/* parse options */
	local_force = force;
	local_mode = mode;
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	while ((optchar=getopt(nbof_args+1,arg,"ftb"))!= EOF) {
		switch (optchar) {
		case 'f':	local_force = TRUE;	break;
		case 't':	local_mode = M_TEXT;	break;
		case 'b':	local_mode = M_BIN;	break;
		case '?':	return cmd_error(errmsg);
		}
	}
	if (REMAINING_ARGS>2 || REMAINING_ARGS==0)
		return cmd_error(errmsg);

	set_force_mode(local_force,local_mode);

/* build target name */
	parse_filename(arg[optind],&drive,path,rootname,extension);
	if (REMAINING_ARGS==1) {
		strcpy(trg,rootname);
		if (*extension) {
			strcat(trg,".");
			strcat(trg,extension);
		}
	} else if (arg[optind+1][strlen(arg[optind+1])-1]==':') {/* only user */
		strcpy(trg,arg[optind+1]);
		strcat(trg,rootname);
		if (*extension) {
			strcat(trg,".");
			strcat(trg,extension);
		}
	} else {
		strcpy(trg,arg[optind+1]);
	}

	printm(2,"Putting \"%s\": ",arg[optind]);
	done = put(arg[optind],trg);
	if (done>=0)
		printm(2,"%ld Bytes\n",done);
	else if (done==-1)
		printm(2,"[skipped]\n");
	else /* done==-2 */
		printm(2,"[aborted]\n");
	restore_force_mode();
	return 0;
}


int cmd_ren() {
/*  ^^^^^^^
Reanmes a file to another name or shift a lot of files to another user. */
int	i;
int	trg_user;
char	root[INPUTLEN], ext[INPUTLEN];

const char errmsg[] = "\tREN <from-cpm-filespec> <to-cpm-filespec>\n"
		      "\tREN <from-cpm-filespec>... <userarea>";

	if (inactive()) return 0;
	if (nbof_args<2) {
		return cmd_error(errmsg);
	}

	parse_cpm_filename(arg[nbof_args],&trg_user,root,ext);
	if (*root==0) {
		if (trg_user==-1) trg_user = cur_user;		
		if (trg_user==-2)
			return errorf(FALSE,"No wildcards allowed in user");
		for (i=1;i<nbof_args;i++) {
			ren_wild(arg[i],trg_user);
		}
	} else {
		if (nbof_args!=2) return cmd_error(errmsg);
		ren_file(arg[1],arg[2]);
	}

	update_directory();
	put_directory();
	return 0;
}


int cmd_source() {
/*  ^^^^^^^^^^ */

	if (nbof_args!=1) 	return cmd_error("SOURCE <dos-filename>");
	execute_file (arg[1]);
	return 0;
}


int cmd_spawn() {
/*  ^^^^^^^^^ */
char	*buf;
const char errmsg[] ="Error executing \"%s\"";

	if (nbof_args==0) {
		printm(3,"[EXIT to return to cpcfs]\n");
		if ((buf=getenv(SHELLVAR))==NULL) {
			save_path();
			if (system(SHELLDEFAULT)) {
				return errorf(TRUE,errmsg,SHELLDEFAULT);
			}
			rest_path();
		} else {
			save_path();
			if (system (buf)) {
				return errorf(TRUE,errmsg,buf);
			}
			rest_path();
		}
	} else {
		reparse(1);
		save_path();
		if (system(arg[1])) {
			return errorf(TRUE,errmsg,arg[1]);
		}
		rest_path();
	}
	if ((*disk_header.tag) && (access(full_imagename,R_OK))) {
		abandonimage();
		return -1;
	}
	return 0;
}


int cmd_stat() {
/*  ^^^^^^^^ */
char	buf[256];
	if (nbof_args!=0) return cmd_error("STAT");

	putcharm(0,10);
	if (*disk_header.tag) {
		printm(0,"Image File     : %s\n",imagename);
		printm(0,"Format         : %s\n",show_format(cur_format));
		putcharm(0,10);
		printm(0,"CP/M           : ");
		if (dpb->SYS) {
			printm(0,"Yes\n");
		} else {
			printm(0,"No");
			if (dpb->OFS > 0)
				printm(0,", but %d track%s reserved\n",
						  dpb->OFS,plural(dpb->OFS));
			else
				printm(0,"\n");
		}
		printm(0,"Current user   : %d\n",cur_user);
		putcharm(0,10);

		printm(0,"Capacity       : %d Blocks = %ld Bytes\n",
				dpb->DSM+1, ((long)dpb->DSM+1)*dpb->BLS);
		printm(0,"Directory      : %d Block%s\n",
				       (dpb->DRM+1)*32/(dpb->BLS),
				plural((dpb->DRM+1)*32/(dpb->BLS)));
		printm(0,"Allocated      : %d Block%s = %ld Bytes = %5.1f%%\n",
		    allocated_blks, plural(allocated_blks),
		    (long)allocated_blks*dpb->BLS, percentage);
		printm(0,"Free           : %d Block%s = %ld Bytes = %5.1f%%\n",
		    free_blks, plural(free_blks),
		    (long)free_blks*dpb->BLS, 100.0-percentage);
		putcharm(0,10);
	} else	{
		printm(0,"No image loaded!\n");
		putcharm(0,10);
	}

	printm(0,"Prompt=\"%s\";  ",prompt);
	printm(0,"Local directory=\"%s\"\n", getwd(buf));
	printm(0,"Verbosity=%d;  ",Verb);
	printm(0,"Page length=%d;  ",pagelen);
	printm(0,"Mode=%s;  ",show_mode(mode));
	printm(0,"Force=");
			if (force) printm(0,"*ON*"); else printm(0,"-off-");
	printm(0,"\n");
	putcharm(0,10);

	return 0;
}


int cmd_sysgen() {
/*  ^^^^^^^^^^ */
	if (inactive()) return 0;
	if (nbof_args!=1) return cmd_error("SYSGEN <dos-filename>");

	if (dpb->OFS == 0) {
		return errorf(FALSE,"No system tracks reserved in %s",
						show_format(cur_format));
	}

	if (dpb->SYS) {
		if (Verb > 0) {
			printm(1,"CP/M already in image! Overwrite? ");
			if (!confirmed()) return 0;
		}
	}

	if (dpb->OFS < 2) {
		return errorf(FALSE,"Too few space for system (I need 2 "
						"tracks, not %d)",dpb->OFS);
	}

	sysgen(arg[1]);
	return 0;
}


int cmd_type() {
/*  ^^^^^^^^
Puts the contents of a CP/M file to a pager [def], a file [-f] or stdout [-c].
*/
char	outname[INPUTLEN];
char	tempname[INPUTLEN];
char	*cpmname;
char	optchar;
FILE	*outfile;
int	tempfile;
int	local_mode;
int	how=1;		/* 0=on stdout, 1=on pager, 2=on file */
int	counter=0;
int	i, r;
int	err;
uchar	*buf;
const char errmsg[] = "TYPE [-f <dos-filename> | -c | -t | -b] <cmp-filename>";

	buf = block_buffer;	/* a shortcut */

	if (inactive()) return 0;
	if (nbof_args==0)       return cmd_error(errmsg);

/* parse options */
	opterr = 0;	/* no errormessages in getopt */
	optind = FIRST_OPTIND;
	local_mode = mode;
	while ((optchar=getopt(nbof_args+1,arg,"f:ctb"))!= EOF) {
		switch (optchar) {
		case 'f':	strcpy(outname,optarg);	how=2;	break;
		case 'c':	how=0;	break;
		case 't':	local_mode = M_TEXT;	break;
		case 'b':	local_mode = M_BIN;	break;
		case ':':
		case '?':	return cmd_error(errmsg);
		}
	}

	if (REMAINING_ARGS!=1) return cmd_error(errmsg);

	set_force_mode(9999,local_mode);
	cpmname = arg[optind];

/* prepare the output medium */
	switch (how) {
	case 0:		/* stdout */
		outfile=fdopen(1,"w");
		break;
	case 1:		/* pager */
		tmp_nam(outname);
		outfile = fopen(outname,"w");
		if (outfile==NULL) {
			return errorf(TRUE,"Cannot open temporary file \"%s\" "
							"for writing ",outname);
		}
	case 2:		/* file */
		outfile = fopen(outname,"w");
		if (outfile==NULL) {
			return errorf(TRUE,"Cannot open \"%s\" for writing ",
									outname);
		}
	}


/* do the output */
	tmp_nam(tempname);
	err=get(cpmname,tempname);
	if (err==-1) {
		restore_force_mode();
/*		return errorf(FALSE,"\"%s\" not found",cpmname);*/
		return -1;
	}

	tempfile=open(tempname,O_RDONLY|O_BINARY);
	if (tempfile==-1) {
		errorf(TRUE,"I cannot read \"%s\"",tempname);
		restore_force_mode();
		return -1;
	}


	r=read(tempfile,buf,(dpb->BLS));
	if (local_mode==M_AUTO) {
		local_mode = detectmode((signed char*)buf,max((dpb->BLS),r));
	}

	while (r>0) {
		if (local_mode==M_TEXT) {
			for (i=0;i<r;i++) {
				err=putc(buf[i],outfile);
				if (err<0) break;
			}
		} else {
/* filesize is a multiple of 16, because it's a multiple of 128 */
			for (i=0;i<(dpb->BLS);i+=16) {
				err=fprintf(outfile,"%s\n",
						show_hex(counter,buf+i,16));
				if (err<0) break;
				counter += 16;
			}
		}
		if (err<0) {
			close(tempfile);
			unlink(tempname);
			return errorf(TRUE,"");
		}
		r=read(tempfile,buf,(dpb->BLS));
	}
	putc(10,outfile);

	close(tempfile);
	unlink(tempname);

	fflush(outfile);
	if (how!=0) fclose(outfile);	/* do not close stdout */
	if (how==1) {
		if (pager(outname)) errorf(TRUE,"TYPE");
		unlink(outname);
	}

	restore_force_mode();
	return 0;
}


int cmd_user() {
/*  ^^^^^^^^ */
int	u;
const char errmsg[] = "\tUSER <userarea 0..15>\n\t<userarea>:";
	if (inactive()) return 0;
	if (nbof_args == 0) printm(0,"User is %d\n",cur_user);
	else if (nbof_args > 1) {
		return cmd_error(errmsg);
	} else {
		if (!isdigit(arg[1][0])) return cmd_error(errmsg);
		u=atoxi(arg[1]);
		if (u>255) return cmd_error("<userarea> must be < 256.");
		if (u>15) printm(4,"User numbers > 15 may cause trouble.\n");
		cur_user=u;
	}
	return 0;
}


int cmd_verbosity()  {
/*  ^^^^^^^^^^^^^ */
int	v;
	if (nbof_args>1) return cmd_error("VERBOSITY [<level -1..19>]");

	if (nbof_args==0)
		printm(0,"Verbosity is %d\n",Verb);
	else {
		v = atoxi(arg[1]);
		printm(2,"Verbosity set to %d\n",v);
		Verb = v;
	}
	return 0;
}


/*********************************************************************
			  User Interface
 *********************************************************************/

#define NBOFCMDS	40
struct {
	char	*name;
	int	(*proc)();
	} command[NBOFCMDS] = {
		{"!",		cmd_spawn },
		{"?",		cmd_help },
		{"attrib",	cmd_attrib },
		{"bye",		cmd_exit },
		{"cd",		cmd_lcd },
		{"close",	cmd_close },
		{"cls",		cmd_cls },
		{"copy",	cmd_copy },
		{"comment",	cmd_comment},
		{"del",		cmd_era },
		{"dir",		cmd_dir },
		{"dira",	cmd_dira },
		{"dpb",		cmd_dpb },
		{"dump",	cmd_dump },
		{"echo",	cmd_echo },
		{"era",		cmd_era },
		{"exit",	cmd_exit },
		{"force",	cmd_force },
		{"format",	cmd_new },
		{"get",		cmd_get },
		{"help",	cmd_help },
		{"lcd",		cmd_lcd },
		{"ldir",	cmd_ldir },
		{"map",		cmd_map },
		{"mget",	cmd_mget },
		{"mode",	cmd_mode },
		{"mput",	cmd_mput },
		{"new",		cmd_new },
		{"open",	cmd_open },
		{"page",	cmd_page },
		{"prompt",	cmd_prompt },
		{"put",		cmd_put },
		{"quit",	cmd_exit },
		{"ren",		cmd_ren },
		{"source",	cmd_source },
		{"stat",	cmd_stat },
		{"sysgen",	cmd_sysgen },
		{"type",	cmd_type },
		{"user",	cmd_user },
		{"verbosity",	cmd_verbosity},
	};


int execute_one_cmd (char *input) {
/*  ^^^^^^^^^^^^^^^
Execute a single command. */
char	buffer[INPUTLEN];
char	userbuffer[INPUTLEN];
char	*line;
char	spawn[] = "!";
int	i;

	Break_Wish = FALSE;
	strncpy(buffer,input,INPUTLEN-1);
#if DOS
	line=strchr(buffer,13);
	if (line) *line=0;
#endif
	line=buffer;
	nbof_args=0;
	if (!line) return 0;
	for (;;) {
		while ((*line==' ')||(*line=='\n')||(*line=='\t'))
			line++;				/*skip white*/
		if (*line==0) break;
		if (*line=='#') break;			/*comment*/
		if (nbof_args==0) {
			if (*line=='!') {		/*! special*/
				arg[0]=spawn;
				line++;
				nbof_args++;
				continue;
			}
		}
		arg[nbof_args++] = line;		/*remember arg*/

		if (*line=='"') {			/* quoted string */
			arg[nbof_args-1]++;		/* skip quote */
			line++;
			while (*line!='"' && *line!=0) line ++;
			if (*line==0) {
				return errorf(FALSE,"Missing closing quote!");
			}
			*line++ = 0;			/* replace quote */
		} else {
			while (*line!=' ' && *line!='\n' && *line!='\t'
			  && *line!=0)
				line++;
			if (*line==0) break;
			else *line++=0;			/*set end-of-arg*/
		}

	}
	nbof_args--;


	if (nbof_args==-1) {
		nbof_args=0;
		return 0;
	}

	lower(arg[0]);

/* shortcut for USER command */
	if (nbof_args==0 && arg[0][strlen(arg[0])-1]==':') {
		sprintf(userbuffer,"user %s",arg[0]);
		execute_one_cmd(userbuffer);
		return 0;
	}

	for (i=0;i<NBOFCMDS;i++) {
		if (strcmp(command[i].name,arg[0])==0) {
			(command[i].proc)();
			return 0;
		}
	}
	return errorf(FALSE,"%s: Unknown Command!",arg[0]);
}


int execute_cmd (char *input) {
/*  ^^^^^^^^^^^
Execute commands separated by ";". */
char	*p;
	for (;;) {
		p = strchr(input,';');
		if (p) *p=0;
		execute_one_cmd(input);
		if (!p) break;
		input = p+1;
	}
	return 0;
}

/******
  main
 ******/

void init(char *argv0) {
/*   ^^^^ */

char	*p;

#if USE_READLINE && UNIX
int	rl_bind_key();		/* where is the prototype??? */
#endif
	os_init();
	strcpy(prompt,"cpcfs> ");
	*disk_header.tag=0;
/*	cur_trk = -1;	set in fs.c */
	DPB_store[USER_DPB] = DPB_store[DATA_DPB]; /* set default user DPB */
	pagelen=25;
	disable_break();
	Break_Wish = FALSE;
	mode = M_AUTO;
	force = FALSE;
#if DOS
	_fmode = O_BINARY;
#endif
#if USE_READLINE && UNIX
/* configure GNU readline */
	rl_bind_key ('\t', rl_insert);
#endif

        p = getenv("CPCFSHOME");
        if (p) {
		strcpy(installpath,p);
		installpath[strlen(installpath)]= DIRSEPARATOR;
		installpath[strlen(installpath)+1]= 0;
	} else {
/* works only for DOS, in Unix argv[0] may be a relative path,
more precisely: BCC has an absolute path in argv[0], where gcc has not */
		strcpy(installpath,argv0);
		p = strrchr(installpath,DIRSEPARATOR);
		if (p!=NULL) *(++p) = 0;
		else	     installpath[0] = 0;
	}
}


int execute_file (char *name) {
/*  ^^^^^^^^^^^^ */
FILE	*file;
char	line[INPUTLEN];

	if ((file=fopen(name,"r")) == NULL) {
		return errorf(TRUE,"\"%s\" not found",name); 
	}
	while (fgets(line,INPUTLEN,file))
		execute_cmd(line);
	fclose(file);
	return 0;
}


void read_cfg_file() {
/*   ^^^^^^^^^^^^^ */

char	name[INPUTLEN];
int	notfound;

	strcpy(name,CONFIGNAME);
	notfound = access(name,R_OK);
	if (notfound) {
		strcpy(name,installpath);
		strcat(name,CONFIGNAME);
		notfound = access (name,R_OK);
		if (notfound)  {
			return;
		}
	}
	execute_file(name);
}


void interaction (char *argv0) {
/*   ^^^^^^^^^^^ */
#if USE_READLINE && UNIX
char	prompt_buf[INPUTLEN];
char	*line;
#elif USE_READLINE && DOS
char	prompt_buf[INPUTLEN];
char	line[INPUTLEN];
int	len;
#else
char	line[INPUTLEN];
#endif

	read_cfg_file();

	setjmp(break_entry);
	for (;;) {
#if USE_READLINE && UNIX
		*prompt_buf = 0;
		if (Verb >= 1) expand_percent(prompt,prompt_buf,INPUTLEN);
		line = readline(prompt_buf);
		if (line==NULL) {
			printm(3,"[Quit]\n");
			execute_cmd("exit");
		}
		if (line && *line)	add_history(line);
		execute_cmd (line);
		free(line);
#elif USE_READLINE && DOS
		*prompt_buf = 0;
		if (Verb >= 1) expand_percent(prompt,prompt_buf,INPUTLEN);
		printf("%s",prompt_buf);
		*line=0;
		len = inputs(line,INPUTLEN-strlen(prompt_buf)-1,-1);
		if (len==-2) {
			printm(3,"[Quit]\n");
			execute_cmd("exit");
		}
		if (line && *line)	add_history(line);
		execute_cmd(line);
#else  /* ! USE_READLINE */
		echom(1,prompt);
		execute_cmd(gets(line));
#endif
	}
}



void usage (bool err) {
/*   ^^^^^ */
char	buf[INPUTLEN];
	if (err) {
		printm(1,"Error in command line!\n\n");
	} else {
		printm(1,"CPCFS - CPCEmu Filessystem Maintenance\n");
		expand_percent("%V",buf,INPUTLEN);
		printm(1,"   %s\n\n",buf);
		printm(1,"SYNOPSIS:\n");
		printm(1,"   cpcfs                  Enter interactive mode\n");	
		printm(1,"or ");
	}
	printm(1,"cpcfs [<imagefile>] <command>...\n");
	printm(1,"where\n");
	printm(1,"   <imagefile> is implicitly opened\n");
	printm(1,"   <command> = -d   dir     Directory (default command)\n");
	printm(1,"               -s   stat    Statistics\n");
	printm(1,"               -g   get     Get a file\n");
	printm(1,"               -p   put     Put a file\n");
	printm(1,"               -mg  mget    Get many files\n");
	printm(1,"               -mp  mput    Put many files\n");
	printm(1,"               -nX  new     Create new image (X=dsv, Data, "
							"System, or Vortex)\n");
	printm(1,"               -f   force   Force overwrite, if file exists\n");
	printm(1,"               -t   text    ASCII Mode\n");
	printm(1,"               -b   bin     Binary Mode\n");
	printm(1,"               -e           Execute arbitrary commands, "
							"separated by ';'\n");
	printm(1,"               -x   source  Execute commands from file\n");
	printm(1,"               -h, -?       This help\n");
}




void ui_main (int argc, char **argv) {
/*   ^^^^^^^
Main function for CPCFS based on Text User Interface */

char	line[INPUTLEN];
int	i;
bool	more_switches = TRUE;

	init(argv[0]);

/* no arguments => interactive mode */
	if (argc==1) {
		Interactive = TRUE;
		interaction(argv[0]);
		exit(0);
	}	

	Interactive = FALSE;
/* only filename => dir all */
	if ((argc==2) && argv[1][0]!='-') {
		strcpy(line,"open "); strcat(line,argv[1]);
		if (execute_cmd(line))		exit(1);
		if (execute_cmd("dir *:*.*"))	exit(1);
		exit(0);
	}

/* execute commandline */
	strcpy(line,"open");	/* if no command is given */
	for (i=1;i<argc;i++) {
		if (more_switches && argv[i][0]=='-') {
			if (i>1) {
				if (execute_cmd(line)) {
					exit(1);
				}
			}
			*line = 0;
			switch (tolower(argv[i][1])) {
			case 'g': strcpy(line,"get"); break;
			case 'p': strcpy(line,"put"); break;
			case 'f': strcpy(line,"force"); break;
			case 't': strcpy(line,"mode text"); break;
			case 'b': strcpy(line,"mode bin"); break;
			case 'm':
				switch (tolower(argv[i][2])) {
				case 'g': strcpy(line,"mget"); break;
				case 'p': strcpy(line,"mput"); break;
				default:  usage(TRUE); exit(1);
				}
				break;
			case 'n':
				switch (tolower(argv[i][2])) {
				case 'd': strcpy(line,"new -d"); break;
				case 's': strcpy(line,"new -s"); break;
				case 'v': strcpy(line,"new -v"); break;
				default:  usage(TRUE); exit(1);
				}
				break;
			case 's': strcpy(line,"stat"); break;
			case 'e': more_switches = FALSE; break;
			case 'd': strcpy(line,"dir"); break;
			case 'x': strcpy(line,"source"); break;
			case 'h':
			case '?': usage(FALSE); exit(0);
			default:  usage(TRUE); exit(1);
			}
		} else {
                        if (strlen(line)+strlen(argv[i])+2 > INPUTLEN) {
                                errorf(FALSE,"Commandline too long (>%d chars)", INPUTLEN);
                                exit(1);
                        }
			strcat(line," ");
			strcat(line,argv[i]);
		}
	}
	execute_cmd(line);
	execute_cmd("close");
}

/*
* This file is part of LSTRD.
*
* Copyright (C) 2003 Pavel Cejka <pavel.cejka at kapsa.club.cz>
*
* Modifications (C) 2015 ub880d <ub880d@users.sf.net>
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or (at
* your option) any later version.
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
* USA
*/

#define SEC_SIZE 256
#define TRK_SIZE 16
#define INFO_SEC 8

// TRDOS INFO SECTOR
#define OFFSET_FIRSTSECTOR	225		/* První volný sektor pou¾itelný k ulo¾ení souboru. */
#define OFFSET_FIRSTTRACK	226		/* První volný track pou¾itelný k ulo¾ení souboru. */
#define OFFSET_DISKFORMAT	227		/* Formát 22=80tr/DS, 23=40tr/DS, 24=80tr/SS, 25=40tr/SS */
#define OFFSET_FILES   		228		/* Poèet souborù vèetnì smazaných, které nebyly poslední. */
#define OFFSET_FREESECTORS	229		/* Poèet volných sektorù - 2 byty */
#define OFFSET_TRDOSIDENT	231		/* TRDOS identifikace, musí být v¾dy 16 */
#define OFFSET_PASSWORD		234		/* OBSOLETE!! Zastaralé, pou¾íval TRDOS 3.x a 4.x */
#define OFFSET_DELETEDFILES	244		/* Poèet smazaných souborù (tìch co nebyly poslední...) */
#define OFFSET_DISKNAME		245		/* Novìj¹í verze TRDOSu z Brna pou¾ívá 10 znakù, star¹í jen 8 */

typedef struct {
	unsigned char byte[SEC_SIZE];
} trdos_sector;
	
typedef struct {
	trdos_sector sector[TRK_SIZE];
} trdos_track;


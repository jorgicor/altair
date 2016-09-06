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
#define OFFSET_FIRSTSECTOR	225		/* Prvn� voln� sektor pou�iteln� k ulo�en� souboru. */
#define OFFSET_FIRSTTRACK	226		/* Prvn� voln� track pou�iteln� k ulo�en� souboru. */
#define OFFSET_DISKFORMAT	227		/* Form�t 22=80tr/DS, 23=40tr/DS, 24=80tr/SS, 25=40tr/SS */
#define OFFSET_FILES   		228		/* Po�et soubor� v�etn� smazan�ch, kter� nebyly posledn�. */
#define OFFSET_FREESECTORS	229		/* Po�et voln�ch sektor� - 2 byty */
#define OFFSET_TRDOSIDENT	231		/* TRDOS identifikace, mus� b�t v�dy 16 */
#define OFFSET_PASSWORD		234		/* OBSOLETE!! Zastaral�, pou��val TRDOS 3.x a 4.x */
#define OFFSET_DELETEDFILES	244		/* Po�et smazan�ch soubor� (t�ch co nebyly posledn�...) */
#define OFFSET_DISKNAME		245		/* Nov�j�� verze TRDOSu z Brna pou��v� 10 znak�, star�� jen 8 */

typedef struct {
	unsigned char byte[SEC_SIZE];
} trdos_sector;
	
typedef struct {
	trdos_sector sector[TRK_SIZE];
} trdos_track;


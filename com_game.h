/*
Copyright (C) 2000-2021 DarkPlaces contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#ifndef COM_GAME_H
#define COM_GAME_H

#include "qdefs.h"

typedef enum gamemode_e
{
	GAME_NORMAL,
	GAME_HIPNOTIC,
	GAME_ROGUE,
	GAME_QUOTH,
	GAME_TRANSFUSION,
	GAME_GOODVSBAD2,
	GAME_BATTLEMECH,
	GAME_COUNT
}
gamemode_t;

extern gamemode_t gamemode;
extern const char *gamename;
extern const char *gamenetworkfiltername;
extern const char *gamedirname1;
extern const char *gamedirname2;
extern const char *gamescreenshotname;
extern const char *gameuserdirname;
extern char com_modname[MAX_OSPATH];

void COM_InitGameType (void);
int COM_ChangeGameTypeForGameDirs(unsigned numgamedirs, const char *gamedirs[], qbool failmissing, qbool init);

#endif

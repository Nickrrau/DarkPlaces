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

#include "darkplaces.h"
#include "com_game.h"

// Game mods

gamemode_t gamemode;
const char *gamename;
const char *gamenetworkfiltername; // same as gamename currently but with _ in place of spaces so that "getservers" packets parse correctly (this also means the 
const char *gamedirname1;
const char *gamedirname2;
const char *gamescreenshotname;
const char *gameuserdirname;
char com_modname[MAX_OSPATH] = "";

gamemode_t com_startupgamemode;
gamemode_t com_startupgamegroup;

typedef struct gamemode_info_s
{
	gamemode_t mode; ///< this gamemode
	gamemode_t group; ///< different games with same group can switch automatically when gamedirs change
	const char* prog_name; ///< not null
	const char* cmdline; ///< not null
	const char* gamename; ///< not null
	const char* gamenetworkfiltername; ///< not null
	const char* gamedirname1; ///< not null
	const char* gamedirname2; ///< may be null
	const char* gamescreenshotname; ///< not null
	const char* gameuserdirname; ///< not null
} gamemode_info_t;

static const gamemode_info_t gamemode_info [GAME_COUNT] =
{// game						basegame					prog_name				cmdline						gamename					gamenetworkfilername		basegame	modgame			screenshot			userdir					   // commandline option
{ GAME_NORMAL,					GAME_NORMAL,				"",						"-quake",					"DarkPlaces-Quake",			"DarkPlaces-Quake",			"id1",		NULL,			"dp",				"darkplaces"			}, // COMMANDLINEOPTION: Game: -quake runs the game Quake (default)
{ GAME_HIPNOTIC,				GAME_NORMAL,				"hipnotic",				"-hipnotic",				"Darkplaces-Hipnotic",		"Darkplaces-Hipnotic",		"id1",		"hipnotic",		"dp",				"darkplaces"			}, // COMMANDLINEOPTION: Game: -hipnotic runs Quake mission pack 1: The Scourge of Armagon
{ GAME_ROGUE,					GAME_NORMAL,				"rogue",				"-rogue",					"Darkplaces-Rogue",			"Darkplaces-Rogue",			"id1",		"rogue",		"dp",				"darkplaces"			}, // COMMANDLINEOPTION: Game: -rogue runs Quake mission pack 2: The Dissolution of Eternity
{ GAME_NEHAHRA,					GAME_NORMAL,				"nehahra",				"-nehahra",					"DarkPlaces-Nehahra",		"DarkPlaces-Nehahra",		"id1",		"nehahra",		"dp",				"darkplaces"			}, // COMMANDLINEOPTION: Game: -nehahra runs The Seal of Nehahra movie and game
{ GAME_QUOTH,					GAME_NORMAL,				"quoth",				"-quoth",					"Darkplaces-Quoth",			"Darkplaces-Quoth",			"id1",		"quoth",		"dp",				"darkplaces"			}, // COMMANDLINEOPTION: Game: -quoth runs the Quoth mod for playing community maps made for it
{ GAME_TRANSFUSION,				GAME_TRANSFUSION,			"transfusion",			"-transfusion",				"Transfusion",				"Transfusion",				"basetf",	NULL,			"transfusion",		"transfusion"			}, // COMMANDLINEOPTION: Game: -transfusion runs Transfusion (the recreation of Blood in Quake)
{ GAME_OPENQUARTZ,				GAME_NORMAL,				"openquartz",			"-openquartz",				"OpenQuartz",				"OpenQuartz",				"id1",		NULL,			"openquartz",		"darkplaces"			}, // COMMANDLINEOPTION: Game: -openquartz runs the game OpenQuartz, a standalone GPL replacement of the quake content
{ GAME_QUAKE15,					GAME_NORMAL,				"quake15",				"-quake15",					"Quake 1.5",				"Quake_1.5",				"id1",		"quake15",		"quake15",			"darkplaces"			}, // COMMANDLINEOPTION: Game: -quake15 runs the Quake 1.5 or Quake Combat+ mod
{ GAME_AD,						GAME_NORMAL,				"ad",					"-ad",						"Arcane Dimensions",		"Arcane_Dimensions",		"id1",		"ad",			"ad",				"darkplaces"			}, // COMMANDLINEOPTION: Game: -ad runs the Arcane Dimensions mod
{ GAME_CTSJ2,					GAME_NORMAL,				"ctsj2",				"-ctsj2",					"Coppertone Summer Jam 2",	"Coppertone_Summer_Jam_2",	"id1",		"ctsj2",		"ctsj2",			"darkplaces"			}, // COMMANDLINEOPTION: Game: -ctsj2 runs the Coppertone Summer Jam 2 mod
};

static void COM_SetGameType(int index);
void COM_InitGameType (void)
{
	char name [MAX_OSPATH];
	int i;
	int index = GAME_NORMAL;

#ifdef FORCEGAME
	COM_ToLowerString(FORCEGAME, name, sizeof (name));
#else
	// check executable filename for keywords, but do it SMARTLY - only check the last path element
	FS_StripExtension(FS_FileWithoutPath(sys.argv[0]), name, sizeof (name));
	COM_ToLowerString(name, name, sizeof (name));
#endif
	for (i = 1;i < (int)(sizeof (gamemode_info) / sizeof (gamemode_info[0]));i++)
		if (gamemode_info[i].prog_name && gamemode_info[i].prog_name[0] && strstr (name, gamemode_info[i].prog_name))
			index = i;

	// check commandline options for keywords
	for (i = 0;i < (int)(sizeof (gamemode_info) / sizeof (gamemode_info[0]));i++)
		if (Sys_CheckParm (gamemode_info[i].cmdline))
			index = i;

	com_startupgamemode = gamemode_info[index].mode;
	com_startupgamegroup = gamemode_info[index].group;
	COM_SetGameType(index);
}

int COM_ChangeGameTypeForGameDirs(unsigned numgamedirs, const char *gamedirs[], qbool failmissing, qbool init)
{
	unsigned i, gamemode_count = sizeof(gamemode_info) / sizeof(gamemode_info[0]);
	int j, index = -1;
	addgamedirs_t ret = GAMEDIRS_SUCCESS;
	// this will not not change the gamegroup

	// first check if a base game (single gamedir) matches
	for (i = 0; i < gamemode_count; i++)
	{
		if (gamemode_info[i].group == com_startupgamegroup && !(gamemode_info[i].gamedirname2 && gamemode_info[i].gamedirname2[0]))
		{
			index = i;
			break;
		}
	}
	if (index < 0)
		Sys_Error("BUG: failed to find the base game!");

	// See if there is a derivative game matching the startup one (two gamedirs),
	// this prevents a Quake expansion (eg Rogue) getting switched to Quake during startup,
	// not used when changing gamedirs later so that it's possible to change from the startup mod to the base one.
	if (init)
	{
		for (i = 0; i < gamemode_count; i++)
		{
			if (gamemode_info[i].group == com_startupgamegroup && (gamemode_info[i].gamedirname2 && gamemode_info[i].gamedirname2[0]) && gamemode_info[i].mode == com_startupgamemode)
			{
				index = i;
				break;
			}
		}
	}

	// See if the base game or mod can be identified by a gamedir,
	// if more than one matches the last is used because the last gamedir is the primary.
	for (j = numgamedirs - 1; j >= 0; --j)
	{
		for (i = 0; i < gamemode_count; i++)
		{
			if (gamemode_info[i].group == com_startupgamegroup)
			if ((gamemode_info[i].gamedirname2 && gamemode_info[i].gamedirname2[0] && !strcasecmp(gamedirs[j], gamemode_info[i].gamedirname2))
			|| (!gamemode_info[i].gamedirname2 && !strcasecmp(gamedirs[j], gamemode_info[i].gamedirname1)))
			{
				index = i;
				goto double_break;
			}
		}
	}
double_break:

	// we now have a good guess at which game this is meant to be...
	COM_SetGameType(index);

	ret = FS_SetGameDirs(numgamedirs, gamedirs, failmissing, !init);
	if (ret == GAMEDIRS_SUCCESS)
	{
		Con_Printf("Game is %s using %s", gamename, fs_numgamedirs > 1 ? "gamedirs" : "gamedir");
		for (j = 0; j < fs_numgamedirs; ++j)
			Con_Printf(" %s%s", (strcasecmp(fs_gamedirs[j], gamedirname1) && (!gamedirname2 || strcasecmp(fs_gamedirs[j], gamedirname2))) ? "^7" : "^9", fs_gamedirs[j]);
		Con_Printf("\n");

		Con_Printf("gamename for server filtering: %s\n", gamenetworkfiltername);

		Host_UpdateVersion();
	}
	return ret;
}

static void COM_SetGameType(int index)
{
	static char gamenetworkfilternamebuffer[64];
	int t;

	if (index < 0 || index >= (int)(sizeof (gamemode_info) / sizeof (gamemode_info[0])))
		index = 0;
	gamemode = gamemode_info[index].mode;
	gamename = gamemode_info[index].gamename;
	gamenetworkfiltername = gamemode_info[index].gamenetworkfiltername;
	gamedirname1 = gamemode_info[index].gamedirname1;
	gamedirname2 = gamemode_info[index].gamedirname2;
	gamescreenshotname = gamemode_info[index].gamescreenshotname;
	gameuserdirname = gamemode_info[index].gameuserdirname;

	if (gamemode == com_startupgamemode)
	{
		if((t = Sys_CheckParm("-customgamename")) && t + 1 < sys.argc)
			gamename = gamenetworkfiltername = sys.argv[t+1];
		if((t = Sys_CheckParm("-customgamenetworkfiltername")) && t + 1 < sys.argc)
			gamenetworkfiltername = sys.argv[t+1];
		if((t = Sys_CheckParm("-customgamedirname1")) && t + 1 < sys.argc)
			gamedirname1 = sys.argv[t+1];
		if((t = Sys_CheckParm("-customgamedirname2")) && t + 1 < sys.argc)
			gamedirname2 = *sys.argv[t+1] ? sys.argv[t+1] : NULL;
		if((t = Sys_CheckParm("-customgamescreenshotname")) && t + 1 < sys.argc)
			gamescreenshotname = sys.argv[t+1];
		if((t = Sys_CheckParm("-customgameuserdirname")) && t + 1 < sys.argc)
			gameuserdirname = sys.argv[t+1];
	}

	if (strchr(gamenetworkfiltername, ' '))
	{
		char *s;
		// if there are spaces in the game's network filter name it would
		// cause parse errors in getservers in dpmaster, so we need to replace
		// them with _ characters
		dp_strlcpy(gamenetworkfilternamebuffer, gamenetworkfiltername, sizeof(gamenetworkfilternamebuffer));
		while ((s = strchr(gamenetworkfilternamebuffer, ' ')) != NULL)
			*s = '_';
		gamenetworkfiltername = gamenetworkfilternamebuffer;
	}
}

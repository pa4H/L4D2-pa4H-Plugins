/*
*
*	So, how does this thing work?
*	Welp, it's fairly easy you simply load the plugin, and use these commands in your config's files.
* 	' bhc_boom_horde_set <amount of boomed survivors> <amount of horde to spawn> '
*	
*	@param boomed - The amount of survivors that will need to be boomed.
*	@param horde - The amount of horde that will spawn as a result.
*	bhc_boom_horde_set <boomed> <horde>
*
* ----------------------------------------------------------------------------------------------------------------
*
*	Please note, the amount of specified horde will spawn once the boomed survivor count reaches that amount. 
*	Meaning, if you want a TOTAL of 15 common to spawn when two survivors are boomed you would need to do this:
*
*	bhc_boom_horde_set 	1 	5 		-		Spawn 5 common when 1 survivor gets boomed
*	bhc_boom_horde_set 	2 	10 		-		Spawn 10 common when 2nd survivor gets boomed (Total of 15 spawned.)
*
*	(or however else you want to divide it up, could be 1 3 and 2 12 if you want it to be.)
*
*/

#include <sourcemod>
#include <left4dhooks>

int BoomHordeEvents[32];
int BoomedCount;

public Plugin myinfo = 
{
	name = "[L4D2] Boomer Horde Control", 
	description = "Allows control over boomer horde sizes.", 
	author = "Spoon, pa4H", 
	version = "2.0", 
	url = "https://github.com/spoon-l4d2"
};

public OnPluginStart()
{
	RegServerCmd("BoomHordeSet", ServerCommand_SetBoomHorde, "Usage: BoomHordeSet <amount of boomed survivors> <amount of horde to spawn>");
	HookEvent("player_no_longer_it", Event_PlayerBoomedExpired);
}

public Action ServerCommand_SetBoomHorde(int args)
{
	char survBoomed[32];
	char boomSize[252];
	GetCmdArg(1, survBoomed, sizeof(survBoomed));
	GetCmdArg(2, boomSize, sizeof(boomSize));
	BoomHordeEvents[StringToInt(survBoomed, 10)] = StringToInt(boomSize, 10);
	return Plugin_Handled;
}

public Action L4D_OnSpawnITMob(int &amount)
{
	BoomedCount += 1;
	if (BoomHordeEvents[BoomedCount] != amount) { amount = BoomHordeEvents[BoomedCount]; }
	if (!amount) { amount = 10; }
	return Plugin_Changed;
}

public Event_PlayerBoomedExpired(Handle event, char[] name, bool dontBroadcast)
{
	if (BoomedCount != 0) { BoomedCount -= 1; }
}


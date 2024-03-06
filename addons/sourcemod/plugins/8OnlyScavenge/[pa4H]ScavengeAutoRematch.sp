#include <sourcemod>

char current_map[64];

public Plugin myinfo = 
{
	name = "AutoRematch",
	author = "pa4H",
	description = "No more returns to lobby",
	version = "1.0",
	url = ""
};

native void L4D2_ChangeLevel(const char[] sMap); //changelevel.smx

public OnPluginStart()
{
	HookEvent("scavenge_match_finished", Event_FinalWin, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	GetCurrentMap(current_map, sizeof(current_map));
}

public Action Event_FinalWin(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(9.0, ChangeCampaign, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ChangeCampaign(Handle timer, int client)
{
	//ServerCommand("changelevel c1m1_hotel"); //Пример стандартной смены карты. Канистры не заспаунятся
	L4D2_ChangeLevel(current_map);
	return Plugin_Stop;
}
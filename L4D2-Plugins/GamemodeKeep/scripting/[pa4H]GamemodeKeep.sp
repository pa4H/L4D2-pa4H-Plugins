#include <sourcemod>
#include <l4d2_changelevel>

Handle hMode;
Handle hRoundLimit;
Handle hConfig;

public Plugin myinfo = 
{
	name = "GamemodeKeep", 
	author = "pa4H, NiCo-op", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
};

public OnPluginStart()
{
	hMode = FindConVar("mp_gamemode");
	hRoundLimit = FindConVar("mp_roundlimit");
	hConfig = CreateConVar("gameModeKeep", "scavenge");
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("round_start_post_nav", OnRoundStartPostNav);
}

stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public Action OnRoundStartPostNav(Handle event, const char[] name, bool dontBroadcast)
{
	char mode[32];
	char config[32];
	char srvHostname[32];
	
	Handle hHostName;
	hHostName = FindConVar("hostname");
	hMode = FindConVar("mp_gamemode");
	hRoundLimit = FindConVar("mp_roundlimit");
	
	GetConVarString(hHostName, srvHostname, sizeof(srvHostname));
	GetConVarString(hMode, mode, sizeof(mode));
	GetConVarString(hConfig, config, sizeof(config));
	
	if (!Contains(srvHostname, config))
	{
		return Plugin_Continue;
	}
	
	if (!StrEqual(config, mode)) {
		SetConVarString(hMode, config);
		SetConVarInt(hRoundLimit, 5);
		ServerCommand("changelevel c8m5_rooftop");
	}
	return Plugin_Continue;
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
} 
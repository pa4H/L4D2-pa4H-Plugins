#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "11111111111111111111111111111", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb, "");
	//RegAdminCmd("sm_test", refreshPlugins, ADMFLAG_BAN);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
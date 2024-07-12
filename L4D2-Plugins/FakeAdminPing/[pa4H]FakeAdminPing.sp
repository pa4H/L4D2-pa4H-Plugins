#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

Handle ClientTimer[MAXPLAYERS + 1];
int PlayerResourceEntity;

public Plugin myinfo = 
{
	name = "FakeAdminPing", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public Action Timer_SetPing(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		int rndPing = GetRandomInt(80, 90);
		SetEntProp(PlayerResourceEntity, Prop_Send, "m_iPing", 0, _, client);
		SetEntProp(PlayerResourceEntity, Prop_Send, "m_iPing", rndPing, _, client);
	}
	return Plugin_Continue;
}


public void OnClientPostAdminCheck(int client) // Игрок загрузился
{
	if (isAdmin(client)) {
		PlayerResourceEntity = GetPlayerResourceEntity();
		ClientTimer[client] = (CreateTimer(1.0, Timer_SetPing, client, TIMER_REPEAT));
	}
}

public void OnClientDisconnect(int client)
{
	delete ClientTimer[client];
}

stock bool isAdmin(int client)
{
	if (GetUserFlagBits(client) == ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
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
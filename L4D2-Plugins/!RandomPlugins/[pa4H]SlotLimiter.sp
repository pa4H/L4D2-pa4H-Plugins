#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "SlotLimiter", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_getOnline", debb, "");
	LoadTranslations("pa4H-Stats.phrases");
}
stock Action debb(int client, int args) // DEBUG
{
	PrintToServer("Online: %i", GetOnlineClients());
	return Plugin_Handled;
}
public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	if (!IsFakeClient(client))
	{
		int pCount = GetOnlineClients();
		Handle h_visiblemaxplayers = FindConVar("sv_visiblemaxplayers");
		if (pCount + 1 > GetConVarInt(h_visiblemaxplayers)) {
			Format(rejectmsg, maxlen, "%T", "ServerFull", client, pCount, GetConVarInt(h_visiblemaxplayers));
			return false;
		}
	}
	return true;
}

stock int GetOnlineClients()
{
	int pCount = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)) { pCount++; }
	}
	return pCount;
}

stock bool IsValidClient(int client)
{
	if (IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
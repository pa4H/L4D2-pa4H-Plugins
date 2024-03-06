#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "AWPRestrict", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	LoadTranslations("pa4HWhe.phrases");
}
stock Action debb(int client, int args) // DEBUG
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}

public OnClientDisconnect(client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUse);
}
public Action WeaponCanUse(int client, int iWeapon)
{
	
	if (!IsValidClient(client)) { return Plugin_Continue; }
	
	static float fTime = 0.0;
	char sWeapon[32];
	bool bForbid;
	bool oneAWP;
	
	for (int i = 1; i < MaxClients; i++) // Ищем АВП у игроков
	{
		if (IsValidClientWOBots(i) && GetClientTeam(i) == 2)
		{
			int slotWeapon = GetPlayerWeaponSlot(i, 0);
			char slot1[32];
			if (slotWeapon != -1) { GetEntityClassname(slotWeapon, slot1, sizeof(slot1)); }
			
			if (StrEqual(slot1, "weapon_sniper_awp", false) == true)
			{
				oneAWP = true;
				
				break;
			}
		}
	}
	if (!oneAWP) { return Plugin_Continue; }
	
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
	
	if (StrEqual(sWeapon, "weapon_sniper_awp")) { bForbid = true; }
	if (bForbid) {
		if (GetEngineTime() - fTime > 0.5) {
			CPrintToChat(client, "%t", "noAWP");
			fTime = GetEngineTime();
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
stock bool IsValidClientWOBots(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
} 
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
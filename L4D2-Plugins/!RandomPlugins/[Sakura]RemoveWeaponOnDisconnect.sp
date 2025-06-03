#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <afk_manager>

public Plugin myinfo = 
{
	name = "RemoveWeaponOnDisconnect", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	RegAdminCmd("sm_rmvwpn", removeWeapon, ADMFLAG_ROOT);	
}

public void AFKM_OnClientAFK(int client) // AFK Manager 4
{
    ServerCommand("sm_rmvwpn %i", client);
}

stock Action removeWeapon(int cli, int args)
{
	char argOne[4];
	GetCmdArg(1, argOne, sizeof(argOne));
	int client = StringToInt(argOne);
	// Забираем все оружие
	for (int i = 0; i < 5; i++)
	{
		int slot = GetPlayerWeaponSlot(client, i);
		if (slot != -1) { RemovePlayerItem(client, slot); }
	}
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give weapon_pistol"); // Выдаем пистолет
	SetCommandFlags("give", flagsgive | FCVAR_CHEAT); 
	
	return Plugin_Handled;
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) // https://wiki.alliedmods.net/Generic_Source_Server_Events#player_disconnect
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Получаем номер клиента
	
	if (IsValidClient(client)) {
		ServerCommand("sm_rmvwpn %i", client);
	}
	return Plugin_Continue;
}
stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
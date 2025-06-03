#include <sourcemod>
#include <colors>
#include <left4dhooks>
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
	RegConsoleCmd("sm_test", debb);
	//RegAdminCmd("sm_test", debb, ADMFLAG_BAN);
}
stock Action debb(int client, int args) // DEBUG
{
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
	if (!IsValidBot(client)) { return Plugin_Continue; }
	char sWeapon[32];
	
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon)); // Получаем название оружия, которое подбираем
	if (IsFakeClient(client) && !StrEqual(sWeapon, "")) { return Plugin_Handled; }
	
	return Plugin_Continue;
}

stock bool IsValidBot(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && IsFakeClient(client)) {
		return true;
	}
	return false;
}
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar cvBileDamage;
float bileDamage = 20.0;

public Plugin myinfo = 
{
	name = "BiledTankDamage", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("tank_spawn", Event_OnTankSpawned);
	
	cvBileDamage = CreateConVar("biledTankDamage", "20.0", "");
	cvBileDamage.AddChangeHook(OnConVarChange);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	bileDamage = StringToFloat(newValue);
}

public Action Event_OnTankSpawned(Event event, char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank && IsClientInGame(tank))
	{
		bileDamage = GetConVarFloat(cvBileDamage);
		SDKHook(tank, SDKHook_OnTakeDamage, OnTakeDamage);
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (damagetype == 128 && IsTank(victim)) {
		switch (damage)
		{
			case 2.0: // Урон после окончания действия байлы
			{
				damage = bileDamage;
				return Plugin_Changed;
			}
			case 20.0: // Байла действует (экран Танка заблёван)
			{
				damage = bileDamage;
				return Plugin_Changed;
			}
		}
	}
	//PrintToChatAll("%N:  %i (%f) %i", victim, victim, damage, damagetype); // DEBUG
	return Plugin_Continue;
}

stock bool IsTank(int client)
{
	if (GetClientTeam(client) == 3 && client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == 8) { return true; }
	}
	return false;
} 
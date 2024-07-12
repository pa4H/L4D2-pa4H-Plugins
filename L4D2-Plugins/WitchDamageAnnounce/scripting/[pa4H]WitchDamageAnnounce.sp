#include <sourcemod>
#include <sdktools>    
#include <left4dhooks>
#include <colors>

#define WitchMaxHP 1000
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

int witchDamage[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "WitchDamageAnnounce", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_testWitch", test);
	HookEvent("infected_hurt", WitchHurt_Event, EventHookMode_Post);
	HookEvent("witch_killed", WitchDeath_Event, EventHookMode_Post);
	
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	
	LoadTranslations("pa4HWitchAnnounce.phrases");
}
stock Action test(int client, int args) // DEBUG
{
	for (int i = 1; i <= MaxClients; i++) { if (IsValidClient(i)) { PrintToChatAll("%N", i); } }
	return Plugin_Handled;
}

void PrintDamage()
{
	CPrintToChatAll("%t", "Killed");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && witchDamage[i] > 0)
		{
			PrintToChatAll("\x05%4d\x01 [\x04%d%%\x01]: \x03%N\x01", witchDamage[i], map(witchDamage[i], 0, 1000, 0, 100), i); // 1024 [100%]: Nickname
		}
	}
	ClearWitchDamage();
}

public void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	ClearWitchDamage();
}

public void OnMapEnd() // требуется, поскольку принудительная смена карты не вызывает событие "round_end"
{
	ClearWitchDamage();
}
public WitchHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int ent = GetEventInt(event, "entityid");
	if (IsWitch(ent))
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if (attacker != 0 && IsClientConnected(attacker) && GetClientTeam(attacker) == L4D_TEAM_SURVIVOR)
		{
			witchDamage[attacker] += GetEventInt(event, "amount");
		}
	}
}
public WitchDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	PrintDamage();
	ClearWitchDamage();
}
void ClearWitchDamage()
{
	for (new i = 1; i <= MaxClients; i++) { witchDamage[i] = 0;  }
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}
stock bool IsWitch(iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
}
public int map(int x, int in_min, int in_max, int out_min, int out_max) // Пропорция
{
	if (x > WitchMaxHP)
	{
		return 100;
	}
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
} 
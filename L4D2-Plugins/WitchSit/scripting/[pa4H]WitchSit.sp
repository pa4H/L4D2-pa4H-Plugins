#include <sourcemod>
#include <left4dhooks>

float origin[3];
float angles[3];

public Plugin myinfo = 
{
	name = "WitchSit", 
	author = "pa4H", 
	description = "Witch sits down after kill", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("player_death", player_death);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
public Action player_death(Handle hEvent, char[] strName, bool DontBroadcast)
{
	int witch = GetEventInt(hEvent, "attackerentid");
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (IsWitch(witch) && victim > 0)
	{
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", origin);
		GetEntPropVector(witch, Prop_Send, "m_angRotation", angles);
		RemoveEdict(witch);
		CreateTimer(0.1, RestoreWitch, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}
public Action RestoreWitch(Handle timer)
{
	L4D2_SpawnWitch(origin, angles);
	return Plugin_Stop;
}
bool IsWitch(entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        char strClassName[64];
        GetEdictClassname(entity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
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
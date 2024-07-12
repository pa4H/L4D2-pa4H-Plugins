#include <sourcemod>
#include <colors>

char tankName[32];
int maxHP;
bool less1000 = false;
float showDelay;

public Plugin myinfo = 
{
	name = "TankHP", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("tank_spawn", Event_OnTankSpawned);
	HookEvent("player_hurt", Event_OnPlayerHurt);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public void Event_OnTankSpawned(Event event, const char[] name, bool dontBroadcast)
{
	maxHP = GetEntProp(GetClientOfUserId(event.GetInt("userid")), Prop_Data, "m_iMaxHealth");
	less1000 = false;
}
public void Event_OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (!IsTank(tank)) { return; }
	
	float tNow = GetEngineTime();
	if (tNow - showDelay < 0.5) { return; }
	showDelay = tNow;
	
	int nowHP = event.GetInt("health");
	if (nowHP < 1000) { less1000 = true; }
	if (nowHP > 4000 && less1000) { PrintHintTextToAll("TANK IS DEAD"); return; }
	if (IsFakeClient(tank))
	{
		FormatEx(tankName, sizeof(tankName), "BOT"); // BOT
	}
	else
	{
		FormatEx(tankName, sizeof(tankName), "%N", tank); // Не бот
	}
	PrintHintTextToAll("%s: [%i / %i]", tankName, nowHP, maxHP);
}

stock bool IsTank(int client)
{
	if (GetClientTeam(client) == 3 && client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client))
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == 8) { return true; }
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
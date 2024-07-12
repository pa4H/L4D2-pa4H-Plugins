#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
int impacted[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Kegly", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("charger_impact", Event_ChargerImpact); // Гром оттолкнул игрока
	HookEvent("charger_carry_start", Event_ChargerCarry); // Гром схватил игрока
}
stock Action debb(int client, int args) // DEBUG
{
	PrecacheSound("pezdox/kegli.mp3");
	EmitSoundToAll("pezdox/kegli.mp3");
	
	ClearScreen();
	char bufer[32];
	Format(bufer, sizeof(bufer), "pezdox/strike.vtf");
	PrecacheDecal(bufer, true);
	//ClientCommand(client, "r_screenoverlay \"pezdox/strike.vtf\"");
	return Plugin_Handled;
}
public OnConfigsExecuted() // Карта загружена, конфиги применены, плагины загружены
{
	prepareTexture("strike");
}
void Event_ChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 6)
	{
		int ability = GetEntPropEnt(client, Prop_Send, "m_customAbility"); // ability_charge
		if (ability > 0 && IsValidEdict(ability) && HasEntProp(ability, Prop_Send, "m_isCharging") && GetEntProp(ability, Prop_Send, "m_isCharging"))
		{
			PrecacheSound("pezdox/kegli.mp3");
			EmitSoundToAll("pezdox/kegli.mp3");
			impacted[client]++;
			//PrintToChatAll("imp: %i", impacted);
		}
	}
	if (impacted[client] == 3)
	{
		//PrintToChatAll("Strike!!!");
		impacted[client] = 0;
		for (int cli = 1; cli < MaxClients; cli++) {
			if (IsValidClient(cli)) {
				ClientCommand(cli, "r_screenoverlay \"\"");
				ClientCommand(cli, "r_screenoverlay \"pezdox/strike.vtf\"");
			}
		}
		
	}
}
void Event_ChargerCarry(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	//PrintToChatAll("carry %i", client);
	CreateTimer(4.0, CleanTimer, client);
}
public Action CleanTimer(Handle hTimer, any client)
{
	//PrintToChatAll("CLEANtimer %i", client);
	impacted[client] = 0;
	ClearScreen();
	return Plugin_Stop;
}
void prepareTexture(char item[32])
{
	char bufer[32];
	
	Format(bufer, sizeof(bufer), "pezdox/%s.vtf", item);
	PrecacheDecal(bufer, true);
	
	Format(bufer, sizeof(bufer), "materials/pezdox/%s.vtf", item);
	AddFileToDownloadsTable(bufer);
	
	Format(bufer, sizeof(bufer), "pezdox/%s.vmt", item);
	PrecacheDecal(bufer, true);
	
	Format(bufer, sizeof(bufer), "materials/pezdox/%s.vmt", item);
	AddFileToDownloadsTable(bufer);
	
	AddFileToDownloadsTable("sound/pezdox/kegli.mp3");
}
public void ClearScreen()
{
	for (int cli = 1; cli < MaxClients; cli++)
	{
		if (IsValidClient(cli))
		{
			ClientCommand(cli, "r_screenoverlay \"\"");
		}
	}
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

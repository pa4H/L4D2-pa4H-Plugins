#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

static const char meleeNames[17][32] = {
	"fireaxe", 
	"baseball_bat", 
	"cricket_bat", 
	"crowbar", 
	"frying_pan", 
	"golfclub", 
	"electric_guitar", 
	"katana", 
	"machete", 
	"tonfa", 
	"knife", 
	"pitchfork", 
	"shovel", 
	"alliance_shield", 
	"fubar", 
	"nail_board", 
	"sledgehammer"
};

public Plugin myinfo = 
{
	name = "Jockey skeet", 
	author = "pa4H, Visor", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	
	HookEvent("player_death", Event_PlayerDeath);
	//RegAdminCmd("sm_test", refreshPlugins, ADMFLAG_BAN);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (killer == 0 || victim == 0 || !IsClientInGame(killer) || GetClientTeam(killer) != 2) { return; }
	char weapon[64]; GetEventString(event, "weapon", weapon, sizeof(weapon));
	int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass"); // Smoker 1, Boomer 2, Hunter 3, Spitter 4, Jockey 5, Charger 6, Witch 7, Tank 8
	if (zClass == 5 && IsMelee(weapon)) {
		CPrintToChatAll("%t", "Announce melee skeet", killer, victim);
		SndPlay(2);
	}
}

bool IsMelee(char[] weapon) // https://github.com/raziEiL/l4d2_weapons/blob/master/scripting/include/l4d2_weapons.inc
{
	for (int i = 0; i < 17; i++)
	{
		if (Contains(weapon, meleeNames[i])) { return true; }
	}
	return false;
}

void SndPlay(int snd)
{
	switch (snd)
	{
		case 1:
		{
			EmitSoundToAll("pezdox/ahuitebe.mp3");
		}
		case 2:
		{
			EmitSoundToAll("pezdox/nanahui.mp3");
		}
		case 3:
		{
			EmitSoundToAll("pezdox/kasku.mp3");
		}
	}
}

stock bool OnGround(int jockey)
{
	return !(GetEntityFlags(jockey) & FL_ONGROUND);
}

stock bool JockeyOnHead(int cliJockey)
{
	// GetEntProp(client, Prop_Send, "m_isGhost") != 1)
	int client = GetEntDataEnt2(cliJockey, 16124);
	return (IsSurvivor(client) && IsPlayerAlive(client));
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
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
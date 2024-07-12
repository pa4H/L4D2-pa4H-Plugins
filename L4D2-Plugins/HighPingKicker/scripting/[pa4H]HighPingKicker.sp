#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>
#include <geoip>

char logFile[64];
const int MaxPing = 200;
const int MaxChecks = 5;

int PlayerResourceEntity;
int pingCheck[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "HighPingKicker", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	RegConsoleCmd("sm_ping", showPing, "");
	
	BuildPath(Path_SM, logFile, 64, "logs/!HighPingKicker.txt");
	
	LoadTranslations("pa4H-HighPingKicker.phrases");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

stock Action showPing(int client, int args)
{
	int ping = GetEntProp(PlayerResourceEntity, Prop_Send, "m_iPing", _, client);
	PrintToChat(client, "Your ping : %i", ping);
	return Plugin_Handled;
}

public OnMapStart()
{
	PlayerResourceEntity = GetPlayerResourceEntity();
	CreateTimer(5.0, Timer_CheckPing, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		pingCheck[i] = 0;
	}
}

public OnClientPutInServer(client)
{
	pingCheck[client] = 0;
}

public Action Timer_CheckPing(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i)) {
			char IP[16], Country[4];
			GetClientIP(i, IP, sizeof(IP), true);
			GeoipCode3(IP, Country);
			if (!StrEqual(Country, "RUS", false)) {
				int ping = GetEntProp(PlayerResourceEntity, Prop_Send, "m_iPing", _, i);
				if (pingCheck[i] > 2 && ping < MaxPing) { pingCheck[i] = 0; } // Если пинг норм, то сбрасываем
				if (ping > MaxPing)
				{
					pingCheck[i]++;
					if (pingCheck[i] == MaxChecks) {
						char buf[256];
						//FormatEx(buf, sizeof(buf), "%T", "KickMsg", i, ping, MaxPing);
						FormatEx(buf, sizeof(buf), "%T", "shKickMsg", i);
						KickClient(i, buf);
						//LogToFileEx(logFile, "Kick: %N (%s)| Ping: %i", i, Country, ping);
						pingCheck[i] = 0;
					}
					else {
						CPrintToChat(i, "%t", "PingIsHigh", ping, pingCheck[i], MaxChecks);
					}
				}
			}
		}
	}
	return Plugin_Continue;
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
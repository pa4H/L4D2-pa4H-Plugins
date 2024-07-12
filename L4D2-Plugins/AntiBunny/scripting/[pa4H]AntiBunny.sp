#include <sourcemod>
#include <colors>

public Plugin myinfo = 
{
	name = "AntiBunny", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	AddCommandListener(say, "say");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
public Action say(client, const char[] command, args)
{
	if (IsValidClient(client) && args > 0)
	{
		char text[256];
		char teamColor[8];
		GetCmdArgString(text, sizeof(text));
		
		GetClientTeam(client) == 2 ? FormatEx(teamColor, sizeof(teamColor), "{blue}") : FormatEx(teamColor, sizeof(teamColor), "{red}");
		
		if (Contains(text, "(\\__/)"))
		{
			CPrintToChatAll("%s%N {default}:  .i.", teamColor, client);
			return Plugin_Handled;
		}
		else if (Contains(text, "(='.'=)"))
		{
			CPrintToChatAll("%s%N {default}:  Я долбоёб!", teamColor, client);
			return Plugin_Handled;
		}
		else if (Contains(text, "('')_('')"))
		{
			CPrintToChatAll("%s%N {default}:  .i.", teamColor, client);
			return Plugin_Handled;
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
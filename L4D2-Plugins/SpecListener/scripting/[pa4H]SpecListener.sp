#include <sourcemod>
#include <colors>
#include <sdktools>

#define VOICE_NORMAL	0	/**< Allow the client to listen and speak normally. */
#define VOICE_MUTED		1	/**< Mutes the client from speaking to everyone. */
#define VOICE_SPEAKALL	2	/**< Allow the client to speak to everyone. */
#define VOICE_LISTENALL	4	/**< Allow the client to listen to everyone. */
#define VOICE_ALL       6	/**< Allow to listen and speak to all*/
#define VOICE_TEAM		8	/**< Allow the client to always speak to team, even when dead. */
#define VOICE_LISTENTEAM	16	/**< Allow the client to always hear teammates, including dead ones. */

public Plugin myinfo = 
{
	name = "SpecLister", 
	author = "pa4H", 
	description = "Allows spectator listen others voice", 
	version = "4.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	HookEvent("player_team", Event_PlayerChangeTeam);
	HookEvent("player_left_start_area", LeftStartAreaEvent, EventHookMode_PostNoCopy);
	
	AddCommandListener(say, "say_team");
}

public Action say(int client, const char[] command, args)
{
	if (client > 0 && args > 0)
	{
		int team = GetClientTeam(client);
		if (team == 1) { return Plugin_Continue; }
		
		char text[256];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		
		if (strcmp(command, "say_team") == 0)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && GetClientTeam(i) == 1) {
					if (team == 2) {
						CPrintToChat(i, "(Выживший) {blue}%N {default}: %s", client, text);
					}
					else if (team == 3) {
						CPrintToChat(i, "(Зараженный) {red}%N {default}: %s", client, text);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public LeftStartAreaEvent(Handle event, char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	if (IsValidClient(client) && GetClientTeam(client) == 1)
	{
		SetClientListeningFlags(client, VOICE_ALL);
	}
}

public Event_PlayerChangeTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client)) {
		CreateTimer(0.2, PlayerChangeTeamCheck, client);
	}
}
public Action PlayerChangeTeamCheck(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		if (GetClientTeam(client) == 1) { SetClientListeningFlags(client, VOICE_ALL); }
		else { SetClientListeningFlags(client, VOICE_NORMAL); }
	}
	return Plugin_Stop;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
#include <sourcemod>
#include <sdktools>
#include <colors>

#define VOICE_NORMAL 0
#define VOICE_MUTED 1

Handle iTimer[MAXPLAYERS + 1];
bool clientSpeaking[MAXPLAYERS + 1];
Handle g_hTimeToMute;
float timeToMute;

char PREFIX[16];
public Plugin myinfo = 
{
	name = "AutoVoiceMute", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = ""
}

public void OnPluginStart()
{
	g_hTimeToMute = CreateConVar("timeToVoiceMute", "", "After this time, the player will be muted", FCVAR_CHEAT);
	timeToMute = GetConVarFloat(g_hTimeToMute); // И сразу его читаем
	HookConVarChange(g_hTimeToMute, OnConVarChange);
	LoadTranslations("pa4HAutoVoiceMute.phrases");
	
	//RegConsoleCmd("sm_test", debb, "");
	
	FormatEx(PREFIX, sizeof(PREFIX), "%t", "PREFIX"); // Сразу помещаем префикс в переменную
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
public OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	timeToMute = GetConVarFloat(g_hTimeToMute);
}

public Action UpdateSpeaking(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		char cliName[64];
		GetClientName(client, cliName, sizeof(cliName));
		for (int i = 1; i <= MaxClients; i++)
		{
			if (i == client) {
				CPrintToChat(i, "%t", "MuteSpam", PREFIX); // Для спамера выводим индивидуальное сообщение
			}
			else
			{
				if (IsValidClient(i)) { CPrintToChat(i, "%t", "MsgForAll", PREFIX, cliName); }
			}
		}
		SetClientListeningFlags(client, VOICE_MUTED); // Мутим
		clientSpeaking[client] = false;
	}
	iTimer[client] = null;
	return Plugin_Stop;
}

public void OnClientSpeaking(int client)
{
	if (!IsValidClient(client) || GetClientListeningFlags(client) == VOICE_MUTED || clientSpeaking[client]) { return; }
	
	iTimer[client] = CreateTimer(timeToMute, UpdateSpeaking, client);
	clientSpeaking[client] = true;
}
public void OnClientSpeakingEnd(int client)
{
	if (!IsValidClient(client) || GetClientListeningFlags(client) == VOICE_MUTED) { return; }
	clientSpeaking[client] = false;
	if (iTimer[client] != null) { iTimer[client] = null; }
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		clientSpeaking[i] = false;
		if (iTimer[i] != null) { delete iTimer[i]; }
	}
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		clientSpeaking[i] = false;
		if (iTimer[i] != null) { delete iTimer[i]; }
	}
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
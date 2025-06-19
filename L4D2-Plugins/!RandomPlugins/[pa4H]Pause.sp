#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

bool isPaused = false;
bool timerWorking = false;
bool fixPauseOnScreen = false;

Handle g_hAllTalk;
Handle g_hNbStop;
Handle g_hSbStop;
Handle g_hSvPausable;
g_iFlags[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Pause", 
	author = "pa4H", 
	description = "Simple pause plugin", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb, "");
	RegConsoleCmd("sm_pause", cmd_pause, "");
	
	g_hAllTalk = FindConVar("sv_alltalk");
	g_hNbStop = FindConVar("nb_stop");
	g_hSbStop = FindConVar("sb_stop");
	g_hSvPausable = FindConVar("sv_pausable");
	
	AddCommandListener(Command_Real_Pause, "pause");
	AddCommandListener(Command_Real_Pause, "setpause");
	AddCommandListener(Command_Real_Pause, "unpause");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

Action cmd_pause(int client, int args)
{
	if (timerWorking) { return Plugin_Handled; }
	if (!isPaused) {
		PauseGame();
		AllTalkOn(client);
		PauseFreeze();
	}
	else {
		CPrintToChatAll("{green}%i", 3);
		CreateTimer(1.0, Timer_unPause, 2);
		timerWorking = true;
	}
	
	return Plugin_Handled;
}

public Action Timer_unPause(Handle timer, any time)
{
	if (time != 0)
	{
		CPrintToChatAll("{green}%i", time);
		CreateTimer(1.0, Timer_unPause, --time);
	}
	else
	{
		UnPauseGame();
		AllTalkOff();
		PauseUnfreeze();
	}
	return Plugin_Stop;
}

void PauseFreeze()
{
	SetConVarInt(g_hSbStop, 1);
	SetConVarInt(g_hNbStop, 1);
	ExecuteCheatCommand("director_stop");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			SetEntityMoveType(i, MOVETYPE_NONE);
			g_iFlags[i] = GetEntProp(i, Prop_Send, "m_fFlags");
			SetEntProp(i, Prop_Send, "m_fFlags", 161);
		}
	}
}

PauseUnfreeze()
{
	SetConVarInt(g_hSbStop, 0);
	SetConVarInt(g_hNbStop, 0);
	ExecuteCheatCommand("director_start");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			SetEntityMoveType(i, MOVETYPE_WALK);
			SetEntProp(i, Prop_Send, "m_fFlags", FL_ONGROUND);
		}
	}
}

void ExecuteCheatCommand(const char[] command, const char[] value = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags);
}

void PauseGame()
{
	int client = GetValidClient();
	isPaused = true;
	Game_Pause(true, client);
}

void UnPauseGame()
{
	int client = GetValidClient();
	isPaused = false;
	timerWorking = false;
	Game_Pause(false, client);
}

void AllTalkOn(int cli)
{
	int Flags = GetConVarFlags(g_hAllTalk);
	SetConVarFlags(g_hAllTalk, (Flags & ~FCVAR_NOTIFY));
	SetConVarInt(g_hAllTalk, 1);
	SetConVarFlags(g_hAllTalk, Flags);
	CPrintToChatAll("{green}[Pause] {default}Игрок {green}%N {default}поставил паузу...\nОбщий чат {olive}включен", cli);
}

stock AllTalkOff()
{
	int Flags = GetConVarFlags(g_hAllTalk);
	SetConVarFlags(g_hAllTalk, (Flags & ~FCVAR_NOTIFY));
	SetConVarInt(g_hAllTalk, 0);
	SetConVarFlags(g_hAllTalk, Flags);
	CPrintToChatAll("{green}[Pause] {default}Игра {lightgreen}продолжается!\n{default}Общий чат {olive}выключен");
}

int GetValidClient()
{
	for (int target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target) && !IsFakeClient(target))return target;
	}
	return 0;
}

void Game_Pause(bool pause, int client)
{
	fixPauseOnScreen = true;
	SetConVarInt(g_hSvPausable, 1);
	if (pause) { FakeClientCommand(client, "setpause"); }
	else { FakeClientCommand(client, "unpause"); }
	SetConVarInt(g_hSvPausable, 0);
	fixPauseOnScreen = false;
}

public Action Command_Real_Pause(int client, const char[] command, args)
{
	if (fixPauseOnScreen) { return Plugin_Continue; }
	return Plugin_Handled;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
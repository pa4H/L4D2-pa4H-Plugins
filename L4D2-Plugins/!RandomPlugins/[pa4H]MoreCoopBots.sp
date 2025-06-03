#include <sourcemod>
#include <sdktools>

Handle hMode;
Handle cMaxPlayers;
#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2

public Plugin myinfo = 
{
	name = "MoreCoopBots", 
	author = "pa4H", 
	description = "", 
	version = "3.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegAdminCmd("sm_spawnbot", spawnBotCmd, ADMFLAG_ROOT);
	
	hMode = FindConVar("mp_gamemode");
	cMaxPlayers = FindConVar("sv_maxplayers");
	
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
}
stock Action spawnBotCmd(int client, int args)
{
	SpawnFakeSurvivorClient();
	return Plugin_Handled;
}

public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) // https://wiki.alliedmods.net/Generic_Source_Server_Events#player_disconnect
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Получаем номер клиента
	if (!IsValidClient(client)) { return Plugin_Continue; }
	
	CreateTimer(0.5, Timer_KickAllBots);
	return Plugin_Continue;
}

public OnClientPutInServer(int client)
{
	if (IsFakeClient(client)) { return; }
	char mode[32];
	GetConVarString(hMode, mode, sizeof(mode));
	if (StrEqual("coop", mode)) {
		CreateTimer(5.0, AddBotTimer); // Если coop, то создаём больше ботов
	}
}

public Action AddBotTimer(Handle timer)
{
	int SurvivorsCount = GetTeamPlayers(2, true); // Получаем количество ботов + игроков
	int ClientsCount = GetTeamPlayers(2, false); // Количество игроков
	
	if (ClientsCount > SurvivorsCount) { SpawnFakeSurvivorClient(); } // Если реальных игроков больше, чем выживших, то добавляем еще одного ботика
	return Plugin_Stop;
}

bool SpawnFakeSurvivorClient()
{
	int ClientsCount = GetTeamPlayers(2, true);
	bool fakeclientKicked = false;
	int fakeclient = 0;
	
	if (ClientsCount < GetConVarInt(cMaxPlayers))
	{
		fakeclient = CreateFakeClient("SurvivorBot");
	}
	
	if (fakeclient != 0)
	{
		// move into survivor team
		ChangeClientTeam(fakeclient, 2);
		
		// check if entity classname is survivorbot
		if (DispatchKeyValue(fakeclient, "classname", "survivorbot") == true)
		{
			// spawn the client
			if (DispatchSpawn(fakeclient) == true)
			{
				// kick the fake client to make the bot take over
				CreateTimer(0.1, Timer_KickFakeBot, fakeclient, TIMER_REPEAT);
				fakeclientKicked = true;
			}
		}
		// if something went wrong, kick the created FakeClient
		if (fakeclientKicked == false) { KickClient(fakeclient, "Kicking FakeClient"); }
	}
	return fakeclientKicked;
}

int GetTeamPlayers(int team, bool includeBots)
{
	int players = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if (IsFakeClient(i) && !includeBots && !GetIdlePlayer(i)) { continue; }
			players++;
		}
	}
	return players;
}
int GetIdlePlayer(int bot)
{
	if (IsClientInGame(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot) && IsFakeClient(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));
		
		if (strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
			if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
				return client;
			}
		}
	}
	return 0;
}


public Action Timer_KickFakeBot(Handle timer, any Bot)
{
	if (IsClientConnected(Bot))
	{
		KickClient(Bot, "Kicking FakeClient");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_KickAllBots(Handle timer, any client)
{
	int SurvivorsCount = GetTeamPlayers(2, true); // Получаем количество ботов + игроков
	int ClientsCount = GetTeamPlayers(2, false); // Количество игроков
	
	if (SurvivorsCount > 4) {  // Если персонажей больше 4
		int max = SurvivorsCount - ClientsCount; // Количество пустых ботов
		int kicked = 0; // Сколько ботов выгнали
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidBot(i)) {
				if (kicked == max) { return Plugin_Stop; } // Кикнули всех ботов? Выходим из функции
				kicked++; KickClient(i, "");
			}
		}
	}
	return Plugin_Stop;
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

stock bool IsValidBot(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && IsFakeClient(client)) {
		return true;
	}
	return false;
} 
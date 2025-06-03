#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>
#include <SakuraVoteSystem>

int TKPoints[MAXPLAYERS + 1];
bool alreadyKick[MAXPLAYERS + 1]; // true - игрока уже кикали. Его надо банить!

Handle cv_pointsToVote;
Handle cv_pointsToAutoBan;
Handle cv_BanDuration;

public Plugin myinfo = 
{
	name = "KickTeamKillers", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_tk", showTKPoints);
	
	cv_pointsToVote = CreateConVar("TK_PointsToStartVote", "70", "", FCVAR_CHEAT);
	cv_pointsToAutoBan = CreateConVar("TK_PointsToAutoBan", "140", "", FCVAR_CHEAT);
	cv_BanDuration = CreateConVar("TK_BanDuration", "180", "", FCVAR_CHEAT);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	
	LoadTranslations("pa4H-TeamKill.phrases");
}
stock Action showTKPoints(int client, int args)
{
	CPrintToChat(client, "{green}[TK] {olive}%i {lightgreen}TeamKill Points ({olive}%i {lightgreen}= ban)", TKPoints[client], GetConVarInt(cv_pointsToAutoBan));
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) // Игрок загрузился
{
	if (!IsValidClient(client)) { return; }
	TKPoints[client] = 0;
	alreadyKick[client] = false;
}

public Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (attacker == 0 || victim == 0 || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2 || GetClientTeam(victim) == 3) { return; }
	TKPoints[attacker] += GetEventInt(event, "dmg_health");
	showTKPointsToClient(attacker, TKPoints[attacker]);
	if (!alreadyKick[attacker] && TKPoints[attacker] >= GetConVarInt(cv_pointsToVote))
	{
		if (vote_isVoting()) { PrintToChatAll("voting"); return; } // Native from SakuraVoteSystem.inc
		startKickVote(attacker);
		alreadyKick[attacker] = true;
		return;
	}
	if (alreadyKick[attacker] && TKPoints[attacker] >= GetConVarInt(cv_pointsToAutoBan))
	{
		ServerCommand("sm_ban %i \"TeamKill\" \"\" \"%i\"", attacker, GetConVarInt(cv_BanDuration));
	}
}

float showDelay;
void showTKPointsToClient(int client, int points)
{
	if (points <= 0) { return; }
	float tNow = GetEngineTime();
	if (tNow - showDelay < 0.5) { return; }
	showDelay = tNow;
	PrintHintText(client, "%t", "YouAttack", points);
	PrintCenterText(client, "%t", "YouAttack", points);
}

void startKickVote(int client)
{
	FakeClientCommand(client, "callvote KickTeamKiller %i", client);
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
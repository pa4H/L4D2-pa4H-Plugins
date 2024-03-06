#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

Handle g_hVsBossBuffer; // Для корректного подсчета процента спауна Танка

public Plugin myinfo = 
{
	name = "VoteBoss", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	RegAdminCmd("sm_voteTankVotePass", voteBossPassed, ADMFLAG_BAN);
	
	g_hVsBossBuffer = FindConVar("versus_boss_buffer"); // Для корректного подсчета процента спауна Танка
	LoadTranslations("pa4HNewVoteSystem.phrases");
}

stock Action debb(int client, int args) // DEBUG
{
	PrintToChatAll("%f", GetCurFlow());
	return Plugin_Handled;
}
stock Action voteBossPassed(int client, int args) // DEBUG
{
	int round = GameRules_GetProp("m_bInSecondHalfOfRound");
	float curDist = GetCurFlow();
	float tankFlow = curDist / 100 + 0.2; // Прибавляем 10%
	if (curDist + 10.0 > 90.0) { CPrintToChatAll("%t", "VoteBossEndMap"); return Plugin_Handled; }
	L4D2Direct_SetVSTankToSpawnThisRound(round, true);
	L4D2Direct_SetVSTankFlowPercent(round, tankFlow);
	char buf[16];
	FormatEx(buf, sizeof(buf), "%.0f%%", GetTankFlow(round) * 100);
	CPrintToChatAll("%t", "VoteBossPercent", buf);
	return Plugin_Handled;
}

stock float GetTankFlow(round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

float GetCurFlow()
{
	return map(L4D2_GetFurthestSurvivorFlow(), 0.0, L4D2Direct_GetMapMaxFlowDistance(), 0.0, 100.0);
}
stock float map(float x, float in_min, float in_max, float out_min, float out_max) // Пропорция
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
} 
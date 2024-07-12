#include <sourcemod>
#include <colors>
#include <left4dhooks>

Handle g_hVsBossBuffer;

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
	RegAdminCmd("sm_vbPass", voteBossPassed, ADMFLAG_BAN);
	LoadTranslations("pa4H-NewVoteSystem.phrases");
	g_hVsBossBuffer = FindConVar("versus_boss_buffer"); // Для корректного подсчета процента спауна Танка
}

stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
stock Action voteBossPassed(int client, int args)
{
	if (args == 0) { return Plugin_Handled; }
	char argOne[8];
	GetCmdArg(1, argOne, sizeof(argOne));
	
	char buf[2][4]; int tankP, witchP;
	
	if (ExplodeString(argOne, "!", buf, 2, 4) > 1) // Если есть 2 аргумент, то есть процент Вички
	{
		tankP = StringToInt(buf[0]);
		witchP = StringToInt(buf[1]);
		
		L4D2Direct_SetVSWitchToSpawnThisRound(0, true);
		L4D2Direct_SetVSWitchFlowPercent(0, CalcFlow(witchP));
		L4D2Direct_SetVSWitchToSpawnThisRound(1, true);
		L4D2Direct_SetVSWitchFlowPercent(1, CalcFlow(witchP));
	}
	else { tankP = StringToInt(argOne); } // Если !voteboss 10 (без вички)
	
	L4D2Direct_SetVSTankToSpawnThisRound(0, true);
	L4D2Direct_SetVSTankFlowPercent(0, CalcFlow(tankP));
	L4D2Direct_SetVSTankToSpawnThisRound(1, true);
	L4D2Direct_SetVSTankFlowPercent(1, CalcFlow(tankP));
		
	CPrintToChatAll("%t", "VoteBossPercent");
	return Plugin_Handled;
}

float CalcFlow(int per)
{
	return ((float(per) + 0.01) / 100.0) + GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}
stock float GetTankFlow(int round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}
stock float GetWitchFlow(int round)
{
	return L4D2Direct_GetVSWitchFlowPercent(round) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

#define L4Dhooks_Gamedata "left4dhooks.l4d2"
#define SECTION_NAME "CTerrorGameRules::SetCampaignScores"
Handle hSetCampaignScores;
bool rndEnd = false; // RoundEnd вызывается два раза. Это фикс

int witchBonus = 0; // 50
int medkitBonus = 100;
int incapBonus = 100;
bool incaped[8]; // 8 выживших. 0Namvet, 1Biker, 2Manager, 3Teen, | 4Gambler, 5Mechanic, 6Coach, 7Producer
int nodeadBonus = 100;

public Plugin myinfo = 
{
	name = "BonusSystem", 
	author = "pa4H, vintik", 
	description = "", 
	version = "2.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	RegConsoleCmd("sm_bonus", showBonus, "");
	
	HookEvent("witch_killed", WitchDeath_Event);
	HookEvent("player_incapacitated", PlayerIncapacitated_Event);
	HookEvent("heal_success", HealSuccess_Event);
	HookEvent("player_death", Event_PlayerDeath);
	
	HookEvent("round_start", RoundStart_Event, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd_Event, EventHookMode_PostNoCopy);
	
	LoadTranslations("pa4H-BonusSystem.phrases");
	
	Handle conf = LoadGameConfigFile(L4Dhooks_Gamedata);
	if (conf == INVALID_HANDLE) {
		SetFailState("Could not load gamedata/%s.txt", L4Dhooks_Gamedata);
	}
	
	StartPrepSDKCall(SDKCall_GameRules);
	if (!PrepSDKCall_SetFromConf(conf, SDKConf_Signature, SECTION_NAME)) {
		SetFailState("Function '"...SECTION_NAME..."' not found.");
	}
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSetCampaignScores = EndPrepSDKCall();
	if (hSetCampaignScores == INVALID_HANDLE) {
		SetFailState("Function '"...SECTION_NAME..."' found, but something went wrong.");
	}
	delete conf;
}
stock Action debb(int client, int args)
{
	return Plugin_Handled;
}

Action showBonus(int client, int args)
{
	CPrintToChat(client, "%t", "ShowBonus", calcBonus(), witchBonus, medkitBonus, incapBonus, nodeadBonus);
	return Plugin_Handled;
}

public WitchDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	witchBonus = 50;
}
public PlayerIncapacitated_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClientB(client) && GetClientTeam(client) == 2 && incapBonus != 0) {
		if (WhoIs(client, "Namvet") && !incaped[0]) {  // 0Namvet, 1Biker, 2Manager, 3Teen
			incapBonus -= 25;
			incaped[0] = true;
			return;
		}
		if (WhoIs(client, "Biker") && !incaped[1]) {
			incapBonus -= 25;
			incaped[1] = true;
			return;
		}
		if (WhoIs(client, "Manager") && !incaped[2]) {
			incapBonus -= 25;
			incaped[2] = true;
			return;
		}
		if (WhoIs(client, "Teen") && !incaped[3]) {
			incapBonus -= 25;
			incaped[3] = true;
			return;
		}
		if (WhoIs(client, "Gambler") && !incaped[4]) {  // 4Gambler, 5Mechanic, 6Coach, 7Producer
			incapBonus -= 25;
			incaped[4] = true;
			return;
		}
		if (WhoIs(client, "Mechanic") && !incaped[5]) {
			incapBonus -= 25;
			incaped[5] = true;
			return;
		}
		if (WhoIs(client, "Coach") && !incaped[6]) {
			incapBonus -= 25;
			incaped[6] = true;
			return;
		}
		if (WhoIs(client, "Producer") && !incaped[7]) {
			incapBonus -= 25;
			incaped[7] = true;
			return;
		}
	}
	
}

public HealSuccess_Event(Handle event, const char[] name, bool dontBroadcast)
{
	//int subject = GetClientOfUserId(GetEventInt(event, "subject"));
	//int healer = GetClientOfUserId(GetEventInt(event, "userid"));
	if (medkitBonus != 0) {
		medkitBonus -= 25;
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	//int killer = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!rndEnd && IsValidClientB(victim) && GetClientTeam(victim) == 2 && nodeadBonus != 0) {
		nodeadBonus -= 25;
	}
}

public void RoundEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (rndEnd) { return; }
	rndEnd = true;
	
	if (GetCurFlow() < 99) {
		medkitBonus = 0;
	}
	
	int bonus = calcBonus();
	
	CPrintToChatAll("%t", "RoundFinal", bonus);
	CPrintToChatAll("%t", "Bonuses", witchBonus, medkitBonus, incapBonus, nodeadBonus);
	
	bool bFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped");
	int SurvivorTeamIndex = bFlipped ? 1 : 0;
	int InfectedTeamIndex = bFlipped ? 0 : 1;
	int surScore; int infScore;
	surScore = L4D2Direct_GetVSCampaignScore(SurvivorTeamIndex);
	infScore = L4D2Direct_GetVSCampaignScore(InfectedTeamIndex);
	
	PrintToConsoleAll("SurScore: %i | InfScore: %i | Bonus: %i", surScore, infScore, bonus);
	
	surScore += bonus;
	
	PrintToConsoleAll("> FinalScore: %i", surScore);
	
	SetScores(surScore, infScore);
	resetBonus();
}
public void RoundStart_Event(Event event, const char[] name, bool dontBroadcast)
{
	rndEnd = false;
}

public OnMapEnd()
{
	resetBonus();
}


int calcBonus()
{
	return witchBonus + medkitBonus + incapBonus + nodeadBonus;
}

void resetBonus()
{
	witchBonus = 0;
	medkitBonus = 100;
	incapBonus = 100;
	nodeadBonus = 100;
	
	for (int i = 0; i < 8; i++) { incaped[i] = false; }
}

void SetScores(const int survScore, const int infectScore)
{
	bool bFlipped = !!GameRules_GetProp("m_bAreTeamsFlipped");
	int SurvivorTeamIndex = bFlipped ? 1 : 0;
	int InfectedTeamIndex = bFlipped ? 0 : 1;
	
	SDKCall(hSetCampaignScores, 
		(bFlipped) ? infectScore : survScore, 
		(bFlipped) ? survScore : infectScore); // Visible scores
	
	L4D2Direct_SetVSCampaignScore(SurvivorTeamIndex, survScore); // Real scores
	L4D2Direct_SetVSCampaignScore(InfectedTeamIndex, infectScore);
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

stock bool IsValidClientB(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
}

bool WhoIs(int client, char[] playerName)
{
	char model[64];
	GetClientModel(client, model, sizeof(model));
	
	if (Contains(model, playerName)) {
		return true;
	}
	return false;
}

int GetCurFlow()
{
	int maxFlow = L4D_GetVersusMaxCompletionScore() / 4; // 800
	int maxSurFlow = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClientB(i) && GetClientTeam(i) == 2) {
			int buf = L4D2_GetVersusCompletionPlayer(i);
			if (maxSurFlow < buf) { maxSurFlow = buf; }
		}
	}
	return (maxSurFlow - 0) * (100 - 0) / (maxFlow - 0) + 0;
} 
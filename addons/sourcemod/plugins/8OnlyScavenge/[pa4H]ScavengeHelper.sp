#include <sourcemod>
#include <sdktools>
#include <colors>

char txtBufer[256];
char txtTime[32];
char slovoA[64];
char slovoB[64];

int scoreA;
int scoreB;
int canFill;

public Plugin myinfo = 
{
	name = "Scavenge Chat Helper", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb, "");
	RegConsoleCmd("sm_time", showTime, "");
	
	HookEvent("scavenge_round_halftime", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", RoundEnd, EventHookMode_PostNoCopy);
	
	HookEvent("gascan_pour_completed", Event_PourCompleted);
	
	LoadTranslations("pa4H-ScavengeHelper");
}

stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

void GetRemainedTime(int team)
{
	float rSeconds = (90.0 - GameRules_GetRoundDuration(team)) + (canFill * 20);
	int min = RoundToFloor(rSeconds) / 60;
	rSeconds -= 60 * min;
	if (rSeconds < 10) {
		FormatEx(txtTime, sizeof(txtTime), "%i:0%.0f", min, rSeconds);
	}
	else {
		FormatEx(txtTime, sizeof(txtTime), "%i:%.0f", min, rSeconds);
	}
}

public RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	canFill = 0;
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			scoreA = GetScavengeTeamScore(2); scoreB = GetScavengeTeamScore(3);
			learnSlovoA(); learnSlovoB();			
			int clientTeam = GetClientTeam(client);
			
			if (GameRules_GetProp("m_bInSecondHalfOfRound") == 1) // Если конец раунда
			{
				if (scoreA > scoreB)
				{
					if (clientTeam == 1)
					{
						GetRemainedTime(2);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "CanWinnerSur", scoreA, txtTime);
					}
					else if (clientTeam == 2) // Показываем команде A (победителям)
					{
						GetRemainedTime(2);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerYou", scoreA, slovoA, txtTime);
						
						GetRemainedTime(3);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserEnemy", scoreB, slovoB, txtTime);					
					}
					else if (clientTeam == 3) // Показываем команде B (проигравшим)
					{
						GetRemainedTime(3);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserYou", scoreB, slovoB, txtTime);
						
						GetRemainedTime(2);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerEnemy", scoreA, slovoA, txtTime);
					}
				}
				else if (scoreA < scoreB)
				{
					if (clientTeam == 1)
					{
						GetRemainedTime(3);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "CanWinnerInf", scoreB, txtTime);
					}
					else if (clientTeam == 3)
					{
						GetRemainedTime(3);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerYou", scoreB, slovoB, txtTime);
						
						GetRemainedTime(2);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserEnemy", scoreA, slovoA, txtTime);
					}
					else if (clientTeam == 2)
					{
						GetRemainedTime(2);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserYou", scoreA, slovoA, txtTime);
						
						GetRemainedTime(3);
						FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerEnemy", scoreB, slovoB, txtTime);						
					}
				}
				else if (scoreA == scoreB) // Считаем у кого больше времени
				{
					if (scoreA == 0 && scoreB == 0) // Если по нулям, то побеждает тот, кто дольше выжил
					{
						if (GameRules_GetRoundDuration(2) > GameRules_GetRoundDuration(3)) // Если дольше выживала
						{  // Считаем у кого больше времени
							if (clientTeam == 1)
							{
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "SurvWinnerSur", txtTime);
							}
							else if (clientTeam == 2) //Показываем команде 2 (победителям)
							{
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeSurvYou", txtTime);
								
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeSurvEnemy", txtTime);					
							}
							else if (clientTeam == 3) //Показываем команде 3 (проигравшим)
							{
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeSurvYou", txtTime);						
								
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeSurvEnemy", txtTime);							
							}
						}
						else //Считаем у кого меньше времени
						{
							if (clientTeam == 1)
							{
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "SurvWinnerInf", txtTime);
							}
							else if (clientTeam == 3)
							{
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeSurvYou", txtTime);								
								
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeSurvEnemy", txtTime);				
							}
							else if (clientTeam == 2)
							{
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeSurvYou", txtTime);					
								
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeSurvEnemy", txtTime);								
							}
						}
					}
					else if (scoreA > 0 && scoreB > 0) // Если 21 21  
					{
						if (GameRules_GetRoundDuration(2) < GameRules_GetRoundDuration(3)) // Если быстрее собрали одинаковое количество кан
						{  // Считаем у кого меньше времени
							if (clientTeam == 1)
							{
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "TimeWinnerSur", scoreA, slovoA, txtTime);
							}
							else if (clientTeam == 2) //Показываем команде 2 (победителям)
							{
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeYou", scoreA, slovoA, txtTime);
								
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeEnemy", scoreB, slovoB, txtTime);
							}
							else // Показываем команде 3 (проигравшим)
							{
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeYou", scoreB, slovoB, txtTime);								
								
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeEnemy", scoreA, slovoA, txtTime);								
							}
						}
						else
						{
							if (clientTeam == 1)
							{
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "TimeWinnerInf", scoreB, slovoB, txtTime);
							}
							else if (clientTeam == 3)
							{
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeYou", scoreB, slovoB, txtTime);							
								
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeEnemy", scoreA, slovoA, txtTime);				
							}
							else
							{
								GetRemainedTime(2);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "LooserTimeYou", scoreA, slovoA, txtTime);							
								
								GetRemainedTime(3);
								FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "WinnerTimeEnemy", scoreB, slovoB, txtTime);
							}
						}
					}
				}
			}
			else // Если половинка раунда
			{
				if (clientTeam == 1) // Спеки
				{
					GetRemainedTime(2);
					FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "Half1", scoreA, slovoA, txtTime);	
				}else				if (clientTeam == 2)
				{
					GetRemainedTime(2);
					FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "Half2", scoreA, slovoA, txtTime);	
				}else				if (clientTeam == 3)
				{
					GetRemainedTime(2);
					FormatEx(txtBufer, sizeof(txtBufer), "%t\n", "Half3", scoreA, slovoA, txtTime);			
				}
			}
			CPrintToChat(client, txtBufer);
		}
	}
}

public Action showTime(client, args)
{
	scoreA = GetScavengeTeamScore(2);
	
	if (GameRules_GetProp("m_bInSecondHalfOfRound") == 1) // Если половинка раунда
	{
		int clientTeam = GetClientTeam(client);
		GetRemainedTime(2);
		
		learnSlovoA();
		if (clientTeam == 1) // Спеки
		{
			GetRemainedTime(2);
			CPrintToChat(client, "%t\n", "Half1", scoreA, slovoA, txtTime);
		} else		if (clientTeam == 2)
		{
			GetRemainedTime(2);
			CPrintToChat(client, "%t\n", "Half2", scoreA, slovoA, txtTime);
		} else		if (clientTeam == 3)
		{
			GetRemainedTime(2);
			CPrintToChat(client, "%t\n", "Half3", scoreA, slovoA, txtTime);
		}
	}
	else // Если половинка раунда не прошла
	{
		CPrintToChat(client, "%t\n", "smTimeNo");
	}
	return Plugin_Handled;
}

void learnSlovoA()
{
	if ((scoreA == 0) || (scoreA >= 5 && scoreA <= 20)) // Ноль канистр. Двадцать канистр
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "Kanistr");
	}
	else if (scoreA == 1) // Одну канистру
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "Kanistru");
	}
	else if (scoreA >= 2 && scoreA <= 4) // Четыре канистры
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "Kanistry");
	}
	else if (scoreA == 21) // Двадцать одну канистру
	{
		FormatEx(slovoA, sizeof(slovoA), "%t", "21Kanistru");
	}
}
void learnSlovoB()
{
	if ((scoreB == 0) || (scoreB >= 5 && scoreB <= 20)) // Ноль канистр. Двадцать канистр
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "Kanistr");
	}
	else if (scoreB == 1) // Одну канистру
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "Kanistru");
	}
	else if (scoreB >= 2 && scoreB <= 4) // Четыре канистры
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "Kanistry");
	}
	else if (scoreB == 21) // Двадцать одну канистру
	{
		FormatEx(slovoB, sizeof(slovoB), "%t", "21Kanistru");
	}
}

float GameRules_GetRoundDuration(team)
{
	float flRoundStartTime = GameRules_GetPropFloat("m_flRoundStartTime");
	if (team == 2 && flRoundStartTime != 0.0 && GameRules_GetPropFloat("m_flRoundEndTime") == 0.0)
	{
		return GetGameTime() - flRoundStartTime;
	}
	team = L4D2_clientTeamToTeamIndex(team);
	if (team == -1) { return -1.0; }
	
	return GameRules_GetPropFloat("m_flRoundDuration", team);
}

int GetScavengeTeamScore(team, round = -1)
{
	team = L4D2_clientTeamToTeamIndex(team);
	if (team == -1) { return -1; }
	
	if (round <= 0 || round > 5)
	{
		round = GameRules_GetProp("m_nRoundNumber");
	}
	--round;
	return GameRules_GetProp("m_iScavengeTeamScore", _, (2 * round) + team);
}

int L4D2_clientTeamToTeamIndex(team)
{
	if (team != 2 && team != 3) { return -1; }
	int flipped = GameRules_GetProp("m_bAreTeamsFlipped", 1);
	if (flipped == 1) { ++team; }
	return team % 2;
}
public void Event_PourCompleted(Event event, const char[] name, bool dontBroadcast)
{
	canFill++;
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

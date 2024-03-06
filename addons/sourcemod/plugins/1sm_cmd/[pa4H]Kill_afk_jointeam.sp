#include <sourcemod>
#include <sdktools>
#include <colors>

char PREFIX[16]; //char txtBufer[256];

public Plugin:myinfo = 
{
	name = "!kill & !afk & !jointeam", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_kill", Kill_Me);
	
	RegConsoleCmd("sm_afk", TurnClientToSpectate);
	RegConsoleCmd("sm_idle", TurnClientToSpectate);
	RegConsoleCmd("sm_spec", TurnClientToSpectate);
	RegConsoleCmd("sm_spectate", TurnClientToSpectate);
	RegConsoleCmd("sm_spectator", TurnClientToSpectate);
	
	RegConsoleCmd("sm_jointeam1", TurnClientToSpectate);
	RegConsoleCmd("sm_jointeam2", TurnClientToSurvivors);
	RegConsoleCmd("sm_jointeam3", TurnClientToInfected);
	
	RegConsoleCmd("sm_survivors", TurnClientToSurvivors);
	RegConsoleCmd("sm_survivor", TurnClientToSurvivors);
	RegConsoleCmd("sm_sur", TurnClientToSurvivors);
	RegConsoleCmd("sm_infected", TurnClientToInfected);
	RegConsoleCmd("sm_inf", TurnClientToInfected);
	
	RegConsoleCmd("sm_js", TurnClientToSurvivors);
	RegConsoleCmd("sm_ji", TurnClientToInfected);
	
	LoadTranslations("pa4HKill_afk_jointeam.phrases");
	FormatEx(PREFIX, sizeof(PREFIX), "%t", "PREFIX"); // Сразу помещаем префикс в переменную
}

public Action Kill_Me(client, args)
{
	if (GetClientTeam(client) == 2 && !IsPlayerIncapped(client)) // Если команда выжившие и игрок не инкапнутый
	{
		return Plugin_Handled; // Ничего не делаем
	}
	ForcePlayerSuicide(client); // В остальных случаях убиваем
	return Plugin_Handled;
}
bool IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) { return true; }
	return false;
}

public Action TurnClientToSpectate(client, args)
{
	//FakeClientCommand(client, "jointeam 1");
	ChangeClientTeam(client, 1);
	CPrintToChat(client, "%t", "AFK", PREFIX);
	return Plugin_Handled;
}

public Action TurnClientToSurvivors(client, args)
{
	FakeClientCommand(client, "jointeam 2");
	//ChangeClientTeam(client, 2)
	return Plugin_Handled;
}
public Action TurnClientToInfected(client, args)
{
	FakeClientCommand(client, "jointeam 3");
	//ChangeClientTeam(client, 3)
	return Plugin_Handled;
} 
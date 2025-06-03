#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

int currentLosses = 0; // Текущие количество проигрышей
Handle cv_maxLosses; // Максимальное количество проигрышей, после запускается следующая карта
char lastMap[64]; // Последняя карта, которую играли

ConVar C_path;
char O_path[PLATFORM_MAX_PATH];
StringMap End_and_next;
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

char Data_path[PLATFORM_MAX_PATH];

public Plugin myinfo = 
{
	name = "SwitchMapAfterLosse", 
	author = "pa4H, Dragokas", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb);
	
	HookEvent("mission_lost", Event_MissionLost); // Выжившие проиграли (необязательно на последней карте)
	
	cv_maxLosses = CreateConVar("maximumLosses", "5", "After start changelevel to next map", FCVAR_CHEAT);
	
	End_and_next = new StringMap();
	C_path = CreateConVar("map_change_path", "data/map_change.cfg", "load this file");
	get_all_cvars();
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public void OnMapStart()  
{
    char curMap[64];
	GetCurrentMap(curMap, sizeof(curMap));
	lastMap = curMap;
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsFinalMap()) { return; } // Определяем последняя ли карта
	
	char curMap[64];
	GetCurrentMap(curMap, sizeof(curMap));
	if (!Contains(lastMap, curMap)) // Если карта поменялась, то...
	{
		currentLosses = 0; // ...сбрасываем счетчик
		return; // ...и ничего не делаем
	}
	currentLosses++; // Увеличиваем счетчик на 1
	
	if (currentLosses == GetConVarInt(cv_maxLosses)) {  // Если счетчик == максимуму
		char next[64];
		if (End_and_next.GetString(curMap, next, sizeof(next)) && is_valid_map(next))
		{
			currentLosses = 0;
			L4D_RestartScenarioFromVote(next); // Запускаем следующую карту
			return;
		}
	}
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
}

stock bool IsFinalMap()
{
	return (FindEntityByClassname(-1, "info_changelevel") == -1 && FindEntityByClassname(-1, "trigger_changelevel") == -1);
}

bool is_valid_map(const char[] map)
{
	char path[PLATFORM_MAX_PATH];
	return FindMap(map, path, sizeof(path)) == FindMap_Found;
}

void get_all_cvars() // Читаем файл с картами
{
	C_path.GetString(O_path, sizeof(O_path));
	if (O_path[0] != '\0')
	{
		BuildPath(Path_SM, Data_path, sizeof(Data_path), "%s", O_path);
	}
	check_config();
}

void check_config()
{
	End_and_next.Clear();
	if (O_path[0] == '\0')
	{
		return;
	}
	if (FileExists(Data_path))
	{
		Current_section_level = 0;
		Current_section_name[0] = '\0';
		SMCParser parser = new SMCParser();
		parser.OnEnterSection = OnEnterSection;
		parser.OnLeaveSection = OnLeaveSection;
		parser.OnKeyValue = OnKeyValue;
		parser.ParseFile(Data_path);
		delete parser;
	}
}

SMCResult OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (Current_section_level == 2)
	{
		if (strcmp(key, "next") == 0)
		{
			End_and_next.SetString(Current_section_name, value);
		}
	}
	return SMCParse_Continue;
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	Current_section_level++;
	if (Current_section_level == 2)
	{
		strcopy(Current_section_name, sizeof(Current_section_name), name);
	}
	return SMCParse_Continue;
}

SMCResult OnLeaveSection(SMCParser smc)
{
	Current_section_level--;
	return SMCParse_Continue;
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
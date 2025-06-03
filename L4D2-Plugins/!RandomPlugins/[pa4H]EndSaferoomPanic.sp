#include <sourcemod>
#include <colors>
#include <left4dhooks>
#include <sdktools>
#include <sdkhooks>

#define LOCK 1
#define UNLOCK 0

int saferoomEnt = -1; // EntityID последнего saferoom
bool lastEventStarted = false; // true - запущен таймер после того, как дотронулись до финального saferoom
float secToOpen = 0.0;

Handle cv_timerToOpenSaferoom; // Таймер в секундах до открытия saferoom

public Plugin myinfo = 
{
	name = "EndSaferoomPanic", 
	author = "pa4H, finishlast", 
	description = "Запускает бесконечную волну при попытке войти в saferoom + таймер", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_test", debb);
	//RegAdminCmd("sm_test", debb, ADMFLAG_BAN);
	
	HookEvent("player_use", PlayerUse_Event, EventHookMode_Pre);
	HookEvent("player_left_start_area", EventPlayerLeftStartArea);
	
	cv_timerToOpenSaferoom = CreateConVar("TimerToOpenSaferoom", "300.0"); // 300s = 5min
	
	//LoadTranslations("KeyForSaferoom.phrases");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

void setPanicEvent(bool infinite)
{
	if (infinite) {
		SetConVarInt(FindConVar("director_panic_forever"), 1);
		CheatCommand(_, "director_force_panic_event", "");
	}
	else {
		SetConVarInt(FindConVar("director_panic_forever"), 0);
	}
}

public EventPlayerLeftStartArea(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.5, roundStartTimer);
}
public Action roundStartTimer(Handle timer)
{
	PrintToChatAll("RoundStart");
	lastEventStarted = false;
	ControlDoor(LOCK); // Блокируем дверь
	return Plugin_Stop;
}

public Action PlayerUse_Event(Event event, const char[] name, bool dontBroadcast)
{
	int used = event.GetInt("targetid");
	//int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidEnt(used))
	{
		char sEntityClass[64];
		GetEdictClassname(used, sEntityClass, sizeof(sEntityClass));
		if (StrEqual(sEntityClass, "prop_door_rotating_checkpoint"))
		{
			if (!lastEventStarted) {
				lastEventStarted = true;
				secToOpen = GetConVarFloat(cv_timerToOpenSaferoom); // Цифры для вывода на экран игрокам
				setPanicEvent(true); // Запускаем бесконечную волну!
				CreateTimer(GetConVarFloat(cv_timerToOpenSaferoom), Timer_lastEvent); // Запускаем таймер на откртие двери
				CreateTimer(1.0, Timer_updateScreen, _, TIMER_REPEAT); // Запускаем таймер, который выводит кол-во оставшихся минут
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_lastEvent(Handle timer)
{
	CPrintToChatAll("Дверь открыта! Заходите");
	ControlDoor(UNLOCK); // Блокируем дверь
	return Plugin_Stop;
}

public Action Timer_updateScreen(Handle timer)
{
	if (secToOpen <= 0.0) { PrintHintTextToAll("Дверь открыта, заходите"); return Plugin_Stop; }
	PrintHintTextToAll("Осталось: %f секунд", secToOpen);
	secToOpen = secToOpen - 1.0;
	return Plugin_Continue;
}

void ControlDoor(int mode)
{
	findDoor();
	if (!IsValidEntity(saferoomEnt)) { return; }
	
	if (mode == LOCK)
	{
		AcceptEntityInput(saferoomEnt, "Close");
		AcceptEntityInput(saferoomEnt, "Lock");
		AcceptEntityInput(saferoomEnt, "ForceClosed");
		SetEntProp(saferoomEnt, Prop_Data, "m_hasUnlockSequence", LOCK);
	}
	else if (mode == UNLOCK)
	{
		SetEntProp(saferoomEnt, Prop_Data, "m_hasUnlockSequence", UNLOCK);
		AcceptEntityInput(saferoomEnt, "Unlock");
		AcceptEntityInput(saferoomEnt, "ForceClosed");
		//AcceptEntityInput(saferoomEnt, "Open");
	}
}

void findDoor()
{
	char targetname[20];
	int founddoor = 0;
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));
		
		if (StrEqual(targetname, "checkpoint_entrance"))
		{
			saferoomEnt = EntIndexToEntRef(entity);
			founddoor = 1;
			break;
		}
	}
	
	char sModel[64];
	if (founddoor == 0)
	{
		while ((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) > -1)
		{
			if (IsValidEntity(entity))
			{
				GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
				
				if (StrContains(sModel, "checkpoint_door") > -1 && StrContains(sModel, "02") > -1)
				{
					saferoomEnt = EntIndexToEntRef(entity);
					break;
				}
			}
		}
	}
}

stock void CheatCommand(int client = 0, char[] command, char[] arguments = "")
{
	if (!client || !IsClientInGame(client))
	{
		for (int target = 1; target <= MaxClients; target++)
		{
			if (IsClientInGame(target))
			{
				client = target;
				break;
			}
		}
		
		if (!client || !IsClientInGame(client)) { return; }
	}
	
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
}
stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
stock bool IsValidClientB(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
}
stock bool isAdmin(int client)
{
	if (GetUserFlagBits(client) == ADMFLAG_ROOT) {  // https://wiki.alliedmods.net/Checking_Admin_Flags_(SourceMod_Scripting)
		return true;
	}
	return false;
}

stock int getTeamCount(int team)
{
	int pCount = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && GetClientTeam(i) == team) {
			pCount++;
		}
	}
	return pCount;
}

stock char[] getGamemode()
{
	char mode[16];
	Handle hMode = FindConVar("mp_gamemode");
	GetConVarString(hMode, mode, sizeof(mode));
	delete hMode;
	return mode;
} 

bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}
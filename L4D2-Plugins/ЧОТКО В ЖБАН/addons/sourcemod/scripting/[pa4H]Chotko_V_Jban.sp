#include <sourcemod>
#include <sdktools>

Handle cleanTimer[MAXPLAYERS + 1]

float _dTimerLength = 1.0;

public Plugin myinfo = 
{
	name = "[pa4H]Chotko_V_Jban", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	RegServerCmd("sm_jban", ShowKillMessage);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetBool("headshot"))
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		
		if (victim > 0 && IsClientInGame(victim) && GetClientTeam(victim) == 3)
		{
			//int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass"); // Smoker 1, Boomer 2, Hunter 3, Jockey 5, Charger 6, Witch 7, Tank 8
			//PrintToChatAll("%i", zClass); // debug
			//PrintToChatAll("attacker: %i zClass: %i", event.GetInt("attacker"), zClass); // debug
			
			ServerCommand("sm_jban %i vjban", event.GetInt("attacker")); // Отправляем убийце
			ServerCommand("sm_jban %i vjban", event.GetInt("userid")); // Отправляем убитому зараженному
		}
	}
	return Plugin_Continue;
}

public OnConfigsExecuted() // Карта загружена, конфиги применены, плагины загружены
{
	prepareTexture("vjban"); //materials/pezdox/vjban.vtf & vjban.vmt  и звук sound/pezdox/v_jban.mp3
}

void prepareTexture(char item[32])
{
	char bufer[32];
	
	Format(bufer, sizeof(bufer), "pezdox/%s.vtf", item);
	PrecacheDecal(bufer, true);
	
	Format(bufer, sizeof(bufer), "materials/pezdox/%s.vtf", item);
	AddFileToDownloadsTable(bufer);
	
	Format(bufer, sizeof(bufer), "pezdox/%s.vmt", item);
	PrecacheDecal(bufer, true);
	
	Format(bufer, sizeof(bufer), "materials/pezdox/%s.vmt", item);
	AddFileToDownloadsTable(bufer);
	
	AddFileToDownloadsTable("sound/pezdox/v_jban.mp3");
}

public Action ShowKillMessage(args)
{
	if (args < 2)
	{
		return Plugin_Handled;
	}
	
	char userID[16];
	GetCmdArg(1, userID, sizeof(userID));
	int client = GetClientOfUserId(StringToInt(userID));
	
	char picture[32];
	GetCmdArg(2, picture, sizeof(picture));
	
	if (cleanTimer[client] != null)
	{
		KillTimer(cleanTimer[client]);
		cleanTimer[client] = null;
	}
	
	cleanTimer[client] = CreateTimer(_dTimerLength, CleanTimer, client);
	
	ClearScreen(client);
	ClientCommand(client, "r_screenoverlay \"pezdox/%s.vtf\"", picture);
	
	PrecacheSound("pezdox/v_jban.mp3");
	EmitSoundToClient(client, "pezdox/v_jban.mp3");
	
	//PrintToChatAll("userID: %s picture: %s timer: %d", userID, picture, cleanTimer[client]); // debug
	
	return Plugin_Handled;
}

public void ClearScreen(client)
{
	if (IsClientInGame(client)) // Чтоб не было ошибки
	{
		ClientCommand(client, "r_screenoverlay \"\"");
	}
}

public Action CleanTimer(Handle hTimer, any client)
{
	KillTimer(hTimer);
	cleanTimer[client] = null;
	ClearScreen(client);
	return Plugin_Stop;
} 
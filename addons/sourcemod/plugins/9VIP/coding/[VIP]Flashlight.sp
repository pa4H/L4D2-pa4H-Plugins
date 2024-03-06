#define PLUGIN_VERSION 		"2.28"
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Flashlight\x04] \x01"

#define ATTACH_GRENADE		"grenade"
#define MODEL_LIGHT			"models/props_lighting/flashlight_dropped_01.mdl"


// Cvar Handles/Variables
ConVar g_hCvarAllow, g_hCvarAlpha, g_hCvarAlphas, g_hCvarRandom, g_hCvarColor, g_hCvarDefault, g_hCvarFlags, g_hCvarHints, g_hCvarIntro, g_hCvarLock, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarPrecache, g_hCvarSave, g_hCvarSpec, g_hCvarUsers;
bool g_bCvarAllow, g_bMapStarted, g_bCvarLock;
char g_sCvarCols[12];
float g_fCvarIntro;
int g_iCvarAlpha, g_iCvarAlphas, g_iCvarColor, g_iCvarDefault, g_iCvarFlags, g_iCvarHints, g_iCvarRandom, g_iCvarSave, g_iCvarSpec, g_iCvarUsers;

// Plugin Variables
ConVar g_hCvarMPGameMode;
bool g_bRoundOver, g_bValidMap;
bool g_bCookieAuth[MAXPLAYERS+1];
char g_sPlayerModel[MAXPLAYERS+1][42];
int g_iClientColor[MAXPLAYERS+1], g_iClientLight[MAXPLAYERS+1], g_iLightIndex[MAXPLAYERS+1], g_iLights[MAXPLAYERS+1], g_iModelIndex[MAXPLAYERS+1];
Handle g_hCookieColor;
Handle g_hCookieState;
StringMap g_hColors;
StringMapSnapshot g_hSnapColors;
Menu g_hMenu;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Flashlight Package",
	author = "SilverShot",
	description = "VIP Version",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=173257"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	// Attachments API
	if( FindConVar("attachments_api_version") == null && (FindConVar("l4d2_swap_characters_version") != null || FindConVar("l4d_csm_version") != null) )
	{
		LogMessage("\n==========\nWarning: You should install \"[ANY] Attachments API\" to fix model attachments when changing character models: https://forums.alliedmods.net/showthread.php?t=325651\n==========\n");
	}

	// Use Priority Patch
	if( FindConVar("l4d_use_priority_version") == null )
	{
		LogMessage("\n==========\nWarning: You should install \"[L4D & L4D2] Use Priority Patch\" to fix attached models blocking +USE action: https://forums.alliedmods.net/showthread.php?t=327511\n==========\n");
	}
}

public void OnPluginStart()
{
	// Translations
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/flashlight.phrases.txt");
	if( FileExists(sPath) )
		LoadTranslations("flashlight.phrases");
	else
		SetFailState("Missing required 'translations/flashlight.phrases.txt', please download and install.");

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	g_hCvarAllow =			CreateConVar(	"l4d_flashlight_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarAlpha =			CreateConVar(	"l4d_flashlight_bright",		"255.0",		"Brightness of the light for Survivors <10-255> (changes Distance value).", CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hCvarAlphas =			CreateConVar(	"l4d_flashlight_brights",		"255.0",		"Brightness of the light for Special Infected <10-255> (changes Distance value).", CVAR_FLAGS, true, 10.0, true, 255.0 );
	g_hCvarColor =			CreateConVar(	"l4d_flashlight_colour",		"200 20 15",	"The default light color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarDefault =		CreateConVar(	"l4d_flashlight_default",		"1",			"Turn on the light when players join. 0=Off. 1=Survivors. 2=Special Infected. 4=Survivor Bots. Add numbers together.", CVAR_FLAGS );
	g_hCvarFlags =			CreateConVar(	"l4d_flashlight_flags",			"",				"Players with these flags may use the sm_light command. (Empty = all).", CVAR_FLAGS );
	g_hCvarHints =			CreateConVar(	"l4d_flashlight_hints",			"1",			"0=Off, 1=Show intro message to players entering spectator.", CVAR_FLAGS );
	g_hCvarIntro =			CreateConVar(	"l4d_flashlight_intro",			"35.0",			"0=Off, Show intro message in chat this many seconds after joining.", CVAR_FLAGS, true, 0.0, true, 120.0);
	g_hCvarLock =			CreateConVar(	"l4d_flashlight_lock",			"0",			"0=Let players set their flashlight color, 1=Force to cvar specified.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_flashlight_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_flashlight_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_flashlight_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarPrecache =		CreateConVar(	"l4d_flashlight_precach",		"c1m3_mall",	"Empty = Allow all. 0=Block on all maps. Prevent displaying the model on these maps, separate by commas (no spaces).", CVAR_FLAGS );
	g_hCvarRandom =			CreateConVar(	"l4d_flashlight_random",		"2",			"Give random colors on spawn? 0=Use color cvar. 1=Give Survivor bots random colors if enabled by the _default cvar. 2=Give real players random colors (unless save enabled). 3=Both.", CVAR_FLAGS );
	g_hCvarSave =			CreateConVar(	"l4d_flashlight_save",			"1",			"0=Off, 1=Save client preferences for flashlight color and state.", CVAR_FLAGS );
	g_hCvarSpec =			CreateConVar(	"l4d_flashlight_spec",			"7",			"0=Off, 1=Spectators, 2=Survivors, 4=Infected, 7=All. Give personal flashlights when dead which only they can see.", CVAR_FLAGS );
	g_hCvarUsers =			CreateConVar(	"l4d_flashlight_users",			"3",			"1=Survivors, 2=Infected, 3=All. Allow these players when alive to use the flashlight.", CVAR_FLAGS );
	CreateConVar(							"l4d_flashlight_version",		PLUGIN_VERSION,	"Flashlight plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_flashlight");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAlpha.AddChangeHook(ConVarChanged_LightAlpha);
	g_hCvarAlphas.AddChangeHook(ConVarChanged_LightAlpha);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarColor.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDefault.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarFlags.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHints.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarIntro.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarLock.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarPrecache.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSave.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpec.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarUsers.AddChangeHook(ConVarChanged_Cvars);

	// Commands
	RegAdminCmd(	"sm_lightclient",	CmdLightClient,	ADMFLAG_ROOT,	"Create and toggle flashlight attachment on the specified target. Usage: sm_lightclient <#user id|name> [R G B|off|random|red|green|blue|purple|cyan|orange|white|pink|lime|maroon|teal|yellow|grey]");
	RegConsoleCmd(	"vip_lightforvip",			CmdLightCommand,				"Toggle the attached flashlight. Usage: sm_light [R G B|off|random|red|green|blue|purple|cyan|orange|white|pink|lime|maroon|teal|yellow|grey]");
	//RegConsoleCmd(	"sm_lightmenu",		CmdLightMenu,					"Opens the flashlight color menu.");

	CreateColors();

	g_hCookieColor = RegClientCookie("l4d_flashlight", "Flashlight Color", CookieAccess_Protected);
	g_hCookieState = RegClientCookie("l4d_flashlights", "Flashlight State", CookieAccess_Protected);
}

public void OnPluginEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
		DeleteLight(i);
}

public void OnMapStart()
{
	g_bMapStarted = true;
	g_bValidMap = true;

	char sCvar[512];
	g_hCvarPrecache.GetString(sCvar, sizeof(sCvar));

	if( sCvar[0] != '\0' )
	{
		if( strcmp(sCvar, "0") == 0 )
		{
			g_bValidMap = false;
		} else {
			char sMap[64];
			GetCurrentMap(sMap, sizeof(sMap));

			Format(sMap, sizeof(sMap), ",%s,", sMap);
			Format(sCvar, sizeof(sCvar), ",%s,", sCvar);

			if( StrContains(sCvar, sMap, false) != -1 )
				g_bValidMap = false;
		}
	}

	if( g_bValidMap )
		PrecacheModel(MODEL_LIGHT, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}



// ====================================================================================================
//					COOKIES
// ====================================================================================================
public void OnClientDisconnect(int client)
{
	g_iClientColor[client] = 0;
	g_iClientLight[client] = 0;
	g_bCookieAuth[client] = false;
}

public void OnClientPostAdminCheck(int client)
{
	CookieAuthTest(client);
}

public void OnClientCookiesCached(int client)
{
	if( !g_bCvarLock && g_iCvarSave && !IsFakeClient(client) )
	{
		char sCookie[10];

		GetClientCookie(client, g_hCookieColor, sCookie, sizeof(sCookie));
		if( sCookie[0] )
		{
			g_iClientColor[client] = StringToInt(sCookie);
		} else {
			g_iClientColor[client] = g_iCvarColor;
		}

		GetClientCookie(client, g_hCookieState, sCookie, sizeof(sCookie));
		if( sCookie[0] )
		{
			g_iClientLight[client] = StringToInt(sCookie);
		}
	} else {
		g_iClientColor[client] = 0;
	}

	// Set color if they spawned before cookies were cached
	if( g_iClientColor[client] )
	{
		int entity = g_iLightIndex[client];
		if( IsValidEntRef(entity) )
		{
			SetEntProp(entity, Prop_Send, "m_clrRender", g_iClientColor[client]);
		}
	}

	CookieAuthTest(client);
}

void CookieAuthTest(int client)
{
	// Check if clients allowed to use hats otherwise delete cookie/hat
	if( g_iCvarFlags && g_bCookieAuth[client] && !IsFakeClient(client) )
	{
		int flags = GetUserFlagBits(client);

		if( !(flags & ADMFLAG_ROOT) && !(flags & g_iCvarFlags) )
		{
			DeleteLight(client);
			g_iClientLight[client] = 0;
			g_iClientColor[client] = 0;
			SetClientCookie(client, g_hCookieColor, "0");
			SetClientCookie(client, g_hCookieState, "0");
		}
	} else {
		g_bCookieAuth[client] = true;
	}
}



// ====================================================================================================
//					MENU + COLORS
// ====================================================================================================
void CreateColors()
{
	// Menu
	g_hMenu = new Menu(Menu_Light);
	g_hMenu.SetTitle("Light Color:");
	g_hMenu.ExitButton = true;

	// Colors
	g_hColors = new StringMap();

	AddColorItem("red",			"255 0 0");
	AddColorItem("green",		"0 255 0");
	AddColorItem("blue",		"0 0 255");
	AddColorItem("purple",		"155 0 255");
	AddColorItem("cyan",		"0 255 255");
	AddColorItem("orange",		"255 155 0");
	AddColorItem("white",		"-1 -1 -1");
	AddColorItem("pink",		"255 0 150");
	AddColorItem("lime",		"128 255 0");
	AddColorItem("maroon",		"128 0 0");
	AddColorItem("teal",		"0 128 128");
	AddColorItem("yellow",		"255 255 0");
	AddColorItem("grey",		"50 50 50");

	g_hSnapColors = g_hColors.Snapshot();
}

void AddColorItem(char[] sName, const char[] sColor)
{
	g_hColors.SetString(sName, sColor);

	sName[0] = CharToUpper(sName[0]);
	g_hMenu.AddItem(sColor, sName);
}

stock Action CmdLightMenu(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	g_hMenu.Display(client, 0);
	return Plugin_Handled;
}

int Menu_Light(Menu menu, MenuAction action, int client, int index)
{
	switch( action )
	{
		case MenuAction_Select:
		{
			char sColor[12];
			menu.GetItem(index, sColor, sizeof(sColor));
			CommandLight(client, 3, sColor);
			g_hMenu.DisplayAt(client, 7 * RoundToFloor(index / 7.0), 0);
		}
	}

	return 0;
}



// ====================================================================================================
//					INTRO
// ====================================================================================================
public void OnClientPutInServer(int client)
{
	// Display intro / welcome message
	if( g_fCvarIntro && IsValidNow() && !IsFakeClient(client) )
		CreateTimer(g_fCvarIntro, TimerIntro, GetClientUserId(client));
}

Action TimerIntro(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if( client && IsClientInGame(client) )
	{
		int team = GetClientTeam(client);
		if( team == 2 ) team = 1;
		else if( team == 3 ) team = 2;
		else team = 0;

		if( g_iCvarUsers & team )
		{
			CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Intro", client);
		}
	}

	return Plugin_Continue;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_LightAlpha(Handle convar, const char[] oldValue, const char[] newValue)
{
	int i, entity;
	g_iCvarAlpha = g_hCvarAlpha.IntValue;
	g_iCvarAlphas = g_hCvarAlphas.IntValue;

	// Loop through players and change their brightness
	for( i = 1; i <= MaxClients; i++ )
	{
		entity = g_iLightIndex[i];
		if( IsValidEntRef(entity) )
		{
			SetVariantInt(GetClientTeam(i) == 3 ? g_iCvarAlphas : g_iCvarAlpha);
			AcceptEntityInput(entity, "distance");
		}
	}
}

void GetCvars()
{
	char sTemp[16];

	g_iCvarAlpha = g_hCvarAlpha.IntValue;
	g_iCvarAlphas = g_hCvarAlphas.IntValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_hCvarColor.GetString(g_sCvarCols, sizeof(g_sCvarCols));
	g_iCvarDefault = g_hCvarDefault.IntValue;
	g_hCvarFlags.GetString(sTemp, sizeof(sTemp));
	g_iCvarFlags = ReadFlagString(sTemp);
	g_iCvarHints = g_hCvarHints.IntValue;
	g_fCvarIntro = g_hCvarIntro.FloatValue;
	g_bCvarLock = g_hCvarLock.BoolValue;
	g_iCvarSave = g_hCvarSave.IntValue;
	g_iCvarSpec = g_hCvarSpec.IntValue;
	g_iCvarUsers = g_hCvarUsers.IntValue;

	char sColors[3][4];
	g_iCvarColor = ExplodeString(g_sCvarCols, " ", sColors, sizeof(sColors), sizeof(sColors[]));
	if( g_iCvarColor == 3 )
	{
		g_iCvarColor = StringToInt(sColors[0]);
		g_iCvarColor += 256 * StringToInt(sColors[1]);
		g_iCvarColor += 65536 * StringToInt(sColors[2]);
	}
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvents();

		if( IsValidNow() )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					OnClientCookiesCached(i);

					if( IsFakeClient(i) )
					{
						CreateTimer(0.1, TimerDelayCreateLight, GetClientUserId(i));
					}

					else if( IsValidClient(i) )
					{
						CreateLight(i);
					}
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		UnhookEvents();

		for( int i = 1; i <= MaxClients; i++ )
		{
			g_iClientLight[i] = 0;
			DeleteLight(i);
		}
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	HookEvent("player_death",		Event_PlayerDeath);
	HookEvent("item_pickup",		Event_ItemPickup);
	HookEvent("player_spawn",		Event_PlayerSpawn);
	HookEvent("player_team",		Event_PlayerTeam);
}

void UnhookEvents()
{
	UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
	UnhookEvent("player_death",		Event_PlayerDeath);
	UnhookEvent("item_pickup",		Event_ItemPickup);
	UnhookEvent("player_spawn",		Event_PlayerSpawn);
	UnhookEvent("player_team",		Event_PlayerTeam);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = false;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bRoundOver = true;

	for( int i = 1; i <= MaxClients; i++ )
		DeleteLight(i);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client )
		return;

	DeleteLight(client); // Delete attached flashlight
	CreateSpecLight(client);
}

void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if( client && IsClientInGame(client) && GetClientTeam(client) == 3 )
		DeleteLight(client);
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int clientID = event.GetInt("userid");
	int client = GetClientOfUserId(clientID);
	DeleteLight(client);

	if( client && IsClientInGame(client) )
	{
		int team = GetClientTeam(client);
		if( team == 2 ) team = 1;
		else if( team == 3 ) team = 2;
		else team = 0;

		if( g_iCvarUsers & team )
		{
			CreateTimer(1.0, TimerDelayCreateLight, clientID); // Needed because round_start event occurs AFTER player_spawn, so IsValidNow() fails...
		}
	}
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int clientID = event.GetInt("userid");
	int client = GetClientOfUserId(clientID);

	if( !client )
		return;

	DeleteLight(client);
	CreateTimer(1.0, TimerDelayCreateLight, clientID);
	CreateSpecLight(client);
}

Action TimerDelayCreateLight(Handle timer, int client)
{
	client = GetClientOfUserId(client);

	if( client && IsValidNow() && IsValidClient(client) ) // Re-create attached flashlight
	{
		if( g_iCvarDefault )
		{
			int team = GetClientTeam(client);
			bool fake = IsFakeClient(client);

			if( team == 2 && ((g_iCvarDefault & 1 && !fake) || (g_iCvarDefault & 4 && fake)) )
			{
				// Set light on
				g_iClientLight[client] = 1;

				// Give random light to clients if not saved or bots if allowed
				if( (g_iCvarRandom & 1 && fake) || (g_iCvarRandom & 2 && !fake && (!g_iCvarSave || g_iClientColor[client] == 0)) )
				{
					int size = g_hSnapColors.Length;

					char sTemp[32];
					g_hSnapColors.GetKey(GetRandomInt(0, size - 1), sTemp, sizeof(sTemp));
					if( g_hColors.GetString(sTemp, sTemp, sizeof(sTemp)) )
					{
						char sColors[3][4];
						int color;

						ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));
						color = StringToInt(sColors[0]);
						color += 256 * StringToInt(sColors[1]);
						color += 65536 * StringToInt(sColors[2]);
						g_iClientColor[client] = color;
					}
				}
				else if( g_iClientColor[client] == 0 )
				{
					g_iClientColor[client] = g_iCvarColor;
				}
			}

			if( g_iCvarDefault & 2 && team == 3 && !fake )
			{
				g_iClientLight[client] = 1;
			}
		}

		CreateLight(client);
	}

	return Plugin_Continue;
}

void CreateSpecLight(int client)
{
	if( g_iCvarSpec && client && !IsFakeClient(client) && !IsPlayerAlive(client) )
	{
		int team = GetClientTeam(client);
		if( team == 3 ) team = 4;
		else if( team == 4 ) team = 8;

		if( g_iCvarSpec & team )
		{
			int entity = MakeLightDynamic(view_as<float>({ 0.0, 0.0, -10.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client);
			DispatchKeyValue(entity, "_light", "255 255 255 255");
			DispatchKeyValue(entity, "brightness", "2");
			g_iLights[client] = EntIndexToEntRef(entity);
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitSpec);

			if( g_iCvarHints )
			{
				CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Intro", client);
			}
		}
	}
}



// ====================================================================================================
//					COMMAND - sm_lightclient
// ====================================================================================================
// Attach flashlight onto specified client / change colors
Action CmdLightClient(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 0 )
	{
		ReplyToCommand(client, "[Flashlight] Usage: sm_lightclient <#user id|name> [R G B|red|green|blue|purple|orange|yellow|white]");
		return Plugin_Handled;
	}

	char sArg[32], target_name[MAX_TARGET_LENGTH];
	GetCmdArg(1, sArg, sizeof(sArg));

	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		sArg,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE, /* Only allow alive players */
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	if( args > 1 )
	{
		GetCmdArgString(sArg, sizeof(sArg));
		// Send the args without target name
		int pos = StrContains(sArg, " ");
		if( pos != -1 )
		{
			Format(sArg, sizeof(sArg), sArg[pos+1]);
			TrimString(sArg);
			args--;
		}
	}
	// else
		// args = 0;

	for( int i = 0; i < target_count; i++ )
	{
		if( IsValidClient(target_list[i]) )
			CommandForceLight(client, target_list[i], args, sArg);
	}
	return Plugin_Handled;
}

void CommandForceLight(int client, int target, int args, const char[] sArg)
{
	// Wrong number of arguments
	if( args != 0 && args != 1 && args != 3 )
	{
		// Display usage help if translation exists and hints turned on
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Usage", client);
		return;
	}

	// Delete flashlight and re-make if the players model has changed, CSM plugin fix...
	char sTempStr[42];
	GetClientModel(target, sTempStr, sizeof(sTempStr));
	if( strcmp(g_sPlayerModel[target], sTempStr) != 0 )
	{
		DeleteLight(target);
		strcopy(g_sPlayerModel[target], sizeof(sTempStr), sTempStr);
	}

	// Check if they have a light, or try to create
	int entity = g_iLightIndex[target];
	if( !IsValidEntRef(entity) )
	{
		CreateLight(target);

		entity = g_iLightIndex[target];
		if( !IsValidEntRef(entity) )
			return;
	}

	// Toggle or set light color and turn on.
	if( args == 1 )
	{
		if( strncmp(sArg, "rand", 4, false) == 0 )
		{
			char sTempL[12];

			// Completely random color
			// Format(sTempL, sizeof(sTempL), "%d %d %d", GetRandomInt(20, 255), GetRandomInt(20, 255), GetRandomInt(20, 255));

			// Random color from list
			int size = g_hSnapColors.Length;
			g_hSnapColors.GetKey(GetRandomInt(0, size - 1), sTempL, sizeof(sTempL));
			if( g_hColors.GetString(sTempL, sTempL, sizeof(sTempL)) )
			{
				SetVariantString(sTempL);
				AcceptEntityInput(entity, "color");
			}
		}
		else if( strcmp(sArg, "off", false) == 0 )
		{
			g_iClientLight[target] = 0;
			SetClientCookie(target, g_hCookieState, "0");

			DeleteLight(target);
			return;
		}
		else
		{
			char sTempL[12];

			if( g_hColors.GetString(sArg, sTempL, sizeof(sTempL)) == false )
				sTempL = "-1 -1 -1";

			SetVariantString(sTempL);
			AcceptEntityInput(entity, "color");
		}
	}
	else if( args == 3 )
	{
		// Specified colors
		char sTempL[12];
		char sSplit[3][4];
		ExplodeString(sArg, " ", sSplit, sizeof(sSplit), sizeof(sSplit[]));
		Format(sTempL, sizeof(sTempL), "%d %d %d", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));

		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}

	AcceptEntityInput(entity, "toggle");

	int color = GetEntProp(entity, Prop_Send, "m_clrRender");
	if( color != g_iClientColor[target] )
	{
		if( g_iCvarSave && !IsFakeClient(target) )
		{
			char sNum[10];
			IntToString(color, sNum, sizeof(sNum));
			SetClientCookie(target, g_hCookieColor, sNum);
		}

		AcceptEntityInput(entity, "TurnOn");
		g_iClientLight[client] = 0; // Gets turned on below
	}

	g_iClientColor[target] = color;
	g_iClientLight[target] = !g_iClientLight[target];

	if( g_iCvarSave && !IsFakeClient(target) )
	{
		char sNum[4];
		IntToString(g_iClientLight[target], sNum, sizeof(sNum));
		SetClientCookie(target, g_hCookieState, sNum);
	}
}



// ====================================================================================================
//					COMMAND - sm_light
// ====================================================================================================
Action CmdLightCommand(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sArg[25];
	GetCmdArgString(sArg, sizeof(sArg));
	CommandLight(client, args, sArg);
	CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Usage", client);
	return Plugin_Handled;
}

void CommandLight(int client, int args, const char[] sArg)
{
	// Must be valid
	if( !client || !IsClientInGame(client) )
		return;

	if( !IsValidNow() )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	if( IsPlayerAlive(client) )
	{
		int team = GetClientTeam(client);
		if( team == 2 ) team = 1;
		else if( team == 3 ) team = 2;
		else team = 0;

		if( !(g_iCvarUsers & team) )
		{
			CPrintToChat(client, "[SM] %T.", "No Access", client);
			return;
		}
	}
	else
	{
		if( g_iCvarSpec == 0 )
		{
			CPrintToChat(client, "[SM] %T.", "No Access", client);
			return;
		}

		int team = GetClientTeam(client);
		if( team == 3 ) team = 4;
		else if( team == 4 ) team = 8;

		if( !(g_iCvarSpec & team) )
		{
			CPrintToChat(client, "[SM] %T.", "No Access", client);
			return;
		}
	}

	// Make sure the user has the correct permissions
	int flagc = GetUserFlagBits(client);

	if( g_iCvarFlags != 0 && !(flagc & g_iCvarFlags) && !(flagc & ADMFLAG_ROOT) )
	{
		CPrintToChat(client, "[SM] %T.", "No Access", client);
		return;
	}

	// Wrong number of arguments
	if( args != 0 && args != 1 && args != 3 )
	{
		// Display usage help if translation exists and hints turned on
		CPrintToChat(client, "%s%T", CHAT_TAG, "Flashlight Usage", client);
		return;
	}

	// Delete flashlight and re-make if the players model has changed, CSM plugin fix...
	char sTempStr[42];
	GetClientModel(client, sTempStr, sizeof(sTempStr));
	if( strcmp(g_sPlayerModel[client], sTempStr) != 0 )
	{
		DeleteLight(client);
		strcopy(g_sPlayerModel[client], sizeof(sTempStr), sTempStr);
	}

	// Off option
	if( args == 1 )
	{
		if( strcmp(sArg, "off", false) == 0 )
		{
			g_iClientLight[client] = 0;
			SetClientCookie(client, g_hCookieState, "0");

			DeleteLight(client);
			return;
		}
	}

	// Check if they have a light, or try to create
	int entity = g_iLightIndex[client];
	if( !IsValidEntRef(entity) )
	{
		CreateLight(client);

		entity = g_iLightIndex[client];
		if( !IsValidEntRef(entity) )
			return;
	}

	// Specified colors
	if( g_bCvarLock && !(flagc & ADMFLAG_ROOT) )
		flagc = 0;
	else
		flagc = 1;

	// Toggle or set light color and turn on.
	if( flagc && args == 1 && strncmp(sArg, "rand", 4, false) == 0 )
	{
		char sTempL[12];

		// Completely random color
		// Format(sTempL, sizeof(sTempL), "%d %d %d", GetRandomInt(20, 255), GetRandomInt(20, 255), GetRandomInt(20, 255));

		// Random color from list
		int size = g_hSnapColors.Length;
		g_hSnapColors.GetKey(GetRandomInt(0, size - 1), sTempL, sizeof(sTempL));
		if( g_hColors.GetString(sTempL, sTempL, sizeof(sTempL)) )
		{
			SetVariantString(sTempL);
			AcceptEntityInput(entity, "color");
		}
	}
	else if( flagc && args == 1 )
	{
		char sTempL[12];

		if( g_hColors.GetString(sArg, sTempL, sizeof(sTempL)) == false )
			sTempL = "-1 -1 -1";

		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}
	else if( flagc && args == 3 )
	{
		// Specified colors
		char sTempL[12];
		char sSplit[3][4];
		ExplodeString(sArg, " ", sSplit, sizeof(sSplit), sizeof(sSplit[]));
		Format(sTempL, sizeof(sTempL), "%d %d %d", StringToInt(sSplit[0]), StringToInt(sSplit[1]), StringToInt(sSplit[2]));

		SetVariantString(sTempL);
		AcceptEntityInput(entity, "color");
	}

	int color = GetEntProp(entity, Prop_Send, "m_clrRender");
	if( color != g_iClientColor[client] )
	{
		if( g_iCvarSave && !IsFakeClient(client) )
		{
			char sNum[10];
			IntToString(color, sNum, sizeof(sNum));
			SetClientCookie(client, g_hCookieColor, sNum);
		}

		AcceptEntityInput(entity, "TurnOn");
		g_iClientLight[client] = 0; // Gets turned on below
	}
	else
	{
		AcceptEntityInput(entity, "toggle");
	}

	g_iClientLight[client] = !g_iClientLight[client];
	g_iClientColor[client] = color;

	if( g_iCvarSave && !IsFakeClient(client) )
	{
		char sNum[4];
		IntToString(g_iClientLight[client], sNum, sizeof(sNum));
		SetClientCookie(client, g_hCookieState, sNum);
	}
}

// Called to attach permanent light.
void CreateLight(int client)
{
	DeleteLight(client);

	// Declares
	int entity;
	float vOrigin[3], vAngles[3];

	// Flashlight model
	if( g_bValidMap && GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		entity = CreateEntityByName("prop_dynamic");
		if( entity == -1 )
		{
			LogError("Failed to create 'prop_dynamic'");
		}
		else
		{
			SetEntityModel(entity, MODEL_LIGHT);
			DispatchSpawn(entity);

			vOrigin = view_as<float>({ 0.0, 0.0, -2.0 });
			vAngles = view_as<float>({ 180.0, 9.0, 90.0 });

			// Attach to survivor
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);
			SetVariantString(ATTACH_GRENADE);
			AcceptEntityInput(entity, "SetParentAttachment");

			TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitLight);
			g_iModelIndex[client] = EntIndexToEntRef(entity);
		}
	}

	// Position light
	switch( GetClientTeam(client) )
	{
		case 2:	vOrigin = view_as<float>({ 0.5, -1.5, -7.5 });
		case 3: vOrigin = view_as<float>({ 0.0, 0.0, 50.0 });
		default: vOrigin = view_as<float>({ 0.0, 0.0, 0.0 });
	}

	vAngles = view_as<float>({ -45.0, -45.0, 90.0 });

	// Light_Dynamic
	entity = MakeLightDynamic(vOrigin, vAngles, client);
	g_iLightIndex[client] = EntIndexToEntRef(entity);

	if( g_iClientColor[client] )
	{
		SetEntProp(entity, Prop_Send, "m_clrRender", g_iClientColor[client]);
	}

	if( g_iClientLight[client] == 1 )
		AcceptEntityInput(entity, "TurnOn");
	else
		AcceptEntityInput(entity, "TurnOff");

	// Special Infected only light
	if( GetClientTeam(client) == 3 )
	{
		g_iLights[client] = EntIndexToEntRef(entity);
		SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmitSpec);
	}
}



// ====================================================================================================
//					LIGHTS
// ====================================================================================================
int MakeLightDynamic(const float vOrigin[3], const float vAngles[3], int client)
{
	int entity = CreateEntityByName("light_dynamic");
	if( entity == -1)
	{
		LogError("Failed to create 'light_dynamic'");
		return 0;
	}

	char sTemp[16];
	Format(sTemp, sizeof(sTemp), "%s 255", g_sCvarCols);
	DispatchKeyValue(entity, "_light", sTemp);
	DispatchKeyValue(entity, "brightness", "1");
	DispatchKeyValueFloat(entity, "spotlight_radius", 32.0);
	DispatchKeyValueFloat(entity, "distance", GetClientTeam(client) == 3 ? float(g_iCvarAlphas) : float(g_iCvarAlpha));
	DispatchKeyValue(entity, "style", "0");
	DispatchSpawn(entity);
	AcceptEntityInput(entity, "TurnOn");

	// Attach to survivor
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", client);

	if( GetClientTeam(client) == 2 && IsPlayerAlive(client) )
	{
		SetVariantString(ATTACH_GRENADE);
		AcceptEntityInput(entity, "SetParentAttachment");
	}

	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	return entity;
}



// ====================================================================================================
//					DELETE ENTITIES
// ====================================================================================================
void DeleteLight(int client)
{
	int entity = g_iLightIndex[client];
	g_iLightIndex[client] = 0;
	DeleteEntity(entity);

	entity = g_iModelIndex[client];
	g_iModelIndex[client] = 0;
	DeleteEntity(entity);

	entity = g_iLights[client];
	g_iLights[client] = 0;
	DeleteEntity(entity);
}

void DeleteEntity(int entity)
{
	if( IsValidEntRef(entity) )
		RemoveEntity(entity);
}



// ====================================================================================================
//					BOOLEANS
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

bool IsValidClient(int client)
{
	if( !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
		return false;

	int team = GetClientTeam(client);
	if( team == 2 ) team = 1;
	else if( team == 3 ) team = 2;
	else team = 0;

	if( !(g_iCvarUsers & team) )
		return false;

	return true;
}

bool IsValidNow()
{
	if( g_bRoundOver || !g_bCvarAllow )
		return false;
	return true;
}



// ====================================================================================================
//					SDKHOOKS TRANSMIT
// ====================================================================================================
Action Hook_SetTransmitLight(int entity, int client)
{
	if( g_iModelIndex[client] == EntIndexToEntRef(entity) || GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") != -1 )
		return Plugin_Handled;
	return Plugin_Continue;
}

Action Hook_SetTransmitSpec(int entity, int client)
{
	if( g_iLights[client] == EntIndexToEntRef(entity) )
		return Plugin_Continue;
	return Plugin_Handled;
}



// ====================================================================================================
//					COLORS.INC REPLACEMENT
// ====================================================================================================
void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"\x03");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"\x03");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"\x04");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"\x04"); // Actually orange in L4D2, but replicating colors.inc behaviour
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"\x05");
	PrintToChat(client, buffer);
}
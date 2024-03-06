/* 
	https://developer.valvesoftware.com/wiki/L4D2_EMS/Appendix:_HUD
	For work, need place file versus.nut in left4dead2\scripts\vscripts with text g_ModeScript
*/

#include <sourcemod>
#include <sdktools>

#define VOICE_NORMAL 0
#define VOICE_MUTED 1
#define L4D2_TEAM_SPECTATORS 1
#define L4D2_TEAM_SURVIVORS  2
#define L4D2_TEAM_INFECTED   3 

char sPath_VscriptHUD[PLATFORM_MAX_PATH];
float speakDelay;

bool ClientSpeaking[MAXPLAYERS + 1];
char surData[128];
char infData[128];

char srvLogo[32] = "";
Handle g_hSrvLogo;
Handle g_AllTalkCvar;


public Plugin myinfo = 
{
	name = "ListSpeakers", 
	author = "Aceleracion, Emilio3, pa4H", 
	description = "Player Speakers List in Hud", 
	version = "4.0", 
	url = "https://t.me/pa4H232"
}

public void OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	RegAdminCmd("sm_runvscript", Command_RunVscript, ADMFLAG_ROOT);
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy); // Сервер запустился
	
	g_hSrvLogo = CreateConVar("SrvLogo", "", "Your server name on top of screen", FCVAR_CHEAT);
	HookConVarChange(g_hSrvLogo, OnConVarChange);
	
	char sPath[PLATFORM_MAX_PATH];
	strcopy(sPath, sizeof(sPath), "scripts/vscripts");
	if (DirExists(sPath) == false)
	{
		CreateDirectory(sPath, 511);
	}
	
	Format(sPath_VscriptHUD, sizeof(sPath_VscriptHUD), "scripts/vscripts/speakerhud.nut");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public void OnClientSpeaking(int client)
{
	if (!IsValidClient(client) || GetClientListeningFlags(client) == VOICE_MUTED) { return; }
	ClientSpeaking[client] = true;
	
	float tNow = GetEngineTime();
	if (tNow - speakDelay < 0.5) { return; }
	speakDelay = tNow;
	UpdateSpeakerList();
}
public void OnClientSpeakingEnd(int client)
{
	if (!IsValidClient(client)) { return; }
	ClientSpeaking[client] = false;
	UpdateSpeakerList();
}


void UpdateSpeakerList()
{
	surData[0] = '\0';
	infData[0] = '\0';
	for (int i = 1; i <= MaxClients; i++)
	{
		if (ClientSpeaking[i])
		{
			if (!IsValidClient(i)) { continue; }
			
			if (GetClientTeam(i) == L4D2_TEAM_SURVIVORS)
			{
				Format(surData, sizeof(surData), "%s> %N\\n", surData, i);
			}
			if (GetClientTeam(i) == L4D2_TEAM_INFECTED)
			{
				Format(infData, sizeof(infData), "%s> %N\\n", infData, i);
			}
		}
		ClientSpeaking[i] = false;
	}
	UpdateHUD();
}

void SaveVscriptHUD()
{
	Handle hFile = OpenFile(sPath_VscriptHUD, "w");
	if (hFile)
	{
		WriteFileLine(hFile, "ModeHUD <-");
		WriteFileLine(hFile, "{");
		WriteFileLine(hFile, "    Fields = ");
		WriteFileLine(hFile, "    {");
		g_AllTalkCvar = FindConVar("sv_alltalk");
		
		if (!GetConVarInt(g_AllTalkCvar)) // sv_alltalk 0
		{
			if (!StrEqual(surData, "", false)) // Show to survivors
			{
				WriteFileLine(hFile, "        speakerS = ");
				WriteFileLine(hFile, "        {");
				WriteFileLine(hFile, "            slot = g_ModeScript.HUD_MID_BOX,");
				WriteFileLine(hFile, "            dataval = \"%s\",", surData);
				WriteFileLine(hFile, "            flags = g_ModeScript.HUD_FLAG_ALIGN_LEFT | g_ModeScript.HUD_FLAG_NOBG | g_ModeScript.HUD_FLAG_TEAM_SURVIVORS,");
				WriteFileLine(hFile, "            name = \"speakerS\" ");
				WriteFileLine(hFile, "        }");
			}
			if (!StrEqual(infData, "", false)) // Show to infecteds
			{
				WriteFileLine(hFile, "        speakerI = ");
				WriteFileLine(hFile, "        {");
				WriteFileLine(hFile, "            slot = g_ModeScript.HUD_MID_BOX,");
				WriteFileLine(hFile, "            dataval = \"%s\",", infData);
				WriteFileLine(hFile, "            flags = g_ModeScript.HUD_FLAG_ALIGN_LEFT | g_ModeScript.HUD_FLAG_NOBG | g_ModeScript.HUD_FLAG_TEAM_INFECTED,");
				WriteFileLine(hFile, "            name = \"speakerI\" ");
				WriteFileLine(hFile, "        }");
			}
		}
		else // sv_alltalk 1
		{
			if (!StrEqual(surData, "", false) || !StrEqual(infData, "", false)) // Show to all
			{
				char allData[128];
				FormatEx(allData, sizeof(allData), "%s%s", surData, infData); // Combine strings
				WriteFileLine(hFile, "        speaker = ");
				WriteFileLine(hFile, "        {");
				WriteFileLine(hFile, "            slot = g_ModeScript.HUD_MID_BOX,");
				WriteFileLine(hFile, "            dataval = \"%s\",", allData);
				WriteFileLine(hFile, "            flags = g_ModeScript.HUD_FLAG_ALIGN_LEFT | g_ModeScript.HUD_FLAG_NOBG,");
				WriteFileLine(hFile, "            name = \"speaker\" ");
				WriteFileLine(hFile, "        }");
			}
		}
		// Server logo
		WriteFileLine(hFile, "            logo = { slot = g_ModeScript.HUD_FAR_RIGHT, dataval = \"%s\", flags = g_ModeScript.HUD_FLAG_ALIGN_LEFT | g_ModeScript.HUD_FLAG_NOBG, name = \"logo\" }", srvLogo);
		WriteFileLine(hFile, "    }");
		WriteFileLine(hFile, "}");
		WriteFileLine(hFile, "");
		WriteFileLine(hFile, "HUDSetLayout(ModeHUD)");
		WriteFileLine(hFile, "HUDPlace(g_ModeScript.HUD_FAR_RIGHT , 0.8 , 0.04 , 0.2 , 0.05)"); // Logo
		
		if (!StrEqual(surData, "", false) || !StrEqual(infData, "", false))
		{
			WriteFileLine(hFile, "HUDPlace(g_ModeScript.HUD_MID_BOX , 0.8 , 0.6 , 0.25 , 0.2 )"); // List of speakers
		}
		
		WriteFileLine(hFile, "g_ModeScript");
		CloseHandle(hFile);
	}
}

void UpdateHUD()
{
	SaveVscriptHUD();
	ServerCommand("sm_runvscript speakerhud");
}

public Action Command_RunVscript(int client, int args)
{
	if (args < 1)
	{
		return Plugin_Handled;
	}
	
	char vscriptFile[40];
	GetCmdArg(1, vscriptFile, sizeof(vscriptFile));
	
	int entity = CreateEntityByName("logic_script");
	if (entity != -1)
	{
		DispatchKeyValue(entity, "vscripts", vscriptFile);
		DispatchSpawn(entity);
		SetVariantString("OnUser1 !self:RunScriptCode::0:-1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::1:-1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
	return Plugin_Handled;
}

public OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVarString(g_hSrvLogo, srvLogo, sizeof(srvLogo));
}

public void OnConfigsExecuted() // Плагины загрузились
{
	UpdateHUD();
}
public RoundStartEvent(Handle event, const char[] name, bool dontBroadcast) // Сервер запустился
{
	CreateTimer(0.5, ShowServerName);
}
public Action ShowServerName(Handle timer)
{
	UpdateHUD();
	return Plugin_Stop;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
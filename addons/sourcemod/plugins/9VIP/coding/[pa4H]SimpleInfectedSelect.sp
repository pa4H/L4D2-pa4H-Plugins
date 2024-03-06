#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>
#include <pa4HVIP> // pa4HVIP.inc

#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6

bool cantChange[MAXPLAYERS + 1];
int g_iNextClass[MAXPLAYERS + 1] =  { 0, ... };
Handle g_hSetClass = INVALID_HANDLE;
Handle g_hCreateAbility = INVALID_HANDLE;
Handle g_hGameConf = INVALID_HANDLE;
int g_oAbility = 0;
int lastClass[MAXPLAYERS + 1] =  { 0, ... };

public Plugin myinfo = 
{
	name = "SimpleInfectedSelect", 
	author = "pa4H, XBetaAlpha", 
	description = "VIP", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	Sub_HookGameData("l4d2_zcs");
	//RegConsoleCmd("sm_test", debb, "");
	//RegAdminCmd("sm_test", refreshPlugins, ADMFLAG_BAN);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsValidClient(client) || !vip_isClientVIP(client) || !IsPlayerGhost(client)) { return Plugin_Continue; }
	
	if (buttons & IN_ATTACK2 && !cantChange[client]) // Игрок нажал ПКМ
	{
		cantChange[client] = true;
		CreateTimer(0.5, timer_DelayChange, client, TIMER_FLAG_NO_MAPCHANGE);
		Sub_DetermineClass(client, GetEntProp(client, Prop_Send, "m_zombieClass"));
	}
	
	if (buttons & IN_ATTACK && IsPlayerGhost(client)) {  // Игрок будучи призраком заспаунился после нажатия на ЛКМ
		CreateTimer(1.0, timer_saveLastClass, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
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
public bool IsPlayerGhost(any Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isGhost"))
		return true;
	else
		return false;
}
public Action timer_saveLastClass(Handle hTimer, any client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;
	
	if (!IsPlayerGhost(client))
	{
		lastClass[client] = GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	
	return Plugin_Continue;
}
public Action timer_DelayChange(Handle hTimer, any client)
{
	cantChange[client] = false;
	return Plugin_Continue;
}

bool haveSameClass(int class)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == 3 && class == GetEntProp(i, Prop_Send, "m_zombieClass")) {
			return true;
		}
	}
	return false;
}

public void Sub_DetermineClass(any Client, any ZClass)
{
	if (ZClass > ZC_CHARGER)
		return;
	
	g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;
	if (g_iNextClass[Client] == lastClass[Client]) {
		ZClass++;
		g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;
	}
	if (haveSameClass(g_iNextClass[Client])) {
		ZClass++;
		g_iNextClass[Client] = (ZClass >= ZC_SMOKER && ZClass < ZC_CHARGER) ? ZClass + 1 : ZC_SMOKER;
	}
	int WeaponIndex;
	while ((WeaponIndex = GetPlayerWeaponSlot(Client, 0)) != -1)
	{
		RemovePlayerItem(Client, WeaponIndex);
		RemoveEdict(WeaponIndex);
	}
	
	SDKCall(g_hSetClass, Client, g_iNextClass[Client]);
	
	int cAbility = GetEntPropEnt(Client, Prop_Send, "m_customAbility");
	if (cAbility > 0)AcceptEntityInput(cAbility, "Kill");
	
	SetEntProp(Client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, Client), g_oAbility));
}
public void Sub_HookGameData(char[] GameDataFile)
{
	g_hGameConf = LoadGameConfigFile(GameDataFile);
	
	if (g_hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();
		
		if (g_hSetClass == INVALID_HANDLE)
			SetFailState("[+] S_HGD: Error: Unable to find SetClass signature.");
		
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();
		
		if (g_hCreateAbility == INVALID_HANDLE)
			SetFailState("[+] S_HGD: Error: Unable to find CreateAbility signature.");
		
		g_oAbility = GameConfGetOffset(g_hGameConf, "oAbility");
		
		CloseHandle(g_hGameConf);
	}
	
	else
		SetFailState("[+] S_HGD: Error: Unable to load gamedata file, exiting.");
}
public OnClientPostAdminCheck(client)
{
	lastClass[client] = 0;
} 
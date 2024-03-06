#include <sourcemod>
#include <sdktools>

#define ZC_SMOKER		1
#define ZC_BOOMER		2
#define ZC_HUNTER		3
#define ZC_SPITTER		4
#define ZC_JOCKEY		5
#define ZC_CHARGER		6
Handle g_hSetClass = INVALID_HANDLE;
Handle g_hCreateAbility = INVALID_HANDLE;
Handle hGameConf = INVALID_HANDLE;
int g_oAbility = 0;

public Plugin myinfo = 
{
	name = "FunCmds", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}
Handle sdkVomitSurvivor = INVALID_HANDLE;
Handle g_hGameConf = INVALID_HANDLE;

public OnPluginStart()
{
	//RegAdminCmd("sm_test", TestTest, ADMFLAG_BAN);
	RegAdminCmd("sm_noweapon", noWeapons, ADMFLAG_BAN);
	RegAdminCmd("sm_noweapons", noWeapons, ADMFLAG_BAN);
	RegAdminCmd("sm_clearweapon", noWeapons, ADMFLAG_BAN);
	RegAdminCmd("sm_clearweapons", noWeapons, ADMFLAG_BAN);
	
	RegAdminCmd("sm_smoker", giveSmoker, ADMFLAG_BAN);
	RegAdminCmd("sm_boomer", giveBoomer, ADMFLAG_BAN);
	RegAdminCmd("sm_hunter", giveHunter, ADMFLAG_BAN);
	RegAdminCmd("sm_spitter", giveSpitter, ADMFLAG_BAN);
	RegAdminCmd("sm_jockey", giveJockey, ADMFLAG_BAN);
	RegAdminCmd("sm_charger", giveCharger, ADMFLAG_BAN);
	Sub_HookGameData("l4d2_zcs");
	
	RegAdminCmd("sm_adminheal", giveHealth, ADMFLAG_BAN);
	RegAdminCmd("sm_vomitall", vomitall, ADMFLAG_BAN);
	AutoExecConfig(true, "l4d2_vomit");
	g_hGameConf = LoadGameConfigFile("l4d2vomit");
	if (g_hGameConf == INVALID_HANDLE) { SetFailState("Couldn't find the offsets and signatures file. Please, check that it is installed correctly."); }
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_OnVomitedUpon");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkVomitSurvivor = EndPrepSDKCall();
	if (sdkVomitSurvivor == INVALID_HANDLE) { SetFailState("Unable to find the \"CTerrorPlayer_OnVomitedUpon\" signature, check the file version!"); }
}
stock Action TestTest(client, args)
{
	
	return Plugin_Handled;
}
Action noWeapons(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_noweapons <client>");
		return Plugin_Handled;
	}
	char argOne[4];
	GetCmdArg(1, argOne, sizeof(argOne));
	int cli = StringToInt(argOne);
	for (int i = 0; i < 5; i++)
	{
		int slot = GetPlayerWeaponSlot(cli, i);
		if (slot != -1) { RemovePlayerItem(cli, slot); }
	}
	return Plugin_Handled;
}
public Action giveHealth(client, args)
{
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetCommandFlags("give", flagsgive | FCVAR_CHEAT);
	return Plugin_Handled;
}
public Action vomitall(client, args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			SDKCall(sdkVomitSurvivor, i, client, true);
		}
	}
	return Plugin_Handled;
}

public Action giveSmoker(client, args)
{
	Sub_DetermineClass(client, ZC_SMOKER);
	return Plugin_Handled;
}
public Action giveBoomer(client, args)
{
	Sub_DetermineClass(client, ZC_BOOMER);
	return Plugin_Handled;
}
public Action giveHunter(client, args)
{
	Sub_DetermineClass(client, ZC_HUNTER);
	return Plugin_Handled;
}
public Action giveSpitter(client, args)
{
	Sub_DetermineClass(client, ZC_SPITTER);
	return Plugin_Handled;
}
public Action giveJockey(client, args)
{
	Sub_DetermineClass(client, ZC_JOCKEY);
	return Plugin_Handled;
}
public Action giveCharger(client, args)
{
	Sub_DetermineClass(client, ZC_CHARGER);
	return Plugin_Handled;
}
public void Sub_DetermineClass(any Client, any ZClass)
{
	int WeaponIndex;
	while ((WeaponIndex = GetPlayerWeaponSlot(Client, 0)) != -1)
	{
		RemovePlayerItem(Client, WeaponIndex);
		RemoveEdict(WeaponIndex);
	}
	
	SDKCall(g_hSetClass, Client, ZClass);
	
	int cAbility = GetEntPropEnt(Client, Prop_Send, "m_customAbility");
	if (cAbility > 0)AcceptEntityInput(cAbility, "Kill");
	
	SetEntProp(Client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, Client), g_oAbility));
}
public void Sub_HookGameData(char[] GameDataFile)
{
	hGameConf = LoadGameConfigFile(GameDataFile);
	
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();
		
		if (g_hSetClass == INVALID_HANDLE)
			SetFailState("[+] S_HGD: Error: Unable to find SetClass signature.");
		
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();
		
		if (g_hCreateAbility == INVALID_HANDLE)
			SetFailState("[+] S_HGD: Error: Unable to find CreateAbility signature.");
		
		g_oAbility = GameConfGetOffset(hGameConf, "oAbility");
		
		CloseHandle(hGameConf);
	}
	
	else
		SetFailState("[+] S_HGD: Error: Unable to load gamedata file, exiting.");
}
public bool IsPlayerGhost(any Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isGhost"))
		return true;
	else
		return false;
}
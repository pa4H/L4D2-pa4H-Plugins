#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

bool g_bBlockSecondaryDrop;
bool g_bBlockM60Drop;
int g_iBlockDropMidAction;
int g_iOffsetAmmo, g_iPrimaryAmmoType;

public Plugin myinfo = 
{
	name = "AllWeaponDrop", 
	author = "pa4H, HarryPotter", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public void OnPluginStart()
{
	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	
	RegConsoleCmd("sm_drop", Command_Drop);
}

Action Command_Drop(int client, int args)
{
	DropActiveWeapon(client);
	return Plugin_Handled;
}

void DropActiveWeapon(int client)
{
	if (!IsValidClient(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || IsplayerIncap(client) || GetInfectedAttacker(client) != -1) { return; }
	
	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	if (RealValidEntity(weapon) && DropBlocker(client, weapon)) {
		DropWeapon(client, weapon);
	}
}

int DropBlocker(int client, int weapon)
{
	int wep_Secondary = GetPlayerWeaponSlot(client, 1);
	
	if (g_bBlockSecondaryDrop && wep_Secondary == weapon)return false;
	
	static char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (g_bBlockM60Drop && StrEqual(classname, "weapon_rifle_m60", false)) {
		return false;
	}
	return true;
}

void DropWeapon(int client, int weapon)
{
	if ((g_iBlockDropMidAction == 1 || (g_iBlockDropMidAction == 2 && GetPlayerWeaponSlot(client, 2) == weapon)) && GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon") == weapon && GetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack") >= GetGameTime()) { return; }
	
	if (GetPlayerWeaponSlot(client, 2) == weapon && GetOrSetPlayerAmmo(client, weapon) == 0) { return; }
	
	int owner = GetEntPropEnt(weapon, Prop_Data, "m_hOwner");
	
	if (owner != client) { return; }
	
	static char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (strcmp(classname, "weapon_pistol") == 0 && GetEntProp(weapon, Prop_Send, "m_isDualWielding") > 0)
	{
		int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
		int second_clip = 0;
		if (clip % 2 == 0) {
			second_clip = clip / 2;
			clip = clip / 2;
		}
		else {
			second_clip = clip / 2 + 1;
			clip = clip / 2;
		}
		
		RemovePlayerItem(client, weapon);
		RemoveEntity(weapon);
		
		int single_pistol = CreateEntityByName("weapon_pistol");
		if (single_pistol <= MaxClients) { return; }
		
		DispatchSpawn(single_pistol);
		EquipPlayerWeapon(client, single_pistol);
		SDKHooks_DropWeapon(client, single_pistol);
		
		SetEntProp(single_pistol, Prop_Send, "m_iClip1", clip);
		
		single_pistol = CreateEntityByName("weapon_pistol");
		if (single_pistol <= MaxClients) { return; }
		
		DispatchSpawn(single_pistol);
		EquipPlayerWeapon(client, single_pistol);
		SetEntProp(single_pistol, Prop_Send, "m_iClip1", second_clip);
		
		return;
	}
	
	int ammo = GetPlayerReserveAmmo(client, weapon);
	
	SDKHooks_DropWeapon(client, weapon);
	
	SetPlayerReserveAmmo(client, weapon, 0);
	SetEntProp(weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
	
	if (strcmp(classname, "weapon_defibrillator") == 0) {
		int modelindex = GetEntProp(weapon, Prop_Data, "m_nModelIndex");
		SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", modelindex);
	}
}

void SetPlayerReserveAmmo(int client, int weapon, int ammo)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0) {
		SetEntProp(client, Prop_Send, "m_iAmmo", ammo, _, ammotype);
		ChangeEdictState(client, FindDataMapInfo(client, "m_iAmmo"));
	}
}

int GetPlayerReserveAmmo(int client, int weapon)
{
	int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (ammotype >= 0) {
		return GetEntProp(client, Prop_Send, "m_iAmmo", _, ammotype);
	}
	return 0;
}

bool IsSurvivor(int client)
{
	return (GetClientTeam(client) == 2 || GetClientTeam(client) == 4);
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
		if (replaycheck) {
			if (IsClientSourceTV(client) || IsClientReplay(client)) { return false; }
		}
		return true;
	}
	return false;
}

bool RealValidEntity(int entity)
{
	return (entity > MaxClients && IsValidEntity(entity));
}

bool IsplayerIncap(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") || GetEntProp(client, Prop_Send, "m_isIncapacitated")) { return true; }
	
	return false;
}

int GetInfectedAttacker(int client)
{
	int attacker;
	
	/* Charger */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (attacker > 0) {
		return attacker;
	}
	
	attacker = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	if (attacker > 0) {
		return attacker;
	}
	/* Jockey */
	attacker = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (attacker > 0) {
		return attacker;
	}
	
	/* Hunter */
	attacker = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (attacker > 0) {
		return attacker;
	}
	
	/* Smoker */
	attacker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (attacker > 0) {
		return attacker;
	}
	
	return -1;
}

int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	int offset = GetEntData(iWeapon, g_iPrimaryAmmoType) * 4;
	
	if (offset) {
		if (iAmmo != -1) { SetEntData(client, g_iOffsetAmmo + offset, iAmmo); }
		else {
			int ammo = GetEntData(client, g_iOffsetAmmo + offset);
			return ammo >= 999 ? 999 : ammo;
		}
	}
	return 0;
} 
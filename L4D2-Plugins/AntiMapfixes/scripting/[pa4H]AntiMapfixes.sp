 // https://github.com/L4D-Community-Team/Last-Stand-Refresh/blob/main/scripts/vscripts/anv_mapfixes.nut
#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "AntiMapFixes", 
	author = "pa4H", 
	description = "anv_mapfixes.nut", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("versus_round_start", clearEvent);
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public void clearEvent(Event hEvent, const char[] sEvName, bool bDontBroadcast) // Срабатывает после выхода из saferoom
{
	// c2m1 
	// Прыжок на грузовик
	FireEntityInput("anv_mapfixes_shortcut_start_trucka", "Kill");
	FireEntityInput("anv_mapfixes_shortcut_start_truckb", "Kill");
	FireEntityInput("anv_mapfixes_shortcut_start_busblu", "Kill");
	// Проход под карту для заразы
	FireEntityInput("anv_mapfixes_cargocontainer_oob_01", "Kill");
	FireEntityInput("anv_mapfixes_cargocontainer_oob_02", "Kill");
	FireEntityInput("anv_mapfixes_cargocontainer_oob_03", "Kill");
	
	// c2m3 Dark Carnival
	// Теперь можно залезть на американские горки
	FireEntityInput("anv_mapfixes_cliprework_scaffnuke_skipa", "Kill");
	FireEntityInput("anv_mapfixes_cliprework_scaffnuke_skipb", "Kill");
	FireEntityInput("anv_mapfixes_cliprework_scaffnuke_skipc", "Kill");
	FireEntityInput("anv_mapfixes_cliprework_scaffnuke_skipd", "Kill");
	FireEntityInput("anv_mapfixes_cliprework_roofa", "Kill");
	FireEntityInput("anv_mapfixes_cliprework_roofb", "Kill");
	FireEntityInput("anv_mapfixes_cliprework_sign", "Kill");
	FireEntityInput("anv_mapfixes_shortcut_finally_done", "Kill");
	FireEntityInput("anv_mapfixes_booster_eventskip1", "Kill");
	FireEntityInput("anv_mapfixes_booster_eventskip2", "Kill");
	killEntity(-2887.0, 2609.0, 121.0);
	killEntity(-2854.0, 2456.0, 444.0);
	// Проход под карту за Курильщика
	FireEntityInput("anv_mapfixes_smokerinfamya", "Kill");
	FireEntityInput("anv_mapfixes_smokerinfamyb", "Kill");
	FireEntityInput("anv_mapfixes_smokerinfamyc", "Kill");
	
	// c4m2 Hard rain
	// Прыжок на грузовик и через забор
	FireEntityInput("anv_mapfixes_truck_fence1", "Kill");
	FireEntityInput("anv_mapfixes_truck_fence2", "Kill");
	
	// c5m3 Parish
	// Прыжок через грузовик
	FireEntityInput("anv_mapfixes_shortcut_vanjump", "Kill");
	// Прыжок через заваленный вещами забор
	FireEntityInput("anv_mapfixes_barricade_stepcollision1", "Kill");
	FireEntityInput("anv_mapfixes_nav_brokenhome_shortcuta", "Kill");
	FireEntityInput("anv_mapfixes_nav_brokenhome_shortcutb", "Kill");
	
	// c8m2
	// Можно застрять Танком в туннеле
	FireEntityInput("anv_mapfixes_tankwarp_solidify", "Kill");
	
	//FireEntityInput("anv_mapfixes", "Kill");
}

void killEntity(float loc0, float loc1, float loc2)
{
	char EdictClassName[128];
	float NearestObject[3];
	float Location[3];
	NearestObject[0] = loc0;
	NearestObject[1] = loc1;
	NearestObject[2] = loc2;
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i) && IsValidEdict(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "env_physics_blocker", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				
				if (GetVectorDistance(NearestObject, Location, false) < 50.0)
				{
					//PrintToChatAll("VectorDistance %f Location: %f %f %f", GetVectorDistance(NearestObject, Location, false), Location[0], Location[1], Location[2]);
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
					
				}
			}
		}
	}
}

FireEntityInput(String:strTargetname[], String:strInput[], String:strParameter[] = "", Float:flDelay = 0.0)
{
	decl String:strBuffer[255];
	Format(strBuffer, sizeof(strBuffer), "OnUser1 %s:%s:%s:%f:1", strTargetname, strInput, strParameter, flDelay);
	
	new entity = CreateEntityByName("info_target");
	if (IsValidEdict(entity))
	{
		DispatchSpawn(entity);
		ActivateEntity(entity);
		
		SetVariantString(strBuffer);
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
		
		CreateTimer(0.0, DeleteEdict, entity);
		return true;
	}
	return false;
}

public Action:DeleteEdict(Handle:timer, any:entity)
{
	if (IsValidEdict(entity))RemoveEdict(entity);
	return Plugin_Stop;
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
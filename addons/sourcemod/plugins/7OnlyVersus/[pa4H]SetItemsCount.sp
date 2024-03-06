#include <sourcemod>
#include <left4dhooks> 
#include <sdktools>
#include <sdkhooks>

//char DropLP[PLATFORM_MAX_PATH]; // debug

float SurvivorStart[3]; // Координаты первого saferoom
int medkitsIndex[5]; // Номера аптечек в списке entity

public Plugin myinfo = 
{
	name = "SetItemsCount", 
	author = "pa4H, Crimson_Fox", 
	description = "", 
	version = "2.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	RegAdminCmd("sm_itemcount", printItemCount, ADMFLAG_BAN, "");
	
	HookEvent("versus_round_start", clearEvent);
	
	//BuildPath(Path_SM, DropLP, sizeof(DropLP), "logs/SetItemCount.log"); // debug
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}

public void clearEvent(Event hEvent, const char[] sEvName, bool bDontBroadcast) // Срабатывает после выхода из saferoom
{
	if (!isVersus()) { return; }
	findSurvivorStart(); // Получаем координаты 1 убеги
	getMedkitsIndexes();
	bool isFinalMap = L4D_IsMissionFinalMap();
	char eName[64];
	int pill, med, adr, pipe, molot, defib, vomit, ince, expl;
	int mi = 0; // Для пропуска medkit'ов в убеге
	for (int i = 1; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, eName, sizeof eName);
			if (strcmp(eName, "weapon_first_aid_kit_spawn") == 0) {
				if (mi < 4 && medkitsIndex[mi] == i) { mi++; } // В medkitsIndex записаны индексы медиков из saferoom'a. Если индекс совпадает, то оставляем ничего не делаем
				else
				{
					med++;
					if (!isFinalMap) {
						if (med > 2) {
							AcceptEntityInput(i, "Kill"); RemoveEdict(i);
							//LogToFileEx(DropLP, "med: %i MEDKIT, ent: %i", med, i); // debug
						}
					}
					else // Если последняя карта
					{
						if (med > 4) {
							AcceptEntityInput(i, "Kill"); RemoveEdict(i);
						}
					}
				}
			}
			if (strcmp(eName, "weapon_pain_pills_spawn") == 0) {
				pill++;
				if (pill > 4) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_adrenaline_spawn") == 0) {
				adr++;
				if (adr > 2) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_defibrillator_spawn") == 0) {
				defib++;
				if (defib > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			
			if (strcmp(eName, "weapon_vomitjar_spawn") == 0) {
				vomit++;
				if (vomit > 2) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_molotov_spawn") == 0) {
				molot++;
				if (molot > 2) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_pipe_bomb_spawn") == 0) {
				pipe++;
				if (pipe > 4) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			
			if (strcmp(eName, "weapon_upgradepack_incendiary_spawn") == 0) {
				ince++;
				if (ince > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
			if (strcmp(eName, "weapon_upgradepack_explosive_spawn") == 0) {
				expl++;
				if (expl > 1) {
					AcceptEntityInput(i, "Kill"); RemoveEdict(i);
				}
			}
		}
	}
}

stock bool isVersus()
{
	char CurrentGameMode[30];
	ConVar mp_gamemode = FindConVar("mp_gamemode");
	mp_gamemode.GetString(CurrentGameMode, sizeof(CurrentGameMode));
	delete mp_gamemode;
	if (strcmp(CurrentGameMode, "versus") == 0) {
		return true;
	}
	return false;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

void findSurvivorStart() // by Crimson_Fox
{
	char EdictClassName[128];
	float Location[3];
	//Search entities for either a locked saferoom door,
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if ((StrContains(EdictClassName, "prop_door_rotating_checkpoint", false) != -1) && (GetEntProp(i, Prop_Send, "m_bLocked") == 1))
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				SurvivorStart = Location;
				return;
			}
		}
	}
	//or a survivor start point.
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "info_survivor_position", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				SurvivorStart = Location;
				return;
			}
		}
	}
}
void getMedkitsIndexes() // by Crimson_Fox
{
	char EdictClassName[128];
	float NearestMedkit[3];
	float Location[3];
	//Look for the nearest medkit from where the survivors start,
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				//If NearestMedkit is zero, then this must be the first medkit we found.
				if ((NearestMedkit[0] + NearestMedkit[1] + NearestMedkit[2]) == 0.0) {
					NearestMedkit = Location;
					continue;
				}
				//If this medkit is closer than the last medkit, record its location.
				if (GetVectorDistance(SurvivorStart, Location, false) < GetVectorDistance(SurvivorStart, NearestMedkit, false)) {
					NearestMedkit = Location;
				}
			}
		}
	}
	//then replace the medkits near it with pain pills.
	int ii = 0;
	for (new i = 0; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEdictClassname(i, EdictClassName, sizeof(EdictClassName));
			if (StrContains(EdictClassName, "weapon_first_aid_kit", false) != -1)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
				if (GetVectorDistance(NearestMedkit, Location, false) < 400)
				{
					if (ii < 5)
					{
						medkitsIndex[ii] = i;
						ii++;
					}
				}
			}
		}
	}
}

stock Action printItemCount(int client, int args)
{
	char eName[64];
	int pill, med, adr, pipe, molot, defib, vomit, ince, expl;
	for (int i = 1; i <= GetEntityCount(); i++)
	{
		if (IsValidEntity(i))
		{
			GetEntityClassname(i, eName, sizeof eName);
			if (strcmp(eName, "weapon_first_aid_kit_spawn") == 0) {
				med++;
			}
			if (strcmp(eName, "weapon_pain_pills_spawn") == 0) {
				pill++;
			}
			if (strcmp(eName, "weapon_adrenaline_spawn") == 0) {
				adr++;
			}
			if (strcmp(eName, "weapon_defibrillator_spawn") == 0) {
				defib++;
			}
			
			if (strcmp(eName, "weapon_vomitjar_spawn") == 0) {
				vomit++;
			}
			if (strcmp(eName, "weapon_molotov_spawn") == 0) {
				molot++;
			}
			if (strcmp(eName, "weapon_pipe_bomb_spawn") == 0) {
				pipe++;
			}
			
			if (strcmp(eName, "weapon_upgradepack_incendiary_spawn") == 0) {
				ince++;
			}
			if (strcmp(eName, "weapon_upgradepack_explosive_spawn") == 0) {
				expl++;
			}
		}
	}
	PrintToChat(client, "Incendiary: %i", ince); PrintToChat(client, "Explosive: %i", expl); PrintToChat(client, "Pipe: %i", pipe); PrintToChat(client, "Molotov: %i", molot); PrintToChat(client, "Vomit: %i", vomit); PrintToChat(client, "Pills: %i", pill); PrintToChat(client, "Adrenaline: %i", adr); PrintToChat(client, "Medkit: %i", med); PrintToChat(client, "Defib: %i", defib);
	return Plugin_Handled;
}
/*stock void Event_CommonDeath(Event event, const char[] name, bool dontBroadcast) // Common
{
	int score; // Количество очков, которые будут начислены игроку
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	
	if (!IsValidClient(killer)) { return; }
	
	if (GetClientTeam(killer) == L4D_TEAM_SURVIVOR)
	{
		score += 1;
		if (event.GetBool("headshot"))
		{
			score *= 2;
		}
	}
	points[killer] += score;
}*/
void saveInfectedDamage()
{
	int infDmg;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == TEAM_INFECTED)
		{
			infDmg = GetEntProp(i, Prop_Send, "m_checkpointSurvivorDamage");
			if (infDmg >= 300) {
				points[i] += 30;
			}
			//PrintToChatAll("infdmg: %i", infDmg); // debug
		}
	}
}
public void Event_PourCompleted(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	points[client] += 1;
	//PrintToChatAll("c: %i can poured", client); // debug
}
void Event_Throwable(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int weaponid = event.GetInt("weaponid");
	if (weaponid == 14 || weaponid == 25) // pipe || vomit
	{
		points[client] += 1;
		//PrintToChatAll("c: %i pipeORvomit", client); // debug
	}
}
void Event_MolotovThrown(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	//if (client == 0) {        return;}
	points[client] += 1;
	//PrintToChatAll("c: %i molotov", client); // debug
}
public void Event_Incapped(Event event, const char[] name, bool dontBroadcast)
{
	//int victim = GetClientOfUserId(event.GetInt("userid"));
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(killer) || GetClientTeam(killer) == L4D_TEAM_SURVIVOR) { return; }
	
	points[killer] += 5;
	//PrintToChatAll("killer: %i incap", killer); // debug
}
public WitchHurt_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int ent = GetEventInt(event, "entityid");
	if (IsWitch(ent))
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if (IsValidClient(attacker) && GetClientTeam(attacker) == L4D_TEAM_SURVIVOR)
		{
			witchDamage[attacker] += GetEventInt(event, "amount");
		}
	}
}
public WitchDeath_Event(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == L4D_TEAM_SURVIVOR)
		{
			if (witchDamage[i] > 800) {
				points[i] += 15;
			}
			//PrintToChatAll("c:%i witch %i", i, witchDamage[i]); // debug
		}
	}
	ClearWitchDamage();
}
public Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if (!tankIsAlive) { return; }
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass"); // Smoker 1, Boomer 2, Hunter 3, Spitter 4, Jockey 5, Charger 6, Witch 7, Tank 8
	
	if (attacker == 0 || victim == 0 || zClass != 8 || !IsClientInGame(attacker) || GetClientTeam(attacker) != L4D_TEAM_SURVIVOR) { return; }
	
	tankDamage[attacker] += GetEventInt(event, "dmg_health");
}
public Event_TankSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	tankIsAlive = true;
	//PrintToChatAll("tank spawned"); // debug
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int score; // Количество очков, которые будут начислены игроку
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	
	//PrintToChatAll("v:%i k:%i",victim, killer); // debug
	if (victim != 0 && killer != 0)
	{
		if (GetClientTeam(victim) == TEAM_INFECTED && GetClientTeam(killer) != TEAM_INFECTED) // Infected is dead
		{
			int zClass = GetEntProp(victim, Prop_Send, "m_zombieClass"); // Smoker 1, Boomer 2, Hunter 3, Spitter 4, Jockey 5, Charger 6, Witch 7, Tank 8
			if (zClass < 7)
			{
				score += 1;
				if (event.GetBool("headshot"))
				{
					headshotCount[killer] += 1;
					score *= 2;
					//PrintToChatAll("head %i", zClass); // debug
				}
				points[killer] += score;
				specKills[killer] += 1;
			}
			if (zClass == 8) // Tank
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && GetClientTeam(i) == L4D_TEAM_SURVIVOR)
					{
						if (tankDamage[i] > 4000) {
							points[i] += tankDamage[i] / 256;
						}
						//PrintToChatAll("c:%i tank:%i", i, tankDamage[i]);
					}
				}
				ClearTankDamage();
				//PrintToChatAll("tank death"); // debug
			}
			//PrintToChatAll("dead %i", zClass); // debug
			//PrintToChatAll("attacker: %i zClass: %i", event.GetInt("attacker"), zClass); // debug
		}
		if (GetClientTeam(victim) == L4D_TEAM_SURVIVOR && GetClientTeam(killer) != L4D_TEAM_SURVIVOR) // Survivor is dead
		{
			points[killer] += 50;
			//PrintToChatAll("survDead killer: %i, sur: %i", killer, victim); // debug
		}
	}
}

public Native_Gaylike(Handle plugin, int numParams)
{
	if (!IsValidClient(GetNativeCell(1))) { return false; }
	points[GetNativeCell(1)] += 50;
	gaylikeRank[GetNativeCell(1)] += 1;
}
public Native_dKills(Handle plugin, int numParams)
{
	if (!IsValidClient(GetNativeCell(1))) { return false; }
	points[GetNativeCell(1)] += 2;
	dKills[GetNativeCell(1)] += 1;
}
public Native_tKills(Handle plugin, int numParams)
{
	if (!IsValidClient(GetNativeCell(1))) { return false; }
	points[GetNativeCell(1)] += 10;
	tKills[GetNativeCell(1)] += 1;
}
public Native_mKills(Handle plugin, int numParams)
{
	if (!IsValidClient(GetNativeCell(1))) { return false; }
	points[GetNativeCell(1)] += 15;
	mKills[GetNativeCell(1)] += 1;
}

// SkillDetect.smx
public OnSkeet(survivor, hunter)
{
	if (!IsValidClient(survivor) || !IsValidClient(hunter)) { return; }
	points[survivor] += 10;
	hunterSkeet[survivor] += 1;
	//PrintToChatAll("c: %i, HuntSkeet", survivor); // debug
}
public OnSkeetMelee(survivor, hunter)
{
	if (!IsValidClient(survivor) || !IsValidClient(hunter)) { return; }
	points[survivor] += 20;
	hunterMelee[survivor] += 1;
	//PrintToChatAll("c: %i, HuntSkeetMelee", survivor); // debug
}
public OnChargerLevel(survivor, charger)
{
	if (!IsValidClient(survivor) || !IsValidClient(charger)) { return; }
	points[survivor] += 15;
	chargerMelee[survivor] += 1;
	//PrintToChatAll("c: %i, CharLevel", survivor); // debug
}
public OnTongueCut(survivor, smoker)
{
	if (!IsValidClient(survivor) || !IsValidClient(smoker)) { return; }
	points[survivor] += 5;
	tongueClear[survivor] += 1;
	//PrintToChatAll("c: %i, TongCut", survivor); // debug
}
public OnTankRockSkeeted(survivor, tank)
{
	if (!IsValidClient(survivor) || !IsValidClient(tank)) { return; }
	points[survivor] += 3;
	rockSkeet[survivor] += 1;
	//PrintToChatAll("c: %i, RockSkeet", survivor); // debug
}
public OnTankRockEaten(tank, survivor)
{
	if (!IsValidClient(tank) || !IsValidClient(survivor)) { return; }
	if (IsValidClient(tank)) {
		points[tank] += 5;
		rockHit[tank] += 1;
		//PrintToChatAll("c: %i, RockEat", tank); // debug
	}
}
public OnHunterHighPounce(hunter, survivor, actualDamage, float calculatedDamage, float height, bool bReportedHigh)
{
	if (!IsValidClient(hunter) || !IsValidClient(survivor)) { return; }
	if (actualDamage > 19) {
		points[hunter] += actualDamage / 8;
	}
	hunterJump[hunter] += 1;
	//PrintToChatAll("c: %i, hunt25: %i", hunter, actualDamage / 2); // debug
}
public OnBoomerVomitLanded(boomer, amount) // Full заблев
{
	if (!IsValidClient(boomer)) { return; }
	boomerVomit[boomer] += amount;
	if (amount == 4)
	{
		points[boomer] += 10;
		//PrintToChatAll("c: %i, FullVomit", boomer); // debug
	}
}
public OnBunnyHopStreak(survivor, streak, float maxVelocity)
{
	if (!IsValidClient(survivor)) { return; }
	if (streak < 3 || maxVelocity < 200) { return; }
	points[survivor] += streak;
	bhopCount[survivor] += streak;
	
	//PrintToChatAll("c: %i, bhop: %i", survivor, streak * 4); // debug
	//CPrintToChatAll("{green}★★ %N {default} done {olive}%d {default}bunnyhops in a streak. Max velocity: {olive}%.01f{default}.", survivor, streak, maxVelocity);
} 
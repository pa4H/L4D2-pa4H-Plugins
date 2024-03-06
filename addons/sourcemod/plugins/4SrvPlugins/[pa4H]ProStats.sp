#include <sourcemod>
#include <sdktools>
#include <left4dhooks> // https://forums.alliedmods.net/showthread.php?t=321696
#include <l4d2_skill_detect>
#include <colors>
#include <geoip>
#include <ripext>

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

char txtBufer[256];
//char logFile[64];

Database db;
char dbQuery[256];

// PlayTime
Handle ClientTimer[MAXPLAYERS + 1];
int Minutes[MAXPLAYERS + 1]; // Наиграно времени всего
int MinutesSession[MAXPLAYERS + 1]; // Наиграно за сессию

// Score system
int points[MAXPLAYERS + 1]; // Массив для хранения очков игроков
int maxTop; // Последнее место в статистике
// Расширенная статистика
int specKills[MAXPLAYERS + 1];
int bhopCount[MAXPLAYERS + 1];
int hunterSkeet[MAXPLAYERS + 1];
int hunterMelee[MAXPLAYERS + 1];
int chargerMelee[MAXPLAYERS + 1];
int tongueClear[MAXPLAYERS + 1];
int rockSkeet[MAXPLAYERS + 1];
int rockHit[MAXPLAYERS + 1];
int hunterJump[MAXPLAYERS + 1];
int boomerVomit[MAXPLAYERS + 1];
int headshotCount[MAXPLAYERS + 1];
int gaylikeRank[MAXPLAYERS + 1];
int dKills[MAXPLAYERS + 1];
int tKills[MAXPLAYERS + 1];
int mKills[MAXPLAYERS + 1];

// Tank
int tankDamage[MAXPLAYERS + 1]; // Количество урона по Танку
bool tankIsAlive = false;

// Witch
int witchDamage[MAXPLAYERS + 1];

// [pa4H]ConnectAnnounce.sp
char PREFIX[16];
char keyAPI[64]; // Ключ для Steam API
int steamPlayTime[MAXPLAYERS + 1]; // Наигранное время
Handle g_hSteamAPI_Key; // Для работы с sm_cvar SteamAPI_Key

#include "ProStats/func.sp"
#include "ProStats/events.sp"
#include "ProStats/API.sp"

public Plugin myinfo = 
{
	name = "ProStats", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	Database.Connect(SQL_ConnectCallBack, "ProStats");
	
	//RegConsoleCmd("sm_test", testStats, "");
	
	RegConsoleCmd("sm_stats", printStats, "");
	RegConsoleCmd("sm_stat", printStats, "");
	RegConsoleCmd("sm_rank", printStats, "");
	RegConsoleCmd("sm_rang", printStats, "");
	RegConsoleCmd("sm_top", printSite, "");
	RegConsoleCmd("sm_top10", printSite, "");
	RegConsoleCmd("sm_top100", printSite, "");
	
	RegAdminCmd("sm_ban", Command_Ban, ADMFLAG_BAN, "Usage: sm_ban <client> <reason>");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	//HookEvent("infected_death", Event_CommonDeath); // Common zombies
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("gascan_pour_completed", Event_PourCompleted);
	HookEvent("weapon_fire", Event_Throwable);
	HookEvent("molotov_thrown", Event_MolotovThrown);
	HookEvent("player_incapacitated_start", Event_Incapped);
	
	HookEvent("infected_hurt", WitchHurt_Event, EventHookMode_Post);
	HookEvent("witch_killed", WitchDeath_Event, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	
	LoadTranslations("pa4HStats.phrases");
	
	g_hSteamAPI_Key = CreateConVar("SteamAPI_Key", "", "Your SteamAPI Key. Can get it on https://steamcommunity.com/dev/apikey", FCVAR_CHEAT);
	GetConVarString(g_hSteamAPI_Key, keyAPI, sizeof(keyAPI));
	HookConVarChange(g_hSteamAPI_Key, OnConVarChange);
	FormatEx(PREFIX, sizeof(PREFIX), "%t", "PREFIX");
	
	//BuildPath(Path_SM, logFile, 64, "logs/!ProStats.txt");
}
stock Action testStats(int client, int args) // DEBUG
{
	
	return Plugin_Handled;
}

public OnClientAuthorized(client) // Когда игрок только-только подключился к серверу (Загружается)
{
	if (!IsFakeClient(client)) {
		nullVars(client);
		char steamIdClient[64];
		GetClientAuthId(client, AuthId_Steam2, steamIdClient, sizeof(steamIdClient)); // Получаем SteamID64. Мой id: STEAM_0:1:38701092
		FormatEx(dbQuery, sizeof(dbQuery), "SELECT Ban, bReason, jMsg FROM StatsBD WHERE sID='%s'", steamIdClient); // Проверяем есть ли SteamID в базе данных. И получаем значение "Забанен?"
		db.Query(SQL_OnClientAuthorizedCallBack, dbQuery, client);
	}
}
public void OnClientPutInServer(int client) // Игрок загрузился
{
	ClientTimer[client] = (CreateTimer(60.0, TimerAdd, client, TIMER_REPEAT));
	
	char steamIdClient[64];
	GetClientAuthId(client, AuthId_Steam2, steamIdClient, sizeof(steamIdClient));
	FormatEx(dbQuery, sizeof(dbQuery), "SELECT Pos, Exp FROM StatsBD WHERE sID='%s'", steamIdClient);
	db.Query(SQL_OnClientPutInServerCallBack, dbQuery, client);
}

public void OnClientDisconnect(int client)
{
	delete ClientTimer[client];
}
public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast) // https://wiki.alliedmods.net/Generic_Source_Server_Events#player_disconnect
{
	char nick[64]; char reason[128];
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Получаем номер клиента
	if (IsValidClient(client)) {
		MinutesSession[client] = 0;
		saveStats();
		GetEventString(event, "name", nick, sizeof(nick)); // Получаем ник игрока
		GetEventString(event, "reason", reason, sizeof(reason)); // Получаем причину выхода
		ReplaceString(reason, sizeof(reason), ".", "")
		
		CPrintToChatAll("%t", "PlayerDisconnect", PREFIX, nick, reason);
	}
	return Plugin_Handled;
}

int rndEnded = false;
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!rndEnded) // Чтоб два раза не срабатывало
	{
		rndEnded = true;
		saveInfectedDamage();
		saveStats();
		// Делаем сортировку мест игроков
		Transaction hTxn = new Transaction();
		hTxn.AddQuery("SET @c := 0;");
		hTxn.AddQuery("UPDATE `StatsBD` SET `Pos` = (@c := @c + 1) ORDER BY `Exp` DESC;");
		db.Execute(hTxn, SQL_TxnCallback_Success, SQL_TxnCallback_Failure);
	}
	else
	{
		rndEnded = false;
	}
}
public void OnMapEnd() // Требуется, поскольку принудительная смена карты не вызывает событие "round_end"
{
	saveStats();
}

//SQL_CallBack's
public void SQL_OnClientAuthorizedCallBack(Database hDatabase, DBResultSet results, const char[] sError, any client)
{
	if (sError[0]) // Если произошла ошибка
	{
		LogError("SQL_OnClientAuthorizedCallBack: %s", sError);
		return;
	}
	char steamIdClient[64];
	GetClientAuthId(client, AuthId_Steam2, steamIdClient, sizeof(steamIdClient)); // Получаем SteamID64. Мой id: STEAM_0:1:38701092
	int isBanned; char banReason[128]; char joinMessage[128]; char nick[64]; char timeString[32]; char steamId64[64];
	GetClientName(client, nick, sizeof(nick)); // Получаем имя
	
	// No MySQL inject
	ReplaceString(nick, sizeof(nick), "<?php", ""); ReplaceString(nick, sizeof(nick), "<?PHP", ""); ReplaceString(nick, sizeof(nick), "?>", ""); ReplaceString(nick, sizeof(nick), "\\", "");	ReplaceString(nick, sizeof(nick), "\"", ""); ReplaceString(nick, sizeof(nick), "'", ""); ReplaceString(nick, sizeof(nick), ";", ""); ReplaceString(nick, sizeof(nick), "�", ""); ReplaceString(nick, sizeof(nick), "`", "");
	
	FormatTime(timeString, sizeof(timeString), "%d.%m.%Y", GetTime()); // Получаем дату
	
	bool hasData = false; // true - данные есть
	if (results.FetchRow()) // Есть данные игрока в базе
	{
		isBanned = results.FetchInt(0);
		results.FetchString(1, banReason, sizeof(banReason));
		results.FetchString(2, joinMessage, sizeof(joinMessage));
		hasData = true;
	}
	if (!hasData) // Нет данных. Создаем игрока в базе данных
	{
		char Country[4]; char IP[32]; char City[32];
		GetClientIP(client, IP, sizeof(IP), true); // Получаем IP игрока
		if (!GeoipCode3(IP, Country)) {  // Получаем Russia
			Country = "???";
		}
		if (!GeoipCity(IP, City, sizeof(City), -1)) {  // Получаем Barnaul Moscow
			City = "???";
		}
		char CountryAndCity[64];
		FormatEx(CountryAndCity, sizeof(CountryAndCity), "%s, %s", Country, City); // Объединяем страну и город
		ReplaceString(CountryAndCity, sizeof(CountryAndCity), "'", "")
		
		CPrintToChatAll("%t", "NewPlayer", client); // У нас новый игрок!
		
		FormatEx(dbQuery, sizeof(dbQuery), "INSERT INTO `StatsBD` (`sID`, `fJoin`, `From`) VALUES ('%s', '%s', '%s')", steamIdClient, timeString, CountryAndCity);
		db.Query(SQL_QueryCallBack, dbQuery);
	}
	
	// Игрок зашел не первый раз
	FormatEx(dbQuery, sizeof(dbQuery), "UPDATE `StatsBD` SET `Nick` = '%s', `lJoin` = '%s' WHERE `sID` = '%s'", nick, timeString, steamIdClient);
	db.Query(SQL_QueryCallBack, dbQuery);
	
	if (isBanned == 1) {
		if (StrEqual(banReason, "", false)) { FormatEx(banReason, sizeof(banReason), "%t", "UBanned"); } // Выводим дефолтное сообщение о бане
		KickClient(client, banReason);
		CPrintToChatAll("%t", "PlayerBanned", client, banReason);
		return;
	}
	
	if (isAdmin(client)) { return; }
	if (hasData) {  // Если игрок не новый
		if (StrEqual(joinMessage, "", false)) { FormatEx(joinMessage, sizeof(joinMessage), "%t", "PlayerName"); }
		CPrintToChatAll("%t", "PlayerLoading", joinMessage, nick); // "Игрок {2} присоединяется..."  Или  "Долбоеб {2} присоединяется..."
	}
	
	GetClientAuthId(client, AuthId_SteamID64, steamId64, sizeof(steamId64)); // Получаем SteamID64. Мой id: 76561198037667913
	//PrintToServer("STEAMID: %s", steamId64); // debug
	steamPlayTime[client] = 0; // Обнуляем количество часов клиента
	SteamAPI_GetHours(steamId64, client); // Получаем часы. Они будут храниться в массиве teamPlayTime
}


public void SQL_OnClientPutInServerCallBack(Database hDatabase, DBResultSet results, const char[] sError, any client)
{
	int top;
	if (sError[0]) {  // Если произошла ошибка
		LogError("SQL_OnClientPutInServerCallBack: %s", sError);
		return;
	}
	
	if (IsValidClient(client) && isAdmin(client)) { return; }
	
	if (results.FetchRow()) // Есть данные
	{
		top = results.FetchInt(0);
	}
	
	if (IsValidClient(client)) {
		char Name[64]; char Country[4]; char IP[32]; char City[32]; char Hours[8];
		GetClientName(client, Name, sizeof(Name)); // Получаем имя игрока
		GetClientIP(client, IP, sizeof(IP), true); // Получаем IP игрока
		if (!GeoipCode3(IP, Country)) {  // Получаем RUS KAZ USA
			Country = "???"; // Если не удалось получить страну
		}
		if (!GeoipCity(IP, City, sizeof(City), -1)) {  // Получаем Barnaul Moscow
			City = "???";
		}
		
		if (steamPlayTime[client] == 0) {  // 0 - не удалось получить часы
			Hours = "?";
		} else {
			IntToString(steamPlayTime[client], Hours, sizeof(Hours)); // Переводим steamPlayTime в String
		}
		
		if (top == 0) {
			CPrintToChatAll("%t", "PlayerJoin", Name, Country, City, Hours);
		}
		else {
			CPrintToChatAll("%t", "PlayerJoinStats", Name, Country, City, top, Hours);
		}
	}
}

void saveStats()
{
	char steamId[64];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			GetClientAuthId(i, AuthId_Steam2, steamId, sizeof(steamId)); // Получаем SteamID64. Мой id: 76561198037667913
			if (GetOnlineClients() < 2) { points[i] = 0; } // Если на сервере 1 игрок, то обнуляем очки
			if (points[i] != 0) {
				//LogToFileEx(logFile, "%N team: %i | points: %i, spec: %i, bhop: %i, huntS: %i, huntM: %i, char: %i, tong: %i, rock: %i, rockH: %i, hunterJ: %i, boomer: %i, head: %i, gaylike: %i, dK: %i, tK: %i, mK: %i", i, GetClientTeam(i), points[i], specKills[i], bhopCount[i], hunterSkeet[i], hunterMelee[i], chargerMelee[i], tongueClear[i], rockSkeet[i], rockHit[i], hunterJump[i], boomerVomit[i], headshotCount[i], gaylikeRank[i], dKills[i], tKills[i], mKills[i]);
				MySQLsave_Stats(steamId, points[i], Minutes[i], specKills[i], bhopCount[i], hunterSkeet[i], hunterMelee[i], chargerMelee[i], tongueClear[i], rockSkeet[i], rockHit[i], hunterJump[i], boomerVomit[i], headshotCount[i], gaylikeRank[i], dKills[i], tKills[i], mKills[i]);
			}
			else {
				MySQLsave_Minutes(steamId, Minutes[i]);
			}
		}
		nullVars(i);
	}
}
void MySQLsave_Stats(char[] steamId, int point, int mins, int spec, int bhop, int hSkeet, int hMelee, int cMelee, int tClear, int rSkeet, int rHit, int hJump, int bVomit, int headshot, int gaylike, int dKill, int tKill, int mKill)
{
	char dbQueryBig[1024];
	FormatEx(dbQueryBig, sizeof(dbQueryBig), "UPDATE `StatsBD` SET `Exp` = `Exp` + '%i', `pTime` = `pTime` + '%i', `tKills` = `tKills` + '%i', `Bhop` = `Bhop` + '%i', `Skeet` = `Skeet` + '%i', `SkMelee` = `SkMelee` + '%i', `ChrgLvl` = `ChrgLvl` + '%i', `TngCut` = `TngCut` + '%i', `RckSk` = `RckSk` + '%i', `RckHit` = `RckHit` + '%i', `HuPnce` = `HuPnce` + '%i', `Vomit` = `Vomit` + '%i', `HeadSh` = `HeadSh` + '%i', `gLike` = `gLike` + '%i', `dKill` =  `dKill` + '%i', `trKill` = `trKill` + '%i', `mKill` = `mKill` + '%i' WHERE `sID` = '%s'", point, mins, spec, bhop, hSkeet, hMelee, cMelee, tClear, rSkeet, rHit, hJump, bVomit, headshot, gaylike, dKill, tKill, mKill, steamId);
	db.Query(SQL_QueryCallBack, dbQueryBig);
}
void MySQLsave_Minutes(char[] steamId, int mins)
{
	FormatEx(dbQuery, sizeof(dbQuery), "UPDATE `StatsBD` SET `pTime` = `pTime` + '%i'  WHERE `sID` = '%s'", mins, steamId);
	db.Query(SQL_QueryCallBack, dbQuery);
}
public Action TimerAdd(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		Minutes[client]++;
		MinutesSession[client]++;
	}
	return Plugin_Continue;
}

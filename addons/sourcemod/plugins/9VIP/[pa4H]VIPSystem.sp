#include <sourcemod>
#include <colors>
#include <sdkhooks>
#include <sdktools>
#include <DateTime>

bool VIPPlayers[MAXPLAYERS + 1];
Database db;
char dbQuery[256];

char prefix[32][32]; // [sizeof][maxclients]

#include "VIPSystem/otherCMD.sp"
#include "VIPSystem/features.sp"
#include "VIPSystem/API.sp"
#include "VIPSystem/prefix.sp"

public Plugin myinfo = 
{
	name = "VIP-System", 
	author = "pa4H", 
	description = " ", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	Database.Connect(SQL_ConnectCallBack, "ProStats");
	
	//RegAdminCmd("sm_test", testVIP, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_vip", showVIPhelp, "");
	RegConsoleCmd("sm_verify", verifySteam, "");
	
	RegAdminCmd("sm_givevip", giveVIP, ADMFLAG_BAN);
	RegAdminCmd("sm_showvip", showVIPs, ADMFLAG_BAN);
	RegAdminCmd("sm_vipshow", showVIPs, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_hat", setHat, "");
	RegConsoleCmd("sm_hats", setHat, "");
	RegConsoleCmd("sm_light", setLight, "");
	RegConsoleCmd("sm_pickbot", pickBot, "");
	
	RegConsoleCmd("sm_prefix", setPrefix, "");
	RegConsoleCmd("sm_delprefix", deletePrefix, "");
	
	HookEvent("versus_round_start", RoundStartPills);
	AddCommandListener(say, "say");
	AddCommandListener(say, "say_team");
	
	LoadTranslations("pa4HVIP.phrases");
}

stock Action testVIP(int client, int args)
{
	//OnClientPostAdminCheck(client);
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client) // Игрок загрузился
{
	if (!IsValidClient(client)) { return; }
	char steamIdClient[64];
	GetClientAuthId(client, AuthId_Steam2, steamIdClient, sizeof(steamIdClient));
	
	checkPrefix(client, steamIdClient);
	
	VIPPlayers[client] = false;
	FormatEx(dbQuery, sizeof(dbQuery), "SELECT `isVIP`, `toDate` FROM `VIPplayers` WHERE `SteamID`='%s'", steamIdClient);
	db.Query(SQL_OnClientPostAdminCheckCallBack, dbQuery, client);
}
public void SQL_OnClientPostAdminCheckCallBack(Database hDatabase, DBResultSet results, const char[] sError, any client)
{
	if (sError[0]) {  // Если произошла ошибка
		LogError("SQL_OnClientPostAdminCheckCallBack: %s", sError);
		return;
	}
	
	int isVIP = 0;
	char toDate[12];
	if (results.FetchRow()) // Есть данные
	{
		isVIP = results.FetchInt(0);
		results.FetchString(1, toDate, sizeof(toDate));
	}
	if (isVIP == 1) {
		if (checkDate(toDate))
		{
			VIPPlayers[client] = true;
			DataPack hPack = new DataPack();
			hPack.WriteCell(client);
			hPack.WriteString(toDate);
			CreateTimer(8.0, Timer_HelloVIP, hPack, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {
			CreateTimer(8.0, Timer_VIPisEnd, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action verifySteam(int client, int args)
{
	if (args != 1)
	{
		CPrintToChat(client, "%t", "argVerify");
		return Plugin_Handled;
	}
	
	int arg1 = GetCmdArgInt(1);
	
	char steamIdClient[64];
	GetClientAuthId(client, AuthId_Steam2, steamIdClient, sizeof(steamIdClient));
	
	DataPack hPack = new DataPack();
	hPack.WriteCell(client);
	hPack.WriteCell(arg1);
	hPack.WriteString(steamIdClient);
	
	FormatEx(dbQuery, sizeof(dbQuery), "SELECT `VerifyCode`, `Free` FROM `VIPplayers` WHERE `VerifyCode`='%i'", arg1);
	db.Query(SQL_VerifySteamCallBack, dbQuery, hPack);
	return Plugin_Handled;
}
public void SQL_VerifySteamCallBack(Database hDatabase, DBResultSet results, const char[] sError, any data)
{
	if (sError[0]) {  // Если произошла ошибка
		LogError("SQL_VerifySteamCallBack: %s", sError);
		return;
	}
	
	DataPack hPack = view_as<DataPack>(data);
	hPack.Reset();
	int client = hPack.ReadCell();
	int verifyCodeUser = hPack.ReadCell();
	char steamID[256];
	hPack.ReadString(steamID, sizeof(steamID));
	delete hPack;
	
	
	int verifyCode = 0;
	int isFree = 0;
	if (results.FetchRow()) {  // Есть данные
		verifyCode = results.FetchInt(0);
		isFree = results.FetchInt(1);
	}
	
	if (isFree == 1) {
		CPrintToChat(client, "%t", "errFree");
		return;
	}
	
	if (verifyCode != verifyCodeUser) {
		CPrintToChat(client, "%t", "errVerify");
	}
	else {
		char toDate[16]; DateTime dt = new DateTime(DateTime_Now);
		dt += TimeSpan.FromDays(14); // Добавляем две недели
		int day = dt.Day; int month = dt.Month; int year = dt.Year;
		FormatEx(toDate, sizeof(toDate), "%i.%i.%i", day, month, year);
		
		VIPPlayers[client] = true; // Делаем ВИПом
		FormatEx(dbQuery, sizeof(dbQuery), "UPDATE `VIPplayers` SET `VerifyCode` = 0, isVIP = '1', `SteamID` = '%s', `toDate` = '%s', `Free` = '1' WHERE `VerifyCode`='%i'", steamID, toDate, verifyCode);
		CPrintToChat(client, "%t", "okVerifyTemp");
		
		db.Query(SQL_QueryCallBack, dbQuery);
	}
}

public void SQL_QueryCallBack(Database hDatabase, DBResultSet results, const char[] sError, any data)
{
	if (sError[0]) // Если произошла ошибка
	{
		LogError("SQL_QueryCallBack: %s", sError);
		return;
	}
}
stock Action showVIPhelp(int client, int args)
{
	Panel hPanel = new Panel();
	if (VIPPlayers[client])
	{
		hPanel.SetTitle("Здравствуйте!");
		hPanel.DrawText(" ");
		hPanel.DrawText("Вам доступны следующие команды:");
		hPanel.DrawText("!awp !laser !hat !light !pickbot !t2 !magnum");
		hPanel.DrawText(" ");
		hPanel.DrawText("В начале каждого раунда\nвам выдаются таблетки и пайпа.");
		hPanel.DrawText("Вы можете выбирать зараженного правой кнопкой мыши.");
		hPanel.DrawText(" ");
		hPanel.DrawText("Для установки префикса, напишите: !prefix ваш_префикс");
		hPanel.DrawItem("Х");
	}
	else {
		hPanel.SetTitle("Для получения VIP посетите наш сервер Discord");
		hPanel.DrawText("!discord");
		hPanel.DrawText(" ");
		hPanel.DrawText("VIP игрокам доступны следующие команды:");
		hPanel.DrawText("!awp !laser !hat !light !pickbot !t2 !magnum");
		hPanel.DrawText(" ");
		hPanel.DrawText("Перед началом каждого раунда\nVIP'ам выдаются таблетки и пайпа.");
		hPanel.DrawText("VIP'ы могут выбирать зараженного правой кнопкой мыши.");
		hPanel.DrawText("Так же можно установить уникальный префикс.");
		hPanel.DrawItem("Х");
	}
	hPanel.Send(client, MenuHandler_MyPanel, 10);
	return Plugin_Handled;
}
stock Action giveVIP(int client, int args) // For admin
{
	VIPPlayers[client] = true;
	return Plugin_Handled;
}
Action showVIPs(int client, int args) // For admin
{
	char nick[64];
	Panel hPanel = new Panel();
	hPanel.SetTitle("Список VIP'ов:");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (VIPPlayers[i]) { FormatEx(nick, sizeof(nick), "%N", i); hPanel.DrawText(nick); }
	}
	hPanel.Send(client, MenuHandler_MyPanel, 10);
	return Plugin_Handled;
} 
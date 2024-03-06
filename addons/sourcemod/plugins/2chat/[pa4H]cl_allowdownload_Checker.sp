#include <sourcemod>
bool df[MAXPLAYERS + 1];
bool ad[MAXPLAYERS + 1];
bool au[MAXPLAYERS + 1];

//char logFile[64];
//{"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
//{"\x01", 		"\x04",    "\x03", 		   "\x03",  "\x03",   "\x05"};

public Plugin myinfo = 
{
	name = "cl_allowdownload Checker", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "vk.com/pa4h1337"
}
public OnPluginStart()
{
	//RegConsoleCmd("sm_cvarTest", debb, "");
	//BuildPath(Path_SM, logFile, 64, "logs/!cl_allowdownload.txt");
}
/*
public Action debb(int client, int args) // DEBUG
{
	CreateTimer(1.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
	QueryClientConVar(client, "cl_downloadfilter", check_DownloadFilter); // Проверяем значение данных кваров у клиента
	QueryClientConVar(client, "cl_allowdownload", check_AllowDownload);
	QueryClientConVar(client, "cl_allowupload", check_AllowUpload);
	return Plugin_Handled;
}
*/
public OnClientPutInServer(client)
{
	if (IsValidClient(client))
	{
		CreateTimer(5.0, Timer_Welcome, client);
		QueryClientConVar(client, "cl_downloadfilter", check_DownloadFilter); // Проверяем значение данных кваров у клиента
		QueryClientConVar(client, "cl_allowdownload", check_AllowDownload);
		QueryClientConVar(client, "cl_allowupload", check_AllowUpload);
	}
}

public void check_DownloadFilter(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (cvarValue[0] != 'a') { df[client] = true; } // Если значение этого квара не равно all (all, none, nosounds)
	//PrintToChat(client, cvarValue[0]);
}
public void check_AllowDownload(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (cvarValue[0] == '0') { ad[client] = true; } // Если значение этого квара не равно 1
	//PrintToChat(client, cvarValue[0]);
}
public void check_AllowUpload(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any value)
{
	if (cvarValue[0] == '0') { au[client] = true; }
	//PrintToChat(client, cvarValue[0]);
}

public Action Timer_Welcome(Handle hTimer, any client) // Каллбек нашего таймера
{
	if (IsClientInGame(client))
	{
		if (df[client] || ad[client] || au[client])
		{
			PrintCenterText(client, "Читай чат");
			PrintToChat(client, "У тебя отключено скачивание звуков. Введи следующие команды в консоль:");
			PrintHintText(client, "Читай чат");
			//LogToFileEx(logFile, "%N | downloadfilter: %b, allowdownload: %b, allowupload: %b", client, df[client], ad[client], au[client]);
		}
		if (df[client]) // Да-да. Я знаю, что использовать switch лучше. Но я же не микроконтроллер программирую)
		{
			PrintToChat(client, "\x04cl_downloadfilter\x03 all");
		}
		if (ad[client])
		{
			PrintToChat(client, "\x04cl_allowdownload\x03 1");
		}
		if (au[client])
		{
			PrintToChat(client, "\x04cl_allowupload\x03 1");
		}
	}
	df[client] = false;
	ad[client] = false;
	au[client] = false;
	return Plugin_Stop;
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		df[i] = false;
		ad[i] = false;
		au[i] = false;
	}
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
} 
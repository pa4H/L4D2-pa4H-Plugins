/*
	OnClientPostAdminCheck -> Если !showMessage, то показываем сообщение и делаем showMessage=true
	В следующий OnClientPostAdminCheck сообщение не показывается
	PlayerDisconnect_Event только когда юзер сам выходит из игры -> showMessage=false
*/
#include <sourcemod>
bool showMessage[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Welcome Message", 
	author = "pa4H", 
	description = "Display simple welcome msg", 
	version = "", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
}

stock Action debb(int client, int args) // DEBUG
{
	
	return Plugin_Handled;
}
public OnClientPostAdminCheck(client)
{
	if (IsFakeClient(client)) { return; }
	if (!showMessage[client]) {
		showMessage[client] = true;
		CreateTimer(5.0, Timer_Welcome, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}
public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	showMessage[client] = false;
	return Plugin_Handled;
}

public Action Timer_Welcome(Handle hTimer, any client)
{
	if (IsClientInGame(client))
	{
		if (GetClientLanguage(client) == 22) // Russian lang
		{
			PrintToChat(client, "\x04Приветствуем на сервере \x03PEZDOX");
			PrintToChat(client, "\x01Доступны команды: \x04!w !afk !kickspec !kill !killbots");
			PrintToChat(client, "\x04!sounds \x01— панель со звуками");
			PrintToChat(client, "\x04Правила \x01и полный список \x04команд \x01в \x03Дискорде:");
			PrintToChat(client, "\x03!discord - напиши в чат, для получения ссылки.");
		}
		else // Another lang 
		{
			PrintToChat(client, "\x04Welcome to \x03PEZDOX \x04 server");
			PrintToChat(client, "\x01Available commands: \x04!w !afk !kickspec !kill !killbots");
			PrintToChat(client, "\x04!sounds \x01— soundpanel");
			PrintToChat(client, "\x04Rules \x01and \x04list of commands \x01in our \x03Discord:");
			PrintToChat(client, "\x03!discord - write in chat, to get link.");
		}
	}
	return Plugin_Stop;
} 
#include <sourcemod>
#include <colors>

public Plugin myinfo = 
{
	name = "[pa4H]Help", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_help", showHelp, "");
	RegConsoleCmd("sm_settings", showHelp, "");
	RegConsoleCmd("sm_info", showHelp, "");
	
	RegConsoleCmd("sm_discord", showDiscord, "");
	RegConsoleCmd("sm_ds", showDiscord, "");
	RegConsoleCmd("sm_vk", showVK, "");
	RegConsoleCmd("sm_telega", showTelegram, "");
	RegConsoleCmd("sm_telegram", showTelegram, "");
	RegConsoleCmd("sm_tg", showTelegram, "");
	RegConsoleCmd("sm_site", showSite, "");
	RegConsoleCmd("sm_steam", showSteam, "");
	
	RegConsoleCmd("sm_report", showReport, "");
	RegConsoleCmd("sm_rep", showReport, "");
	
	RegConsoleCmd("sm_ip", showServers, "");
	RegConsoleCmd("sm_server", showServers, "");
	RegConsoleCmd("sm_servers", showServers, "");
	RegConsoleCmd("sm_versus", showServers, "");
	RegConsoleCmd("sm_parkour", showServers, "");
	RegConsoleCmd("sm_parkur", showServers, "");
	RegConsoleCmd("sm_scavenge", showServers, "");
	RegConsoleCmd("sm_sbor", showServers, "");
	
	LoadTranslations("pa4HHelp.phrases");
}
stock Action debb(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
Action showServers(int client, int args)
{
	CPrintToChat(client, "%T", "IPv", client);
	CPrintToChat(client, "%T", "IPo", client);
	return Plugin_Handled;
}
Action showHelp(int client, int args)
{
	Panel hPanel = new Panel();
	hPanel.SetTitle("Вся актуальная информация, правила, список команд\nна сервере Discord. Напиши в чат !ds");
	hPanel.DrawText(" ");
	hPanel.DrawText("Статистика и баны на сайте pa4h.ru");
	hPanel.DrawText(" ");
	hPanel.DrawText("Группа в Steam. Напиши в чат !steam");
	hPanel.DrawText("Чтобы узнать IP сервера, напиши в чат !ip");
	hPanel.Send(client, MenuHandler_MyPanel, 100);
	return Plugin_Handled;
}
public MenuHandler_MyPanel(Handle panel, MenuAction action, client, option) {
	/*if (action == MenuAction_Select) { PrintToChat(client, "Номер выбранной опции: %d", option); }*/
}
Action showDiscord(int client, int args)
{
	CPrintToChat(client, "%T", "Discord", client);
	return Plugin_Handled;
}
Action showVK(int client, int args)
{
	CPrintToChat(client, "%T", "VK", client);
	return Plugin_Handled;
}
Action showTelegram(int client, int args)
{
	CPrintToChat(client, "%T", "Telegram", client);
	return Plugin_Handled;
}
Action showSite(int client, int args)
{
	CPrintToChat(client, "%T", "Site", client);
	return Plugin_Handled;
}
Action showSteam(int client, int args)
{
	CPrintToChat(client, "%T", "Steam", client);
	return Plugin_Handled;
}
Action showReport(int client, int args)
{
	CPrintToChat(client, "%T", "Report", client);
	return Plugin_Handled;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
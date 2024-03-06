public Action Command_Ban(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ban <client> <reason>");
		return Plugin_Handled;
	}
	
	char steamID[64];
	char banReason[128];
	GetCmdArg(1, steamID, sizeof(steamID));
	GetCmdArg(2, banReason, sizeof(banReason));
	int cli = StringToInt(steamID);
	GetClientAuthId(cli, AuthId_Steam2, steamID, sizeof(steamID));
	
	FormatEx(dbQuery, sizeof(dbQuery), "UPDATE `StatsBD` SET `Ban` = '1', `bReason` = '%s' WHERE `sID` = '%s'", banReason, steamID);
	db.Query(SQL_QueryCallBack, dbQuery);
	
	//LogToFileEx(logFile, "Banned: %N %s %s", cli, steamID, banReason);
	
	FormatEx(banReason, sizeof(banReason), "%t", "UBanned");
	KickClient(cli, banReason);
	CPrintToChatAll("%t", "OnBan", cli);
	
	return Plugin_Handled;
}
public Action printStats(client, args)
{
	Panel hPanel = new Panel();
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "StatLoading", client);
	hPanel.SetTitle(txtBufer);
	hPanel.Send(client, MenuHandler_MyPanel, 20);
	delete hPanel;
	
	// Получаем последнее место
	FormatEx(dbQuery, sizeof(dbQuery), "SELECT Pos FROM StatsBD ORDER BY Pos DESC LIMIT 1");
	db.Query(SQL_Event_RoundEnd, dbQuery);
	
	char steamIdClient[64];
	GetClientAuthId(client, AuthId_Steam2, steamIdClient, sizeof(steamIdClient));
	FormatEx(dbQuery, sizeof(dbQuery), "SELECT pTime, Pos, Exp FROM StatsBD WHERE sID='%s'", steamIdClient);
	db.Query(SQL_StatsCallBack, dbQuery, client);
	
	/*
	PrintToChatAll("STATS:");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			PrintToChatAll("c:%i %N [%i]", i, i, points[i]);
		}
	}*/
	//saveStats();
	return Plugin_Handled;
}
public void SQL_Event_RoundEnd(Database hDatabase, DBResultSet results, const char[] sError, any client)
{
	if (sError[0]) // Если произошла ошибка
	{
		LogError("SQL_Event_RoundEnd: %s", sError);
		return;
	}
	if (results.FetchRow())
	{
		maxTop = results.FetchInt(0); // Получаем последнее место
	}
}
public Action printSite(client, args)
{
	Panel hPanel = new Panel();
	hPanel.SetTitle("Статистика, баны, топы на сайте:");
	hPanel.DrawItem("pa4h.ru");
	hPanel.Send(client, MenuHandler_MyPanel, 10);
	return Plugin_Handled;
}
public void SQL_StatsCallBack(Database hDatabase, DBResultSet results, const char[] sError, any client)
{
	int hours, top, scores;
	if (sError[0]) // Если произошла ошибка
	{
		LogError("SQL_StatsCallBack: %s", sError);
		return;
	}
	if (results.FetchRow()) // Есть данные
	{
		hours = results.FetchInt(0);
		top = results.FetchInt(1);
		scores = results.FetchInt(2);
	}
	
	char minut[8]; FormatEx(minut, sizeof(minut), "%T", "PanelMin", client);
	char chasov[4]; FormatEx(chasov, sizeof(chasov), "%T", "PanelHour", client);
	
	Panel hPanel = new Panel();
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelTitle", client);
	hPanel.SetTitle(txtBufer);
	hPanel.DrawText(" ");
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelTop", client, top, maxTop); // ("Место: 1 из 999");
	hPanel.DrawText(txtBufer);
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelScores", client, scores); // ("Очков: 99999999");
	hPanel.DrawText(txtBufer);
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelPlayTime", client, hours / 60, chasov, hours % 60, minut); // ("Время проведённое на сервере: 1234 ч.");
	hPanel.DrawText(txtBufer);
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelPlayTimeSession", client, MinutesSession[client], minut); // ("Время за сессию: 2 ч.");
	hPanel.DrawText(txtBufer);
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelScoresSession", client, points[client]); // ("Очков за сессию: 123");
	hPanel.DrawText(txtBufer);
	FormatEx(txtBufer, sizeof(txtBufer), "%T", "PanelExit", client);
	hPanel.DrawText(" ");
	hPanel.DrawText("Стата и баны: pa4h.ru");
	hPanel.DrawItem(txtBufer); // Exit
	hPanel.Send(client, MenuHandler_MyPanel, 20);
	delete hPanel;
}
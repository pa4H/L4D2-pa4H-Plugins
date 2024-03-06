void checkPrefix(int client, char[] steamID)
{
	prefix[client] = "";
	FormatEx(dbQuery, sizeof(dbQuery), "SELECT `Prefix` FROM `VIPplayers` WHERE `SteamID`='%s'", steamID);
	db.Query(SQL_PrefixCallBack, dbQuery, client);
}
public void SQL_PrefixCallBack(Database hDatabase, DBResultSet results, const char[] sError, any client)
{
	if (sError[0]) {  // Если произошла ошибка
		LogError("SQL_PrefixCallBack: %s", sError);
		return;
	}
	char pref[32];
	if (results.FetchRow()) {  // Есть данные
		results.FetchString(0, pref, sizeof(pref));
		prefix[client] = pref;
	}
}
public Action say(client, const char[] command, args)
{
	if (client > 0 && args > 0)
	{
		if (!StrEqual(prefix[client], "", false)) // Если что-то есть
		{
			char text[256];
			GetCmdArgString(text, sizeof(text));
			int team = GetClientTeam(client);
			StripQuotes(text);
			if (Contains(text, "/")) { return Plugin_Handled; }
			
			if (strcmp(command, "say") == 0)
			{
				if (team == 1) {
					CPrintToChatAll("%t", "pAll", prefix[client], client, text);
				}
				if (team == 2) {
					CPrintToChatAll("%t", "pAllS", prefix[client], client, text);
				}
				else if (team == 3) {
					CPrintToChatAll("%t", "pAllI", prefix[client], client, text);
				}
				return Plugin_Handled;
			}
			else if (strcmp(command, "say_team") == 0)
			{
				if (team == 1)
				{
					CPrintToChatAll("%t", "pSpec", prefix[client], client, text);
				}
				else
				{
					if (team == 2)
					{
						Format(text, sizeof(text), "%t", "pSurv", prefix[client], client, text);
					}
					else if (team == 3)
					{
						Format(text, sizeof(text), "%t", "pInf", prefix[client], client, text);
					}
					for (int i = 1; i <= MaxClients; i++)
					{
						if (IsClientInGame(i) && GetClientTeam(i) == team)
						{
							CPrintToChat(i, "%s", text);
						}
					}
				}
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

Action setPrefix(int client, int args)
{
	if (!VIPPlayers[client])
	{
		CPrintToChat(client, "%t", "notVIP");
	}
	else
	{
		if (args != 1)
		{
			CPrintToChat(client, "%t", "errPrefix");
			return Plugin_Handled;
		}
		char steamID[64];
		char arg[16];
		char newPrefix[16];
		GetCmdArg(1, arg, sizeof(arg));
		FormatEx(newPrefix, sizeof(newPrefix), "%s", arg);
		
		// No colors & SQL inject
		ReplaceString(newPrefix, sizeof(newPrefix), "{", ""); ReplaceString(newPrefix, sizeof(newPrefix), "}", "");
		ReplaceString(newPrefix, sizeof(newPrefix), "<?php", ""); ReplaceString(newPrefix, sizeof(newPrefix), "<?PHP", ""); ReplaceString(newPrefix, sizeof(newPrefix), "?>", ""); ReplaceString(newPrefix, sizeof(newPrefix), "\\", "");	ReplaceString(newPrefix, sizeof(newPrefix), "\"", ""); ReplaceString(newPrefix, sizeof(newPrefix), "'", ""); ReplaceString(newPrefix, sizeof(newPrefix), ";", ""); ReplaceString(newPrefix, sizeof(newPrefix), "�", ""); ReplaceString(newPrefix, sizeof(newPrefix), "`", "");
		
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		
		FormatEx(dbQuery, sizeof(dbQuery), "UPDATE `VIPplayers` SET `Prefix` = '%s' WHERE `SteamID`='%s'", newPrefix, steamID);
		db.Query(SQL_QueryCallBack, dbQuery);
		prefix[client] = newPrefix;
		CPrintToChat(client, "{green}[VIP] {default}Префикс {olive}%s {default}установлен!", newPrefix);
	}
	return Plugin_Handled;
}

Action deletePrefix(int client, int args) // configs/adminchat.txt
{
	char steamID[64];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
	FormatEx(dbQuery, sizeof(dbQuery), "UPDATE `VIPplayers` SET `Prefix` = '' WHERE `SteamID`='%s'", steamID);
	db.Query(SQL_QueryCallBack, dbQuery);
	prefix[client] = "";
	CPrintToChat(client, "{green}[VIP] {default}Префикс удалён");
	
	return Plugin_Handled;
} 
Action pickBot(int client, int args)
{
	if (!VIPPlayers[client])
	{
		CPrintToChat(client, "%t", "notVIP");
	}
	else
	{
		FakeClientCommand(client, "vip_pickbotforvip");
	}
	return Plugin_Handled;
}
Action setLight(int client, int args)
{
	if (!VIPPlayers[client])
	{
		CPrintToChat(client, "%t", "notVIP");
	}
	else
	{
		char arg1[16];
		GetCmdArg(1, arg1, sizeof(arg1));
		FakeClientCommand(client, "vip_lightforvip %s", arg1);
	}
	return Plugin_Handled;
}
Action setHat(int client, int args)
{
	if (!VIPPlayers[client])
	{
		CPrintToChat(client, "%t", "notVIP");
	}
	else
	{
		FakeClientCommand(client, "vip_hatforvip");
	}
	return Plugin_Handled;
}
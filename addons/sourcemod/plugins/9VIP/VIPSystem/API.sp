public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("vip_isClientVIP", Native_isClientVIP); // pa4HVIP.inc
	return APLRes_Success;
}

public Native_isClientVIP(Handle plugin, int numParams)
{
	if (!IsValidClient(GetNativeCell(1))) { return false; }
	return VIPPlayers[GetNativeCell(1)];
}
public MenuHandler_MyPanel(Handle panel, MenuAction action, client, option) {
	/*if (action == MenuAction_Select) { PrintToChat(client, "Номер выбранной опции: %d", option); }*/
}
stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true;} else {return false;}
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
public void SQL_ConnectCallBack(Database hDB, const char[] szError, any data)
{
	if (hDB == null || szError[0])
	{
		SetFailState("Could not connect to database: %s", szError);
		return;
	}
	db = hDB;
	db.SetCharset("utf8mb4");
} 

bool dateExpired(int curDay, curMonth, curYear, d, m, y) // dateExpired(текущая_дата, дата_окончания_ВИП)
{
	if (curYear > y) {
		return true; // текущая_дата > дата_окончания
	}
	if (curMonth > m && curYear >= y) {
		return true;
	}
	if (curDay >= d && curYear >= y) {
		if (curMonth >= m && curYear >= y) {
			return true;
		}
	}
	return false; // текущая_дата < дата_окончания
}

bool checkDate(char[] toDate)
{
	// Получаем текущую дату
	DateTime dateTime = new DateTime(DateTime_Now);
	int curDay = dateTime.Day;
	int curMonth = dateTime.Month;
	int curYear = dateTime.Year;
	
	// Получаем дату окончания VIP
	int d, m, y; // Здесь будет дата окончания VIP
	char parts[3][5];
	if (ExplodeString(toDate, ".", parts, 3, 5) >= 1)
	{
		d = StringToInt(parts[0]);
		m = StringToInt(parts[1]);
		y = StringToInt(parts[2]);
		//PrintToChatAll("parsed: %s %s %s", parts[0], parts[1], parts[2]);
	}
	
	// Сравниваем две даты
	if (!dateExpired(curDay, curMonth, curYear, d, m, y))
	{
		return true; // Дата не истекла
	}
	return false; // Дата истекла
}

public Action Timer_HelloVIP(Handle hTimer, any data)
{
	DataPack hPack = view_as<DataPack>(data);
	hPack.Reset();
	int client = hPack.ReadCell();
	char toDate[12];
	hPack.ReadString(toDate, sizeof(toDate));
	delete hPack;
	if (!IsValidClient(client)) { return Plugin_Stop; }
	CPrintToChat(client, "%t", "helloVIP", toDate);
	return Plugin_Stop;
}

public Action Timer_VIPisEnd(Handle hTimer, any client)
{
	CPrintToChat(client, "%t", "VIPisEnd");
	return Plugin_Stop;
}
public OnConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetConVarString(g_hSteamAPI_Key, keyAPI, sizeof(keyAPI));
}
public void SteamAPI_GetHours(char[] steamId, int client) {
	//PrintToServer("GET GET GET"); // debug
	// Формируем адрес: https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=keyAPI&steamid=steamId&format=json
	HTTPRequest request = new HTTPRequest("https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001");
	request.AppendQueryParam("key", "%s", keyAPI);
	request.AppendQueryParam("steamid", "%s", steamId);
	request.AppendQueryParam("format", "json");
	request.Get(OnTodosReceived, client); // Отправляем HTTP Get запрос
}
public void OnTodosReceived(HTTPResponse resp, any client) {  // Обработчик нашего запроса
	if (resp.Status != HTTPStatus_OK) {  // Проверка на ошибку запроса
		PrintToServer("SteamAPI GET Error");
		steamPlayTime[client] = 0; // Если не удалось получить часы, выдаём 0
		return;
	}
	
	JSONObject json_file = view_as<JSONObject>(resp.Data); // Сохраняем содержимое GET запроса
	JSONObject json_response = view_as<JSONObject>(json_file.Get("response")); // Получаем объект "response"
	if (json_response.Size >= 2) // Получаем количество объектов. Должно быть 2
	{
		JSONArray json_games = view_as<JSONArray>(json_response.Get("games")); // В объекте "response" получаем массив "games"
		JSONObject todo; // Объект JSON'a с которым мы будем работать
		char gameName[32]; // Название игры
		
		for (int i = 0; i < json_games.Length; i++) // Проходим по всем объектам в массиве "games" // Количество объектов в массиве. Их будет 5
		{
			todo = view_as<JSONObject>(json_games.Get(i)); // Получаем объект под номером i
			todo.GetString("name", gameName, sizeof(gameName)); // Получаем ключ "name"
			
			if (StrContains(gameName, "Left 4 Dead", false) != -1) // Если "name": "Left 4 Dead 2", то...
			{
				steamPlayTime[client] = todo.GetInt("playtime_forever"); // Получаем параметр "playtime_forever"
				steamPlayTime[client] /= 60; // Делим полученные минуты на 60 и получаем ЧАСЫ
				//PrintToServer("client: %i name: %s hours: %i", client, gameName, steamPlayTime[client]); // debug
				break; // Нашли что искали? Выходим из цикла
			}
			//steamPlayTime[client] = 0; // Если ничего не нашли. Приравниваем к 0. На всякий случай пусть дублируется
		}
		
		delete json_games; // Чистим за собой
		delete todo;
	}
	else // У игрока скрытый профиль. 0 часов
	{
		steamPlayTime[client] = 0;
		//PrintToServer("Private Profile"); // debug
	}
	delete json_file; // Чисти
	delete json_response; // Чисти
}

void ClearTankDamage()
{
	tankIsAlive = false;
	for (new i = 1; i <= MaxClients; i++) { tankDamage[i] = 0; }
}
void ClearWitchDamage()
{
	for (new i = 1; i <= MaxClients; i++) { witchDamage[i] = 0; }
}
public MenuHandler_MyPanel(Handle panel, MenuAction action, client, option) {  // Заглушка
	/*if (action == MenuAction_Select) { PrintToChat(client, "Номер выбранной опции: %d", option); }*/
}
public void SQL_QueryCallBack(Database hDatabase, DBResultSet results, const char[] sError, any data) // Заглушка
{
	if (sError[0]) // Если произошла ошибка
	{
		LogError("SQL_QueryCallBack: %s", sError);
		return;
	}
}
public void SQL_TxnCallback_Success(Database hDatabase, any Data, int iNumQueries, DBResultSet[] results, any[] QueryData) {  } public void SQL_TxnCallback_Failure(Database hDatabase, any Data, int iNumQueries, const char[] szError, int iFailIndex, any[] QueryData) { LogError("SQL_TxnCallback_Failure: %s", szError); }
public void SQL_ConnectCallBack(Database hDB, const char[] szError, any data)
{
	if (hDB == null || szError[0])
	{
		SetFailState("Could not connect to database: %s", szError); // Отключаем плагин
		return;
	}
	db = hDB;
	db.SetCharset("utf8mb4");
}
void nullVars(int i) {
	points[i] = 0;
	Minutes[i] = 0;
	
	specKills[i] = 0;
	bhopCount[i] = 0;
	hunterSkeet[i] = 0;
	hunterMelee[i] = 0;
	chargerMelee[i] = 0;
	tongueClear[i] = 0;
	rockSkeet[i] = 0;
	rockHit[i] = 0;
	hunterJump[i] = 0;
	boomerVomit[i] = 0;
	headshotCount[i] = 0;
	gaylikeRank[i] = 0;
	dKills[i] = 0;
	tKills[i] = 0;
	mKills[i] = 0;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("stats_Gaylike", Native_Gaylike); // pa4HStats.inc
	CreateNative("stats_dKills", Native_dKills); 
	CreateNative("stats_tKills", Native_tKills); 
	CreateNative("stats_mKills", Native_mKills); 
	return APLRes_Success;
}

stock bool isAdmin(int client)
{
	if (GetUserFlagBits(client) == ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}
stock int GetOnlineClients()
{
	int cl;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)) { cl++; }
	}
	return cl;
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
stock bool IsWitch(iEntity)
{
	if (iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
	{
		char strClassName[64];
		GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
		return StrEqual(strClassName, "witch");
	}
	return false;
} 
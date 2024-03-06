#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>

char mapRealName[64]; // Хранилище для названий карт "Нет Милосердию", "Вымерший центр" и тд
int winner = 0; // Номер карты, которая победила в голосовании. индекс 0 = mapSequence[0]
int clientVotes[14]; // В массиве содержатся голоса за каждую карту
bool canPlayerVote[MAXPLAYERS + 1]; // В массиве содержатся игроки которым можно\нельзя голосовать
bool canPlayersRevote = true;
bool canVote = false;
int loadedPlayers = 0;

native void L4D2_ChangeLevel(const char[] sMap); // changelevel.smx

ArrayList newMaps; // Сформированный список для меню
ArrayList oldMaps; // Тут храним карты, которые играли. Массив пополняется после окончания Round Versus

Handle voteTimer;
Handle timeEndVote;
Handle timeChangeMap;
Handle halfOfRound;
Handle canRevote;

//char DropLP[PLATFORM_MAX_PATH]; // debug

public Plugin myinfo =  {
	name = "MapVoter", 
	author = "pa4H", 
	description = "", 
	version = "2.0", 
	url = "vk.com/pa4h1337"
};

char mapSequence[][32] =  {  // Последовательность карт
	"c8m1_apartment", "c2m1_highway", "c1m1_hotel", "c11m1_greenhouse", "c5m1_waterfront", "c3m1_plankcountry", "c4m1_milltown_a", 
	"c6m1_riverbank", "c7m1_docks", "c9m1_alleys", "c10m1_caves", 
	"c12m1_hilltop", "c13m1_alpinecreek", "c14m1_junkyard"
};

public void OnPluginStart()
{
	//RegAdminCmd("sm_mapresult", mapVoteResult, ADMFLAG_BAN);
	//RegConsoleCmd("sm_test", testFunc, "");
	RegAdminCmd("sm_startvote", admin_StartNewVote, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_revote", reVoteStart);
	
	RegConsoleCmd("sm_mapvote", mapVote);
	RegConsoleCmd("sm_votemap", mapVote);
	RegConsoleCmd("sm_mv", mapVote);
	RegConsoleCmd("sm_rtv", mapVote);
	
	
	timeEndVote = CreateConVar("timeToEndVote", "30.0", "", FCVAR_CHEAT);
	timeChangeMap = CreateConVar("timeToChangeMap", "10.0", "", FCVAR_CHEAT);
	halfOfRound = CreateConVar("voteOnRound", "1", "0 or 1 half of round", FCVAR_CHEAT);
	canRevote = CreateConVar("canRevote", "0", "0 or 1", FCVAR_CHEAT);
	
	newMaps = new ArrayList(ByteCountToCells(32));
	oldMaps = new ArrayList(ByteCountToCells(32));
	
	HookEvent("versus_match_finished", Event_VersusMatchFinished, EventHookMode_Pre); // Конец финальной карты
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	
	LoadTranslations("pa4HMapVoter.phrases");
	//BuildPath(Path_SM, DropLP, sizeof(DropLP), "logs/MapVoter.log"); // debug
}

stock Action testFunc(int client, int args) // DEBUG
{
	return Plugin_Handled;
}
stock Action reVoteStart(int client, int args)
{
	if (L4D_IsMissionFinalMap())
	{
		if (!canPlayersRevote) { CPrintToChatAll("%t", "noRevote"); return Plugin_Handled; }
		if (GetConVarBool(canRevote) && !canVote) {
			CPrintToChatAll("%t", "RevoteStart");
			canPlayersRevote = false;
			StartVote();
		} else if (!GetConVarBool(canRevote) && !canVote) {
			CPrintToChat(client, "%t", "cantRevote");
		}
	}
	else {
		CPrintToChat(client, "%t", "VoteOnlyOnFinal"); // Если играем не последнюю карту
	}
	return Plugin_Handled;
}
stock Action admin_StartNewVote(int client, int args)
{
	canPlayersRevote = true;
	StartVote();
	return Plugin_Handled;
}
public OnClientPostAdminCheck(client)
{
	canPlayersRevote = true;
	if (GetConVarInt(halfOfRound) != 0) { return; }
	if (IsValidClient(client)) {
		loadedPlayers++
		//LogToFileEx(DropLP, "Cliconnect: %i online: %i", loadedPlayers, GetOnlineClients());
	}
	
	if (loadedPlayers == GetOnlineClients() && L4D_IsMissionFinalMap() && isFirstRound()) // Если играем последную карту и идёт первая половина карты
	{
		StartVote();
	}
}

void StartVote()
{
	getMapsList(); // Формирование списка карт
	loadedPlayers = 0;
	canVote = true;
	
	if (voteTimer != INVALID_HANDLE) { voteTimer = null; }
	voteTimer = CreateTimer(GetConVarFloat(timeEndVote), Timer_EndVote); // Создаем таймер после которого закончится голосование
	
	PrecacheSound("ui/beep_synthtone01.wav");
	EmitSoundToAll("ui/beep_synthtone01.wav");
	
	clearVotes(); // Очищаем все голоса
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			showMenu(i); // Показываем меню всем
		}
	}
}

public Action Timer_EndVote(Handle hTimer, any UserId)
{
	canVote = false;
	loadedPlayers = 0;
	
	int buf = 0;
	winner = 0;
	for (int map = 0; map < 14; map++)
	{
		if (clientVotes[map] >= buf && clientVotes[map] != 0) { buf = clientVotes[map]; winner = map; } // Узнаем победившую карту
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			FormatEx(mapRealName, sizeof(mapRealName), "%T", mapSequence[winner], i);
			CPrintToChat(i, "%t", "VoteWinner", mapRealName); // Выводим в чат победившую карту
			
			ClientCommand(i, "slot10"); // Закрываем всем меню
			//LogToFileEx(DropLP, "VoteWinner: %s", mapRealName); // debug
		}
	}
	resultsToConsole();
	return Plugin_Stop;
}
public Menu_Dummy(Menu menu, MenuAction action, int client, int param2) {  }

void showMenu(int client)
{
	Menu menu = new Menu(Menu_VotePoll); // Внутри скобок обработчик нажатий меню
	menu.SetTitle("%T", "SelectMap", client); // Заголовок меню	
	
	char mapName[32];
	for (int i = 0; i < newMaps.Length; i++) // Добавляем всё в меню. ТОЛЬКО НА СТОРОНЕ КЛИЕНТА
	{
		newMaps.GetString(i, mapName, sizeof(mapName));
		FormatEx(mapRealName, sizeof(mapRealName), "%T", mapName, client);
		int voteCount = golos(mapName);
		if (voteCount != 0) { Format(mapRealName, sizeof(mapRealName), "(%i) %s", voteCount, mapRealName); }
		menu.AddItem(mapName, mapRealName); // Добавляем в меню "c8m1_apartment" "Нет Милосердию"	
	}
	menu.Display(client, 10);
}

public Menu_VotePoll(Menu menu, MenuAction action, int client, int param2) // Обработчик нажатия кнопок в меню
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		if (!canPlayerVote[client]) { return; }
		char szInfo[32];
		menu.GetItem(param2, szInfo, sizeof(szInfo)); // Получаем описание пункта по которому нажал игрок
		int sel = 0;
		if (StrEqual(szInfo, "c8m1_apartment") == true)
		{
			sel = 0;
		}
		else if (StrEqual(szInfo, "c2m1_highway") == true) {
			sel = 1;
		}
		else if (StrEqual(szInfo, "c1m1_hotel") == true) {
			sel = 2;
		}
		else if (StrEqual(szInfo, "c11m1_greenhouse") == true) {
			sel = 3;
		}
		else if (StrEqual(szInfo, "c5m1_waterfront") == true) {
			sel = 4;
		}
		else if (StrEqual(szInfo, "c3m1_plankcountry") == true) {
			sel = 5;
		}
		else if (StrEqual(szInfo, "c4m1_milltown_a") == true) {
			sel = 6;
		}
		else if (StrEqual(szInfo, "c6m1_riverbank") == true) {
			sel = 7;
		}
		else if (StrEqual(szInfo, "c7m1_docks") == true) {
			sel = 8;
		}
		else if (StrEqual(szInfo, "c9m1_alleys") == true) {
			sel = 9;
		}
		else if (StrEqual(szInfo, "c10m1_caves") == true) {
			sel = 10;
		}
		else if (StrEqual(szInfo, "c12m1_hilltop") == true) {
			sel = 11;
		}
		else if (StrEqual(szInfo, "c13m1_alpinecreek") == true) {
			sel = 12;
		}
		else if (StrEqual(szInfo, "c14m1_junkyard") == true) {
			sel = 13;
		}
		clientVotes[sel] += 1;
		canPlayerVote[client] = false;
		FormatEx(mapRealName, sizeof(mapRealName), "%T", mapSequence[sel], client);
		CPrintToChat(client, "%t", "VotedFor", mapRealName);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && canVote)
			{
				showMenu(i);
			}
		}
		//LogToFileEx(DropLP, "Cl: %i; indx: %d; mapName: %s", client, param2, szInfo); // debug
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_Exit) // Если нажали Выход
	{
		if (canVote) { showMenu(client); }
		//CPrintToChat(client, "%t", "VoteCancel");
	}
}

int golos(char[] mapName)
{
	if (StrEqual(mapName, "c8m1_apartment") == true)
	{
		return clientVotes[0];
	}
	else if (StrEqual(mapName, "c2m1_highway") == true) {
		return clientVotes[1];
	}
	else if (StrEqual(mapName, "c1m1_hotel") == true) {
		return clientVotes[2];
	}
	else if (StrEqual(mapName, "c11m1_greenhouse") == true) {
		return clientVotes[3];
	}
	else if (StrEqual(mapName, "c5m1_waterfront") == true) {
		return clientVotes[4];
	}
	else if (StrEqual(mapName, "c3m1_plankcountry") == true) {
		return clientVotes[5];
	}
	else if (StrEqual(mapName, "c4m1_milltown_a") == true) {
		return clientVotes[6];
	}
	else if (StrEqual(mapName, "c6m1_riverbank") == true) {
		return clientVotes[7];
	}
	else if (StrEqual(mapName, "c7m1_docks") == true) {
		return clientVotes[8];
	}
	else if (StrEqual(mapName, "c9m1_alleys") == true) {
		return clientVotes[9];
	}
	else if (StrEqual(mapName, "c10m1_caves") == true) {
		return clientVotes[10];
	}
	else if (StrEqual(mapName, "c12m1_hilltop") == true) {
		return clientVotes[11];
	}
	else if (StrEqual(mapName, "c13m1_alpinecreek") == true) {
		return clientVotes[12];
	}
	else if (StrEqual(mapName, "c14m1_junkyard") == true) {
		return clientVotes[13];
	}
	return 999;
}

void getMapsList() // Формирование списка карт
{
	newMaps.Clear();
	for (int i = 0; i < sizeof(mapSequence); i++) // Выводим все карты из массива mapSequence
	{
		newMaps.PushString(mapSequence[i]);
	}
	char mapName[32];
	GetCurrentMap(mapName, sizeof(mapName)); // Получаем название карты
	Format(mapName, sizeof(mapName), "%t", mapName); // c1m4_atrium > c1m1_hotel
	
	int indexToDel = newMaps.FindString(mapName);
	if (indexToDel != -1) {
		newMaps.Erase(indexToDel); }
	
	for (int o = 0; o < oldMaps.Length; o++) {  // Удаляем карты на которых играли
		oldMaps.GetString(o, mapName, sizeof(mapName));
		indexToDel = newMaps.FindString(mapName);
		if (indexToDel != -1) {
			newMaps.Erase(indexToDel); }
	}
	
	for (int o = 0; o < oldMaps.Length; o++) {  // Добавляем в конец карты на которых играли
		oldMaps.GetString(o, mapName, sizeof(mapName));
		newMaps.PushString(mapName);
	}
}

public Action mapVote(int client, int args) // !mapvote
{
	if (L4D_IsMissionFinalMap())
	{
		if (canPlayerVote[client] == false && canVote) {  // Игрок уже проголосовал
			CPrintToChat(client, "%t", "PlayerCantVote");
		}
		if (canVote) {
			showMenu(client);
		} else {  // Голосование закончилось
			FormatEx(mapRealName, sizeof(mapRealName), "%T", mapSequence[winner], client);
			CPrintToChat(client, "%t", "VoteStoped", mapRealName);
		}
	}
	else {
		CPrintToChat(client, "%t", "VoteOnlyOnFinal"); // Если играем не последнюю карту
	}
	return Plugin_Handled;
}

public void Event_VersusMatchFinished(Event hEvent, const char[] sEvName, bool bDontBroadcast) // Конец финальной карты
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			FormatEx(mapRealName, sizeof(mapRealName), "%T", mapSequence[winner], i);
			CPrintToChat(i, "%t", "NextMap", mapRealName); // "Следующая карта Нет милосердию"
		}
	}
	char mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));
	Format(mapName, sizeof(mapName), "%t", mapName); // c1m4_atrium > c1m1_hotel
	oldMaps.PushString(mapName); // Сохраняем карту на которой играли
	if (oldMaps.Length >= 13) { oldMaps.Clear(); }
	
	CreateTimer(GetConVarFloat(timeChangeMap), Timer_ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE); // Через 10 секунд меняем карту
	//LogToFileEx(DropLP, "Timer started"); // debug
}

public Action Timer_ChangeMap(Handle hTimer, any UserId)
{
	L4D2_ChangeLevel(mapSequence[winner]); // Меняем карту
	return Plugin_Stop;
}

void resultsToConsole()
{
	PrintToConsoleAll("Map Winner: %s", mapSequence[winner]);
	for (int i = 0; i < 14; i++)
	{
		PrintToConsoleAll("%s: %i", mapSequence[i], clientVotes[i]);
	}
}

void clearVotes() // Очищаем голоса за все карты
{
	for (int i = 0; i < 14; i++)
	{
		clientVotes[i] = 0;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		canPlayerVote[i] = true;
	}
}

public void OnMapEnd() // Требуется, поскольку принудительная смена карты не вызывает событие "round_end"
{
	if (voteTimer != INVALID_HANDLE) { voteTimer = null; }
	loadedPlayers = 0;
	canPlayersRevote = true;
}

stock int GetOnlineClients()
{
	int cl;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && !IsFakeClient(i)) { cl++; }
	}
	return cl;
}

stock Action mapVoteResult(int client, int args)
{
	FormatEx(mapRealName, sizeof(mapRealName), "%T", mapSequence[winner], client);
	CPrintToChat(client, "%t", "VoteStoped", mapRealName);
	return Plugin_Handled;
}

public RoundStartEvent(Handle event, const char[] name, bool dontBroadcast) // Сервер запустился
{
	if (GetConVarInt(halfOfRound) != 1) { return; }
	if (!isFirstRound() && L4D_IsMissionFinalMap()) {
		StartVote();
	}
}

bool isFirstRound()
{
	if (GameRules_GetProp("m_bInSecondHalfOfRound") == 0) {
		return true;
	}
	return false;
}

bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
} 
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <left4dhooks>
#include <l4d2_changelevel>
#include <pa4HDBLog>

#define L4D2_TEAM_ALL        -1 // ID всех команд
#define L4D2_TEAM_SPECTATORS 1  // ID наблюдателей
#define L4D2_TEAM_SURVIVORS  2  // ID выживших
#define L4D2_TEAM_INFECTED   3  // ID зараженных

const int _voteDelay = 10; // Задержка между вызовом голосования
const int _voteLimit = 9; // 10 раз игрок может вызывать голосование

Handle g_AllTalkCvar; // Переменная для взаимодействия с sv_alltalk

int count_YesVotes; // Количество голосов ЗА
int count_NoVotes; // Количество голосов ПРОТИВ
int playersCount; // Количество игроков способных голосовать
bool VoteInProgress; // Если true, то голосование проводится
int timeCooldown = 0; // Время, через которое можно будет голосовать
bool CanPlayerVote[MAXPLAYERS + 1]; // False если игрок проголосовал
int playerLimit[MAXPLAYERS + 1]; // Сколько раз игрок может вызывать голосование

char argOne[64]; // Первый аргумент из консоли
char argTwo[64]; // Второй аргумент из консоли

int voteInTeam; // Сюда пишется номер тимы где будет происходить голосование
char callerName[32]; // Имя игрока начавшего голосование
char voteName[128]; // Название голсования
char votePassAnswer[128]; // Ответ на состоявшееся голосование (текст)
char buferArgument[64]; // Буферная переменная для хранения 1 аргумента
char buferArgument2[64]; // Буферная переменная для хранения 2 аргумента
char mapForChange[64]; // Переменная для хранения названия карты для смены
char txtBufer[256]; // Буферная переменная для форматирования текста
char PREFIX[16]; // Переменная для хранения префикса
bool keepAllTalk; // Если true, включаем в начале раунда AllTalk

Handle g_hTimer; // Для убийства таймера обязательно нужно создавать его через Handle
Handle map_Timer;
Handle cooldown_Timer;
KeyValues kv;

public Plugin myinfo = 
{
	name = "New Vote System", 
	author = "pa4H", 
	description = "New vote system for L4D2", 
	version = "240624", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_customvote", customVote, "Usage: sm_customvote <Text> <Text after PASS vote>");
	
	RegAdminCmd("sm_pass", voteYes, ADMFLAG_BAN);
	RegAdminCmd("sm_veto", voteNo, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_alltalk", getAllTalk, "");
	
	RegAdminCmd("sm_resetvotes", resetVote, ADMFLAG_BAN);
	RegAdminCmd("sm_resetlimit", resetVote, ADMFLAG_BAN);
	RegAdminCmd("sm_resetlimits", resetVote, ADMFLAG_BAN);
	RegAdminCmd("sm_resetvote", resetVote, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_kickspec", kickSpecVote, "");
	RegConsoleCmd("sm_sk", kickSpecVote, "");
	RegConsoleCmd("sm_ks", kickSpecVote, "");
	RegConsoleCmd("sm_nospec", kickSpecVote, "");
	
	RegConsoleCmd("sm_killbots", kickInfectedBotsVote, "");
	RegConsoleCmd("sm_kb", kickInfectedBotsVote, "");
	
	RegConsoleCmd("sm_voteboss", voteBossVote, "");
	RegConsoleCmd("sm_bossvote", voteBossVote, "");
	RegConsoleCmd("sm_vb", voteBossVote, "");
	
	RegConsoleCmd("sm_voterestart", restartChapterVote, "");
	RegConsoleCmd("sm_restart", restartChapterVote, "");
	RegConsoleCmd("sm_rematch", restartChapterVote, "");
	
	RegConsoleCmd("Vote", vote); // Обработчик команды Vote (Vote Yes; Vote No)
	AddCommandListener(Listener_CallVote, "callvote"); // Обработчик команды callvote
	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy); // Сервер запустился
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	
	LoadTranslations("pa4H-NewVoteSystem.phrases"); // Загружаем тексты всех фраз
	LoadTranslations("pa4H-NewVoteSystemMaps.phrases"); // Загружаем названия карт
	
	FormatEx(PREFIX, sizeof(PREFIX), "%t", "PREFIX");
	
	char kvPath[256]
	BuildPath(Path_SM, kvPath, sizeof(kvPath), "data/DisallowVote.txt");
	kv = new KeyValues("DisallowVote");
	if (!FileToKeyValues(kv, kvPath)) {
		PrintToServer("Error loading DisallowVote");
	}
	resetLimits(true); // Сброс лимитов на возможность вызывать голосование 
}

public Action Listener_CallVote(int client, const char[] command, argc)
{
	if (GetClientTeam(client) == L4D2_TEAM_SPECTATORS) { CPrintToChat(client, "%t", "SpecNoVote"); return Plugin_Handled; }
	if (VoteInProgress) { PrintToChat(client, "Ебучий баг голосования!!!!"); return Plugin_Handled; } // Голосование идёт? Выходим из функции
	if (timeCooldown > 0) { CPrintToChat(client, "%t", "VoteCooldown", timeCooldown); return Plugin_Handled; }
	// Проверяем возможность голосовать
	char steamID[64];
	GetClientAuthId(client, AuthId_SteamID64, steamID, sizeof(steamID));
	if (KvJumpToKey(kv, steamID, false)) {
		CPrintToChat(client, "%T", "DisallowVote", client, PREFIX);
		return Plugin_Handled;
	}
	if (playerLimit[client] == 0) {
		CPrintToChat(client, "%T", "VoteLimit", client, PREFIX, _voteLimit);
		return Plugin_Handled;
	}
	// Проверка окончена
	
	GetCmdArg(1, argOne, sizeof(argOne)); // Получаем 1 аргумент
	GetCmdArg(2, argTwo, sizeof(argTwo)); // Получаем 2 аргумент
	GetClientName(client, callerName, sizeof(callerName)); // Получаем ник игрока
	//PrintToConsoleAll("%s %s", argOne, argTwo); // debug
	
	// DB:
	char toDBText[128];
	if (StrEqual(argOne, "Kick", false))
	{
		int gClient = GetClientOfUserId(StringToInt(argTwo));
		char db_nick[64];
		GetClientName(gClient, db_nick, sizeof(db_nick));
		FormatEx(toDBText, sizeof(toDBText), "(Vote) Kick: %s", db_nick);
	}
	else {
		FormatEx(toDBText, sizeof(toDBText), "(Vote) %s %s", argOne, argTwo);
	}
	dbLog_Push(client, toDBText);
	
	// KickSpec
	if (StrEqual(argOne, "KickSpec", false))
	{
		CPrintToChatAll("%t", "KickSpec", PREFIX, callerName); // "{1} {2} голосует за исключение зрителей!"
		createVote(client, L4D2_TEAM_ALL);
		return Plugin_Handled;
	}
	// KillBots
	if (StrEqual(argOne, "KillBots", false))
	{
		if (GetClientTeam(client) == L4D2_TEAM_INFECTED)
		{
			for (int x = 1; x <= MaxClients; x++) // Пишем только в чат зараженных
			{
				if (IsValidClient(x) && GetClientTeam(x) == L4D2_TEAM_INFECTED)
				{
					CPrintToChat(x, "%t", "KillInfectedBots", PREFIX, callerName); // "{1} {2} голосует за убийство ботов"
				}
			}
			createVote(client, L4D2_TEAM_INFECTED);
		}
		else
		{
			CPrintToChat(client, "%t", "NoKillInfectedBots", PREFIX); // "Только команда зараженных может использовать эту команду"
		}
		return Plugin_Handled;
	}
	// VoteBoss
	if (StrEqual(argOne, "VoteBoss", false)) // !voteboss 10 20
	{
		char buf[2][4]; int tankP, witchP;
		
		if (ExplodeString(argTwo, "!", buf, 2, 4) > 1) // Если есть 2 аргумент, то есть процент Вички
		{
			tankP = StringToInt(buf[0]);
			witchP = StringToInt(buf[1]);
		}
		else { tankP = StringToInt(argTwo); witchP = GetWitchFlow(); } // Если !voteboss 10 (без вички)
		
		if ((tankP < 1 || witchP < 1) || (tankP > 80 || witchP > 80)) { CPrintToChatAll("%t", "VoteBossLimits"); return Plugin_Handled; }
		
		CPrintToChatAll("%t", "VoteBoss", callerName, tankP); // "{1} предлагает вызвать..."
		if (witchP > 0) { CPrintToChatAll("%t", "vbWitch", witchP); }
		createVote(client, L4D2_TEAM_ALL);
		return Plugin_Handled;
	}
	// ReturnToLobby
	if (StrEqual(argOne, "ReturnToLobby", false))
	{
		for (int x = 1; x <= MaxClients; x++)
		{
			if (IsValidClient(x)) {
				if (client == x) {  // Пишем в чат вызывающего голосование
					CPrintToChat(x, "%t", "ReturnToLobby1", PREFIX); // "{1} Нельзя выходить в лобби!"
				}
				else {  // Пишем в общий чат
					CPrintToChat(x, "%t", "ReturnToLobby2", PREFIX, callerName); // "{1} Тупой дебил {2} попытался выйти в лобби"
				}
			}
		}
		return Plugin_Handled;
	}
	// AllTalk
	if (StrEqual(argOne, "ChangeAllTalk", false))
	{
		g_AllTalkCvar = FindConVar("sv_alltalk"); // Обращаемся к sv_alltalk
		if (GetConVarInt(g_AllTalkCvar)) {  // Если Alltalk включен (sv_alltalk 1)
			CPrintToChatAll("%t", "ChangeAllTalkOff", PREFIX, callerName); // Turn off ALLTalk?
		}
		else {
			CPrintToChatAll("%t", "ChangeAllTalkOn", PREFIX, callerName); // Turn on ALLTalk?
		}
		createVote(client, L4D2_TEAM_ALL);
		return Plugin_Handled;
	}
	// ChangeChapter
	if (StrEqual(argOne, "ChangeChapter", false)) // Scavenge (argTwo: c8m5_rooftop)
	{
		for (int x = 1; x <= MaxClients; x++) {
			if (IsValidClient(x)) {
				FormatEx(txtBufer, sizeof(txtBufer), "%T", argTwo, x); // Получаем вместо c8m1_apartments Нет милосердию: 1.Апартаменты
				CPrintToChat(x, "%t", "ChangeChapter", PREFIX, callerName, txtBufer); // "{1} {2} голосует за смену карты на {3}"
			}
		}
		createVote(client, L4D2_TEAM_ALL);
		return Plugin_Handled;
	}
	// ChangeMission
	if (StrEqual(argOne, "ChangeMission", false)) // Versus, coop (argTwo: L4D2C8)
	{
		for (int x = 1; x <= MaxClients; x++) {
			if (IsValidClient(x)) {
				FormatEx(txtBufer, sizeof(txtBufer), "%T", argTwo, x); // Получаем вместо L4D2C8 Нет милосердию: 1.Апартаменты
				CPrintToChat(x, "%t", "ChangeChapter", PREFIX, callerName, txtBufer); // "{1} {2} голосует за смену карты на {3}"
			}
		}
		createVote(client, L4D2_TEAM_ALL);
		return Plugin_Handled;
	}
	// Kick
	if (StrEqual(argOne, "Kick", false))
	{
		int gClient = GetClientOfUserId(StringToInt(argTwo));
		if (!IsValidClient(gClient)) { return Plugin_Handled; }
		char nick[64];
		GetClientName(gClient, nick, sizeof(nick));
		
		CPrintToChatAll("%t", "Kick", PREFIX, callerName, nick); // "{1} {2} голосует за исключение игрока {3}"
		createVote(client, GetClientTeam(gClient)); // Вызываем голосование для команды, где находится жертва
		return Plugin_Handled;
	}
	// RestartGame
	if (StrEqual(argOne, "RestartGame", false)) // RestartGame: coop, versus | Scavenge: none. Use !rematch
	{
		CPrintToChatAll("%t", "RestartChapter", PREFIX, callerName); // "{1} {2} голосует за перезапуск главы!"
		createVote(client, L4D2_TEAM_ALL);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public void createVote(int client, int team)
{
	//CPrintToChatAll("createVote: arg1: %s arg2: %s team: %i", argOne, argTwo, voteInTeam); // Debug
	playerLimit[client]--; // На одну возможность проголосовать меньше
	GetClientName(client, callerName, sizeof(callerName)); // Получаем имя игрока
	voteInTeam = team; // В какой тиме будет происходить голосование
	
	buferArgument = argOne; // Тут хранится аргумент 1
	buferArgument2 = argTwo; // Тут хранится аргумент 2
	
	// Создаем VGUI с голосованием
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x) && GetClientTeam(x) != L4D2_TEAM_SPECTATORS)
		{
			getVoteAndAnswer(x); // Получаем фразы на языке клиента (x)
			BfWrite bf = UserMessageToBfWrite(StartMessageOne("VoteStart", x, USERMSG_RELIABLE));
			bf.WriteByte(voteInTeam); // Сюда пишем номер команды где отобразится окно с голосованием
			bf.WriteByte(0); // Client index игрока, который начал голосование. 99 for server
			bf.WriteString("#L4D_TargetID_Player"); // Обязательно
			bf.WriteString(voteName); // Текст голосования (Перезапустить кампанию?)
			bf.WriteString(callerName); // Ник игрока
			EndMessage();
		}
	}
	// Сбрасываем все флаги
	count_YesVotes = 0;
	count_NoVotes = 0;
	playersCount = 0;
	VoteInProgress = true;
	for (int i = 1; i <= MaxClients; i++) // Два раза один и и тот же цикл, ммм...
	{
		if (IsValidClient(i)) // Могут голосовать только игроки. Не боты
		{
			if (GetClientTeam(i) == voteInTeam) // Голосуют игроки из команды где вызвали голосование
			{
				CanPlayerVote[i] = true;
				playersCount++;
			}
			else if (voteInTeam == L4D2_TEAM_ALL && GetClientTeam(i) != L4D2_TEAM_SPECTATORS) // Если должны голосовать игроки со всех команд
			{
				CanPlayerVote[i] = true;
				playersCount++;
			}
		}
	}
	
	UpdateVotes();
	if (g_hTimer != INVALID_HANDLE) { delete g_hTimer; }
	g_hTimer = CreateTimer(10.0, Timer_VoteCheck); // Спустя это время голосование закончится
}
public Action Timer_VoteCheck(Handle timer) // Таймер
{
	if (VoteInProgress) // Сработал таймер. Если проводится голосование, то...
	{
		//PrintToChatAll("VoteStop"); // Debug
		VoteInProgress = false; // ...оно завершается
		UpdateVotes();
	}
	g_hTimer = null;
	return Plugin_Stop;
}
void getVoteAndAnswer(int client) // Получаем фразы на языке клиента
{
	if (StrEqual(argOne, "ChangeAllTalk", false))
	{
		g_AllTalkCvar = FindConVar("sv_alltalk"); // Обращаемся к sv_alltalk
		if (GetConVarInt(g_AllTalkCvar)) // Если Alltalk включен (sv_alltalk 1)
		{
			FormatEx(voteName, sizeof(voteName), "%T", "OffChangeAllTalkVoteName", client); // Turn off ALLTalk?
			FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "OffChangeAllTalkVotePass", client);
		}
		else
		{
			FormatEx(voteName, sizeof(voteName), "%T", "OnChangeAllTalkVoteName", client); // Turn on ALLTalk?
			FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "OnChangeAllTalkVotePass", client);
		}
		return;
	}
	if (StrEqual(argOne, "KickSpec", false))
	{
		FormatEx(voteName, sizeof(voteName), "%T", "KickSpecVoteName", client);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "KickSpecVotePass", client);
		return;
	}
	if (StrEqual(argOne, "KillBots", false))
	{
		FormatEx(voteName, sizeof(voteName), "%T", "KillInfectedBotsVoteName", client);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "KillInfectedBotsVotePass", client);
		return;
	}
	if (StrEqual(argOne, "VoteBoss", false))
	{
		char buf[2][4]; int tankP, witchP;
		
		if (ExplodeString(argTwo, "!", buf, 2, 4) > 1) // Если есть 2 аргумент, то есть процент Вички
		{
			tankP = StringToInt(buf[0]);
			witchP = StringToInt(buf[1]);
		}
		else { tankP = StringToInt(argTwo); witchP = GetWitchFlow(); }
		
		FormatEx(voteName, sizeof(voteName), "%T", "VoteBossVoteName", client, tankP, witchP);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "VoteBossVotePass", client, tankP, witchP);
		return;
	}
	if (StrEqual(argOne, "ChangeChapter", false))
	{
		FormatEx(txtBufer, sizeof(txtBufer), "%T", argTwo, client); // Вместо c8m1_apartments получаем = Нет милосердию: 1.Апартаменты
		FormatEx(voteName, sizeof(voteName), "%T", "ChangeChapterVoteName", client, txtBufer);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "ChangeChapterVotePass", client);
		return;
	}
	if (StrEqual(argOne, "ChangeMission", false))
	{
		FormatEx(txtBufer, sizeof(txtBufer), "%T", argTwo, client); // Вместо L4D2C8 получаем = Нет милосердию: 1.Апартаменты
		FormatEx(voteName, sizeof(voteName), "%T", "ChangeChapterVoteName", client, txtBufer);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "ChangeChapterVotePass", client);
		return;
	}
	if (StrEqual(argOne, "Kick", false))
	{
		IntToString(GetClientOfUserId(StringToInt(argTwo)), buferArgument2, sizeof(buferArgument2));
		char nick[64];
		GetClientName(GetClientOfUserId(StringToInt(argTwo)), nick, sizeof(nick));
		FormatEx(voteName, sizeof(voteName), "%T", "KickVoteName", client, nick);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "KickVotePass", client);
		return;
	}
	if (StrEqual(argOne, "RestartGame", false))
	{
		FormatEx(voteName, sizeof(voteName), "%T", "RestartChapterVoteName", client);
		FormatEx(votePassAnswer, sizeof(votePassAnswer), "%T", "RestartChapterVotePass", client);
		return;
	}
}
void UpdateVotes()
{
	Event event = CreateEvent("vote_changed");
	event.SetInt("yesVotes", count_YesVotes);
	event.SetInt("noVotes", count_NoVotes);
	event.SetInt("potentialVotes", playersCount); // Количество людей, которые могут голосовать
	event.Fire();
	
	if ((count_YesVotes + count_NoVotes == playersCount) || !VoteInProgress) // Если проголосовали все ИЛИ голосование закончилось, то...
	{
		for (int i = 1; i <= MaxClients; i++) {  // Сбрасываем
			if (IsValidClient(i)) { CanPlayerVote[i] = false; }
		}
		VoteInProgress = false;
		
		if (count_YesVotes > count_NoVotes) // Если набрали 60% голосов за Путина
		{
			// Выводим для всех валидных клиентов
			for (int x = 1; x <= MaxClients; x++)
			{
				if (IsValidClient(x))
				{
					getVoteAndAnswer(x); // Получаем фразы на языке клиента (x)
					BfWrite bf = UserMessageToBfWrite(StartMessageOne("VotePass", x, USERMSG_RELIABLE));
					bf.WriteByte(voteInTeam);
					bf.WriteString("#L4D_TargetID_Player");
					bf.WriteString(votePassAnswer);
					EndMessage();
				}
			}
			
			votePassedFunc(); // Здесь находятся функции выполняемые после успешного голосования.
		}
		else // Голосование против
		{
			BfWrite bf = UserMessageToBfWrite(StartMessageAll("VoteFail")); // Выводим "Голосов ЗА должно быть больше"
			bf.WriteByte(voteInTeam);
			EndMessage();
		}
		g_hTimer = null; // https://www.safezone.cc/threads/zaversheno-sourcepawn-sovety-dlja-novichkov-i-profi.37354/#add2
		
		timeCooldown = _voteDelay;
		delete cooldown_Timer;
		cooldown_Timer = CreateTimer(1.0, Timer_VoteCooldown, _, TIMER_REPEAT); //
	}
}
public Action Timer_VoteCooldown(Handle timer) // Таймер задержки на следующее голосование
{
	if (timeCooldown != 0)
	{
		timeCooldown--;
		return Plugin_Continue;
	}
	else
	{
		cooldown_Timer = null;
		return Plugin_Stop;
	}
}

public void OnMapEnd()
{
	//delete g_hTimer;
	delete map_Timer;
	delete cooldown_Timer;
	VoteInProgress = false;
	timeCooldown = 0;
}

void votePassedFunc() // Если голосование успешно, то выполняем...
{
	// AllTalk
	if (StrEqual(buferArgument, "ChangeAllTalk", false))
	{
		g_AllTalkCvar = FindConVar("sv_alltalk"); // Обращаемся к sv_alltalk
		if (GetConVarInt(g_AllTalkCvar)) // Если Alltalk включен (sv_alltalk 1)
		{
			keepAllTalk = false;
			SetConVarBool(g_AllTalkCvar, false); // Выключаем = sv_alltalk 0
			CPrintToChatAll("%t", "AllTalkOFF", PREFIX); // Общий чат выключен!
		}
		else
		{
			keepAllTalk = true; // Держим включенным alltalk всю игру
			SetConVarBool(g_AllTalkCvar, true); // = sv_alltalk 1
			CPrintToChatAll("%t", "AllTalkON", PREFIX); // Общий чат включен!
		}
		return;
	}
	// KickSpec
	if (StrEqual(buferArgument, "KickSpec", false))
	{
		for (int x = 1; x <= MaxClients; x++) // Проходим по всем клиентам сервера
		{
			if (IsValidClient(x) && GetClientTeam(x) == 1) // Если клиент человек и находится в команде наблюдателей, то...
			{
				KickClient(x, "%t", "KickSpecReason"); // "Вы были исключены голосованием !kickspec" 
			}
		}
		return;
	}
	// KillInfectedBots
	if (StrEqual(buferArgument, "KillBots", false))
	{
		for (int x = 1; x <= MaxClients; x++)
		{
			if (IsClientConnected(x) && IsFakeClient(x) && GetClientTeam(x) == 3)
			{
				ForcePlayerSuicide(x);
			}
		}
		return;
	}
	// VoteBoss
	if (StrEqual(buferArgument, "VoteBoss", false))
	{
		ServerCommand("sm_vbPass %s", buferArgument2); // Передаём sm_vbPass 10!20 или просто 10
		return;
	}
	// ChangeChapter
	if (StrEqual(buferArgument, "ChangeChapter", false))
	{
		FormatEx(mapForChange, sizeof(mapForChange), "%s", buferArgument2);
		delete map_Timer;
		map_Timer = CreateTimer(3.0, Timer_MapChange, true);
		return;
	}
	// ChangeMission
	if (StrEqual(buferArgument, "ChangeMission", false)) // В качестве аргумента приводится L4D2C8 вместо c8m1_apartments
	{
		char buf[sizeof(buferArgument2)];
		FormatEx(buf, sizeof(buf), "map%s", buferArgument2); // Добавляем к L4D2C1 слово map = mapL4D2C1
		FormatEx(mapForChange, sizeof(mapForChange), "%t", buf); // Даём mapL4D2C1, получаем c1m1_hotel
		delete map_Timer;
		map_Timer = CreateTimer(3.0, Timer_MapChange, true);
		return;
	}
	
	// Kick
	if (StrEqual(buferArgument, "Kick", false))
	{
		int cli = StringToInt(buferArgument2);
		if (!IsValidClient(cli)) { return; }
		KickClient(cli, "%t", "KickReason"); // "Вы были исключены голосованием"
		return;
	}
	
	// RestartGame
	if (StrEqual(buferArgument, "RestartGame", false))
	{
		GetCurrentMap(mapForChange, sizeof(mapForChange)); // Получаем называние карты (c8m1_apartments)
		delete map_Timer;
		map_Timer = CreateTimer(3.0, Timer_MapChange, false); // Меняем на ту же самую карту С СОХРАНЕНИЕМ ОЧКОВ
		return;
	}
}

public Action Timer_MapChange(Handle timer, any resetScores) // Таймер
{
	map_Timer = null; // Убиваем таймер
	L4D2_ChangeLevel(mapForChange, resetScores); // При помощи native void L4D2_ChangeLevel меняем карту.
	return Plugin_Stop;
}

public Action vote(int client, int args)
{
	if (VoteInProgress && CanPlayerVote[client] == true)
	{
		char arg[8];
		GetCmdArg(1, arg, sizeof(arg)); // Получаем аргумент Yes или No
		BfWrite voteCast = UserMessageToBfWrite(StartMessageOne("VoteRegistered", client, USERMSG_RELIABLE)); // Чтобы пометить выбор игрока в окне голосования
		//PrintToServer("Got vote %s from %i", arg, client); // Debug
		
		if (StrEqual(arg, "Yes", true)) // Если игрок нажал F1 (Vote Yes)
		{
			count_YesVotes++;
			voteCast.WriteByte(1);
		}
		else if (StrEqual(arg, "No", true)) // Если игрок нажал F2 (Vote No)
		{
			count_NoVotes++;
			voteCast.WriteByte(0);
		}
		EndMessage();
		CanPlayerVote[client] = false; // Запрещаем голосовать повторно
		UpdateVotes();
	}
	return Plugin_Handled;
}

bool IsValidClient(client) {
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

public Action voteYes(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++) // Заставляем всех клиентов...
	{
		if (IsValidClient(i)) {
			FakeClientCommandEx(i, "Vote Yes"); // ...голосовать ЗА
		}
	}
	return Plugin_Handled;
}
public Action voteNo(int client, int args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			FakeClientCommandEx(i, "Vote No");
		}
	}
	return Plugin_Handled;
}
public Action getAllTalk(int client, int args)
{
	g_AllTalkCvar = FindConVar("sv_alltalk");
	CPrintToChat(client, "%t", "AllTalkStatus", PREFIX, GetConVarInt(g_AllTalkCvar));
	return Plugin_Handled;
}
public Action resetVote(int client, int args)
{
	resetLimits(true);
	return Plugin_Handled;
}

public Action customVote(int client, int args)
{
	if (GetClientTeam(client) == L4D2_TEAM_SPECTATORS) { CPrintToChat(client, "%t", "SpecNoVote"); }
	if (args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_customVote \"Text\" \"Text after PASS vote\"");
		return Plugin_Handled;
	}
	if (VoteInProgress) { ReplyToCommand(client, "[SM] Vote in progress"); return Plugin_Handled; } // Голосование идёт? Выходим из функции
	GetCmdArg(1, voteName, sizeof(voteName));
	GetCmdArg(2, votePassAnswer, sizeof(votePassAnswer));
	createVote(client, L4D2_TEAM_ALL);
	return Plugin_Handled;
}

public Action restartChapterVote(int client, int args)
{
	FakeClientCommandEx(client, "callvote RestartGame"); // Вызываем рестарт карты
	return Plugin_Handled;
}

public Action kickSpecVote(int client, int args)
{
	FakeClientCommandEx(client, "callvote KickSpec");
	return Plugin_Handled;
}

public Action kickInfectedBotsVote(int client, int args)
{
	FakeClientCommandEx(client, "callvote KillBots");
	return Plugin_Handled;
}
public Action voteBossVote(int client, int args)
{
	if (args < 1) { CPrintToChat(client, "%t", "VoteBossCmd"); return Plugin_Handled; }
	if (GetCurFlow() > 4.0) { CPrintToChat(client, "%t", "VoteBossNotAllowed"); return Plugin_Handled; }
	GetCmdArg(1, argOne, sizeof(argOne));
	GetCmdArg(2, argTwo, sizeof(argTwo));
	if (args == 2) {
		Format(argOne, sizeof(argOne), "%s!%s", argOne, argTwo);
	}
	
	FakeClientCommandEx(client, "callvote VoteBoss %s", argOne);
	return Plugin_Handled;
}

public RoundStartEvent(Handle event, const char[] name, bool dontBroadcast) // Сервер запустился
{
	CreateTimer(0.5, keepAlltalk);
}
public Action keepAlltalk(Handle timer)
{
	if (!keepAllTalk) { return Plugin_Handled; }
	g_AllTalkCvar = FindConVar("sv_alltalk"); // Обращаемся к sv_alltalk
	SetConVarBool(g_AllTalkCvar, true); // = sv_alltalk 1
	return Plugin_Handled;
}

void resetLimits(bool all = true, int cli = 0) // Сброс лимитов на возможность вызывать голосование 
{
	if (!all) {
		playerLimit[cli] = _voteLimit;
		return;
	}
	for (int i = 1; i < MaxClients; i++)
	{
		playerLimit[i] = _voteLimit;
	}
}
public Action PlayerDisconnect_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	resetLimits(false, client);
	return Plugin_Handled;
}

// VoteBoss
int GetWitchFlow()
{
	Handle g_hVsBossBuffer;
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");
	return RoundToFloor((L4D2Direct_GetVSWitchFlowPercent(GameRules_GetProp("m_bInSecondHalfOfRound")) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance()) * 100);
}
float GetCurFlow()
{
	return map(L4D2_GetFurthestSurvivorFlow(), 0.0, L4D2Direct_GetMapMaxFlowDistance(), 0.0, 100.0);
}
stock float map(float x, float in_min, float in_max, float out_min, float out_max) // Пропорция
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
} 
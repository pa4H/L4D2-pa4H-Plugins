#include <sourcemod>
#include <colors>
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3
int p1, p2;
char clName[32];
char clNum[4];

public Plugin myinfo = 
{
	name = "TeamSwitcher", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	
	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_BAN, "Swap 2 players menu");
	RegAdminCmd("sm_swapto", Command_SwapTo, ADMFLAG_BAN, "Swap to <team> menu");
	RegAdminCmd("sm_swapmenu", Command_SwapMenu, ADMFLAG_BAN, "Show menu with player list");
}
stock Action debb(int client, int args) // DEBUG
{
	
	return Plugin_Handled;
}

public Action Command_Swap(int client, int args)
{
	Menu menu = new Menu(Menu_Swap1); // Внутри скобок обработчик нажатий меню
	menu.SetTitle("Select 1 player");
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i)) { GetClientName(i, clName, sizeof(clName)); FormatEx(clNum, sizeof(clNum), "%i", i); menu.AddItem(clNum, clName); }
		menu.Display(client, 15);
	}
	return Plugin_Handled;
}

public Menu_Swap1(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		char szInfo[4];
		menu.GetItem(param2, szInfo, sizeof(szInfo)); // Получаем описание пункта по которому нажал игрок
		p1 = StringToInt(szInfo);
		
		Menu menu2 = new Menu(Menu_Swap2); // Внутри скобок обработчик нажатий меню
		menu2.SetTitle("Select 2 player");
		for (new i = 0; i < MaxClients; i++)
		{
			if (IsValidClient(i) && i != p1) { GetClientName(i, clName, sizeof(clName)); FormatEx(clNum, sizeof(clNum), "%i", i); menu2.AddItem(clNum, clName); }
		}
		menu2.Display(client, 15);
	}
}
public Menu_Swap2(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		char szInfo[4];
		menu.GetItem(param2, szInfo, sizeof(szInfo)); // Получаем описание пункта по которому нажал игрок
		p2 = StringToInt(szInfo);
		
		int p1team = GetClientTeam(p1);
		ChangeClientTeam(p1, L4D_TEAM_SPECTATOR);
		swapToTeam(p2, p1team);
		swapToTeam(p1, p1team == L4D_TEAM_SURVIVOR ? L4D_TEAM_INFECTED : L4D_TEAM_SURVIVOR);
		
		PrintToChat(client, "[SM] Players swapped");
	}
}

public Action Command_SwapTo(int client, int args)
{
	Menu menu = new Menu(Menu_SwapTo1); // Внутри скобок обработчик нажатий меню
	menu.SetTitle("Select player");
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i)) { GetClientName(i, clName, sizeof(clName)); FormatEx(clNum, sizeof(clNum), "%i", i); menu.AddItem(clNum, clName); }
		menu.Display(client, 15);
	}
	return Plugin_Handled;
}

public Menu_SwapTo1(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		char szInfo[4];
		menu.GetItem(param2, szInfo, sizeof(szInfo)); // Получаем описание пункта по которому нажал игрок
		p1 = StringToInt(szInfo);
		
		Menu menu2 = new Menu(Menu_SwapTo2); // Внутри скобок обработчик нажатий меню
		menu2.SetTitle("Select team");
		menu2.AddItem("2", "Survivor");
		menu2.AddItem("3", "Infected");
		menu2.AddItem("1", "Spectator");
		menu2.Display(client, 15);
	}
}
public Menu_SwapTo2(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		char szInfo[4];
		menu.GetItem(param2, szInfo, sizeof(szInfo)); // Получаем описание пункта по которому нажал игрок
		int team = StringToInt(szInfo);
		if (getTeamCount(team) < 4) {
			if (team == 1) {
				swapToTeam(p1, 1); }
			else {
				swapToTeam(p1, team);
			}
			PrintToChat(client, "[SM] Player swaped to team");
		}
		else
		{
			PrintToChat(client, "[SM] Team is full");
		}
	}
}

public Action Command_SwapMenu(int client, int args)
{
	Menu menu = new Menu(Menu_SwapMenu); // Внутри скобок обработчик нажатий меню
	getTeamCount(L4D_TEAM_SURVIVOR) > 0 ? menu.SetTitle("SURVIVORS:") : menu.SetTitle("INFECTED:");
	int max = 0;
	int maxSur = getTeamCount(L4D_TEAM_SURVIVOR);
	int maxInf = getTeamCount(L4D_TEAM_INFECTED);
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = false;
	
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == L4D_TEAM_SURVIVOR) {
			max++;
			GetClientName(i, clName, sizeof(clName));
			FormatEx(clNum, sizeof(clNum), "%i", i);
			if (max == maxSur) { FormatEx(clName, sizeof(clName), "%s\nINFECTED:", clName); }
			menu.AddItem(clNum, clName);
		}
	}
	max = 0;
	
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == L4D_TEAM_INFECTED) {
			max++;
			GetClientName(i, clName, sizeof(clName));
			FormatEx(clNum, sizeof(clNum), "%i", i);
			if (max == maxInf) { FormatEx(clName, sizeof(clName), "%s\nSPECTATORS:", clName); }
			menu.AddItem(clNum, clName); }
	}
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == L4D_TEAM_SPECTATOR) { GetClientName(i, clName, sizeof(clName)); FormatEx(clNum, sizeof(clNum), "%i", i); menu.AddItem(clNum, clName); }
	}
	menu.Display(client, 15);
	return Plugin_Handled;
}

public Menu_SwapMenu(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		char szInfo[4];
		menu.GetItem(param2, szInfo, sizeof(szInfo)); // Получаем описание пункта по которому нажал игрок
		p1 = StringToInt(szInfo);
		int p1Team = GetClientTeam(p1);
		if (GetClientTeam(p1) != L4D_TEAM_SPECTATOR)
		{
			if (getTeamCount(p1Team == L4D_TEAM_SURVIVOR ? L4D_TEAM_INFECTED : L4D_TEAM_SURVIVOR) < 4)
			{
				swapToTeam(p1, p1Team == L4D_TEAM_SURVIVOR ? L4D_TEAM_INFECTED : L4D_TEAM_SURVIVOR);
				PrintToChat(client, "[SM] Player swapped");
			}
			else
			{
				swapToTeam(p1, L4D_TEAM_SPECTATOR);
				PrintToChat(client, "[SM] Team is full. Swapped to spec");
			}
		}
		else // spectator
		{
			if (getTeamCount(L4D_TEAM_SURVIVOR) != 4)
			{
				swapToTeam(p1, L4D_TEAM_SURVIVOR);
				PrintToChat(client, "[SM] Spec swapped to surv");
			}
			else
			{
				swapToTeam(p1, L4D_TEAM_INFECTED);
				PrintToChat(client, "[SM] Spec swapped to inf");
			}
		}
	}
}

void swapToTeam(int client, int team)
{
	switch (team)
	{
		case 1: // Spec
		{
			ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
		}
		case 2: // Surv
		{
			char botName[16];
			for (int i = 1; i < MaxClients; i++)
			{
				if (IsClientConnected(i) && IsFakeClient(i) && GetClientTeam(i) == 2) {
					GetClientName(i, botName, sizeof(botName));
					if (strcmp(botName, "Bill") == 0) {
						break;
					}
					if (strcmp(botName, "Louis") == 0) {
						break;
					}
					if (strcmp(botName, "Zoey") == 0) {
						break;
					}
					if (strcmp(botName, "Francis") == 0) {
						break;
					}
				}
			}
			
			int flagsgive = GetCommandFlags("sb_takecontrol");
			SetCommandFlags("sb_takecontrol", flagsgive & ~FCVAR_CHEAT);
			FakeClientCommand(client, "sb_takecontrol %s", botName);
			SetCommandFlags("sb_takecontrol", flagsgive | FCVAR_CHEAT);
		}
		case 3: // Inf
		{
			FakeClientCommand(client, "jointeam 3");
		}
	}
	
}

int getTeamCount(int team)
{
	int count;
	for (new i = 0; i < MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == team) { count++; }
	}
	return count;
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client) && IsClientInGame(client)) {
		return true;
	}
	return false;
}
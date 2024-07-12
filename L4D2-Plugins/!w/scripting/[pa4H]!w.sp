#include <sourcemod>
#include <colors>

int limits[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Whe", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	HookEvent("round_start", resetLimits, EventHookMode_Pre);
	HookEvent("scavenge_round_start", resetLimits, EventHookMode_Pre);
	HookEvent("round_end", resetLimits, EventHookMode_Pre);
	
	RegConsoleCmd("sm_w", showMenu);
	RegConsoleCmd("sm_t1", showGunsMenu);
	RegConsoleCmd("sm_melee", showMeleeMenu);
	
	// Guns
	RegConsoleCmd("sm_shotgun", gChrome);
	RegConsoleCmd("sm_pump", gPump);
	RegConsoleCmd("sm_chrome", gChrome);
	RegConsoleCmd("sm_smg", gSmg);
	RegConsoleCmd("sm_uzi", gUzi);
	RegConsoleCmd("sm_sniper", gScout);
	RegConsoleCmd("sm_scout", gScout);
	
	// Melee
	RegConsoleCmd("sm_knife", gKnife);
	RegConsoleCmd("sm_fireaxe", gAxe);
	RegConsoleCmd("sm_axe", gAxe);
	RegConsoleCmd("sm_katana", gKatana);
	RegConsoleCmd("sm_machete", gMachete);
	RegConsoleCmd("sm_pan", gPan);
	RegConsoleCmd("sm_fryingpan", gPan);
	
	LoadTranslations("pa4HWhe.phrases");
}

Action gPump(int client, int args)
{
	giveItem(client, "pumpshotgun");
	return Plugin_Handled;
}
Action gChrome(int client, int args)
{
	giveItem(client, " shotgun_chrome ");
	return Plugin_Handled;
}
Action gSmg(int client, int args)
{
	giveItem(client, "smg_silenced");
	return Plugin_Handled;
}
Action gUzi(int client, int args)
{
	giveItem(client, "smg");
	return Plugin_Handled;
}
Action gScout(int client, int args)
{
	giveItem(client, "sniper_scout");
	return Plugin_Handled;
}

Action gKnife(int client, int args)
{
	giveItem(client, "knife");
	return Plugin_Handled;
}
Action gAxe(int client, int args)
{
	giveItem(client, "fireaxe");
	return Plugin_Handled;
}
Action gKatana(int client, int args)
{
	giveItem(client, "katana");
	return Plugin_Handled;
}
Action gMachete(int client, int args)
{
	giveItem(client, "machete");
	return Plugin_Handled;
}
Action gPan(int client, int args)
{
	giveItem(client, "frying_pan");
	return Plugin_Handled;
}

Action showMeleeMenu(int client, int args)
{
	meleeMenu(client);
	return Plugin_Handled;
}

Action showGunsMenu(int client, int args)
{
	gunsMenu(client);
	return Plugin_Handled;
}

void meleeMenu(int client)
{
	char buf[32];
	Menu mel = new Menu(Melee_VotePoll);
	mel.SetTitle("%T", "SelectMelee", client, limits[client]);
	FormatEx(buf, sizeof(buf), "%T", "Knife", client);
	mel.AddItem("knife", buf);
	FormatEx(buf, sizeof(buf), "%T", "Fireaxe", client);
	mel.AddItem("fireaxe", buf);
	FormatEx(buf, sizeof(buf), "%T", "Katana", client);
	mel.AddItem("katana", buf);
	FormatEx(buf, sizeof(buf), "%T", "Machete", client);
	mel.AddItem("machete", buf);
	FormatEx(buf, sizeof(buf), "%T", "Pan", client);
	mel.AddItem("frying_pan", buf);
	
	mel.Display(client, 15);
}

void gunsMenu(int client)
{
	char buf[32];
	Menu gun = new Menu(Melee_VotePoll);
	gun.SetTitle("%T", "SelectGun", client, limits[client]);
	FormatEx(buf, sizeof(buf), "%T", "Pump", client);
	gun.AddItem("pumpshotgun", buf);
	FormatEx(buf, sizeof(buf), "%T", "Chrome", client);
	gun.AddItem("shotgun_chrome", buf);
	FormatEx(buf, sizeof(buf), "%T", "Smg", client);
	gun.AddItem("smg_silenced", buf);
	FormatEx(buf, sizeof(buf), "%T", "Uzi", client);
	gun.AddItem("smg", buf);
	FormatEx(buf, sizeof(buf), "%T", "Sniper", client);
	gun.AddItem("sniper_scout", buf);
	
	gun.Display(client, 15);
}

Action showMenu(int client, int args)
{
	Menu menu = new Menu(Menu_VotePoll); // Внутри скобок обработчик нажатий меню
	menu.SetTitle("%T", "SelectWeapon", client, limits[client]); // Заголовок меню
	
	char wName[32];
	FormatEx(wName, sizeof(wName), "%T", "Melee", client);
	menu.AddItem("mel", wName);
	FormatEx(wName, sizeof(wName), "%T", "Guns", client);
	menu.AddItem("gun", wName);
	
	menu.Display(client, 15);
	return Plugin_Handled;
}

public Menu_VotePoll(Menu menu, MenuAction action, int client, int param2) // Обработчик нажатия кнопок в меню
{
	if (action == MenuAction_Select) // Если нажали кнопку от 1 до 7 включительно
	{
		char arg[32];
		menu.GetItem(param2, arg, sizeof(arg)); // Получаем описание пункта по которому нажал игрок
		if (StrEqual(arg, "mel") == true)
		{
			meleeMenu(client);
		}
		else if (StrEqual(arg, "gun") == true)
		{
			gunsMenu(client);
		}
	}
}

public Melee_VotePoll(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char szInfo[32];
		menu.GetItem(param2, szInfo, sizeof(szInfo));
		giveItem(client, szInfo)
	}
}

void giveItem(int client, char[] args)
{
	if (!IsPlayerAlive(client)) { return; }
	if (GetClientTeam(client) != 2) { CPrintToChat(client, "%t", "OnlySurv"); return; }
	if (limits[client] > 4) { CPrintToChat(client, "%t", "Limits"); return; } else { limits[client]++; }
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", args);
	SetCommandFlags("give", flagsgive | FCVAR_CHEAT);
}

public resetLimits(Event hEvent, const char[] sEvName, bool bDontBroadcast)
{
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		limits[i] = 0;
	}
}

stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}

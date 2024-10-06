#include <sourcemod>
#include <colors>
#include <sdkhooks>
#include <sdktools>

int limits[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Whe", 
	author = "pa4H", 
	description = "AllWeapons", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	HookEvent("round_start", resetLimits, EventHookMode_Pre);
	HookEvent("scavenge_round_start", resetLimits, EventHookMode_Pre);
	HookEvent("round_end", resetLimits, EventHookMode_Pre);
	
	RegConsoleCmd("sm_w", showMenu);
	RegConsoleCmd("sm_melee", showMeleeMenu);
	RegConsoleCmd("sm_t1", showT1Menu);
	RegConsoleCmd("sm_t2", showT2Menu);
	
	// T1
	RegConsoleCmd("sm_shotgun", gChrome);
	RegConsoleCmd("sm_pump", gPump);
	RegConsoleCmd("sm_chrome", gChrome);
	RegConsoleCmd("sm_smg", gSmg);
	RegConsoleCmd("sm_smgs", gSmg);
	RegConsoleCmd("sm_uzi", gUzi);
	RegConsoleCmd("sm_sniper", gScout);
	RegConsoleCmd("sm_scout", gScout);
	RegConsoleCmd("sm_awp", giveAWP);
	
	// T2
	RegConsoleCmd("sm_magnum", giveMagnum);
	RegConsoleCmd("sm_hunter", gHunter);
	RegConsoleCmd("sm_military", gMilitary);
	RegConsoleCmd("sm_mil", gMilitary);
	RegConsoleCmd("sm_autoshotgun", gAutoshotgun);
	RegConsoleCmd("sm_auto", gAutoshotgun);
	RegConsoleCmd("sm_spas", gSpas);
	RegConsoleCmd("sm_m4", gM4);
	RegConsoleCmd("sm_scar", gScar);
	RegConsoleCmd("sm_ak47", gAK);
	
	// Melee
	RegConsoleCmd("sm_knife", gKnife);
	RegConsoleCmd("sm_fireaxe", gAxe);
	RegConsoleCmd("sm_axe", gAxe);
	RegConsoleCmd("sm_katana", gKatana);
	RegConsoleCmd("sm_machete", gMachete);
	RegConsoleCmd("sm_pan", gPan);
	RegConsoleCmd("sm_fryingpan", gPan);
	
	LoadTranslations("pa4H-Whe.phrases");
}

// T1

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
Action giveAWP(int client, int args)
{
	giveItem(client, "sniper_awp");
	return Plugin_Handled;
}

// T2
Action gM4(int client, int args)
{
	giveItem(client, "weapon_rifle");
	return Plugin_Handled;
}
Action gAutoshotgun(int client, int args)
{
	giveItem(client, "weapon_autoshotgun");
	return Plugin_Handled;
}
Action gSpas(int client, int args)
{
	giveItem(client, "weapon_shotgun_spas");
	return Plugin_Handled;
}

Action gScar(int client, int args)
{
	giveItem(client, "weapon_rifle_desert");
	return Plugin_Handled;
}
Action gAK(int client, int args)
{
	giveItem(client, "weapon_rifle_ak47");
	return Plugin_Handled;
}
Action gMilitary(int client, int args)
{
	giveItem(client, "weapon_sniper_military");
	return Plugin_Handled;
}
Action gHunter(int client, int args)
{
	giveItem(client, "weapon_hunting_rifle");
	return Plugin_Handled;
}
Action giveMagnum(int client, int args)
{
	giveItem(client, "weapon_pistol_magnum");
	return Plugin_Handled;
}

// Melee

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

// Менюшки

Action showMeleeMenu(int client, int args)
{
	meleeMenu(client);
	return Plugin_Handled;
}

Action showT1Menu(int client, int args)
{
	t1Menu(client);
	return Plugin_Handled;
}
Action showT2Menu(int client, int args)
{
	t2Menu(client);
	return Plugin_Handled;
}

void meleeMenu(int client)
{
	char buf[32];
	Menu mel = new Menu(GunsMenu_handler);
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

void t1Menu(int client)
{
	char buf[32];
	Menu gun = new Menu(GunsMenu_handler);
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
void t2Menu(int client)
{
	char buf[64];
	Menu gun = new Menu(GunsMenu_handler);
	gun.SetTitle("%T", "SelectGun", client, limits[client]);
	FormatEx(buf, sizeof(buf), "%T", "Hunter", client);
	gun.AddItem("weapon_hunting_rifle", buf);
	FormatEx(buf, sizeof(buf), "%T", "Military", client);
	gun.AddItem("weapon_sniper_military", buf);
	FormatEx(buf, sizeof(buf), "%T", "Autoshotgun", client);
	gun.AddItem("weapon_autoshotgun", buf);
	FormatEx(buf, sizeof(buf), "%T", "Spas", client);
	gun.AddItem("weapon_shotgun_spas", buf);
	FormatEx(buf, sizeof(buf), "%T", "M4", client);
	gun.AddItem("weapon_rifle", buf);
	FormatEx(buf, sizeof(buf), "%T", "AK47", client);
	gun.AddItem("weapon_rifle_ak47", buf);
	FormatEx(buf, sizeof(buf), "%T", "Scar", client);
	gun.AddItem("weapon_rifle_desert", buf);
	
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
	menu.AddItem("gun1", wName);
	FormatEx(wName, sizeof(wName), "%T", "Guns2", client);
	menu.AddItem("gun2", wName);
	
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
		else if (StrEqual(arg, "gun1") == true)
		{
			t1Menu(client);
		}
		else if (StrEqual(arg, "gun2") == true)
		{
			showT2Menu(client, 0);
		}
	}
}

public GunsMenu_handler(Menu menu, MenuAction action, int client, int param2)
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
	for (int i = 1; i <= MAXPLAYERS; i++)
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

stock bool IsValidClientWBots(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
} 
#include <sourcemod>
#include <colors>

KeyValues kv;
ConVar g_hInterval;
Handle g_hTimer;
ArrayList hArray;

int pos = 0;
char buf[256];

public Plugin myinfo = 
{
	name = "SimpleAdv", 
	author = "pa4H, Tsunami", 
	description = "Display advertisements", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");
	
	g_hInterval = CreateConVar("sm_advertisements_interval", "45", "Number of seconds between advertisements.");
	
	hArray = new ArrayList(ByteCountToCells(256));
	
	char kvPath[256]
	BuildPath(Path_SM, kvPath, sizeof(kvPath), "data/Advertisements.txt");
	kv = new KeyValues("Adv");
	if (!FileToKeyValues(kv, kvPath)) {
		PrintToServer("Error loading Advertisements");
	}
}
stock Action debb(int client, int args) // DEBUG
{
	for (int i = 0; i < hArray.Length; i++)
	{
		hArray.GetString(i, buf, sizeof(buf));
		CPrintToChatAll("%s", buf);
	}
	return Plugin_Handled;
}

public Action Timer_DisplayAd(Handle timer)
{
	hArray.GetString(pos, buf, sizeof(buf));
	CPrintToChatAll("%s", buf);
	pos++;
	if (pos > hArray.Length - 1) { pos = 0; }
	return Plugin_Continue;
}

public void OnConfigsExecuted()
{
	ParseAdv();
	RestartTimer();
}

void ParseAdv()
{
	pos = 0;
	
	hArray.Clear();
	kv.Rewind();
	if (kv.GotoFirstSubKey())
	{
		do 
		{
			kv.GetString("chat", buf, sizeof(buf));
			hArray.PushString(buf);
		} while (kv.GotoNextKey()); 
	}
	
}

void RestartTimer()
{
	delete g_hTimer;
	g_hTimer = CreateTimer(GetConVarFloat(g_hInterval), Timer_DisplayAd, _, TIMER_REPEAT);
}

public Action Command_ReloadAds(int args)
{
	ParseAdv();
	return Plugin_Handled;
}

stock bool Contains(const char[] one, const char[] two)
{
	if (StrContains(one, two, false) != -1) { return true; } else { return false; }
}
stock bool IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
} 
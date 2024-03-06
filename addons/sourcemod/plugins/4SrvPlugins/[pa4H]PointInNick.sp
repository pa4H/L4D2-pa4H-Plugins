#include <sourcemod>
#include <colors>
#include <sdktools>
#include <sdkhooks>

ArrayList newNames;
char newNick[64];
bool firstRun = true;

public Plugin myinfo = 
{
	name = "PointInNick", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	//RegConsoleCmd("sm_test", debb, "");
	
	UserMsg UMsg = GetUserMessageId("SayText2");
	HookUserMessage(UMsg, SayText2, true);
	
	newNames = new ArrayList(ByteCountToCells(64));
}
stock Action debb(int client, int args) // DEBUG
{
	OnClientPutInServer(client);
	return Plugin_Handled;
}

public Action SayText2(UserMsg msg_id, Handle msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char sMessage[64];
	BfReadString(msg, sMessage, sizeof(sMessage));
	BfReadString(msg, sMessage, sizeof(sMessage));
	if (StrContains(sMessage, "Name_Change") != -1)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	if (firstRun) {
		firstRun = false;
		char szLine[64];
		File rFile = OpenFile("addons/sourcemod/data/NewNames.txt", "r");
		while (!rFile.EndOfFile() && rFile.ReadLine(szLine, sizeof(szLine)))
		{
			TrimString(szLine);
			newNames.PushString(szLine);
		}
		delete rFile;
	}
	
	if (IsFakeClient(client)) { return; }
	char nick[64]
	GetClientName(client, nick, sizeof(nick));
	if (Contains(nick, ".")) {
		getRandomNick();
		SetClientName(client, newNick);
	}
}

void getRandomNick()
{
	newNames.GetString(GetRandomInt(0, newNames.Length - 1), newNick, sizeof(newNick));
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
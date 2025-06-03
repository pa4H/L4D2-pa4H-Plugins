#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "PlayerColorizer", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public OnPluginStart()
{
	RegAdminCmd("sm_randcolor", setRandomColor, ADMFLAG_BAN);
	RegAdminCmd("sm_setColor", setColor, ADMFLAG_BAN);
}
stock Action setRandomColor(int client, int args)
{
	if (!IsValidClient(client)) { return Plugin_Handled; }
	int R = GetRandomInt(1, 255);
	int G = GetRandomInt(1, 255);
	int B = GetRandomInt(1, 255);
	
	SetEntityRenderColor(client, R, G, B, 255);
	return Plugin_Handled;
}

stock Action setColor(int client, int args)
{
	if (!IsValidClientB(client)) { return Plugin_Handled; }
	char argOne[4];
	char argTwo[16];
	int cli = 0;
	GetCmdArg(1, argOne, sizeof(argOne)); // Номер клиента
	GetCmdArg(2, argTwo, sizeof(argTwo)); // 255,255,255
	
	cli = StringToInt(argOne);
	if (!IsValidClientB(cli)) { return Plugin_Handled; }
	char parts[3][8]; // 4 числа, максимум по 8 символов каждое
	ExplodeString(argTwo, ",", parts, sizeof(parts), sizeof(parts[]));
	
	SetEntityRenderColor(cli, StringToInt(parts[0]), StringToInt(parts[1]), StringToInt(parts[2]), 255);
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client)) {
		return true;
	}
	return false;
}
stock bool IsValidClientB(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
}
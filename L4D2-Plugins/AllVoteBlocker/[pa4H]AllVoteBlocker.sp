#include <sourcemod>

public Plugin myinfo = 
{
	name = "All Vote Blocker", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{	
	AddCommandListener(Listener_CallVote, "callvote"); // Обработчик команды callvote
}

public Action Listener_CallVote(int client, const char[] command, argc)
{
	return Plugin_Handled;
}
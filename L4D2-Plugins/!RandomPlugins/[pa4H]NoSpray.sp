#include <sourcemod>

public Plugin myinfo = 
{
	name = "NoSpray", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "https://t.me/pa4H232"
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse)
{
	if(impulse == 201)
	{
		impulse = 0;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}
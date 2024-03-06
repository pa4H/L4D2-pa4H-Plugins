#include <sourcemod>
#include <sdktools>
public Plugin myinfo = 
{
	name = "Server cmds", 
	author = "pa4H", 
	description = "", 
	version = "1.0", 
	url = "vk.com/pa4h1337"
}

public OnPluginStart()
{
	//RegAdminCmd("sm_test", TestTest, ADMFLAG_BAN);
	RegAdminCmd("sm_refreshplugins", refreshPlugins, ADMFLAG_BAN);
	RegAdminCmd("sm_refreshserver", refreshPlugins, ADMFLAG_BAN);
	RegAdminCmd("sm_rsh", refreshPlugins, ADMFLAG_BAN);
	
	RegAdminCmd("sm_servercfg", refreshServercfg, ADMFLAG_BAN);
	
	RegAdminCmd("sm_director_start", directorStart, ADMFLAG_BAN);
	RegAdminCmd("sm_director_stop", directorStop, ADMFLAG_BAN);
	
	RegAdminCmd("sm_grabTank", grabTank, ADMFLAG_BAN); // need !passtank.smx
	
	RegAdminCmd("sm_killall", killHelp, ADMFLAG_BAN);
	RegAdminCmd("sm_allkill", killHelp, ADMFLAG_BAN);
	RegAdminCmd("sm_killsurv", killAllSurv, ADMFLAG_BAN);
	RegAdminCmd("sm_killsur", killAllSurv, ADMFLAG_BAN);
	RegAdminCmd("sm_killinf", killAllInf, ADMFLAG_BAN);
}
stock Action TestTest(client, args)
{
	return Plugin_Handled;
}
Action killHelp(client, args)
{
	PrintToChat(client, "Use: !killsur, !killinf");
	return Plugin_Handled;
}
public Action killAllSurv(client, args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2)
		{
			ForcePlayerSuicide(i);
		}
	}
	return Plugin_Handled;
}
public Action killAllInf(client, args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 3)
		{
			ForcePlayerSuicide(i);
		}
	}
	return Plugin_Handled;
}

public Action grabTank(client, args) // need !passtank.smx
{
	FakeClientCommand(client, "sm_forcepass #%i", GetClientUserId(client));
	return Plugin_Handled;
}
public Action refreshPlugins(client, args)
{
	ServerCommand("sm plugins refresh");
	ServerCommand("sm_reload_translations");
	PrintToConsole(client, "Plugins refreshed!");
	return Plugin_Handled;
}
public Action refreshServercfg(client, args)
{
	ServerCommand("exec server.cfg");
	PrintToConsole(client, "server.cfg executed!");
	return Plugin_Handled;
}
public Action directorStart(client, args)
{
	ExecuteCheatCommand("director_start");
	PrintToConsole(client, "Director Started");
	return Plugin_Handled;
}
public Action directorStop(client, args)
{
	ExecuteCheatCommand("director_stop");
	PrintToConsole(client, "Director Stopped");
	return Plugin_Handled;
}

void ExecuteCheatCommand(const char[] command, const char[] value = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags);
} 
public RoundStartPills(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(10.0, GivePillsTimer);
}
public Action GivePillsTimer(Handle timer)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && VIPPlayers[i] && GetClientTeam(i) == 2)
		{
			int iWeapon1 = GetPlayerWeaponSlot(i, 2);
			int iWeapon2 = GetPlayerWeaponSlot(i, 4);
			char slot2[32];
			char slot4[32];
			if (iWeapon1 != -1) { GetEntityClassname(iWeapon1, slot2, sizeof(slot2)); }
			if (iWeapon2 != -1) { GetEntityClassname(iWeapon2, slot4, sizeof(slot4)); }
			if (StrEqual(slot2, "", false) == true) { (GetRandomInt(0, 1) == 1) ? FakeClientCommand(i, "give pipe_bomb") : FakeClientCommand(i, "give vomitjar"); }
			if (StrEqual(slot4, "", false) == true) { (GetRandomInt(0, 1) == 1) ? FakeClientCommand(i, "give pain_pills") : FakeClientCommand(i, "give adrenaline"); }
		}
	}
	SetCommandFlags("give", flags | FCVAR_CHEAT);
	return Plugin_Stop;
} 
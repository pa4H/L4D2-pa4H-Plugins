public RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	canFill = 0;
	for (int client = 1; client < MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			SetGlobalTransTarget(client);
			scoreA = GetScavengeTeamScore(2); scoreB = GetScavengeTeamScore(3);
			learnSlovoA(); learnSlovoB();			
			int clientTeam = GetClientTeam(client);
			
			if (GameRules_GetProp("m_bInSecondHalfOfRound") == 1) // Если конец раунда
			{
				if (scoreA > scoreB) // Победа выживших по очкам
				{
					if (clientTeam == 1)
					{
						FormatEx(txtBufer, sizeof(txtBufer), "%t", "CanWinnerSur", scoreA);
					}
					else if (clientTeam == 2) // Показываем команде A (победителям)
					{
						FormatEx(txtBufer, sizeof(txtBufer), "%t", "WinnerYou", scoreA, slovoA);				
					}
					else if (clientTeam == 3) // Показываем команде B (проигравшим)
					{
						FormatEx(txtBufer, sizeof(txtBufer), "%t", "LooserYou", scoreB, slovoB);
					}
				}
				else if (scoreA < scoreB) // Победа зараженных по очкам
				{
					if (clientTeam == 1)
					{
						FormatEx(txtBufer, sizeof(txtBufer), "%t", "CanWinnerInf", scoreB);
					}
					else if (clientTeam == 2)
					{
						FormatEx(txtBufer, sizeof(txtBufer), "%t", "LooserYou", scoreB, slovoB);
					}
					else if (clientTeam == 3)
					{
						FormatEx(txtBufer, sizeof(txtBufer), "%t", "WinnerYou", scoreA, slovoA);					
					}
				}
				else if (scoreA == scoreB) // Считаем у кого больше времени
				{
					if (scoreA == 0 && scoreB == 0) // Если по нулям, то побеждает тот, кто дольше выжил
					{
						if (GameRules_GetRoundDuration(2) > GameRules_GetRoundDuration(3)) //  Если дольше выживали выжившие
						{
							int tim = RoundToFloor(GameRules_GetRoundDuration(2)) - RoundToFloor(GameRules_GetRoundDuration(3));
							if (clientTeam == 1)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "SurvWinnerSur", tim);
							}
							else if (clientTeam == 2) //Показываем команде 2 (победителям)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "WinnerTimeSurvYou", tim);					
							}
							else if (clientTeam == 3) //Показываем команде 3 (проигравшим)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "LooserTimeSurvYou", tim);											
							}
						}
						else // Если дольше выживали зараженные
						{
							int tim = RoundToFloor(GameRules_GetRoundDuration(3)) - RoundToFloor(GameRules_GetRoundDuration(2));
							if (clientTeam == 1)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "SurvWinnerInf", tim);
							}
							else if (clientTeam == 2)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "LooserTimeSurvYou", tim);				
							}
							else if (clientTeam == 3)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "WinnerTimeSurvYou", tim);													
							}
						}
					}
					else if (scoreA > 0 && scoreB > 0) // Если 21 21  
					{
						if (GameRules_GetRoundDuration(2) < GameRules_GetRoundDuration(3)) // Если выжившие быстрее собрали одинаковое количество кан
						{  // Считаем у кого меньше времени
							if (clientTeam == 1)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "TimeWinnerSur", scoreA, slovoA);
							}
							else if (clientTeam == 2) // Показываем команде 2 (победителям)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "WinnerTimeYou", scoreA, slovoA);
							}
							else // Показываем команде 3 (проигравшим)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "LooserTimeYou", scoreB, slovoB);															
							}
						}
						else // Если команда выживших медленнее собрала каны
						{
							if (clientTeam == 1)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "TimeWinnerInf", scoreB, slovoB);
							}
							else if (clientTeam == 2)
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "LooserTimeYou", scoreB, slovoB);									
							}
							else
							{
								FormatEx(txtBufer, sizeof(txtBufer), "%t", "WinnerTimeYou", scoreA, slovoA);							
							}
						}
					}
				}
			}
			else // Если половинка раунда
			{
				GetTimer(2);
				if (clientTeam == 1) {
					FormatEx(txtBufer, sizeof(txtBufer), "%t", "Half1", scoreA, slovoA, txtTime);	
				} 
				else if (clientTeam == 2) {
					FormatEx(txtBufer, sizeof(txtBufer), "%t", "Half2", scoreA, slovoA, txtTime);	
				}
				else if (clientTeam == 3) {
					FormatEx(txtBufer, sizeof(txtBufer), "%t", "Half3", scoreA, slovoA, txtTime);			
				}
			}
			CPrintToChat(client, txtBufer);
		}
	}
}
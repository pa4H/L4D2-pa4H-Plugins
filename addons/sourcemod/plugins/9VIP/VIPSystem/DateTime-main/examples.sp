#include <sourcemod>
#include <DateTime>

#pragma tabsize 0;
#pragma newdecls required;
#pragma semicolon 1;

public Plugin myinfo = 
{
	name = "DateTime & TimeSpan examples",
	author = "Nexd",
	description = "",
	version = "1.0",
	url = "https://github.com/KillStr3aK"
};

public void OnPluginStart()
{
	DateTime dateTime = new DateTime(DateTime_Now);

	char szDate[DATE_LENGTH];
	dateTime.ToString(szDate, sizeof(szDate));
	PrintToChatAll("Current time is: %s (Unix: %i)", szDate, dateTime.Unix);

	dateTime += TimeSpan.FromHours(2);
	dateTime.ToString(szDate, sizeof(szDate));
	PrintToChatAll("Time 2 hours later: %s (Unix: %i)", szDate, dateTime.Unix);

	char stringDate[DATE_LENGTH] = "2021-07-19 10:22:35"; // 2021-07-19 is also valid, it equals to 2021-07-19 00:00:00
	DateTime parsedDateTime;

	// atm, stringDate contains a valid date, so if you know that the input will 'always' be okay, you can just use DateTime dt = DateTime.Parse(input); to avoid pointless checks & so.
	// you may want to use DateTime.TryParse when you wait for user input or so.
	if(DateTime.TryParse(stringDate, parsedDateTime))
	{
		parsedDateTime.ToString(szDate, sizeof(szDate));
		PrintToChatAll("Parsed date: %s (Unix: %i)", szDate, parsedDateTime.Unix);
	} else PrintToChatAll("Invalid date!");

	parsedDateTime = DateTime.Parse(stringDate);

	// you can save the ToString() value to a database column with "datetime" type,
	// then you can either use the Parse functions, or SELECT UNIX_TIMESTAMP(column) FROM ...; then fetch that integer value and call the DateTime constructor.
}

#pragma semicolon 1

#include <sourcemod>
#include <multicolors>

#define PLUGIN_PREFIX "{green}[ConVar Suppression]{default}"
#define PLUGIN_VERSION "2.0.1"

#pragma newdecls required

Handle g_hGlobalTrie = INVALID_HANDLE;

public Plugin myinfo =
{
	name		= "ConVar Suppression",
	author		= "Kyle Sanderson, .Rushaway",
	description	= "Atleast we have candy.",
	version		= PLUGIN_VERSION,
	url		= "http://www.SourceMod.net/"
};

public void OnPluginStart()
{
	g_hGlobalTrie = CreateTrie();

	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);

	RegAdminCmd("sm_suppressconvar", OnSupressConVar, ADMFLAG_ROOT, "Supress a ConVar from displaying changes to Clients.");
	RegAdminCmd("sm_suppressconvar_reset", OnResetConVar, ADMFLAG_ROOT, "Remove all ConVars stored in Trie.");

	CreateConVar("sm_convarsuppression_version", PLUGIN_VERSION, "Version string for ConVar Supression.", FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
}

public Action OnSupressConVar(int client, int argc)
{
	char sCommand[256];

	if (argc < 2 || argc > 2)
	{
		if (!GetCmdArg(0, sCommand, sizeof(sCommand)))
		{
			return Plugin_Handled;
		}

		CReplyToCommand(client, "%s Usage: %s {olive}<convar> <1|0>", PLUGIN_PREFIX, sCommand);
		return Plugin_Handled;
	}

	if (!GetCmdArg(2, sCommand, sizeof(sCommand)))
	{
		return Plugin_Handled;
	}

	TrimString(sCommand);
	int iValue = -1;

	if (!IsCharNumeric(sCommand[0]))
	{
		switch (CharToLower(sCommand[0]))
		{
			case 'd':
			{
				iValue = 0;
			}

			case 'e':
			{
				iValue = 1;
			}
		}
	}
	else
	{
		iValue = StringToInt(sCommand);
	}

	if (!GetCmdArg(1, sCommand, sizeof(sCommand)))
	{
		return Plugin_Handled;
	}

	switch (iValue)
	{
		case 0:
		{
			RemoveFromTrie(g_hGlobalTrie, sCommand);
			CReplyToCommand(client, "%s Removed Hook ConVar: {green}%s", PLUGIN_PREFIX, sCommand);
			if(client)
				LogAction(client, -1, "[ConVar Suppression] \"%L\" Removed Hook for ConVar: \"%s\"", client, sCommand);
			else
				LogAction(-1, -1, "[ConVar Suppression] <Console> Removed Hook for ConVar: \"%s\"", sCommand);
		}

		case 1:
		{
			SetTrieValue(g_hGlobalTrie, sCommand, 1, true);
			CReplyToCommand(client, "%s Added Hook for ConVar: {green}%s", PLUGIN_PREFIX, sCommand);
			if(client)
				LogAction(client, -1, "[ConVar Suppression] \"%L\" Added Hook for ConVar: \"%s\"", client, sCommand);
			else
				LogAction(-1, -1, "[ConVar Suppression] <Console> Added Hook for ConVar: \"%s\"", sCommand);
		}

		default:
		{
			CReplyToCommand(client, "%s Illegal Input for {green}Enabled/Disabled {default}with ConVar: {green}%s", PLUGIN_PREFIX, sCommand);
		}
	}

	return Plugin_Handled;
}

public Action OnResetConVar(int client, int argc)
{
	ClearTrie(g_hGlobalTrie);
	CReplyToCommand(client, "%s Successfully remove all ConVars stored in Trie.", PLUGIN_PREFIX);
	LogAction(client, -1, "[ConVar Suppression] \"%L\" Remove all ConVars stored in Trie.", client);
	return Plugin_Handled;
}
public Action Event_ServerCvar(Handle event, const char[] name, bool dontBroadcast)
{
	char sConVarName[64];
	int iValue;

	GetEventString(event, "cvarname", sConVarName, sizeof(sConVarName));
	return (GetTrieValue(g_hGlobalTrie, sConVarName, iValue) && iValue) ? Plugin_Handled : Plugin_Continue;
}
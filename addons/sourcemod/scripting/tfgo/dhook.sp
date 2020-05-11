static Handle DHookGetCaptureValueForPlayer;
static Handle DHookSetWinningTeam;
static Handle DHookHandleSwitchTeams;
static Handle DHookHandleScrambleTeams;
static Handle DHookGiveNamedItem;

static int HookIdsGiveNamedItem[TF_MAXPLAYERS + 1] =  { -1, ... };

void DHook_Init(GameData gamedata)
{
	DHookGetCaptureValueForPlayer = DHook_CreateVirtual(gamedata, "CTFGameRules::GetCaptureValueForPlayer");
	DHookSetWinningTeam = DHook_CreateVirtual(gamedata, "CTFGameRules::SetWinningTeam");
	DHookGiveNamedItem = DHook_CreateVirtual(gamedata, "CTFPlayer::GiveNamedItem");
	DHookHandleSwitchTeams = DHook_CreateVirtual(gamedata, "CTFGameRules::HandleSwitchTeams");
	DHookHandleScrambleTeams = DHook_CreateVirtual(gamedata, "CTFGameRules::HandleScrambleTeams");
	
	DHook_CreateDetour(gamedata, "CTFPlayer::PickupWeaponFromOther", Detour_PickupWeaponFromOther);
}

static Handle DHook_CreateVirtual(GameData gamedata, const char[] name)
{
	Handle hook = DHookCreateFromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create hook: %s", name);
	
	return hook;
}

static void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	Handle detour = DHookCreateFromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (preCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, false, preCallback))
				LogError("Failed to enable pre detour: %s", name);
		
		if (postCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, true, postCallback))
				LogError("Failed to enable post detour: %s", name);
		
		delete detour;
	}
}

void DHook_HookGamerules()
{
	DHookGamerules(DHookGetCaptureValueForPlayer, true, _, DHook_GetCaptureValueForPlayer);
	DHookGamerules(DHookSetWinningTeam, false, _, DHook_SetWinningTeam);
	DHookGamerules(DHookHandleSwitchTeams, false, _, DHook_HandleSwitchTeams);
	DHookGamerules(DHookHandleScrambleTeams, false, _, DHook_HandleScrambleTeams);
}

void DHook_HookClientEntity(int client)
{
	HookIdsGiveNamedItem[client] = DHookEntity(DHookGiveNamedItem, false, client, DHookRemoval_GiveNamedItem, DHook_GiveNamedItem);
}

void DHook_UnhookClientEntity(int client)
{
	if (HookIdsGiveNamedItem[client] != -1)
	{
		DHookRemoveHookID(HookIdsGiveNamedItem[client]);
		HookIdsGiveNamedItem[client] = -1;
	}
}

public MRESReturn Detour_PickupWeaponFromOther(int client, Handle returnVal, Handle params)
{
	int weapon = DHookGetParam(params, 1); // tf_dropped_weapon
	int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	TFGOPlayer(client).AddToLoadout(defindex);
	Forward_OnClientPickupWeapon(client, defindex);
}

public MRESReturn DHook_GetCaptureValueForPlayer(Handle returnVal, Handle params)
{
	int client = DHookGetParam(params, 1);
	if (TFGOPlayer(client).HasDefuseKit && g_IsBombPlanted) // Defuse kit only takes effect when the bomb is planted
	{
		DHookSetReturn(returnVal, DHookGetReturn(returnVal) + 1);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_SetWinningTeam(Handle params)
{
	TFTeam team = DHookGetParam(params, 1);
	WinReason winReason = DHookGetParam(params, 2);
	
	// Allow planting team to die
	if (g_IsBombPlanted && team != g_BombPlantingTeam && winReason == WinReason_Opponents_Dead)
	{
		return MRES_Supercede;
	}
	else if (winReason == WinReason_Stalemate)
	{
		for (int i = view_as<int>(TFTeam_Red); i <= view_as<int>(TFTeam_Blue); i++)
		{
			// Only a non-attacking team can get the time win, and only if this stalemate is a result of the timer running out
			if (!TFGOTeam(view_as<TFTeam>(i)).IsAttacking && GetAlivePlayerCount() > 0)
			{
				DHookSetParam(params, 1, i);
				DHookSetParam(params, 2, WinReason_Custom_Out_Of_Time);
				return MRES_ChangedOverride;
			}
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHook_HandleSwitchTeams()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		TFGOPlayer(client).Reset();
	}
	
	for (int team = view_as<int>(TFTeam_Red); team <= view_as<int>(TFTeam_Blue); team++)
	{
		TFGOTeam(view_as<TFTeam>(team)).ConsecutiveLosses = STARTING_CONSECUTIVE_LOSSES;
	}
}

public MRESReturn DHook_HandleScrambleTeams()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		TFGOPlayer(client).Reset();
	}
	
	for (int team = view_as<int>(TFTeam_Red); team <= view_as<int>(TFTeam_Blue); team++)
	{
		TFGOTeam(view_as<TFTeam>(team)).ConsecutiveLosses = STARTING_CONSECUTIVE_LOSSES;
		SetTeamScore(team, 0);
	}
	
	// Arena informs the players of a team switch but not of a scramble, wtf?
	Event alert = CreateEvent("teamplay_alert");
	alert.SetInt("alert_type", 0);
	alert.Fire();
	PrintToChatAll("%T", "TF_TeamsScrambled", LANG_SERVER);
	EmitGameSoundToAll(GAMESOUND_ANNOUNCER_TEAM_SCRAMBLE);
}

public MRESReturn DHook_GiveNamedItem(int client, Handle returnVal, Handle params)
{
	if (DHookIsNullParam(params, 1) || DHookIsNullParam(params, 3))
		return MRES_Ignored;
	
	int defindex = DHookGetParamObjectPtrVar(params, 3, 4, ObjectValueType_Int) & 0xFFFF;
	int slot = TF2_GetItemSlot(defindex, TF2_GetPlayerClass(client));
	TFClassType class = TF2_GetPlayerClass(client);
	
	if (0 <= slot <= WeaponSlot_BuilderEngie && TFGOPlayer(client).GetWeaponFromLoadout(class, slot) != defindex)
	{
		DHookSetReturn(returnVal, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public void DHookRemoval_GiveNamedItem(int hookId)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (HookIdsGiveNamedItem[client] == hookId)
		{
			HookIdsGiveNamedItem[client] = -1;
			return;
		}
	}
}

static char g_MinigunShootCritSounds[][] = {
	")weapons/dragon_gun_motor_loop_crit.wav",
	")weapons/gatling_shoot_crit.wav",
	")weapons/minifun_shoot_crit.wav",
	")weapons/minigun_shoot_crit.wav",
	")weapons/tomislav_shoot_crit.wav"
};

static char g_EngineerBombSeeGameSounds[][] =  {
	"engineer_mvm_bomb_see01", 
	"engineer_mvm_bomb_see02", 
	"engineer_mvm_bomb_see03"
};

static char g_HeavyBombSeeGameSounds[][] =  {
	"heavy_mvm_bomb_see01"
};

static char g_MedicBombSeeGameSounds[][] =  {
	"medic_mvm_bomb_see01", 
	"medic_mvm_bomb_see02", 
	"medic_mvm_bomb_see03"
};

static char g_SoldierBombSeeGameSounds[][] =  {
	"soldier_mvm_bomb_see01", 
	"soldier_mvm_bomb_see02", 
	"soldier_mvm_bomb_see03"
};

public void PrecacheSounds()
{
	PrecacheSound(SOUND_BOMB_BEEPING);
	PrecacheSound("mvm/mvm_bomb_explode.wav");
	
	PrecacheScriptSound(GAMESOUND_BOMB_EXPLOSION);
	PrecacheScriptSound(GAMESOUND_BOMB_WARNING);
	PrecacheScriptSound(GAMESOUND_PLAYER_PURCHASE);
	PrecacheScriptSound(GAMESOUND_ANNOUNCER_BOMB_PLANTED);
	PrecacheScriptSound(GAMESOUND_ANNOUNCER_TEAM_SCRAMBLE);
	
	for (int i = 0; i < sizeof(g_EngineerBombSeeGameSounds); i++) PrecacheScriptSound(g_EngineerBombSeeGameSounds[i]);
	for (int i = 0; i < sizeof(g_HeavyBombSeeGameSounds); i++) PrecacheScriptSound(g_HeavyBombSeeGameSounds[i]);
	for (int i = 0; i < sizeof(g_MedicBombSeeGameSounds); i++) PrecacheScriptSound(g_MedicBombSeeGameSounds[i]);
	for (int i = 0; i < sizeof(g_SoldierBombSeeGameSounds); i++) PrecacheScriptSound(g_SoldierBombSeeGameSounds[i]);
}

public void EmitBombSeeGameSounds()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) != g_BombPlantingTeam)
		{
			switch (TF2_GetPlayerClass(client))
			{
				case TFClass_Engineer: EmitGameSoundToAll(g_EngineerBombSeeGameSounds[GetRandomInt(0, sizeof(g_EngineerBombSeeGameSounds) - 1)]);
				case TFClass_Heavy: EmitGameSoundToAll(g_HeavyBombSeeGameSounds[GetRandomInt(0, sizeof(g_HeavyBombSeeGameSounds) - 1)]);
				case TFClass_Medic: EmitGameSoundToAll(g_MedicBombSeeGameSounds[GetRandomInt(0, sizeof(g_MedicBombSeeGameSounds) - 1)]);
				case TFClass_Soldier: EmitGameSoundToAll(g_SoldierBombSeeGameSounds[GetRandomInt(0, sizeof(g_SoldierBombSeeGameSounds) - 1)]);
			}
		}
	}
}

public Action Event_Pre_Teamplay_Broadcast_Audio(Event event, const char[] name, bool dontBroadcast)
{
	char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	if (strncmp(sound, "Game.", 5) == 0)
	{
		if (StrEqual(sound, "Game.YourTeamWon"))
			PlayTeamClientMusicKits(team, Music_WonRound);
		else if (StrEqual(sound, "Game.YourTeamLost") || StrEqual(sound, "Game.Stalemate"))
			PlayTeamClientMusicKits(team, Music_LostRound);
		
		return Plugin_Handled;
	}
	else if (StrEqual(sound, "Announcer.AM_RoundStartRandom"))
	{
		PlayAllClientMusicKits(Music_StartAction);
	}
	
	return Plugin_Continue;
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (strncmp(sample, ")weapons/", 9) == 0)
	{
		// Spatialized minigun crit sounds from headshots loop forever, block them entirely
		for (int i = 0; i < sizeof(g_MinigunShootCritSounds); i++)
		{
			if (StrEqual(sample, g_MinigunShootCritSounds[i]))
				return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

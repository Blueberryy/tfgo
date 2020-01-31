static StringMap g_MusicKitRegistry;
static char g_PlayerMusicKits[TF_MAXPLAYERS + 1][PLATFORM_MAX_PATH];

methodmap DefaultMusicKit < TFGOMusicKit
{
	public DefaultMusicKit(char[] id)
	{
		this.IsDefault = true;
		return view_as<MusicKit>(id);
	}
	
	public void GetName(char[] buffer, int length)
	{
		strcopy(buffer, length, "Default Music Kit");
	}
	
	// TODO: The rest
	// Not sure if I'm even doing this right, first time working with native methodmaps. Ah well, gonna work one way or another.
}

stock void MusicKit_Init()
{
	// TODO
}

stock TFGOMusicKit GetMusicKitForClient(int client)
{
	return TFGOMusicKit(g_PlayerMusicKits[client]);
}

stock void PlayAllClientMusicKits(TFGOMusicType type)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		TFGOMusicKit kit = GetMusicKitForClient(client);
		kit.EmitMusicToClient(client, type);
	}
}

stock void PlayClientMusicKits(const int[] clients, int numClients, TFGOMusicType type)
{
	for (int i = 0; i < numClients; i++)
	{
		TFGOMusicKit kit = GetMusicKitForClient(clients[i]);
		kit.EmitMusicToClient(clients[i], type);
	}
}

stock void PlayTeamClientMusicKits(TFTeam team, TFGOMusicType type)
{
	int[] clients = new int[MaxClients];
	int total = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) == team)
			clients[total++] = client;
	}
	
	if (total)
		PlayClientMusicKits(clients, total, type);
}

stock void PlayClientMusicKitToAll(int client, TFGOMusicType type)
{
	TFGOMusicKit kit = GetMusicKitForClient(client);
	kit.EmitMusicToAll(type);
}

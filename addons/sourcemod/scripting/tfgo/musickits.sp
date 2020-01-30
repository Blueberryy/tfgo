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

#if defined _tfgo_included
#endinput
#endif
#define _tfgo_included

#include <tf2>


/**
* Music kit sound types
*/
enum TFGOMusicType
{
	Music_BombPlanted, 
	Music_BombTenSecCount, 
	Music_LostRound, 
	Music_RoundTenSecCount, 
	Music_WonRound, 
	Music_StartAction, 
	Music_StartRound, 
	Music_RoundMVPAnthem
}

/**
* Music kits are a collection of sounds that can be used to play music to one or more clients.
*/
methodmap TFGOMusicKit
{
	/**
	* Whether this is a default music kit.
	*
	* Default music kits have a chance to be assigned to players at the start of the game.
	*/
	property bool IsDefault
	{
		public native get();
		public native set(bool val);
	}
	
	/**
	* Creates a new music kit with the specified ID.
	*
	* @param id	The ID used to uniquely identify this music kit
	* @return	TFGOMusicKit methodmap
	*/
	public native TFGOMusicKit(char[] id);
	
	/**
	* Gets the name of this music kit.
	*
	* @param buffer	The buffer to store the name in
	* @param length	The size of the buffer
	* @noreturn
	*/
	public native void GetName(char[] buffer, int length);
	
	/**
	* Sets the name of this music kit.
	*
	* @param name	The name
	* @noreturn
	*/
	public native void SetName(char[] name);
	
	/**
	* Gets the music kit sounds for a specified sound type.
	*
	* @param type	The music type
	* @return		An ArrayList of sounds or null
	*/
	public native ArrayList GetSounds(TFGOMusicType type);
	
	/**
	* Sets the music kit sounds for a specified sound type.
	*
	* @note This WILL override any previously added sounds!
	* @param sounds	An ArrayList of sounds
	* @param type	The type of sounds in the list
	* @noreturn
	*/
	public native void SetSounds(ArrayList sounds, TFGOMusicType type);
	
	/**
	* Adds a sound for a specified sound type.
	*
	* @param sound	The sound to add
	* @param type	The type of sound to add
	*/
	public native void AddSound(char[] sound, TFGOMusicType type);
	
	/**
	* Removes a sound for a specified sound type.
	*
	* @param sound	The sound to remove
	* @param type	The type of sound to remove
	*/
	public native void RemoveSound(char[] sound, TFGOMusicType type);
	
	public int GetRandomMusicFile(TFGOMusicType type, char[] buffer, int length)
	{
		ArrayList sounds = this.GetSounds(type);
		return sounds.GetString(GetRandomInt(0, sounds.Length), buffer, length);
	}
	
	public void StopMusicForClient(int client, TFGOMusicType type)
	{
		ArrayList sounds = this.GetSounds(type);
		for (int i = 0; i < sounds.Length; i++)
		{
			char sound[PLATFORM_MAX_PATH];
			if (sounds.GetString(i, sound, sizeof(sound)))
				StopSound(client, SNDCHAN_STATIC, sound);
		}
	}
	
	public void StopMusicForClients(const int[] clients, int numClients, TFGOMusicType type)
	{
		for (int i = 0; i < numClients; i++)
		{
			this.StopMusicForClient(clients[i], type);
		}
	}
	
	public void StopMusicForAll(TFGOMusicType type)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			this.StopMusicForClient(client, type);
		}
	}
	
	public void StopActiveMusic(TFGOMusicType type)
	{
		switch (type)
		{
			case Music_BombPlanted:
			{
				this.StopMusicForAll(Music_StartAction);
				this.StopMusicForAll(Music_RoundTenSecCount);
			}
			case Music_BombTenSecCount:
			{
				this.StopMusicForAll(Music_BombPlanted);
			}
			case Music_StartAction:
			{
				this.StopMusicForAll(Music_StartRound);
			}
			case Music_StartRound:
			{
				this.StopMusicForAll(Music_WonRound);
				this.StopMusicForAll(Music_LostRound);
			}
			case Music_RoundTenSecCount:
			{
				this.StopMusicForAll(Music_StartAction);
			}
			case Music_WonRound, Music_LostRound, Music_RoundMVPAnthem:
			{
				this.StopMusicForAll(Music_StartAction);
				this.StopMusicForAll(Music_BombPlanted);
				this.StopMusicForAll(Music_RoundTenSecCount);
				this.StopMusicForAll(Music_BombTenSecCount);
			}
		}
	}
	
	public void EmitMusicToClient(int client, TFGOMusicType type)
	{
		char sound[PLATFORM_MAX_PATH];
		if (this.GetRandomMusicFile(type, sound, sizeof(sound)))
		{
			this.StopActiveMusic(type);
			EmitSoundToClient(client, sound, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
		}
	}
	
	public void EmitMusicToClients(const int[] clients, int numClients, TFGOMusicType type)
	{
		char sound[PLATFORM_MAX_PATH];
		if (this.GetRandomMusicFile(type, sound, sizeof(sound)))
		{
			this.StopActiveMusic(type);
			EmitSound(clients, numClients, sound, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
		}
	}
	
	public void EmitMusicToAll(TFGOMusicType type)
	{
		char sound[PLATFORM_MAX_PATH];
		if (this.GetRandomMusicFile(type, sound, sizeof(sound)))
		{
			this.StopActiveMusic(type);
			EmitSoundToAll(sound, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
		}
	}
	
	public void PrepareMusicKit()
	{
		for (int type = 0; type < view_as<int>(TFGOMusicType); type++)
		{
			ArrayList sounds = this.GetSounds(view_as<TFGOMusicType>(type));
			for (int i = 0; i < sounds.Length; i++)
			{
				char sound[PLATFORM_MAX_PATH];
				if (sounds.GetString(i, sound, sizeof(sound)))
				{
					AddFileToDownloadsTable(sound);
					StrCat("#", sizeof(sound), sound); //prepend music char
					PrecacheSound(sound);
					sounds.SetString(i, sound); //update sound list with added music char
				}
			}
		}
	}
}

/**
 * Forward called when the bomb has been planted.
 *
 * @param team		The team that planted the bomb
 * @param cappers	ArrayList of clients that planted the bomb
 * @noreturn
 */
forward void TFGO_OnBombPlanted(TFTeam team, ArrayList cappers);

/**
 * Forward called when the bomb was detonated.
 *
 * @param team	The team that detonated the bomb
 * @noreturn
 */
forward void TFGO_OnBombDetonated(TFTeam team);

/**
 * Forward called when the bomb has been defused.
 *
 * @param team		The team that defused the bomb
 * @param cappers	ArrayList of clients that defused the bomb
 * @param timeLeft	Time left on the bomb detonation timer when it was defused
 * @noreturn
 */
forward void TFGO_OnBombDefused(TFTeam team, ArrayList cappers, float timeLeft);

/**
 * Forward called when a player earns cash.
 *
 * @param client	The client that earned the cash
 * @param amount	The amount of money that was earned
 * @noreturn
 */
forward void TFGO_OnCashAwarded(int client, int amount);

/**
 * Forward called when a player picks up a weapon.
 *
 * @param client	The client that picked up the weapon
 * @param defindex	The item definition index of the weapon
 * @noreturn
 */
forward void TFGO_OnWeaponPickup(int client, int defindex);

/**
* Retrieves the cost of a weapon.
*
* @param defindex	The item definition index of the weapon
* @return the cost of the weapon
*/
native int TFGO_GetWeaponCost(int defindex);

public SharedPlugin __pl_tfgo =
{
	name = "tfgo",
	file = "tfgo.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_tfgo_SetNTVOptional()
{
	MarkNativeAsOptional("TFGOMusicKit.IsDefault.get");
	MarkNativeAsOptional("TFGOMusicKit.IsDefault.set");
	MarkNativeAsOptional("TFGOMusicKit.TFGOMusicKit");
	MarkNativeAsOptional("TFGOMusicKit.GetName");
	MarkNativeAsOptional("TFGOMusicKit.SetName");
	MarkNativeAsOptional("TFGOMusicKit.GetSounds");
	MarkNativeAsOptional("TFGOMusicKit.SetSounds");
	MarkNativeAsOptional("TFGOMusicKit.AddSound");
	MarkNativeAsOptional("TFGOMusicKit.RemoveSound");
	
	MarkNativeAsOptional("TFGO_GetWeaponCost");
}
#endif
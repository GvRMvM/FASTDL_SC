#include "anti_rush"

#include "beast/checkpoint_spawner"
#include "beast/envtempeffects"
#include "beast/game_hudsprite"
#include "beast/player_blocker"

#include "decay/item_eyescanner"
#include "decay/item_healthcharger"
#include "decay/item_recharge"
#include "decay/monster_alienflyer"
#include "decay/weapon_slave"

const bool blAntiRushEnabled = false;// You can change this to have AntiRush mode enabled or disabled

void MapInit()
{
	RegisterItemEyeScannerEntity();
	RegisterItemRechargeCustomEntity();
	RegisterItemHealthCustomEntity();
	RegisterAlienflyer();
	ANTI_RUSH::EntityRegister( blAntiRushEnabled );

	if( g_Engine.mapname == "dy_alien" )
	{
		RegisterWeaponIslave();
		g_EngineFuncs.CVarSetFloat( "mp_weapon_respawndelay", -1 );
		g_EngineFuncs.CVarSetFloat( "mp_ammo_respawndelay", -1 );
		g_EngineFuncs.CVarSetFloat( "mp_item_respawndelay", -1 );
		g_EngineFuncs.CVarSetFloat( "mp_weaponstay", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_suitpower", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_hevsuit_voice", 0 );
		g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 0 );
		g_EngineFuncs.CVarSetFloat( "npc_dropweapons", 0 );

		g_Scheduler.SetInterval( "LockPlayerModel", 0.0f, -1 );
	}

	g_EngineFuncs.CVarSetFloat( "mp_npckill", 2 );
	g_EngineFuncs.CVarSetFloat( "sk_plr_357_bullet", 33 );

	g_EngineFuncs.ServerPrint( "Half-Life: Decay Version 1.8 - Download this campaign from scmapdb.com\n" );
}

void MapActivate()
{
	if( !ANTI_RUSH::IsActive() )
	{
		do( g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, "percent_*" ) ) );
        while( g_EntityFuncs.FindEntityByTargetname( null, "percent_*" ) !is null );

		do( g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, "skull_*" ) ) );
        while( g_EntityFuncs.FindEntityByTargetname( null, "skull_*" ) !is null );
	}
}
// Outerbeast: This was in the standalone custom ent "info_cheathelper" but that was completely unnecessary. Keeping shit simple by using a trigger_script.
dictionary dictCodes =
{
	{ "ucxltt", "devshed" },
	{ "sclltxrr", "unlock_alien" },
	{ "lsrclsrc", "unlock_gman" },
	{ "utututscr", "unlock_alien_ally" }
};
string strCheatInput;
bool blAlienMissionUnlocked = false;

void CheatHealper(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null || !pActivator.IsPlayer() || pCaller is null )
		return;

	const array<string> STR_KEYS = dictCodes.getKeys();
	strCheatInput = strCheatInput + pCaller.GetTargetname();

	if( strCheatInput.Length() > 9 )
		strCheatInput = strCheatInput.SubString( strCheatInput.Length() - 9, strCheatInput.Length() );

	for( uint i = 0; i < STR_KEYS.length(); i++ )
	{
		if( strCheatInput.Find( STR_KEYS[i] ) == String::INVALID_INDEX )
			continue;

		if( ( i == 2 || i == 3 ) && !blAlienMissionUnlocked )
			break;
		
		g_EntityFuncs.FireTargets( string( dictCodes[STR_KEYS[i]] ), pActivator, pCaller, useType, 0.0f, 0.0f );
		dictCodes[STR_KEYS[i]] = strCheatInput = "";

		if( i == 1 )
			blAlienMissionUnlocked = true;

		break;
	}

	//g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "CHEATER-DEBUG: " + strCheatInput + "\n" );
}

void SetAlienMode(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null )
		return;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

	if( pPlayer is null )
		return;

	pPlayer.m_bloodColor = BLOOD_COLOR_GREEN;

	if( pPlayer.entindex() % 2 > 0 )
		pPlayer.SetOverriddenPlayerModel( "alien_slave" );
	else
		pPlayer.SetOverriddenPlayerModel( "agrunt" );

	CBasePlayerItem@ pWeaponSlave = pPlayer.HasNamedPlayerItem( "weapon_slave" );
	KeyValueBuffer@ pKeys = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );

	if( string( pKeys.GetValue( "model" ) ) == "agrunt" )
	{
		pPlayer.GiveNamedItem( "weapon_hornetgun", 0, 0 );
		
		if( pWeaponSlave !is null )
        	pPlayer.RemovePlayerItem( pWeaponSlave );
	}
	else
		pPlayer.GiveNamedItem( "weapon_slave", 0, 0 );

	g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$s_overriden_playermodel", "" + string( pKeys.GetValue( "model" ) ) );
}

void LockPlayerModel()
{
	for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

		if( pPlayer is null )
			continue;

		CustomKeyvalues@ kvPlayer = pPlayer.GetCustomKeyvalues();

		if( !kvPlayer.HasKeyvalue( "$s_overriden_playermodel" ) )
			continue;

		KeyValueBuffer@ pKeys = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );

		if( string( pKeys.GetValue( "model" ) ) != kvPlayer.GetKeyvalue( "$s_overriden_playermodel" ).GetString() )
			pPlayer.SetOverriddenPlayerModel( kvPlayer.GetKeyvalue( "$s_overriden_playermodel" ).GetString() );
	}
}

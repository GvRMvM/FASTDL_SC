#include "player_sentry"

namespace OUTERBEAST
{

enum EnemyTier
{
    TIER_1,
    TIER_2,
    TIER_3,
    TIER_4
};

HUDTextParams txtBuildPoints, txtO2Level;
const string 
	strTokenMdl = "models/ragemap2023/beast/item_toolcoin.mdl",// Model by Garompa
	strO2Canister = "models/ragemap2023/beast/o2_canister.mdl",// Model by Hezus
	strTorNoAgrunt = "models/cards/Tor.mdl",
	strSpawnSpr = "sprites/b-tele1.spr",
	strSpawnStartSpr = "sprites/Fexplo1.spr",
	strSpawnEndSpr = "sprites/XFlare1.spr",
	strSpawnSnd = "debris/beamstart7.wav",
	strO2Snd = "doors/aliendoor3.wav",
	strTokenCollectSnd = "turretfortress/coin.wav";

const float flTokenLifetime = 20.0f;
uint 
	iCurrentDiff = 0,
	iTotalBuildPoints = 0;

array<uint> I_O2_LEVEL( g_Engine.maxClients + 1 );

const array<array<string>> ARR_STR_ENEMIES =
{
	{// Tier 1
        "monster_houndeye",
        "monster_stukabat",
        "monster_pitdrone"
    },
	{// Tier 2
        "monster_alien_slave",
        "monster_alien_controller",
        "monster_alien_grunt"
    },
	{// Tier 3
        "monster_shocktrooper",
        "monster_babygarg",
        "monster_alien_voltigore"
    },
	{// Tier 4
        "monster_kingpin",
        "monster_alien_tor"
    }
};

const array<array<float>> ARR_FL_DIFF =
{
	{ 0.9, 0.2, 0.1, 0.0 },
	{ 0.9, 0.5, 0.4, 0.1 },
	{ 0.8, 0.7, 0.5, 0.3 },
	{ 0.6, 0.7, 0.7, 0.5 }
};

array<string> STR_UNLOCKED_WEAPONS =
{
	"weapon_pipewrench",
	"weapon_9mmhandgun"
};

EHandle hExclusionZone, hO2Zone, hEnemySpawner, hDoor1, hDoor2;

string get_STR_MODELS(int i) property
{
    switch( i )
    {
    	case 0: return strTokenMdl;
    	case 1: return strO2Canister;
		case 2: return strTorNoAgrunt;
		case 3: return strSpawnSpr;
		case 4: return strSpawnStartSpr;
		case 5: return strSpawnEndSpr;
	}
	
	return "";
}

void Precache()
{
	for( uint i = 0; i < ARR_STR_ENEMIES.length(); i++ )
	{
		for( uint j = 0; j < ARR_STR_ENEMIES[i].length(); j++ )
			g_Game.PrecacheMonster( ARR_STR_ENEMIES[i][j], false );
	}

	for( uint i = 0; i < 5; i++ )
		g_Game.PrecacheModel( STR_MODELS[i] );

	g_SoundSystem.PrecacheSound( strSpawnSnd );
	g_SoundSystem.PrecacheSound( strO2Snd );
	g_SoundSystem.PrecacheSound( strTokenCollectSnd );
}

void Init()
{
	Precache();
	PLAYER_SENTRY::WeaponRegister();

	txtBuildPoints.x = 1.0f;
	txtBuildPoints.y = 0.7f;

	txtBuildPoints.r1 = 255;
	txtBuildPoints.r2 = 255;
	txtBuildPoints.g1 = 255;
	txtBuildPoints.g2 = 255;
	txtBuildPoints.b1 = 0;
	txtBuildPoints.b2 = 0;
	txtBuildPoints.a1 = 255;
	txtBuildPoints.a2 = 255;

	txtBuildPoints.fadeinTime = 0.0;
	txtBuildPoints.fadeoutTime = 0.0;
	txtBuildPoints.holdTime = 3.0;
	txtBuildPoints.fxTime = 0.0;

	txtBuildPoints.channel = 7;
	txtBuildPoints.effect = 0;

	txtO2Level = txtBuildPoints;
	txtO2Level.x = 1.0f;
	txtO2Level.y = 0.75f;
	txtO2Level.r1 = 128;
	txtO2Level.r2 = 128;
	txtO2Level.g1 = 128;
	txtO2Level.b1 = 255;
	txtO2Level.b2 = 255;
	txtO2Level.channel = 8;

	g_Scheduler.SetTimeout( "FetchEnts", 1.0 );
}

void FetchEnts()
{
	hExclusionZone = g_EntityFuncs.FindEntityByTargetname( null, "outerbeast_enemy_spawn_exclusion_zone" );
	hO2Zone = g_EntityFuncs.FindEntityByTargetname( null, "outerbeast_o2_zone" );

	CBaseEntity@ pDoor;

	while( ( @pDoor = g_EntityFuncs.FindEntityByTargetname( pDoor, "outerbeast_base_door" ) ) !is null )
	{
		if( pDoor is null || pDoor.GetClassname() != "func_door" )
			continue;

		if( !hDoor1 )
			hDoor1 = pDoor;
		else if( !hDoor2 )
			hDoor2 = pDoor;
	}
}

Vector RandomCircle(Vector origin, float angle, float radius)
{
    Vector vec;

    vec.x = radius * cos( Math.DegreesToRadians( angle ) );
    vec.y = radius * sin( Math.DegreesToRadians( angle ) );

    return origin + vec;
}

uint weighted_random(float[] weights)
{
    float total = 0.0f;

    for( uint i = 0; i < weights.length(); i++ )
        total += weights[i]; // Sum the weights together so we can pick elements, i.e. no hardcoded range.

    float
		sum = 0.0f,
		r = Math.RandomFloat( 0.0f, total );

    for( uint i = 0; i < weights.length(); i++ )
    {
        sum += weights[i];

        if( r <= sum )
            return i;
    }

    return 0;
}

void PlayerSpawn(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null || !pActivator.IsPlayer() )
		return;

	CSprite@ pSpawn = g_EntityFuncs.CreateSprite( strSpawnSpr, pActivator.pev.origin, true );
	pSpawn.SetTransparency( 5, 0, 0, 0, 255, 0 );
	pSpawn.AnimateAndDie( 10.0f );

	for( uint i = 0; i < STR_UNLOCKED_WEAPONS.length(); i++ )
		cast<CBasePlayer@>( pActivator ).GiveNamedItem( STR_UNLOCKED_WEAPONS[i] );

	I_O2_LEVEL[pActivator.entindex()] = 0.0f;
}

void DisplayStats(CBaseEntity@ pTriggerScript)
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;

		g_PlayerFuncs.HudMessage( pPlayer, txtBuildPoints, "Total Build points: " + iTotalBuildPoints );
		g_PlayerFuncs.HudMessage( pPlayer, txtO2Level, "O2: " + I_O2_LEVEL[iPlayer] + "%" );
	}
}
// Token stuff
void DropToken(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null || !pActivator.IsMonster() )
		return;

	CustomKeyvalues@ kvActivator = pActivator.GetCustomKeyvalues();
	int tier = kvActivator.HasKeyvalue( "$i_tier" ) ? kvActivator.GetKeyvalue( "$i_tier" ).GetInteger() : 0;

	dictionary dictToken =
	{
		{ "origin", "" + ( pActivator.pev.origin + Vector( 0, 0, 16 ) ).ToString().Replace( ",", "" ) },
		{ "targetname", "outerbeast_token" },
		{ "model", strTokenMdl },
		{ "skin", "" + tier },
		{ "scale", "2" },
		{ "sequencename", "not_carried" },
		{ "m_flCustomRespawnTime", "-1" },
		{ "target", "outerbeast_token_collected" },
		{ "spawnflags", "1024" }
	};

	if( pActivator.GetClassname() == "monster_stukabat" )
		dictToken["origin"] = ( Vector( pActivator.pev.origin.x, pActivator.pev.origin.y, hEnemySpawner.GetEntity().pev.origin.z ) ).ToString().Replace( ",", "" );
	// !-HACK-!: Deleting a dead voltigore before selfdestruct prevents beam fx from expiring. Moving it outside the map upon death to get around this.
	if( pActivator.GetClassname() == "monster_alien_voltigore" )
		pActivator.pev.origin.z -= 500;
	else
		g_EntityFuncs.Remove( pActivator );

	g_Scheduler.SetTimeout( "TokenExpire", flTokenLifetime, EHandle( g_EntityFuncs.CreateEntity( "item_security", dictToken ) ) );
}

void TokenCollected(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null || pCaller is null )
		return;

	iTotalBuildPoints += 1 << pCaller.pev.skin;
	g_SoundSystem.PlaySound( pActivator.edict(), CHAN_ITEM, strTokenCollectSnd, 3.0f, ATTN_NORM, 0, PITCH_HIGH, 0, true, pActivator.pev.origin );
}

void TokenExpire(EHandle hToken)
{
	g_EntityFuncs.Remove( hToken.GetEntity() );
}

bool NeedsPoints(EHandle hEntity)
{
	if( !hEntity )
		return false;

	return hEntity.GetEntity().pev.impulse > 0;
}

void UsePoints(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null || !pActivator.IsPlayer() || !pActivator.IsAlive() )
		return;

	int iCurrentPoints = iTotalBuildPoints;

	if( iCurrentPoints <= 0 )
	{
		g_PlayerFuncs.SayText( cast<CBasePlayer@>( pActivator ), "You need to collect tokens to earn points.\n" );
		return;
	}

	int iPointsCost = pCaller.pev.impulse;

	if( iCurrentPoints >= iPointsCost )
	{
		iTotalBuildPoints -= iPointsCost;
		g_EntityFuncs.FireTargets( pCaller.pev.netname, pActivator, pCaller, USE_TOGGLE, 0.0f, 0.0f );
	}
	else
		g_PlayerFuncs.SayText( cast<CBasePlayer@>( pActivator ), "You don't have enough points!\n" );
}
// Unlocking stuff
void UnlockPrompt(CBaseEntity@ pTriggerScript)
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if( pPlayer is null || !pPlayer.IsAlive() )
			continue;

		CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer, 64.0f );

		if( pAimedEntity is null || !NeedsPoints( pAimedEntity ) )
			continue;

		string strAimedentityName = pAimedEntity.GetTargetname();
		strAimedentityName.Replace( "outerbeast_", "" );

		if( STR_UNLOCKED_WEAPONS.find( strAimedentityName ) >= 0 )
			g_PlayerFuncs.PrintKeyBindingString( pPlayer, "+use " + pAimedEntity.pev.message );
		else
			g_PlayerFuncs.PrintKeyBindingString( pPlayer, "+use " + pAimedEntity.pev.message + "\n Cost: " + pAimedEntity.pev.impulse + " points" );
	}
}

void WeaponUnlock(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( pActivator is null || !pActivator.IsPlayer() || pCaller is null )
		return;

	string strWeaponName = pCaller.GetTargetname();
	strWeaponName.Replace( "outerbeast_", "" );

	if( STR_UNLOCKED_WEAPONS.find( strWeaponName ) < 0 )
	{
		STR_UNLOCKED_WEAPONS.insertLast( strWeaponName );
		pCaller.pev.rendermode = 0;
		pCaller.pev.renderamt = 255;
		pCaller.pev.target = pCaller.GetTargetname() + "_refill";
		string strMessage = string( pCaller.pev.message );
		strMessage.Replace( "Unlock", "Refill" );
		pCaller.pev.message = strMessage;
	}

	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
			continue;

		if( pPlayer.HasNamedPlayerItem( strWeaponName ) !is null )
			continue;

		pPlayer.GiveNamedItem( strWeaponName );
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, strWeaponName + " unlocked.\n" );
	}

	g_Scheduler.SetTimeout( "RemoveWeaponLightCollision" , 0.1f );
}
// 10 lines of code vs 10 entities? The deal sells itself
void RemoveWeaponLightCollision()
{
	CBaseEntity@ pWeaponLight;

	while( ( @pWeaponLight = g_EntityFuncs.FindEntityByTargetname( pWeaponLight, "outerbeast_wpn_light_*" ) ) !is null )
	{
		if( pWeaponLight is null || 
			pWeaponLight.GetClassname() != "func_wall_toggle" || 
			pWeaponLight.pev.effects & EF_NODRAW != 0 || 
			pWeaponLight.pev.solid == SOLID_NOT )
			continue;

		pWeaponLight.pev.solid = SOLID_NOT;
	}
}
// O2 stuff
bool InO2Zone(EHandle hPlayer)
{
    if( !hPlayer )
        return false;
	// if the door opens there will be no O2 inside
	if( ( cast<CBaseDoor@>( hDoor1.GetEntity() ).GetToggleState() == 0 || 
		cast<CBaseDoor@>( hDoor2.GetEntity() ).GetToggleState() == 0 ) )
		return false;
	else
    	return hPlayer.GetEntity().Intersects( hO2Zone.GetEntity() );
}

void PlayerBreath(CBaseEntity@ pTriggerScript)
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() || InO2Zone( pPlayer ) )
            continue;

		if( I_O2_LEVEL[iPlayer] > 0 )
			--I_O2_LEVEL[iPlayer];
		// Suffocation
        if( I_O2_LEVEL[iPlayer] == 0 )
        {
            pPlayer.m_bitsDamageType &= ~DMG_DROWNRECOVER; // Don't know if needed
            pPlayer.TakeDamage( g_EntityFuncs.Instance( 0 ).pev, g_EntityFuncs.Instance( 0 ).pev, 4.0f, DMG_DROWN );
        }
    }
}

void RefillO2(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( pActivator is null || !pActivator.IsPlayer() )
        return;

	g_SoundSystem.PlaySound( pActivator.edict(), CHAN_VOICE, strO2Snd, 0.75f, ATTN_NORM, 0, 255, 0, true, pActivator.pev.origin );
    I_O2_LEVEL[pActivator.entindex()] = 100;
}
// Gravity
void PlayerGravity(CBaseEntity@ pTriggerScript)
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

		if( InO2Zone( pPlayer ) && pPlayer.pev.gravity != 1.0f )
			pPlayer.pev.gravity = 1.0f;
		else if( !InO2Zone( pPlayer ) && pPlayer.pev.gravity == 1.0f )
			pPlayer.pev.gravity = 0.6f;
    }
}
// Enemy stuff
void EnemySpawner(CBaseEntity@ pTriggerScript)
{
	if( !hEnemySpawner )
		hEnemySpawner = pTriggerScript;

	if( g_EntityFuncs.MonstersInSphere( array<CBaseEntity@>( 64 ), pTriggerScript.pev.origin, 1757.0f ) > 32 )
		return;
	
	if( iCurrentDiff > 3 )
		iCurrentDiff = 3;

	if( g_PlayerFuncs.GetNumPlayers() < 6 && iCurrentDiff >= 3 )
		iCurrentDiff = 2;

	Vector vecFinalPos;

	for( int monstercount = Math.RandomLong( 1, 6 ); monstercount > 0; monstercount-- )
	{
		EnemyTier tierRand = EnemyTier( weighted_random( ARR_FL_DIFF[iCurrentDiff] ) );
		vecFinalPos = RandomCircle( pTriggerScript.pev.origin, Math.RandomFloat( 0, 360 ), Math.RandomFloat( 500, 1500 ) );
		vecFinalPos.z = pTriggerScript.pev.origin.z;

		CBaseMonster@ pAlien = CreateEnemy( tierRand, vecFinalPos );

		if( pAlien is null || pAlien.Intersects( hExclusionZone.GetEntity() ) )
		{
			g_EntityFuncs.Remove( pAlien );
			continue;
		}

		if( pAlien.GetClassname() == "monster_stukabat" || pAlien.GetClassname() == "monster_alien_controller" )
			pAlien.pev.origin.z += 90;

		pAlien.SetClassification( CLASS_ALIEN_MONSTER );

		int 
			iBeamCount = Math.RandomLong( 20, 40 ),
			iBeamAlpha = 128,
			iStartSpriteAlpha = 255,
			iEndSpriteAlpha = 255;

		Vector 
			vecBeamColor,
			vecLightColor,
			vecStartSpriteColor,
			vecEndSpriteColor;
		
		float 
			flBeamRadius = 256,
			flLightRadius = 160,
			flStartSpriteScale = 1.0f,
			flStartSpriteFramerate = 12,
			flEndSpriteScale = 1.0f,
			flEndSpriteFramerate = 12;

		switch( tierRand )
		{
			case TIER_1:
				vecBeamColor = vecLightColor = vecStartSpriteColor = vecEndSpriteColor = Vector( 100, 0, 100 );
				break;

			case TIER_2:
				vecBeamColor = vecLightColor = vecStartSpriteColor = vecEndSpriteColor = Vector( 100, 100, 100 );
				break;

			case TIER_3:
				vecBeamColor = vecLightColor = vecStartSpriteColor = vecEndSpriteColor = Vector( 100, 100, 0 );
				break;

			case TIER_4:
				vecBeamColor = vecLightColor = vecStartSpriteColor = vecEndSpriteColor = Vector( 0, 0, 100 );
				break;
		}

		NetworkMessage custom( MSG_BROADCAST, NetworkMessages::TE_CUSTOM, pAlien.pev.origin );
			custom.WriteByte( 2 );
			custom.WriteVector( pAlien.pev.origin );
			// for the beams
			custom.WriteByte( iBeamCount );
			custom.WriteVector( vecBeamColor );
			custom.WriteByte( iBeamAlpha );
			custom.WriteCoord( flBeamRadius );
			// for the dlight
			custom.WriteVector( vecLightColor );
			custom.WriteCoord( flLightRadius );
			// for the sprites
			custom.WriteVector( vecStartSpriteColor );
			custom.WriteByte( int( flStartSpriteScale*10 ) );
			custom.WriteByte( int( flStartSpriteFramerate ) );
			custom.WriteByte( iStartSpriteAlpha );
			// Sprites don't work
			custom.WriteVector( vecEndSpriteColor );
			custom.WriteByte( int( flEndSpriteScale*10 ) );
			custom.WriteByte( int( flEndSpriteFramerate ) );
			custom.WriteByte( iEndSpriteAlpha );
		custom.End();

		CSprite@ 
			pStartSprite = g_EntityFuncs.CreateSprite( strSpawnStartSpr, pAlien.pev.origin, true ),
			pEndSprite = g_EntityFuncs.CreateSprite( strSpawnEndSpr, pAlien.pev.origin, true );

		pStartSprite.SetTransparency( 3, int( vecStartSpriteColor.x ), int( vecStartSpriteColor.y ), int( vecStartSpriteColor.z ), 255, 14 );
		pStartSprite.AnimateAndDie( 10.0f );
		pStartSprite.SetScale( float( tierRand ) );

		pEndSprite.SetTransparency( 3, int( vecEndSpriteColor.x ), int( vecEndSpriteColor.y ), int( vecEndSpriteColor.z ), 255, 14 );
		pEndSprite.AnimateAndDie( 10.0f );
		pEndSprite.SetScale( float( tierRand + 1 ) );
	}
}

CBaseMonster@ CreateEnemy(EnemyTier tier, Vector vecPos)
{
	dictionary dictEnemy =
	{
		{ "origin", "" + vecPos.ToString() },
		{ "angles", "" + Vector( 0, Math.VecToYaw( hEnemySpawner.GetEntity().pev.origin - vecPos ), 0 ).ToString() },
		{ "TriggerCondition", "4" },
		{ "TriggerTarget", "outerbeast_drop_token" },
		{ "targetname", "outerbeast_monsters" },
		{ "spawnflags", "5" },
		{ "$i_tier", "" + int( tier ) }
	};

	string strClassname = ARR_STR_ENEMIES[tier][Math.RandomLong( 0, ARR_STR_ENEMIES[tier].length() - 1 )];

	if( strClassname == "monster_alien_tor" )
		dictEnemy["model"] = strTorNoAgrunt;
	
	return g_EntityFuncs.CreateEntity( strClassname, dictEnemy ).MyMonsterPointer();
}

void IncreaseDiff(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if( iCurrentDiff > 3 )
		return;
	
	iCurrentDiff++;
}

void Shutdown(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null )
            continue;

		g_PlayerFuncs.HudMessage( pPlayer, txtBuildPoints, "" );
        g_PlayerFuncs.HudMessage( pPlayer, txtO2Level, "" );

		pPlayer.pev.gravity = 1.0f;
    }

	do( g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, "outerbeast_*" ) ) );
    while( g_EntityFuncs.FindEntityByTargetname( null, "outerbeast_*" ) !is null );
}

}

// i see you snooping at the code :eyes:
#include "giegue_sentryMK2"

namespace GIEGUE
{

void MapInit()
{
	RegisterSentryMK2();
	g_Game.PrecacheOther( "monster_sentry_mk2" );
}

const bool USING_LINUX = true; // please do not set this to false if you're using linux, please don't X_X
const NetworkMessages::NetworkMessageType SVC_SETANGLE = NetworkMessages::NetworkMessageType( 10 );

// if you really like this section and want to play all levels, set this to true
// warning: will increase playtime to 30+ min!
const bool FULL_GAMEPLAY = true; 
const int lvlAreaD = FULL_GAMEPLAY ? 36 : 20;
const int lvlAreaC = lvlAreaB + 1;
const int lvlAreaB = FULL_GAMEPLAY ? 19 : 11;
const int lvlAreaA = FULL_GAMEPLAY ? 18 : 10;

int level = 0;
int deaths = 0;
DateTime startTime;
int totalTimeF = 0;

int level_selection = 0;
const array< string > szSectionNames =
{
	"BOUNCY SENTRIES", // 0
	"YOU SHALL NOT WALK", // 1
	"YOU SHALL NOT JUMP", // 2
	"SHOW YOUR SPRAY", // 3
	"THE CAMERAMAN IS DRUNK", // 4
	"CATCH ME IF YOU CAN", // 5
	"NOW DO IT IN REVERSE LMAO", // 6
	"45 DEGREES", // 7
	"REALLY COOL BIRDS", // 8
	"SHOOTING STARS", // 9
	"ANNOYING MECHANIC", // 10
	"TOTALLY NORMAL BARNACLES", // 11
	"TRIGGER STUCK", // 12
	"PAIN IS KEY", // 13
	"BALLING", // 14
	"TIME TO RECONNECT" // 15
};
array< bool > bSections( szSectionNames.length() ); // ignoring the 2 starting ones

const array< string > szSectionNamesC =
{
	"THROWING PLAYERS", // 0
	"BRIDGE OF PLAYERS", // 1
	"JANKMAN", // 2
	"STACKING PROBLEM", // 3
	"HAPPY BULLSQUIDS", // 4
	"POPPOFORMATION", // 5
	"BUCKSHOT CURRENCY", // 6
	"GET IN THE BOX", // 7
	"SHY BUTTON", // 8
	"STRIPES", // 9
	"LET THERE BE LIGHT", // 10
	"KEYBOARD SMASH", // 11
	"EARRAPE WARNING", // 12
	"MY HORSE IS AMAZING", // 13
	"STOMP THE WAY", // 14
	"I HATE RNG" // 15
};
array< bool > bSectionsC( szSectionNamesC.length() ); // ignoring the starting one

array< bool > bJumped( 33 );
float flSpeedMultiplier = 1.00;
int iBoxBreakTimes = 0;
array< string > szOldWeapon( 33 );
bool bEasierJank = false;
bool bEasierPoppo = false;

void ManualRespawn( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	// game not yet started
	if ( level == 0 )
		return;
	
	if ( pActivator.IsPlayer() )
	{
		// time to reconnect should not consider this as a death
		if ( level_selection != 15 && level <= lvlAreaA )
			deaths++;
		
		CBasePlayer@ pPlayer = cast< CBasePlayer@ >( pActivator );
		pPlayer.pev.gravity = 1.0;
		
		RefillAmmo( pPlayer );
	}
}

void RefillAmmo( CBasePlayer@ pPlayer )
{
	if ( level == 37 )
		return; // not anymore
	
	switch ( level_selection )
	{
		case 0:
		case 7:
		{
			if ( level > lvlAreaC && level_selection == 0 )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_crowbar" ) is null )
					pPlayer.GiveNamedItem( "weapon_crowbar" );
			}
			else if ( level > lvlAreaC && level_selection == 7 )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_shotgun" ) is null )
					pPlayer.GiveNamedItem( "weapon_shotgun" );
				pPlayer.GiveAmmo( 125, "buckshot", pPlayer.GetMaxAmmo( "buckshot" ) );
			}
			else if ( level > 2 && level <= lvlAreaA )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_m249" ) is null )
					pPlayer.GiveNamedItem( "weapon_m249" );
				pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
				
				if ( level_selection == 7 && level <= lvlAreaA )
				{
					// respawn restores view, re-tilt
					TiltScreen( pPlayer );
				}
			}
			
			break;
		}
		case 2:
		{
			if ( pPlayer.HasNamedPlayerItem( "weapon_grapple" ) is null )
				pPlayer.GiveNamedItem( "weapon_grapple" );
		}
		case 4:
		{
			if ( level <= lvlAreaA )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_sniperrifle" ) is null )
					pPlayer.GiveNamedItem( "weapon_sniperrifle" );
				pPlayer.GiveAmmo( 15, "m40a1", pPlayer.GetMaxAmmo( "m40a1" ) );
			}
			break;
		}
		case 5:
		{
			if ( level > lvlAreaC )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_m16" ) is null )
					pPlayer.GiveNamedItem( "weapon_m16" );
				pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
			}
			break;
		}
		case 6:
		{
			if ( level > lvlAreaC )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_shotgun" ) is null )
					pPlayer.GiveNamedItem( "weapon_shotgun" );
				pPlayer.GiveAmmo( 125, "buckshot", pPlayer.GetMaxAmmo( "buckshot" ) );
			}
			break;
		}
		case 3:
		case 8:
		{
			if ( pPlayer.HasNamedPlayerItem( "weapon_357" ) is null )
				pPlayer.GiveNamedItem( "weapon_357" );
			pPlayer.GiveAmmo( 36, "357", pPlayer.GetMaxAmmo( "357" ) );
			break;
		}
		case 10:
		{
			if ( level > lvlAreaC )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_snark" ) is null )
					pPlayer.GiveNamedItem( "weapon_snark" );
				pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Snarks" ), 99 );
			}
			else
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_m249" ) is null )
					pPlayer.GiveNamedItem( "weapon_m249" );
				pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
				
				if ( pPlayer.HasNamedPlayerItem( "weapon_sniperrifle" ) is null )
					pPlayer.GiveNamedItem( "weapon_sniperrifle" );
				pPlayer.GiveAmmo( 15, "m40a1", pPlayer.GetMaxAmmo( "m40a1" ) );
				
				if ( pPlayer.HasNamedPlayerItem( "weapon_357" ) is null )
					pPlayer.GiveNamedItem( "weapon_357" );
				pPlayer.GiveAmmo( 36, "357", pPlayer.GetMaxAmmo( "357" ) );
				
				if ( pPlayer.HasNamedPlayerItem( "weapon_pipewrench" ) is null )
					pPlayer.GiveNamedItem( "weapon_pipewrench" );
				
				if ( pPlayer.HasNamedPlayerItem( "weapon_m16" ) is null )
					pPlayer.GiveNamedItem( "weapon_m16" );
				//pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
				
				if ( pPlayer.HasNamedPlayerItem( "weapon_gauss" ) is null )
					pPlayer.GiveNamedItem( "weapon_gauss" );
				pPlayer.GiveAmmo( 100, "uranium", pPlayer.GetMaxAmmo( "uranium" ) );
				
				if ( pPlayer.HasNamedPlayerItem( "weapon_rpg" ) is null )
					pPlayer.GiveNamedItem( "weapon_rpg" );
				pPlayer.GiveAmmo( 5, "rockets", pPlayer.GetMaxAmmo( "rockets" ) );
			}
			break;
		}
		case 11:
		{
			if ( pPlayer.HasNamedPlayerItem( "weapon_pipewrench" ) is null )
				pPlayer.GiveNamedItem( "weapon_pipewrench" );
			break;
		}
		case 12:
		{
			if ( level > lvlAreaC )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_satchel" ) is null )
					pPlayer.GiveNamedItem( "weapon_satchel" );
				pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Satchel Charge" ), 99 );
			}
			else
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_m16" ) is null )
					pPlayer.GiveNamedItem( "weapon_m16" );
				pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
			}
			break;
		}
		case 13:
		{
			if ( level > lvlAreaC )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_pipewrench" ) is null )
					pPlayer.GiveNamedItem( "weapon_pipewrench" );
			}
			else
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_gauss" ) is null )
					pPlayer.GiveNamedItem( "weapon_gauss" );
				pPlayer.GiveAmmo( 100, "uranium", pPlayer.GetMaxAmmo( "uranium" ) );
			}
			break;
		}
		case 14:
		{
			if ( level <= lvlAreaA )
			{
				if ( pPlayer.HasNamedPlayerItem( "weapon_sporelauncher" ) is null )
					pPlayer.GiveNamedItem( "weapon_sporelauncher" );
				pPlayer.GiveAmmo( 30, "sporeclip", pPlayer.GetMaxAmmo( "sporeclip" ) );
			}
			break;
		}
	}
}

HookReturnCode PlayerTakeDamage( DamageInfo@ diData )
{
	// Gather data
	CBaseEntity@ attacker = diData.pAttacker;
	CBaseEntity@ inflictor = diData.pInflictor;
	CBasePlayer@ victim = cast< CBasePlayer@ >( g_EntityFuncs.Instance( diData.pVictim.pev ) );
	float flDamage = diData.flDamage;
	
	if ( flDamage > 512 )
	{
		// prevent "gibme" spam
		if ( g_Engine.time < victim.m_flTimeOfLastDeath )
			diData.flDamage = flDamage = 0.0; // block
		
		victim.m_flTimeOfLastDeath = g_Engine.time + 5.0;
	}
	
	if ( attacker !is null && attacker.IsPlayer() && attacker !is victim )
	{
		if ( level > lvlAreaC && level_selection == 0 )
			LaunchPlayer( victim, cast< CBasePlayer@ >( attacker ) );
		
		// game disallows damage but my code can still create accidental TKs, negate damage
		diData.flDamage = flDamage = 0.0;
	}
	
	if ( attacker !is null && attacker.pev.classname == "monster_bullchicken" && level > lvlAreaC && level_selection == 4 )
	{
		// make bullsquid throw slighly more "powerful" to help players reach the top
		victim.pev.velocity.z += 150;
	}
	else if ( attacker !is null && attacker.pev.classname == "monster_babygarg" )
	{
		// lower the damage to make this section easier
		diData.flDamage = flDamage = Math.RandomLong( 0, 1 );
	}
	else if ( attacker !is null && attacker.pev.classname == "monster_gargantua" && level > lvlAreaC && level_selection == 14 )
	{
		// also lower it here
		diData.flDamage = flDamage = Math.RandomLong( 2, 4 );
	}
	else if ( attacker !is null && attacker.pev.classname == "monster_headcrab" && level > lvlAreaC && level_selection == 5 )
	{
		// instant kill
		diData.flDamage = flDamage = 100.0;
	}
	
	if ( ( victim.pev.health - flDamage ) < 1 )
	{
		diData.flDamage = 0.0; // prevent death
		
		if ( level > lvlAreaC && level_selection == 1 )
			BodySpawner( victim, victim, GIB_NOPENALTY );
		else if ( level > lvlAreaC && level_selection == 5 )
			PoppoSpawner( victim, attacker );
		else
		{
			victim.m_iDeaths++;
			deaths++;
			victim.GibMonster();
			g_PlayerFuncs.RespawnPlayer( victim );
		}
		
		// reset
		victim.pev.gravity = 1.0;
		
		RefillAmmo( victim );
		
		// cause of death?
		if ( diData.bitsDamageType & DMG_FALL != 0 )
		{
			switch ( level_selection )
			{
				case 4: g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s feet were too drunk and fell.\n" ); break;
				case 9: g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s fell to the stars... literally.\n" ); break;
				default: g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s legs are so OK that its body exploded.\n" );
			}
		}
		else if ( level <= lvlAreaA && level_selection == 14 )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s point of view became irrelevant.\n" );
		else if ( level_selection == 9 && diData.bitsDamageType & DMG_SNIPER != 0 )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " jumped into the bad stripe.\n" );
		else if ( level > lvlAreaC && level_selection == 15 && diData.bitsDamageType & DMG_BLAST != 0 )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " blew of anger at the bad RNG.\n" );
		else if ( attacker.pev.classname == "monster_stukabat" )
		{
			if ( diData.bitsDamageType & DMG_SNIPER != 0 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " tried to hurt the cool bird.\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " couldn't handle the awesomeness of the Stukabats.\n" );
		}
		else if ( attacker.pev.classname == "monster_sentry" )
		{
			if ( diData.bitsDamageType & DMG_BULLET != 0 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s body was filled with bouncy bullets.\n" );
			else
			{
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " was om nom nom'd by a totally normal Barnacle.\n" );
				
				// sentry does not let go as this isn't a real death!
				cast< CBaseMonster@ >( attacker ).m_hEnemy = null;
				victim.pev.flags |= FL_NOTARGET;
				g_Scheduler.SetTimeout( "BarnacleFix", 0.65, @victim );
			}
		}
		else if ( attacker.pev.classname == "monster_headcrab" )
		{
			if ( level > lvlAreaC && level_selection == 5 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " became part of the Poppoformation.\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " died to a Headcrab. lmao.\n" );
		}
		else if ( attacker.pev.classname == "monster_gargantua" )
		{
			if ( level > lvlAreaC )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " became a burned bread.\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " tried to hug the Gargantua.\n" );
		}
		else if ( attacker.pev.classname == "monster_pitdrone" )
		{
			if ( level_selection == 12 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " had a stroke reading a certain Pit Drone name.\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " was slashed, spitten, or something by a Pit Drone.\n" );
		}
		else if ( attacker.pev.classname == "monster_shocktrooper" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + ": Look, ma! Im a custom death message!\n" );
		else if ( attacker.pev.classname == "monster_bullchicken" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " was bitten by a bad alligator.\n" );
		else if ( attacker.pev.classname == "monster_babygarg" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " became a toasted bread.\n" );
		else if ( attacker.pev.classname == "monster_human_grunt" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s body was filled with the new currency.\n" );
		else if ( attacker.pev.classname == "monster_robogrunt" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " somehow died to an slow-ass robotic thing.\n" );
		else if ( attacker.pev.classname == "monster_zombie" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " was cut into tiny gibs.\n" );
		else if ( level_selection == 7 && level <= lvlAreaA )
		{
			string szMonsterName = cast< CBaseMonster@ >( attacker ).m_FormattedName;
			if ( szMonsterName.Length() > 0 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " had a 45 degree death by a 45 degree " + szMonsterName + ".\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " had a 45 degree death by a not 45 degree entity. :C\n" );
		}
		else if ( attacker.pev.classname == "monster_houndeye" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + "'s ears were popped by a cute hound.\n" );
		else if ( attacker.pev.classname == "monster_gonome" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " became jelly for the monsters.\n" );
		else if ( attacker.pev.classname == "monster_alien_slave" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " is probably into electrocution... probably.\n" );
		else if ( attacker.pev.classname == "monster_alien_controller" )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " died to an irrelevant monster.\n" );
		else
		{
			if ( level > lvlAreaC && level_selection == 1 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " made a shiny new statue of his death.\n" );
			else if ( level > lvlAreaC && level_selection == 12 )
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " destroyed his own speakers.\n" );
			else
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( victim.pev.netname ) + " died and I have no death message for it. :C\n" );
		}
	}
	
	if ( level_selection == 13 && level <= lvlAreaA )
	{
		// gibme is a cheat
		if ( flDamage < 512 )
		{
			CBaseEntity@ pDoor = g_EntityFuncs.FindEntityByTargetname( null, "giegue_door_wreckage" );
			if ( pDoor !is null )
			{
				if ( ( pDoor.pev.health - flDamage ) < 0 )
					g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
				else
					pDoor.pev.health -= flDamage;
			}
		}
	}
	
	return HOOK_CONTINUE;
}

void InitSection( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	// an entity from the boss section is visible through sky, i'm sorry :S
	CBaseEntity@ EXTERNAL_BRUSH = g_EntityFuncs.FindEntityByTargetname( null, "outro_water_latch" );
	if ( EXTERNAL_BRUSH !is null )
		EXTERNAL_BRUSH.pev.effects |= EF_NODRAW;
	
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			// little fix
			pPlayer.SetMaxSpeed( int( g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) ) );
		}
	}
	
	// dex's section turns this off, put it back on
	g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 1 );
	
	// not every server has a homemade static.cfg
	g_EngineFuncs.CVarSetFloat( "mp_npckill", 2 );
	
	// BUG - Level 10 (Annoying Mechanic)
	// Shuffle partially fails because pPlayer->m_rgpPlayerItems() can't grab all weapons.
	// Disallow dropweapons.
	g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 0 );
	
	level = 1;
	startTime = UnixTimestamp();
	
	g_EntityFuncs.FireTargets( "giegue_bgm1", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_wreck_respawn", null, null, USE_TOGGLE, 0.0f, 0.0f );
	
	g_EntityFuncs.FireTargets( "spawn_giegue", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_spawn2", null, null, USE_ON, 0.0f, 0.0f );
	
	CBaseEntity@ pCounter = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_counter" );
	pCounter.pev.health = 2;
	
	g_EntityFuncs.FireTargets( "giegue_button1_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
	
	// "hide" these
	CBaseEntity@ pCrate = null;
	while ( ( @pCrate = g_EntityFuncs.FindEntityByTargetname( pCrate, "giegue_spray_block" ) ) !is null )
	{
		pCrate.pev.takedamage = DAMAGE_NO;
		pCrate.pev.solid = SOLID_NOT;
		pCrate.pev.effects |= EF_NODRAW;
		g_EntityFuncs.SetOrigin( pCrate, pCrate.pev.origin ); // re-link
	}
	
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
	SpawnHelper( 1, 20 );
}

void NextSection( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBaseEntity@ pCounter = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_counter" );
	pCounter.pev.frags = 0;
	pCounter.pev.health = 1;
	
	level++;
	
	g_EntityFuncs.FireTargets( "giegue_startlight", null, null, USE_OFF, 0.0f, 0.0f );
	
	g_EntityFuncs.FireTargets( "giegue_door_wall", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_wreck_respawn", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_topmid_block", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_ladders", null, null, USE_ON, 0.0f, 0.0f );
	
	g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_area3_sides", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_area3_top_c", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_area3_bottom_c", null, null, USE_ON, 0.0f, 0.0f );
	
	g_EntityFuncs.FireTargets( "giegue_area3_stripes", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_area3_notlava", null, null, USE_OFF, 0.0f, 0.0f );
	
	// ARRGHH!!
	// trigger_hurt does not obey trigger mode, force them off.
	CBaseEntity@ pHurt = null;
	while ( ( @pHurt = g_EntityFuncs.FindEntityByClassname( pHurt, "trigger_hurt" ) ) !is null )
	{
		if ( string( pHurt.pev.targetname ).StartsWith( "giegue_" ) )
		{
			if ( string( pHurt.pev.targetname ).StartsWith( "giegue_ph_" ) )
				g_EntityFuncs.Remove( pHurt );
			else
			{
				// don't disable my healer!
				if ( pHurt.pev.dmg > 0 )
				{
					pHurt.pev.solid = SOLID_NOT;
					g_EntityFuncs.SetOrigin( pHurt, pHurt.pev.origin );
				}
			}
		}
	}
	
	g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink );
	
	g_EngineFuncs.CVarSetFloat( "sv_accelerate", 10 );
	g_EngineFuncs.CVarSetFloat( "sv_airaccelerate", 10 );
	g_EngineFuncs.CVarSetFloat( "mp_falldamage", -1 );
	
	g_EngineFuncs.LightStyle( 0, "m" );
	
	g_PlayerFuncs.RespawnAllPlayers();
	
	CBaseEntity@ pButton = null;
	while ( ( @pButton = g_EntityFuncs.FindEntityByTargetname( pButton, "giegue_goal_button" ) ) !is null )
	{
		g_EntityFuncs.Remove( pButton );
	}
	
	CBaseEntity@ pBody = null;
	while ( ( @pBody = g_EntityFuncs.FindEntityByTargetname( pBody, "giegue_deadplayer" ) ) !is null )
	{
		g_EntityFuncs.Remove( pBody );
	}
	
	CBaseEntity@ pSnark = null;
	while ( ( @pSnark = g_EntityFuncs.FindEntityByClassname( pSnark, "monster_snark" ) ) !is null )
	{
		g_EntityFuncs.Remove( pSnark );
	}
	
	CBaseEntity@ pChumtoad = null;
	while ( ( @pChumtoad = g_EntityFuncs.FindEntityByClassname( pChumtoad, "monster_chumtoad" ) ) !is null )
	{
		g_EntityFuncs.Remove( pChumtoad );
	}
	
	CBaseEntity@ pHelp = null;
	while ( ( @pHelp = g_EntityFuncs.FindEntityByTargetname( pHelp, "giegue_hint" ) ) !is null )
	{
		pHelp.KeyValue( "classify", "-1" );
	}
	
	CBaseEntity@ pHelpTimer = g_EntityFuncs.FindEntityByTargetname( null, "giegue_hint_timer" );
	g_EntityFuncs.Remove( pHelpTimer );
	
	// HACK - Stop g_EntityFuncs.FireTargets() from firing it's targets
	CBaseEntity@ pDelay = null;
	while ( ( @pDelay = g_EntityFuncs.FindEntityByClassname( pDelay, "DelayedUse" ) ) !is null )
	{
		if ( string( pDelay.pev.target ).StartsWith( "giegue_" ) )
			g_EntityFuncs.Remove( pDelay );
	}
	
	CBaseEntity@ pSpore = null;
	while ( ( @pSpore = g_EntityFuncs.FindEntityByClassname( pSpore, "sporegrenade" ) ) !is null )
	{
		g_EntityFuncs.Remove( pSpore );
	}
	
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.pev.health = 100;
			pPlayer.pev.gravity = 1.0;
			pPlayer.pev.fuser4 = 0;
			
			pPlayer.RemoveAllItems( false );
			pPlayer.SetItemPickupTimes( 0 ); // stay out of my way
			
			pPlayer.SetMaxSpeedOverride( -1 );
			
			g_PlayerFuncs.ConcussionEffect( pPlayer, 0.0, 0.0, 0.0 );
			g_EngineFuncs.CrosshairAngle( pPlayer.edict(), 0, 0 );
			
			pPlayer.pev.solid = SOLID_NOT; // don't want them bumping around or autoclimb moving them upwards
			g_Scheduler.SetTimeout( "RestoreSolid", 0.35, @pPlayer );
		}
	}
	
	if ( level == 2 )
	{
		pCounter.pev.health = 3;
		g_EntityFuncs.FireTargets( "giegue_button2_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
		HUDDisplay( null );
		SpawnHelper( 2, 20 );
	}
	else
	{
		if ( level <= lvlAreaA )
		{
			int newLevel = -1;
			while ( newLevel == -1 )
			{
				newLevel = Math.RandomLong( 0, int( szSectionNames.length() - 1 ) );
				if ( !bSections[ newLevel ] )
				{
					level_selection = newLevel;
					bSections[ level_selection ] = true;
					switch ( level_selection )
					{
						case 0: // Bouncy Sentries
						{
							pCounter.pev.health = 1;
							GiveSAW();
							g_Scheduler.SetTimeout( "LevelA0", 0.25 ); // wait for players to reach the ground
							g_Scheduler.SetTimeout( "LevelA0Fix", 0.50 );
							//SpawnHelper( 3, 55 );
							break;
						}
						case 1: // You shall not walk
						{
							g_EngineFuncs.CVarSetFloat( "sv_accelerate", 0 );
							g_EngineFuncs.CVarSetFloat( "sv_airaccelerate", 100 );
							
							pCounter.pev.health = 1;
							g_EntityFuncs.FireTargets( "giegue_button_a1_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							SpawnHelper( 4, 20 );
							break;
						}
						case 2: // You shall not jump
						{
							BlockJump();
							LevelA2();
							pCounter.pev.health = 1;
							g_EntityFuncs.FireTargets( "giegue_button_a2_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_topmid_block", null, null, USE_OFF, 0.0f, 0.0f );
							SpawnHelper( 5, 30 );
							break;
						}
						case 3: // Show your spray
						{
							// plugins only, it's WORKAROUND TIME!!! :C
							//g_Hooks.RegisterHook( Hooks::Player::PlayerDecal, @PlayerSpray );
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @ScanPlayerSpray );
							
							pCounter.pev.health = 14;
							g_EntityFuncs.FireTargets( "giegue_topmid_block", null, null, USE_OFF, 0.0f, 0.0f );
							
							// re-enable
							CBaseEntity@ pCrate = null;
							while ( ( @pCrate = g_EntityFuncs.FindEntityByTargetname( pCrate, "giegue_spray_block" ) ) !is null )
							{
								pCrate.pev.takedamage = DAMAGE_YES;
								pCrate.pev.solid = SOLID_BSP;
								pCrate.pev.effects &= ~EF_NODRAW;
								g_EntityFuncs.SetOrigin( pCrate, pCrate.pev.origin ); // re-link
							}
							
							SpawnHelper( 6, 40 );
							break;
						}
						case 4: // The cameraman is drunk
						{
							pCounter.pev.health = 1;
							GiveSniper();
							
							// move the button around
							@pButton = g_EntityFuncs.FindEntityByTargetname( null, "giegue_button_a4_ce" );
							pButton.pev.origin.x = Math.RandomFloat( 3488, 4704 );
							pButton.pev.origin.y = Math.RandomFloat( 1408, 2528 );
							g_EntityFuncs.SetOrigin( pButton, pButton.pev.origin );
							
							g_EntityFuncs.FireTargets( "giegue_button_a4_ce", null, null, USE_TOGGLE, 0.0f, 0.1f );
							g_EntityFuncs.FireTargets( "giegue_ladders", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_bottom_hurt", null, null, USE_ON, 0.0f, 0.0f );
							
							DrunkON();
							SpawnHelper( 7, 20 );
							break;
						}
						case 5: // Catch me if you can
						{
							pCounter.pev.health = 1;
							
							g_EntityFuncs.FireTargets( "giegue_button_a1_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							
							g_Scheduler.SetTimeout( "LevelA5", 0.1 );
							SpawnHelper( 8, 35 );
							break;
						}
						case 6: // Now do it in reverse LMAO
						{
							g_EngineFuncs.CVarSetFloat( "sv_accelerate", -5 );
							g_EngineFuncs.CVarSetFloat( "sv_airaccelerate", -1 );
							
							pCounter.pev.health = 3;
							g_EntityFuncs.FireTargets( "giegue_button_a6_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							SpawnHelper( 9, 35 );
							break;
						}
						case 7: // 45 degrees
						{
							pCounter.pev.health = 12;
							
							GiveSAW();
							Force1stPerson();
							
							g_Scheduler.SetTimeout( "LevelA7", 0.25 ); // wait a bit
							//SpawnHelper( 10, 60 );
							break;
						}
						case 8: // Really cool birds
						{
							pCounter.pev.health = 18;
							Give357();
							
							g_EntityFuncs.FireTargets( "giegue_button_a8_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							
							g_Scheduler.SetTimeout( "LevelA8", 0.25 );
							SpawnHelper( 11, 40 );
							break;
						}
						case 9: // Shooting Stars
						{
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @GravityJump );
							
							pCounter.pev.health = 1;
							
							g_EntityFuncs.FireTargets( "giegue_button_a2_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_topmid_block", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_top_hurt", null, null, USE_ON, 0.0f, 0.0f );
							
							LevelA9();
							SpawnHelper( 12, 20 );
							break;
						}
						case 10: // Annoying mechanic
						{
							Give357();
							GiveGauss();
							GiveM16();
							GiveRPG();
							GiveSAW();
							GiveSniper();
							GiveWrench();
							
							g_EntityFuncs.FireTargets( "giegue_button_a2_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_topmid_block", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_ladders", null, null, USE_OFF, 0.0f, 0.0f );
							
							pCounter.pev.health = 4;
							LevelA10();
							
							g_Scheduler.SetTimeout( "ScrambleWeapons", 0.25 );
							SpawnHelper( 13, 40 );
							break;
						}
						case 11: // Totally normal Barnacles
						{
							pCounter.pev.health = 6;
							GiveWrench();
							
							g_Scheduler.SetTimeout( "LevelA11", 0.25 );
							//SpawnHelper( 14, 50 );
							break;
						}
						case 12: // TRIGGER STUCK
						{
							GiveM16();
							pCounter.pev.health = 1;
							
							g_EntityFuncs.FireTargets( "giegue_button_a12_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							//g_EntityFuncs.FireTargets( "giegue_a12_multi_ce", null, null, USE_TOGGLE, 0.0f, 0.1f );
							g_Hooks.RegisterHook( Hooks::Weapon::WeaponPrimaryAttack, @InfiniteM16Burst );
							
							LevelA12();
							g_Scheduler.SetTimeout( "LevelA12Fix", 0.25 );
							SpawnHelper( 15, 45 );
							break;
						}
						case 13: // Pain is Key
						{
							GiveGauss();
							pCounter.pev.health = 1;
							g_EngineFuncs.CVarSetFloat( "mp_falldamage", 1 );
							
							LevelA13();
							SpawnHelper( 16, 45 );
							break;
						}
						case 14: // Balling
						{
							GiveSpore();
							pCounter.pev.health = 9;
							
							LevelA14();
							g_Scheduler.SetTimeout( "ScanSpore", 0.25 );
							//SpawnHelper( 17, 40 );
							break;
						}
						case 15: // Time to reconnect
						{
							// this won't work if the player is soloing, skip
							if ( g_PlayerFuncs.GetNumPlayers() == 1 )
							{
								pCounter.pev.health = 1;
								g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.25f );
							}
							else
							{
								pCounter.pev.health = g_PlayerFuncs.GetNumPlayers() / 2;
								g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ReconnectCounter );
								
								// serve as a hint
								CBaseEntity@ pDoor = null;
								while ( ( @pDoor = g_EntityFuncs.FindEntityByTargetname( pDoor, "giegue_door_wreckage" ) ) !is null )
								{
									pDoor.pev.spawnflags |= 32; // Show HUD Info
									pDoor.pev.health = pCounter.pev.health;
									pDoor.KeyValue( "displayname", "Times: " + int( pCounter.pev.health ) );
								}
							}
							
							SpawnHelper( 18, 25 );
							break;
						}
					}
				}
				else
					newLevel = -1;
			}
			HUDDisplay( null );
		}
		else if ( level == lvlAreaB )
		{
			// Area A complete
			g_Scheduler.SetTimeout( "InitSectionB", 0.01 );
		}
		else if ( level <= lvlAreaD )
		{
			int newLevel = -1;
			while ( newLevel == -1 )
			{
				newLevel = Math.RandomLong( 0, int( szSectionNamesC.length() - 1 ) );
				if ( !bSectionsC[ newLevel ] )
				{
					level_selection = newLevel;
					bSectionsC[ level_selection ] = true;
					switch ( level_selection )
					{
						case 0: // Throwing Players
						{
							// multiplayer only
							if ( g_PlayerFuncs.GetNumPlayers() == 1 )
							{
								pCounter.pev.health = 1;
								g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.25f );
							}
							else
							{
								pCounter.pev.health = 23;
								GiveCrowbar();
								g_Scheduler.SetTimeout( "LevelC0", 0.25 ); // wait for players to reach the ground
							}
							SpawnHelper( 21, 25 );
							break;
						}
						case 1: // Bridge of Players
						{
							pCounter.pev.health = 1;
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @NoPlayerClimb );
							
							g_EntityFuncs.FireTargets( "giegue_button_c1_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_sides", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_top_c", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_notlava", null, null, USE_ON, 0.0f, 0.0f );
							
							SpawnHelper( 22, 25 );
							break;
						}
						case 2: // Jankman
						{
							pCounter.pev.health = 1;
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @JankMove );
							
							g_EntityFuncs.FireTargets( "giegue_button_c2_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							SpawnHelper( 23, 25 );
							break;
						}
						case 3: // Stacking Problem
						{
							pCounter.pev.health = 3;
							Give357();
							g_EntityFuncs.FireTargets( "giegue_area3_sides", null, null, USE_OFF, 0.0f, 0.0f );
							
							LevelC3();
							SpawnHelper( 24, 30 );
							break;
						}
						case 4: // Happy Bullsquids
						{
							pCounter.pev.health = 2;
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @BullsquidJump );
							
							g_EntityFuncs.FireTargets( "giegue_button_c4_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_top_c", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_bottom_c", null, null, USE_OFF, 0.0f, 0.0f );
							
							LevelC4();
							g_Scheduler.SetTimeout( "BullsquidHugPlayer", 0.25 );
							SpawnHelper( 25, 35 );
							break;
						}
						case 5: // Poppoformation
						{
							pCounter.pev.health = 4;
							GiveM16();
							
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							
							LevelC5();
							SpawnHelper( 26, 70 );
							break;
						}
						case 6: // Buckshot Currency
						{
							pCounter.pev.health = 6;
							GiveShotgun();
							
							g_Scheduler.SetTimeout( "LevelC6", 0.25 );
							g_Scheduler.SetTimeout( "InfiniteNPCShotgun", 0.50 );
							//SpawnHelper( 27, 50 );
							break;
						}
						case 7: // Get in the Box
						{
							pCounter.pev.health = 1;
							GiveShotgun();
							
							g_Scheduler.SetTimeout( "LevelC7", 0.25 );
							g_Scheduler.SetTimeout( "ScanBGarg", 0.50 );
							
							g_EntityFuncs.FireTargets( "giegue_rng_c7", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							//SpawnHelper( 28, 30 );
							break;
						}
						case 8: // Shy Button
						{
							pCounter.pev.health = 1;
							
							g_EntityFuncs.FireTargets( "giegue_button_c8_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_sides", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_top_c", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_bottom_c", null, null, USE_OFF, 0.0f, 0.0f );
							
							flSpeedMultiplier = 1.00;
							g_Scheduler.SetTimeout( "LevelC8", 0.1 );
							SpawnHelper( 29, 40 );
							break;
						}
						case 9: // Stripes
						{
							pCounter.pev.health = 6;
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @NoPlayerClimb );
							
							g_EntityFuncs.FireTargets( "giegue_button_c9_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_stripes", null, null, USE_ON, 0.0f, 0.0f );
							SpawnHelper( 30, 20 );
							break;
						}
						case 10: // Let there be light
						{
							pCounter.pev.health = 8;
							GiveSnarks();
							ScanSnarks();
							
							g_EngineFuncs.LightStyle( 0, "a" );
							g_EntityFuncs.FireTargets( "giegue_button_c10_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							SpawnHelper( 31, 10 );
							break;
						}
						case 11: // Keyboard Smash
						{
							pCounter.pev.health = 3;
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @RoboMove );
							
							LevelC11();
							g_EntityFuncs.FireTargets( "giegue_button1_ceC", null, null, USE_TOGGLE, 0.0f, 0.0f );
							SpawnHelper( 32, 30 );
							break;
						}
						case 12: // Earrape Warning
						{
							pCounter.pev.health = 4;
							GiveSatchels();
							g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, @FastSatchel );
							
							g_Scheduler.SetTimeout( "LevelC12", 0.25 );
							//SpawnHelper( 33, 15 );
							break;
						}
						case 13: // My horse is amazing
						{
							pCounter.pev.health = 1;
							g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @NoPlayerClimb );
							GiveWrench();
							
							g_EntityFuncs.FireTargets( "giegue_button_c1_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_notlava", null, null, USE_ON, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_sides", null, null, USE_OFF, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							
							g_Scheduler.SetTimeout( "LevelC13", 0.25 );
							SpawnHelper( 34, 20 );
							break;
						}
						case 14: // Stomp the way
						{
							//pCounter.pev.health = 1;
							
							ScanStomp();
							LevelC14();
							SpawnHelper( 35, 40 );
							break;
						}
						case 15: // I hate RNG
						{
							pCounter.pev.health = 1;
							GiveCrowbar();
							
							g_EntityFuncs.FireTargets( "giegue_button_c15_ce", null, null, USE_TOGGLE, 0.0f, 0.0f );
							g_EntityFuncs.FireTargets( "giegue_area3_middle", null, null, USE_OFF, 0.0f, 0.0f );
							SpawnHelper( 36, 40 );
							break;
						}
					}
				}
				else
					newLevel = -1;
			}
			HUDDisplay( null );
		}
		else
		{
			// Area C complete
			g_Scheduler.SetTimeout( "InitSectionD", 0.01 );
		}
	}
}

void TiltScreen( CBasePlayer@ pPlayer )
{
	int16 pitch = int( pPlayer.pev.v_angle.x * (65536/360) );
	int16 yaw = int( pPlayer.pev.v_angle.y * (65536/360) );
	int RNG = Math.RandomLong( 1, 2 );
	
	NetworkMessage zee_angle( MSG_ONE_UNRELIABLE, SVC_SETANGLE, pPlayer.edict() );
	zee_angle.WriteShort( pitch ); // Pitch
	zee_angle.WriteShort( yaw ); // Yaw
	zee_angle.WriteShort( RNG == 1 ? -9000 : 9000 ); // Roll
	zee_angle.End();
	
	g_EngineFuncs.CrosshairAngle( pPlayer.edict(), RNG == 1 ? -20 : 20, RNG == 1 ? -5 : 5 );
}

void RestoreSolid( CBasePlayer@ pPlayer )
{
	if ( pPlayer !is null && pPlayer.IsConnected() )
	{
		pPlayer.pev.solid = SOLID_SLIDEBOX;
	}
}
void BarnacleFix( CBasePlayer@ pPlayer )
{
	if ( pPlayer !is null && pPlayer.IsConnected() )
	{
		pPlayer.pev.flags &= ~FL_NOTARGET;
	}
}

void EndGame( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	// shutdown turns off the spawnpoints but sometimes still respawns in the wrong place, turn this one off right now
	g_EntityFuncs.FireTargets( "giegue_spawn6", null, null, USE_OFF, 0.0f, 0.0f );
	
	CBaseEntity@ pScript = null;
	while ( ( @pScript = g_EntityFuncs.FindEntityByTargetname( pScript, "giegue_script_run" ) ) !is null )
	{
		g_EntityFuncs.Remove( pScript );
	}
	
	// Just to clear the HUD
	HUDTextParams rtime;
	rtime.x = -1;
	rtime.y = 0.85;
	rtime.effect = 0;
	rtime.r1 = 250;
	rtime.g1 = 250;
	rtime.b1 = 250;
	rtime.a1 = 250;
	rtime.r2 = 250;
	rtime.g2 = 250;
	rtime.b2 = 250;
	rtime.a2 = 250;
	rtime.fadeinTime = 0.0;
	rtime.fadeoutTime = 0.0;
	rtime.holdTime = 1.0;
	rtime.fxTime = 0.0;
	rtime.channel = 2;
	g_PlayerFuncs.HudMessageAll( rtime, "" );
	
	g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink );
	g_Hooks.RemoveHook( Hooks::Player::PlayerTakeDamage );
	g_Hooks.RemoveHook( Hooks::Player::PlayerKilled );
	g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer );
	g_Hooks.RemoveHook( Hooks::Weapon::WeaponPrimaryAttack );
	
	// restore CVars
	g_EngineFuncs.CVarSetFloat( "sv_maxspeed", 270 );
	g_EngineFuncs.CVarSetFloat( "mp_flashlight", 1 );
	g_EngineFuncs.CVarSetFloat( "mp_suitpower", 1 );
	g_EngineFuncs.CVarSetFloat( "sv_gravity", 800 );
	g_EngineFuncs.CVarSetFloat( "mp_dropweapons", 1 );
	g_EngineFuncs.CVarSetFloat( "mp_npckill", 1 );
	
	// nothing happened here, no sir.
	CBaseEntity@ EXTERNAL_BRUSH = g_EntityFuncs.FindEntityByTargetname( null, "outro_water_latch" );
	if ( EXTERNAL_BRUSH !is null )
		EXTERNAL_BRUSH.pev.effects &= ~EF_NODRAW;
}

void HUDDisplay( CBaseEntity@ pTriggerScript )
{
	HUDTextParams rtime;
	rtime.x = -1;
	rtime.y = 0.85;
	rtime.effect = 0;
	rtime.r1 = 250;
	rtime.g1 = 250;
	rtime.b1 = 250;
	rtime.a1 = 250;
	rtime.r2 = 250;
	rtime.g2 = 250;
	rtime.b2 = 250;
	rtime.a2 = 250;
	rtime.fadeinTime = 0.0;
	rtime.fadeoutTime = 0.0;
	rtime.holdTime = 1.0;
	rtime.fxTime = 0.0;
	rtime.channel = 2;
	
	TimeDifference tdTotalTime( DateTime( UnixTimestamp() ), startTime );
	
	int seconds = 0;
	int minutes = 0;
	
	if ( USING_LINUX )
	{
		// lower accuracy as time ticks are tied to server FPS
		totalTimeF++;
		seconds = totalTimeF / 4; // 0.25 sec ticks
	}
	else
		seconds = tdTotalTime.GetSeconds();
	
	while ( seconds >= 60 )
	{
		seconds -= 60;
		minutes++;
	}
	
	string szTime1 = "";
	if ( minutes < 10 )
		szTime1 += "0" + minutes + ":";
	else
		szTime1 += string( minutes ) + ":";
	
	string szTime2 = "";
	if ( seconds < 10 )
		szTime2 += "0" + seconds + "\n";
	else
		szTime2 += string( seconds ) + "\n";
	
	string INFO;
	switch ( level )
	{
		case 1: INFO = "A PLAIN ROOM\n\n"; break;
		case 2: INFO = "WAIT, IT REPEATS?\n\n"; break;
		case 37: INFO = "THE ROOM\n\n"; break;
		default:
		{
			if ( level == lvlAreaB )
				INFO = "WIDE SVEN\n\n";
			else if ( level == lvlAreaC )
				INFO = "OH! NEW MUSIC!\n\n";
			else if ( g_PlayerFuncs.GetNumPlayers() == 1 && ( ( level <= lvlAreaA && level_selection == 15 ) || ( level > lvlAreaC && level_selection == 0 ) ) )
				INFO = "OOPS, SINGLE PLAYER!\n\n";
			else
			{
				if ( level <= lvlAreaA )
					INFO = szSectionNames[ level_selection ] + "\n\n";
				else
					INFO = szSectionNamesC[ level_selection ] + "\n\n";
			}
		}
	}
	INFO += "DEATHS: " + deaths + "\nTIME: " + szTime1 + szTime2;
	
	g_PlayerFuncs.HudMessageAll( rtime, INFO + "\n" );
}

void StukabatHurt( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if ( pActivator !is null && pActivator.IsMonster() )
	{
		CBaseMonster@ pMonster = cast< CBaseMonster@ >( pActivator );
		if ( pMonster.pev.dmg_inflictor !is null )
		{
			CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pMonster.pev.dmg_inflictor );
			if ( pAttacker !is null && pAttacker.IsPlayer() )
			{
				pAttacker.TakeDamage( pMonster.pev, pMonster.pev, 200, DMG_SNIPER );
			}
		}
		
		g_Scheduler.SetTimeout( "FixAITrigger", 0.01, EHandle( pMonster ), "giegue_stukabat_hurt" );
	}
}

void BGargHurt( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	if ( pActivator !is null && pActivator.IsMonster() )
	{
		CBaseMonster@ pMonster = cast< CBaseMonster@ >( pActivator );
		
		// get off the ground will ya?
		pMonster.pev.origin.z += 1;
		pMonster.pev.flags &= ~FL_ONGROUND;
		
		// make it easier to push the monster on the upwards slope
		pMonster.pev.velocity.z += 70;
		
		CBaseEntity@ pAttacker = g_EntityFuncs.Instance( pMonster.pev.dmg_inflictor );
		if ( pAttacker !is null && pAttacker.IsPlayer() )
		{
			// even more easier?
			Math.MakeVectors( pAttacker.pev.v_angle );
			pMonster.pev.velocity = pMonster.pev.velocity + g_Engine.v_forward * 35;
		}
		
		g_Scheduler.SetTimeout( "FixAITrigger", 0.01, EHandle( pMonster ), "giegue_bgarg_hurt" );
	}
}
void FixAITrigger( EHandle hMonster, string szTriggerTarget )
{
	if ( hMonster.IsValid() )
	{
		CBaseMonster@ pMonster = cast< CBaseMonster@ >( hMonster.GetEntity() );
		
		// re-enable
		pMonster.m_iTriggerCondition = AITRIGGER_TAKEDAMAGE;
		pMonster.m_iszTriggerTarget = szTriggerTarget;
	}
}

void CheckA12( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	// toggleable + shooteable buttons + multisource aren't a good mix... check differently
	int iOn = 0;
	CBaseEntity@ pButton = null;
	while ( ( @pButton = g_EntityFuncs.FindEntityByTargetname( pButton, "giegue_goal_button" ) ) !is null )
	{
		if ( pButton.pev.classname == "func_button" )
		{
			if ( pButton.pev.frame == 1 )
				iOn++;
		}
	}
	
	if ( iOn == 10 )
	{
		g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
		
		CBaseEntity@ pCounter = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_counter" );
		pCounter.pev.health = 999;
	}
}

void BoxWin( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBaseMonster@ pMonster = cast< CBaseMonster@ >( g_EntityFuncs.FindEntityByClassname( null, "monster_babygarg" ) );
	pMonster.GibMonster();
	
	CBaseEntity@ pBox = g_EntityFuncs.FindEntityByTargetname( null, "giegue_the_box" );
	g_EntityFuncs.Remove( pBox );
	
	g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
}

void BoxRNG( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBaseEntity@ pCreate = g_EntityFuncs.FindEntityByTargetname( null, "giegue_button_c15_ce" );
	
	Vector vecOrigin = pCreate.pev.origin; vecOrigin.z += 96;
	Vector vecAngles = g_vecZero;
	int RNG = Math.RandomLong( 1, 100 );
	
	if ( RNG <= 1 )
	{
		g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
		return;
	}
	else if ( RNG <= 15 )
	{
		// monster
		CBaseEntity@ pMonster = null;
		switch ( Math.RandomLong( 1, 4 ) )
		{
			case 1: vecOrigin.x -= 96; vecAngles.y = 0; break;
			case 2: vecOrigin.x += 96; vecAngles.y = 180; break;
			case 3: vecOrigin.y -= 96; vecAngles.y = 90; break;
			case 4: vecOrigin.y += 96; vecAngles.y = -90; break;
		}
		
		switch ( Math.RandomLong( 1, 4 ) )
		{
			case 1:
			{
				@pMonster = g_EntityFuncs.Create( "monster_bullchicken", vecOrigin, vecAngles, false );
				pMonster.pev.health = pMonster.pev.max_health = 200.0 - ( iBoxBreakTimes * 2 );
				pMonster.pev.targetname = "giegue_goal_button";
				pMonster.KeyValue( "displayname", "monster_box" );
				pMonster.KeyValue( "classify", "16" );
				break;
			}
			case 2:
			{
				@pMonster = g_EntityFuncs.Create( "monster_gonome", vecOrigin, vecAngles, false );
				pMonster.pev.health = pMonster.pev.max_health = 200.0 - ( iBoxBreakTimes * 2 ); 
				pMonster.pev.targetname = "giegue_goal_button";
				pMonster.KeyValue( "displayname", "monster_box" );
				pMonster.KeyValue( "classify", "17" );
				break;
			}
			case 3:
			{
				@pMonster = g_EntityFuncs.Create( "monster_shocktrooper", vecOrigin, vecAngles, false );
				pMonster.pev.spawnflags |= 1024; // No Shockroach
				pMonster.pev.health = pMonster.pev.max_health = 200.0 - ( iBoxBreakTimes * 2 );
				pMonster.pev.targetname = "giegue_goal_button";
				pMonster.KeyValue( "displayname", "monster_box" );
				pMonster.KeyValue( "classify", "18" );
				break;
			}
			case 4:
			{
				@pMonster = g_EntityFuncs.Create( "monster_pitdrone", vecOrigin, vecAngles, false );
				pMonster.pev.health = pMonster.pev.max_health = 200.0 - ( iBoxBreakTimes * 2 );
				pMonster.pev.targetname = "giegue_goal_button";
				pMonster.KeyValue( "displayname", "monster_box" );
				pMonster.KeyValue( "classify", "19" );
				break;
			}
		}
	}
	else if ( RNG <= 20 )
	{
		// Passing -explodemagnitude keyvalue doesn't seem to work, do a manual explosion
		g_EntityFuncs.CreateExplosion( pCreate.pev.origin, Vector( 0, 0, -90 ), pCreate.edict(), 200 - ( iBoxBreakTimes * 2 ), true );
	}
	
	iBoxBreakTimes++;
	
	// 100 times and no dice? Force it open!
	if ( iBoxBreakTimes >= 100 )
		g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
	else
		g_EntityFuncs.FireTargets( "giegue_button_c15_ce", null, null, USE_ON, 0.0f, 0.000002f ); // paranoia
}

void EasierJank( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	bEasierJank = true;
}

void EasierPoppo( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	bEasierPoppo = true;
	GiveRPG();
}

void BlockJump()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.pev.fuser4 = 1;
			pPlayer.GiveNamedItem( "weapon_grapple" );
		}
	}
}

void GiveSAW()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_m249" );
			pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
		}
	}
}
void GiveSniper()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_sniperrifle" );
			pPlayer.GiveAmmo( 15, "m40a1", pPlayer.GetMaxAmmo( "m40a1" ) );
		}
	}
}
void Give357()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_357" );
			pPlayer.GiveAmmo( 36, "357", pPlayer.GetMaxAmmo( "357" ) );
		}
	}
}
void GiveWrench()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_pipewrench" );
		}
	}
}
void GiveM16()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_m16" );
			pPlayer.GiveAmmo( 600, "556", pPlayer.GetMaxAmmo( "556" ) );
		}
	}
}
void GiveGauss()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_gauss" );
			pPlayer.GiveAmmo( 100, "uranium", pPlayer.GetMaxAmmo( "uranium" ) );
		}
	}
}
void GiveSpore()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_sporelauncher" );
			pPlayer.GiveAmmo( 30, "sporeclip", pPlayer.GetMaxAmmo( "sporeclip" ) );
		}
	}
}
void GiveRPG()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_rpg" );
			pPlayer.GiveAmmo( 5, "rockets", pPlayer.GetMaxAmmo( "rockets" ) );
		}
	}
}
void GiveCrowbar()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_crowbar" );
		}
	}
}
void GiveSnarks()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_snark" );
			pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Snarks" ), 99 );
		}
	}
}
void GiveSatchels()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_satchel" );
			pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex( "Satchel Charge" ), 99 );
		}
	}
}
void GiveShotgun()
{
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.GiveNamedItem( "weapon_shotgun" );
			pPlayer.GiveAmmo( 125, "buckshot", pPlayer.GetMaxAmmo( "buckshot" ) );
		}
	}
}

void DrunkON()
{
	if ( level_selection != 4 )
		return;
	
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			g_PlayerFuncs.ConcussionEffect( pPlayer, 100.0, 1.0, 0.0 );
			//g_EngineFuncs.CrosshairAngle( pPlayer.edict(), Math.RandomLong( -20, 20 ), Math.RandomLong( -20, 20 ) );
		}
	}
	
	g_Scheduler.SetTimeout( "DrunkON", 0.25 );
}

HookReturnCode ScanPlayerSpray( CBasePlayer@ pPlayer, uint& out dummy )
{
	if ( level_selection == 3 && pPlayer.pev.impulse == 201 ) // spray
	{
		TraceResult tr;
		Math.MakeVectors( pPlayer.pev.v_angle );
		g_Utility.TraceLine( pPlayer.pev.origin + pPlayer.pev.view_ofs, pPlayer.pev.origin + pPlayer.pev.view_ofs + g_Engine.v_forward * 128, ignore_monsters, pPlayer.edict(), tr );
		
		if ( tr.flFraction != 1.0 )
		{
			// line hit something
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
			if ( pEntity !is null && pEntity.pev.takedamage > DAMAGE_NO )
				pEntity.TakeDamage( pPlayer.pev, pPlayer.pev, 1, DMG_BLAST );
		}
		
		pPlayer.m_flNextDecalTime = g_Engine.time; // now
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode GravityJump( CBasePlayer@ pPlayer, uint& out dummy )
{
	// inactive
	if ( level_selection != 9 || pPlayer.pev.gravity != -1.0 )
		return HOOK_CONTINUE;
	
	int iPlayerIndex = pPlayer.entindex();
	
	if ( ( pPlayer.pev.flags & FL_ONGROUND ) != 0 )
	{
		// Don't assume we are on the ground if a player is below us
		CBaseEntity@ pOther = g_EntityFuncs.Instance( pPlayer.pev.groundentity );
		if ( pOther !is null )
		{
			if ( !pOther.IsPlayer() )
			{
				pPlayer.pev.origin.z += 2.0;
				pPlayer.pev.gravity = -1.0;
				pPlayer.pev.velocity.z = 2.0;
			}
		}
	}
	
	if ( ( pPlayer.pev.button & IN_JUMP ) != 0 )
	{
		if ( !bJumped[ iPlayerIndex ] )
		{
			pPlayer.pev.velocity.z = -200.0;
			bJumped[ iPlayerIndex ] = true;
		}
	}
	else
	{
		if ( ( pPlayer.pev.oldbuttons & IN_JUMP ) != 0 )
			bJumped[ iPlayerIndex ] = false;
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode InfiniteM16Burst( CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon )
{
	if ( level_selection == 12 && pWeapon.m_iId == WEAPON_M16 )
	{
		pWeapon.pev.fuser2 = 30.0;
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode FastSatchel( CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon )
{
	if ( level_selection == 12 && pWeapon.m_iId == WEAPON_SATCHEL )
	{
		pWeapon.m_flNextSecondaryAttack = 0.1;
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode ReconnectCounter( CBasePlayer@ pPlayer )
{
	if ( level_selection == 15 )
	{
		CBaseEntity@ pDoor = g_EntityFuncs.FindEntityByTargetname( null, "giegue_door_wreckage" );
		if ( pDoor !is null )
		{
			g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
			pDoor.pev.health -= 1;
		}
	}
	
	return HOOK_CONTINUE;
}

// UNDONE: Don't make this a hook, it causes issues.
void BodySpawner( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if ( level_selection != 1 && level_selection != 13 )
		return;
	
	if ( iGib != GIB_ALWAYS )
	{
		// don't create bodys at the spawn
		float X = pPlayer.pev.origin.x;
		float Y = pPlayer.pev.origin.y;
		if ( X < 3880 || X > 4310 || Y > 1550 )
		{
			CBaseMonster@ pModel = cast< CBaseMonster@ >( g_EntityFuncs.Create( "monster_generic", pPlayer.pev.origin, pPlayer.pev.angles, true ) );
			pModel.pev.angles.x = pModel.pev.angles.z = 0; // don't tilt
			pModel.pev.spawnflags = 256; // Pre-Disaster
			pModel.KeyValue( "classify", "2" );
			g_EntityFuncs.SetModel( pModel, "models/player.mdl" );
			g_EntityFuncs.DispatchSpawn( pModel.edict() );
			pModel.KeyValue( "displayname", string( pPlayer.pev.netname ) + "'s dead body" );
			pModel.pev.targetname = "giegue_deadplayer";
			pModel.pev.flags |= FL_NOTARGET;
			pModel.m_afSoundTypes = 0; // don't react to anything
		}
	}
	
	deaths++;
	pPlayer.GibMonster();
	g_PlayerFuncs.RespawnPlayer( pPlayer, true, true );
}

void PoppoSpawner( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker )
{
	if ( pPlayer !is pAttacker )
	{
		// don't create new monsters at the spawn
		float X = pPlayer.pev.origin.x;
		float Y = pPlayer.pev.origin.y;
		if ( X < 3880 || X > 4310 || Y > 1550 )
		{
			// do a very tiny Z offset, might help with rare cases of crabs spawning inside ramps
			Vector vecSrc = pPlayer.pev.origin;
			vecSrc.z += 1;
			if ( ( pPlayer.pev.flags & FL_DUCKING ) != 0 )
				vecSrc.z += 8;
			
			// Spawn a new headcrab at the player's death position
			CBaseEntity@ pCrab = g_EntityFuncs.Create( "monster_headcrab", vecSrc, pPlayer.pev.angles, false );
			pCrab.pev.angles.x = pCrab.pev.angles.z = 0; // don't tilt
			pCrab.pev.targetname = "giegue_goal_button";
			pCrab.KeyValue( "TriggerCondition", "4" );
			pCrab.KeyValue( "TriggerTarget", "giegue_goal_counter" );
			pCrab.KeyValue( "classify", "7" );
			pCrab.KeyValue( "displayname", "Poppoformed Player" );
			pCrab.pev.health = pCrab.pev.max_health = 95; // player spawned headcrab
			pCrab.pev.scale = 1.25;
			
			// Increase goal counter (Players now need to kill an extra headcrab)
			CBaseEntity@ pCounter = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_counter" );
			pCounter.pev.health += 1;
		}
		else
		{
			// Heal otherwise
			if ( !bEasierPoppo )
				pAttacker.TakeHealth( pAttacker.pev.max_health, DMG_MEDKITHEAL );
		}
	}
	
	pPlayer.m_iDeaths++;
	deaths++;
	pPlayer.GibMonster();
	g_PlayerFuncs.RespawnPlayer( pPlayer );
}

HookReturnCode NoPlayerClimb( CBasePlayer@ pPlayer, uint& out dummy )
{
	// inactive
	if ( level_selection != 1 && level_selection != 9 && level_selection != 13 )
		return HOOK_CONTINUE;
	
	if ( ( pPlayer.pev.flags & FL_ONGROUND ) != 0 )
	{
		CBaseEntity@ pOther = g_EntityFuncs.Instance( pPlayer.pev.groundentity );
		if ( pOther !is null )
		{
			// no longer needed
			/*
			if ( pOther.IsPlayer() )
			{
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( pPlayer.pev.netname ) + " climbed on the wrong body.\n" );
				BodySpawner( pPlayer, pPlayer, GIB_ALWAYS );
				@pPlayer.pev.groundentity = null;
			}
			*/
			if ( pOther.pev.targetname == "giegue_area3_notlava" )
			{
				pPlayer.m_iDeaths++;
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( pPlayer.pev.netname ) + " touched the red thing that is totally not lava.\n" );
				BodySpawner( pPlayer, pPlayer, ( level_selection == 13 ? GIB_ALWAYS : GIB_NOPENALTY ) );
				@pPlayer.pev.groundentity = null;
			}
			else if ( pOther.pev.targetname == "giegue_area3_stripes" && pOther.pev.rendercolor == Vector( 255, 0, 0 ) )
			{
				// PlayerKilled hook is inactive at this point
				pPlayer.TakeDamage( pOther.pev, pOther.pev, 100.0, DMG_SNIPER );
				@pPlayer.pev.groundentity = null;
			}
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode BullsquidJump( CBasePlayer@ pPlayer, uint& out dummy )
{
	// inactive
	if ( level_selection != 4 )
		return HOOK_CONTINUE;
	
	if ( ( pPlayer.pev.flags & FL_ONGROUND ) != 0 )
	{
		CBaseMonster@ pMonster = cast< CBaseMonster@ >( g_EntityFuncs.Instance( pPlayer.pev.groundentity ) );
		if ( pMonster !is null )
		{
			if ( pMonster.pev.sequence != 9 )
			{
				// bullsquid uses generic melee attack2
				Schedule@ pSchedule = pMonster.ScheduleFromName( "Secondary Melee Attack" );
				if ( pSchedule !is null )
				{
					// have to do this or CheckTraceHullAttack will not hit the player if it's standing on the monster
					pMonster.SetPlayerAlly( false ); 
					pMonster.m_hEnemy = pPlayer;
					
					// force bullsquid to do its bite attack
					pMonster.ChangeSchedule( pSchedule );
					
					// restore friendly status
					g_Scheduler.SetTimeout( "ResetBullsquid", 0.5, EHandle( pMonster ) );
				}
				pMonster.pev.sequence = 9; // bad but don't call multiple times (we're in prethink)
			}
		}
	}
	
	return HOOK_CONTINUE;
}

HookReturnCode RoboMove( CBasePlayer@ pPlayer, uint& out dummy )
{
	// inactive
	if ( level_selection != 11 )
		return HOOK_CONTINUE;
	
	if ( pPlayer.GetMaxSpeedOverride() == 1 )
	{
		if ( pPlayer.pev.button & IN_FORWARD != 0 && pPlayer.pev.oldbuttons & IN_FORWARD == 0 )
		{
			Math.MakeVectors( pPlayer.pev.v_angle );
			pPlayer.pev.origin.x += g_Engine.v_forward.x * 32;
			pPlayer.pev.origin.y += g_Engine.v_forward.y * 32;
		}
		if ( pPlayer.pev.button & IN_BACK != 0 && pPlayer.pev.oldbuttons & IN_BACK == 0 )
		{
			Math.MakeVectors( pPlayer.pev.v_angle );
			pPlayer.pev.origin.x -= g_Engine.v_forward.x * 32;
			pPlayer.pev.origin.y -= g_Engine.v_forward.y * 32;
		}
		if ( pPlayer.pev.button & IN_MOVELEFT != 0 && pPlayer.pev.oldbuttons & IN_MOVELEFT == 0 )
		{
			Math.MakeVectors( pPlayer.pev.v_angle );
			pPlayer.pev.origin.x -= g_Engine.v_right.x * 32;
			pPlayer.pev.origin.y -= g_Engine.v_right.y * 32;
		}
		if ( pPlayer.pev.button & IN_MOVERIGHT != 0 && pPlayer.pev.oldbuttons & IN_MOVERIGHT == 0 )
		{
			Math.MakeVectors( pPlayer.pev.v_angle );
			pPlayer.pev.origin.x += g_Engine.v_right.x * 32;
			pPlayer.pev.origin.y += g_Engine.v_right.y * 32;
		}
		
		// i don't want to create another trigger_hurt just for this :S
		float X = pPlayer.pev.origin.x;
		float Y = pPlayer.pev.origin.y;
		if ( X < 3456 || X > 4736 || Y < 1280 )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( pPlayer.pev.netname ) + " noclipped out of existance.\n" );
			pPlayer.m_iDeaths++;
			deaths++;
			pPlayer.GibMonster();
			g_PlayerFuncs.RespawnPlayer( pPlayer, true, true );
		}
		
		CBaseEntity@ pDoor = g_EntityFuncs.FindEntityByTargetname( null, "giegue_door_wreckage" );
		if ( pDoor !is null && Y > 2560 || Y > 2722 ) // i know it's outside map, it's intentional...
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( pPlayer.pev.netname ) + " noclipped out of existance.\n" );
			pPlayer.m_iDeaths++;
			deaths++;
			pPlayer.GibMonster();
			g_PlayerFuncs.RespawnPlayer( pPlayer, true, true );
		}
	}
	else
		pPlayer.SetMaxSpeedOverride( 1 );
	
	return HOOK_CONTINUE;
}

HookReturnCode JankMove( CBasePlayer@ pPlayer, uint& out dummy )
{
	// inactive
	if ( level_selection != 2 )
		return HOOK_CONTINUE;
	
	float flJankSpeed = 5.8;
	if ( bEasierJank )
		flJankSpeed = 2.9;
	
	// x0.59 for Z. any lower won't lift the player off the ground
	if ( pPlayer.pev.button & IN_FORWARD != 0 && pPlayer.pev.oldbuttons & IN_FORWARD == 0 )
	{
		Math.MakeVectors( pPlayer.pev.v_angle );
		pPlayer.pev.velocity.x = pPlayer.pev.velocity.x + g_Engine.v_forward.x * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		pPlayer.pev.velocity.y = pPlayer.pev.velocity.y + g_Engine.v_forward.y * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		
		if ( pPlayer.pev.flags & FL_ONGROUND != 0 )
			pPlayer.pev.velocity.z = g_Engine.v_up.z * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * 0.59;
	}
	if ( pPlayer.pev.button & IN_BACK != 0 && pPlayer.pev.oldbuttons & IN_BACK == 0 )
	{
		Math.MakeVectors( pPlayer.pev.v_angle );
		pPlayer.pev.velocity.x = pPlayer.pev.velocity.x - g_Engine.v_forward.x * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		pPlayer.pev.velocity.y = pPlayer.pev.velocity.y - g_Engine.v_forward.y * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		
		if ( pPlayer.pev.flags & FL_ONGROUND != 0 )
			pPlayer.pev.velocity.z = g_Engine.v_up.z * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * 0.59;
	}
	if ( pPlayer.pev.button & IN_MOVELEFT != 0 && pPlayer.pev.oldbuttons & IN_MOVELEFT == 0 )
	{
		Math.MakeVectors( pPlayer.pev.v_angle );
		pPlayer.pev.velocity.x = pPlayer.pev.velocity.x - g_Engine.v_right.x * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		pPlayer.pev.velocity.y = pPlayer.pev.velocity.y - g_Engine.v_right.y * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		
		if ( pPlayer.pev.flags & FL_ONGROUND != 0 )
			pPlayer.pev.velocity.z = g_Engine.v_up.z * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * 0.59;
	}
	if ( pPlayer.pev.button & IN_MOVERIGHT != 0 && pPlayer.pev.oldbuttons & IN_MOVERIGHT == 0 )
	{
		Math.MakeVectors( pPlayer.pev.v_angle );
		pPlayer.pev.velocity.x = pPlayer.pev.velocity.x + g_Engine.v_right.x * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		pPlayer.pev.velocity.y = pPlayer.pev.velocity.y + g_Engine.v_right.y * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * flJankSpeed;
		
		if ( pPlayer.pev.flags & FL_ONGROUND != 0 )
			pPlayer.pev.velocity.z = g_Engine.v_up.z * g_EngineFuncs.CVarGetFloat( "sv_maxspeed" ) * 0.59;
	}
	
	return HOOK_CONTINUE;
}

void ResetBullsquid( EHandle hMonster )
{
	if ( hMonster.IsValid() )
	{
		CBaseMonster@ pMonster = cast< CBaseMonster@ >( hMonster.GetEntity() );
		pMonster.SetPlayerAlly( true );
		pMonster.m_hEnemy = null;
	}
}

void Force1stPerson()
{
	if ( level_selection != 7 )
		return;
	
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			pPlayer.SetViewMode( ViewMode_FirstPerson );
		}
	}
	
	g_Scheduler.SetTimeout( "Force1stPerson", 0.01 );
}

void ScanSpore()
{
	if ( level_selection != 14 )
		return;
	
	CBaseEntity@ pSpore = null;
	while ( ( @pSpore = g_EntityFuncs.FindEntityByClassname( pSpore, "sporegrenade" ) ) !is null )
	{
		pSpore.pev.scale = 50;
		
		// try to prevent "velocity too high/low" spam
		if ( ( pSpore.pev.velocity.Length() * 1.50 ) < g_EngineFuncs.CVarGetFloat( "sv_maxvelocity" ) )
			pSpore.pev.velocity = pSpore.pev.velocity * 1.50;
	}
	
	g_Scheduler.SetTimeout( "ScanSpore", 0.025 );
}

void ScrambleWeapons()
{
	if ( level_selection != 10 )
		return;
	
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			CBasePlayerWeapon@ pWeapon = cast< CBasePlayerWeapon@ >( pPlayer.m_hActiveItem.GetEntity() );
			if ( pWeapon !is null )
			{
				// Temporarily suspend this if the player needs to reload a weapon
				if ( !pWeapon.m_fInReload )
				{
					if ( szOldWeapon[ pPlayer.entindex() ] != string( pWeapon.pev.classname ) ) // really...?
					{
						// Player attemping to switch weapon, randomize the selection
						array< string > szWeapons;
						
						/* BUG or FAIL? pPlayer.m_rgpPlayerItems() fails to detect all weapons
						for ( uint ui = 0; ui < MAX_ITEM_TYPES; ui++ )
						{
							CBasePlayerItem@ pItem = pPlayer.m_rgpPlayerItems( ui );
							if ( pItem !is null )
							{
								// There must be ammo for this weapon
								CBasePlayerWeapon@ pCheck = cast< CBasePlayerWeapon@ >( pItem );
								if ( pCheck !is null ) // valid weapon?
								{
									if ( pPlayer.m_rgAmmo( pCheck.m_iPrimaryAmmoType ) > 0 )
									{
										// Has ammo, add it
										szWeapons.insertLast( pItem.pev.classname );
									}
									else
									{
										// No ammo but still has some bullets left on it's magazine
										if ( pCheck.m_iClip > 0 )
										{
											// Has ammo, add it
											szWeapons.insertLast( pItem.pev.classname );
										}
									}
								}
							}
						}
						*/
						
						// Add the weapons by hand
						szWeapons.insertLast( "weapon_357" );
						szWeapons.insertLast( "weapon_m16" );
						szWeapons.insertLast( "weapon_rpg" );
						szWeapons.insertLast( "weapon_sniperrifle" );
						szWeapons.insertLast( "weapon_m249" );
						szWeapons.insertLast( "weapon_gauss" );
						szWeapons.insertLast( "weapon_pipewrench" );
						
						int iShuffleTimes = pPlayer.GetCustomKeyvalues().GetKeyvalue( "$i_shuffletimes" ).GetInteger();
						
						if ( iShuffleTimes < 10 )
						{
							// Select a random weapon
							szOldWeapon[ pPlayer.entindex() ] = szWeapons[ Math.RandomLong( 0, szWeapons.length() - 1 ) ];
							pPlayer.SelectItem( szOldWeapon[ pPlayer.entindex() ] );
							iShuffleTimes++;
						}
						else
						{
							// Force-select the gauss if we still can't grab it
							szOldWeapon[ pPlayer.entindex() ] = "weapon_gauss";
							pPlayer.SelectItem( "weapon_gauss" );
							iShuffleTimes = 0;
						}
						pPlayer.KeyValue( "$i_shuffletimes", string( iShuffleTimes ) );
					}
				}
			}
		}
	}
	
	g_Scheduler.SetTimeout( "ScrambleWeapons", 0.01 );
}

void CreatePlayerHurt( CBasePlayer@ pPlayer )
{
	CBaseEntity@ pCopy = g_EntityFuncs.FindEntityByTargetname( null, "giegue_throw_hurt" );
	
	CBaseEntity@ pHurt = g_EntityFuncs.Create( "trigger_hurt", pPlayer.pev.origin, g_vecZero, true );
	g_EntityFuncs.SetModel( pHurt, pCopy.pev.model );
	pHurt.pev.spawnflags = 8 + 64; // No clients + Affect non-moving NPCs
	pHurt.pev.targetname = "giegue_ph_" + pPlayer.entindex();
	pHurt.pev.dmg = 10000;
	g_EntityFuncs.DispatchSpawn( pHurt.edict() );
	@pHurt.pev.owner = pPlayer.edict();
	@pHurt.pev.aiment = pPlayer.edict();
	pHurt.pev.movetype = MOVETYPE_FOLLOW;
}

void LaunchPlayer( CBasePlayer@ pPlayer, CBasePlayer@ pAttacker )
{
	Math.MakeVectors( pAttacker.pev.v_angle );
	
	// To force the player off the ground
	pPlayer.pev.origin.z += 1;
	pPlayer.pev.flags &= ~FL_ONGROUND;
	
	pPlayer.pev.velocity = g_Engine.v_forward * 800 + g_Engine.v_up * 320;
	
	CBaseEntity@ pHurt = g_EntityFuncs.FindEntityByTargetname( null, "giegue_ph_" + pPlayer.entindex() );
	if ( pHurt is null )
		CreatePlayerHurt( pPlayer );
	else if ( pHurt !is null && pHurt.pev.solid == SOLID_NOT )
		g_EntityFuncs.FireTargets( "giegue_ph_" + pPlayer.entindex(), null, null, USE_ON, 0.0f, 0.0f );
	
	g_Scheduler.SetTimeout( "LaunchPostGround", 0.08, EHandle( pPlayer ), pPlayer.entindex() );
}

void LaunchPostGround( EHandle hPlayer, int playerIndex )
{
	CBaseEntity@ pHurt = g_EntityFuncs.FindEntityByTargetname( null, "giegue_ph_" + playerIndex );
	
	if ( hPlayer.IsValid() )
	{
		CBaseEntity@ pPlayer = hPlayer.GetEntity();
		if ( pPlayer.pev.flags & FL_ONGROUND != 0 )
		{
			// remember, trigger_hurt does not obey trigger mode
			if ( pHurt !is null )
			{
				pHurt.pev.solid = SOLID_NOT;
				g_EntityFuncs.SetOrigin( pHurt, pHurt.pev.origin );
			}
		}
		else
		{
			if ( pHurt !is null )
				pHurt.pev.dmgtime = g_Engine.time; // remove delay
			
			g_Scheduler.SetTimeout( "LaunchPostGround", 0.04, EHandle( pPlayer ), pPlayer.entindex() );
		}
	}
	else
	{
		if ( pHurt !is null )
			g_EntityFuncs.Remove( pHurt );
	}
}

void ScanSnarks()
{
	if ( level_selection != 10 )
		return;
	
	// unefficient for something so simple...
	CBaseEntity@ pSnark = null;
	int iNumSnarks = 0;
	while ( ( @pSnark = g_EntityFuncs.FindEntityByClassname( pSnark, "monster_snark" ) ) !is null )
	{
		/* does not work, emit manual DLIGHTs
		if ( pSnark.pev.effects & EF_BRIGHTLIGHT == 0 )
			pSnark.pev.effects |= EF_BRIGHTLIGHT;
		*/
		iNumSnarks++;
		if ( iNumSnarks > 56 )
			break; // too many!
		
		NetworkMessage Light( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		Light.WriteByte( TE_DLIGHT );
		Light.WriteCoord( pSnark.pev.origin.x );
		Light.WriteCoord( pSnark.pev.origin.y );
		Light.WriteCoord( pSnark.pev.origin.z );
		Light.WriteByte( 24 ); // radius
		Light.WriteByte( int( 160 ) ); // R
		Light.WriteByte( int( 160 ) ); // G
		Light.WriteByte( int( 160 ) ); // B
		Light.WriteByte( 1 ); // life
		Light.WriteByte( 10 ); // decay rate
		Light.End();
	}
	
	g_Scheduler.SetTimeout( "ScanSnarks", 0.1 );
}

void ScanBGarg()
{
	if ( level_selection != 7 )
		return;
	
	CBaseEntity@ pGarg = g_EntityFuncs.FindEntityByClassname( pGarg, "monster_babygarg" );
	CBaseEntity@ pBox = g_EntityFuncs.FindEntityByTargetname( null, "giegue_the_box" );
	
	if ( pGarg is null && pBox !is null )
	{
		g_EntityFuncs.FireTargets( "giegue_c7_unstuck", null, null, USE_ON, 0.0f, 0.0f );
		return;
	}
	
	g_Scheduler.SetTimeout( "ScanBGarg", 0.5 );
}

void FailC13( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	// don't false positive
	if ( level_selection != 7 )
		return;
	
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "* Wait, did you actually kill the babygarg? ... Ah fuck, I can't believe you've done this.\n" );
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "* You were supposed to lure it into the box! Try to use your head next time.\n" );
	
	CBaseEntity@ pBox = null;
	while ( ( @pBox = g_EntityFuncs.FindEntityByTargetname( pBox, "giegue_the_box" ) ) !is null )
	{
		g_EntityFuncs.Remove( pBox );
	}
	
	g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 5.0f );
}

void ScanStomp()
{
	if ( level_selection != 14 )
		return;
	
	CBaseEntity@ pStomp = g_EntityFuncs.FindEntityByClassname( null, "garg_stomp" );
	if ( pStomp !is null )
	{
		float X = pStomp.pev.origin.x;
		float Y = pStomp.pev.origin.y;
		if ( X > 4016 && X < 4176 && Y > 2512 )
		{
			CBaseEntity@ pDoor = g_EntityFuncs.FindEntityByTargetname( null, "giegue_door_wreckage" );
			if ( pDoor !is null )
			{
				g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
				return; // ONCE!
			}
		}
	}
	
	g_Scheduler.SetTimeout( "ScanStomp", 0.001 );
}

void BullsquidHugPlayer()
{
	if ( level_selection != 4 )
		return;
	
	array< CBasePlayer@ > arrPlayers;
	
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			arrPlayers.insertLast( pPlayer );
		}
	}
	
	CBaseMonster@ pBullsquid = null;
	while ( ( @pBullsquid = cast< CBaseMonster@ >( g_EntityFuncs.FindEntityByClassname( pBullsquid, "monster_bullchicken" ) ) ) !is null )
	{
		if ( !pBullsquid.IsPlayerFollowing() )
		{
			// Pick a random player
			pBullsquid.StartPlayerFollowing( arrPlayers[ Math.RandomLong( 0, arrPlayers.length() - 1 ) ], false );
		}
	}
	
	g_Scheduler.SetTimeout( "BullsquidHugPlayer", 1.0 );
}

void InfiniteNPCShotgun()
{
	if ( level_selection != 6 )
		return;
	
	CBaseMonster@ pHGrunt = null;
	while ( ( @pHGrunt = cast< CBaseMonster@ >( g_EntityFuncs.FindEntityByClassname( pHGrunt, "monster_human_grunt" ) ) ) !is null )
	{
		pHGrunt.m_cAmmoLoaded = 16;
	}
	
	g_Scheduler.SetTimeout( "InfiniteNPCShotgun", 0.5 );
}

void UpdateMonsterStack( EHandle hMonster1, EHandle hMonster2, EHandle hMonster3 )
{
	CBaseMonster@ pMonster1 = null;
	CBaseMonster@ pMonster2 = null;
	CBaseMonster@ pMonster3 = null;
	
	if ( hMonster1.IsValid() )
	{
		@pMonster1 = cast< CBaseMonster@ >( hMonster1.GetEntity() );
		Vector vecOrigin1 = pMonster1.pev.origin;
		vecOrigin1.z += pMonster1.pev.size.z;
		
		if ( pMonster1.IsAlive() )
		{
			if ( hMonster2.IsValid() )
			{
				@pMonster2 = cast< CBaseMonster@ >( hMonster2.GetEntity() );
				Vector vecOrigin2 = pMonster2.pev.origin;
				vecOrigin2.z += pMonster2.pev.size.z;
				
				if ( pMonster2.IsAlive() )
				{
					g_EntityFuncs.SetOrigin( pMonster2, vecOrigin1 );
					pMonster2.pev.velocity = g_vecZero;
					
					if ( hMonster3.IsValid() )
					{
						@pMonster3 = cast< CBaseMonster@ >( hMonster3.GetEntity() );
						
						if ( pMonster3.IsAlive() )
						{
							g_EntityFuncs.SetOrigin( pMonster3, vecOrigin2 );
							pMonster3.pev.velocity = g_vecZero;
						}
						else
						{
							pMonster2.pev.takedamage = DAMAGE_YES;
							pMonster2.pev.flags &= ~FL_GODMODE;
						}
					}
					else
					{
						pMonster2.pev.takedamage = DAMAGE_YES;
						pMonster2.pev.flags &= ~FL_GODMODE;
					}
				}
				else
				{
					pMonster1.pev.takedamage = DAMAGE_YES;
					pMonster1.pev.flags &= ~FL_GODMODE;
				}
				
				// Sven's AI constantly tries to push the monsters towards the ground if they are in the air. Forced to use super-fast think time.
				g_Scheduler.SetTimeout( "UpdateMonsterStack", 0.000001, EHandle( pMonster1 ), EHandle( pMonster2 ), EHandle( pMonster3 ) );
			}
			else
			{
				pMonster1.pev.takedamage = DAMAGE_YES;
				pMonster1.pev.flags &= ~FL_GODMODE;
			}
		}
	}
}

void LevelA0()
{
	CBaseEntity@ pMonster = null;
	
	// BUG - monster_sentries sometimes trigger their TriggerTarget twice upon death, don't rely on it!
	/*
	@pMonster = g_EntityFuncs.Create( "multi_manager", g_vecZero, g_vecZero, true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.spawnflags = 1; // multithreaded
	pMonster.KeyValue( "giegue_goal_counter", "5#1" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	*/
	// top
	@pMonster = g_EntityFuncs.Create( "monster_sentry", Vector( 3648, 1920, 404 ), g_vecZero, false );
	pMonster.pev.targetname = "giegue_bouncy_sentry";
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "pew pew pew" );
	//pMonster.KeyValue( "TriggerCondition", "4" );
	//pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.pev.movetype = MOVETYPE_BOUNCE;
	pMonster.pev.velocity = Vector( Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( 0.0, 200.0 ) );
	
	@pMonster = g_EntityFuncs.Create( "monster_sentry", Vector( 4544, 1920, 404 ), g_vecZero, false );
	pMonster.pev.targetname = "giegue_bouncy_sentry";
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "pew pew pew" );
	//pMonster.KeyValue( "TriggerCondition", "4" );
	//pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.pev.movetype = MOVETYPE_BOUNCE;
	pMonster.pev.velocity = Vector( Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( 0.0, 200.0 ) );
	
	// middle
	@pMonster = g_EntityFuncs.Create( "monster_sentry", Vector( 4384, 1920, 164 ), g_vecZero, false );
	pMonster.pev.targetname = "giegue_bouncy_sentry";
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "pew pew pew" );
	//pMonster.KeyValue( "TriggerCondition", "4" );
	//pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.pev.movetype = MOVETYPE_BOUNCE;
	pMonster.pev.velocity = Vector( Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( 0.0, 200.0 ) );
	
	@pMonster = g_EntityFuncs.Create( "monster_sentry", Vector( 3808, 2240, 164 ), g_vecZero, false );
	pMonster.pev.targetname = "giegue_bouncy_sentry";
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "pew pew pew" );
	//pMonster.KeyValue( "TriggerCondition", "4" );
	//pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.pev.movetype = MOVETYPE_BOUNCE;
	pMonster.pev.velocity = Vector( Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( 0.0, 200.0 ) );
	
	@pMonster = g_EntityFuncs.Create( "monster_sentry", Vector( 3808, 1600, 164 ), g_vecZero, false );
	pMonster.pev.targetname = "giegue_bouncy_sentry";
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "pew pew pew" );
	//pMonster.KeyValue( "TriggerCondition", "4" );
	//pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.pev.movetype = MOVETYPE_BOUNCE;
	pMonster.pev.velocity = Vector( Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( 0.0, 200.0 ) );
	
	// bottom
	@pMonster = g_EntityFuncs.Create( "monster_sentry", Vector( 4096, 1920, -204 ), g_vecZero, false );
	pMonster.pev.targetname = "giegue_bouncy_sentry";
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "pew pew pew" );
	//pMonster.KeyValue( "TriggerCondition", "4" );
	//pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.pev.movetype = MOVETYPE_BOUNCE;
	pMonster.pev.velocity = Vector( Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( -400.0, 400.0 ), Math.RandomFloat( 0.0, 200.0 ) );
}

void LevelA0Fix()
{
	if ( level_selection != 0 )
		return;
	
	CBaseEntity@ pSentry = g_EntityFuncs.FindEntityByTargetname( null, "giegue_bouncy_sentry" );
	if ( pSentry is null )
	{
		// all destroyed
		g_EntityFuncs.FireTargets( "giegue_goal_counter", null, null, USE_ON, 0.0f, 0.0f );
		return;
	}
	
	g_Scheduler.SetTimeout( "LevelA0Fix", 0.1 );
}

void LevelA2()
{
	CBaseEntity@ pMonster = null;
	
	for ( int i = 0; i < 3; i++ )
	{
		for ( int j = 0; j < 3; j++ )
		{
			@pMonster = g_EntityFuncs.Create( "monster_headcrab", Vector( 4048 + ( 48 * j ), 1872 + ( 48 * i ), 32 ), g_vecZero, true );
			pMonster.pev.targetname = "giegue_goal_button"; // for easier deletion
			pMonster.KeyValue( "is_player_ally", "1" );
			pMonster.KeyValue( "displayname", "Is this Sven Co-op 2?" );
			g_EntityFuncs.DispatchSpawn( pMonster.edict() );
		}
	}
}

void LevelA5()
{
	if ( level_selection != 5 )
		return;
	
	CBaseEntity@ pButton = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_button" );
	if ( pButton !is null ) // false positive?
	{
		pButton.pev.solid = SOLID_NOT;
		pButton.pev.movetype = MOVETYPE_NOCLIP;
		
		Vector vecDestination = pButton.GetCustomKeyvalues().GetKeyvalue( "$v_destination" ).GetVector();
		
		// Might go out of bounds if moving too fast
		if ( pButton.pev.origin.x < 3442 || pButton.pev.origin.y > 2600 || pButton.pev.origin.z > 700
		||   pButton.pev.origin.x > 4790 || pButton.pev.origin.y < 1200 || pButton.pev.origin.z < -400 )
		{
			// get in here
			g_EntityFuncs.SetOrigin( pButton, vecDestination );
			vecDestination = g_vecZero;
		}
		
		if ( vecDestination == g_vecZero || ( vecDestination - pButton.pev.origin ).Length() < 32 )
		{
			vecDestination.x = Math.RandomFloat( 3488, 4704 );
			vecDestination.y = Math.RandomFloat( 1312, 2528 );
			vecDestination.z = Math.RandomFloat( -352, 608 );
			
			Vector vecVelocity = ( vecDestination - pButton.pev.origin ) * flSpeedMultiplier;
			pButton.pev.velocity = vecVelocity;
			
			CustomKeyvalues@ pKVD = pButton.GetCustomKeyvalues();
			pKVD.SetKeyvalue( "$v_destination", vecDestination );
			flSpeedMultiplier -= 0.01;
			if ( flSpeedMultiplier < 0.01 )
				flSpeedMultiplier = 0.01;
		}
	}
	
	g_Scheduler.SetTimeout( "LevelA5", 0.000001 );
}

void LevelA7()
{
	// tilt first
	for ( int i = 1; i <= g_Engine.maxClients; i++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			TiltScreen( pPlayer );
		}
	}
	
	CBaseEntity@ pMonster = null;
	
	// top
	@pMonster = g_EntityFuncs.Create( "monster_alien_slave", Vector( 3648, 1920, 404 ), Vector( 0, -90, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 300.0;
	pMonster.KeyValue( "is_not_revivable", "1" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_alien_slave", Vector( 4544, 1920, 404 ), Vector( 0, -90, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 300.0;
	pMonster.KeyValue( "is_not_revivable", "1" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_alien_slave", Vector( 4100, 1920, 404 ), Vector( 0, -90, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 300.0;
	pMonster.KeyValue( "is_not_revivable", "1" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	// middle
	@pMonster = g_EntityFuncs.Create( "monster_houndeye", Vector( 4640, 1600, 36 ), Vector( 0, -90, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_houndeye", Vector( 3806, 1776, 36 ), Vector( 0, -30, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_houndeye", Vector( 4380, 2090, 36 ), Vector( 0, -160, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_houndeye", Vector( 4110, 2430, 36 ), Vector( 0, -160, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	// bottom
	@pMonster = g_EntityFuncs.Create( "monster_zombie_soldier", Vector( 4096, 1920, -204 ), Vector( 0, 0, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 100.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie_soldier", Vector( 4096, 1478, -332 ), Vector( 0, 90, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 100.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie_soldier", Vector( 4096, 2400, -332 ), Vector( 0, -90, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 100.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie_soldier", Vector( 3650, 1920, -332 ), Vector( 0, 0, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 100.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie_soldier", Vector( 4540, 1920, -332 ), Vector( 0, 180, Math.RandomLong( 0, 1 ) == 0 ? 45 : -45 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 100.0;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
}

void LevelA8()
{
	CBaseEntity@ pMonster = null;
	
	for ( int i = 0; i < 9; i++ )
	{
		for ( int j = 0; j < 9; j++ )
		{
			// full 81 stukabats should be left to the RNG
			if ( Math.RandomLong( 0, 1 ) == 0 )
			{
				@pMonster = g_EntityFuncs.Create( "monster_stukabat", Vector( 3520 + ( 128 * j ), 2496 - ( 128 * i ), 544 ), Vector( 0, -90, 0 ), false );
				pMonster.pev.targetname = "giegue_goal_button";
				pMonster.pev.health = pMonster.pev.max_health = 100.0;
				pMonster.KeyValue( "displayname", "ha ha im so cool you cant hurt me" );
				pMonster.KeyValue( "TriggerCondition", "2" );
				pMonster.KeyValue( "TriggerTarget", "giegue_stukabat_hurt" );
			}
		}
	}
}

void LevelA9()
{
	if ( level_selection != 9 )
		return;
	
	for ( int iPlayerIndex = 1; iPlayerIndex <= g_Engine.maxClients; iPlayerIndex++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayerIndex );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			if ( pPlayer.pev.gravity != -1.0 )
			{
				float X = pPlayer.pev.origin.x;
				float Y = pPlayer.pev.origin.y;
				if ( X < 3880 || X > 4310 || Y > 1550 )
				{
					pPlayer.pev.origin.z += 2.0;
					pPlayer.pev.gravity = -1.0;
					pPlayer.pev.velocity.z = 2.0;
				}
			}
		}
	}
	
	g_Scheduler.SetTimeout( "LevelA9", 0.01 );
}

void LevelA10()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_gargantua", Vector( 4100, 2400, 36 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.health = pMonster.pev.max_health = 555.0;
	pMonster.pev.scale = 0.5; //g_EntityFuncs.SetSize( pMonster.pev, Vector( -16, -16, 0 ), Vector( 16, 16, 32 ) );
	pMonster.KeyValue( "displayname", "gimme a hug" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_headcrab", Vector( 4100, 1632, 36 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.health = pMonster.pev.max_health = 444.0;
	pMonster.pev.scale = 1.5;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_pitdrone", Vector( 4100, 1922, -204 ), Vector( 0, Math.RandomFloat( -180, 180 ), 0 ), false );
	pMonster.pev.health = pMonster.pev.max_health = 444.0;
	pMonster.pev.scale = 0.5;
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
}

void LevelA11()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "multi_manager", g_vecZero, g_vecZero, true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.spawnflags = 1; // multithreaded
	pMonster.KeyValue( "giegue_goal_counter", "5#1" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	// top
	@pMonster = g_EntityFuncs.Create( "monster_sentry_mk2", Vector( 3648, 1920, 404 ), g_vecZero, true );
	pMonster.pev.spawnflags = 128;
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "Barnacle?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.KeyValue( "weapon", "7" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_sentry_mk2", Vector( 4544, 1920, 404 ), g_vecZero, true );
	pMonster.pev.spawnflags = 128;
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "Barnacle?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.KeyValue( "weapon", "7" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	// middle
	@pMonster = g_EntityFuncs.Create( "monster_sentry_mk2", Vector( 4384, 1920, 164 ), g_vecZero, true );
	pMonster.pev.spawnflags = 128;
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "Barnacle?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.KeyValue( "weapon", "7" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_sentry_mk2", Vector( 3808, 2240, 164 ), g_vecZero, true );
	pMonster.pev.spawnflags = 128;
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "Barnacle?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.KeyValue( "weapon", "7" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_sentry_mk2", Vector( 3808, 1600, 164 ), g_vecZero, true );
	pMonster.pev.spawnflags = 128;
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "Barnacle?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.KeyValue( "weapon", "7" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	// bottom
	@pMonster = g_EntityFuncs.Create( "monster_sentry_mk2", Vector( 4096, 1920, -204 ), g_vecZero, true );
	pMonster.pev.spawnflags = 128;
	pMonster.pev.health = pMonster.pev.max_health = 123.0;
	pMonster.KeyValue( "displayname", "Barnacle?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_button" );
	pMonster.KeyValue( "weapon", "7" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
}

void LevelA12()
{
	CBaseEntity@ pMonster = null;
	
	// the full copypasta is too long to fit in the displayname so it's going to be TOO short
	string szCopypasta = "wtf did u just fucking say about me, bitch? ill have u know i have\n";
	szCopypasta += "have over 300 kills. im trained and im the top in the entire world\n";
	szCopypasta += "u are nothing to me. ill wipe u the fuck out, mark my fucking words\n";
	szCopypasta += "u think you can get away with that shit? ill wipe out ur pathetic life\n";
	szCopypasta += "i can kill u in over 700 ways. i have access to the entire arsenal of\n";
	szCopypasta += "ragemap2023 and ill use it to wipe ur ass, u little shit. ur fucking dead";
	
	@pMonster = g_EntityFuncs.Create( "monster_pitdrone", Vector( 4384, 1920, 164 ), Vector( 0, 270, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.pev.frags = 300 + Math.RandomLong( 1, 9 ); // y e s
	pMonster.KeyValue( "displayname", szCopypasta );
	
	@pMonster = g_EntityFuncs.Create( "monster_pitdrone", Vector( 3808, 2240, 164 ), Vector( 0, 270, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.KeyValue( "displayname", "You only stopped to look at it because of how it looked on your screen, admit it. :C" );
	
	@pMonster = g_EntityFuncs.Create( "monster_pitdrone", Vector( 3808, 1600, 164 ), Vector( 0, 270, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.KeyValue( "displayname", "Please don't mind the copypasta. I did it as a joke to my friends." );
}

// i dare not open JACK and corrupt the RMF file just for a single keyvalue in a trigger_createentity
// proton opens svencraft but crashes as soon as an entity is selected.
void LevelA12Fix()
{
	CBaseEntity@ pButton = null;
	while ( ( @pButton = g_EntityFuncs.FindEntityByTargetname( pButton, "giegue_goal_button" ) ) !is null )
	{
		// the monsters have the same targetname, check class
		if ( pButton.pev.classname == "func_button" )
		{
			// Don't spray the buttons with blood
			pButton.pev.effects |= EF_NODECALS;
		}
	}
}

void LevelA13()
{
	CBaseEntity@ pDoor = null;
	while ( ( @pDoor = g_EntityFuncs.FindEntityByTargetname( pDoor, "giegue_door_wreckage" ) ) !is null )
	{
		pDoor.pev.spawnflags |= 32; // Show HUD Info
		pDoor.pev.health = 255 * g_PlayerFuncs.GetNumPlayers();
		pDoor.KeyValue( "displayname", "so, ragemap is 16 years old...\ncan i suggest a flashback of previous ragemap editions for 2024?\ndunno, maybe the next theme is time travel" );
	}
	
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_shocktrooper", Vector( 3800, 2280, 404 ), Vector( 0, -45, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.pev.spawnflags |= 1024; // No Shockroach
	pMonster.KeyValue( "displayname", "trigger_hurt" );
	
	@pMonster = g_EntityFuncs.Create( "monster_shocktrooper", Vector( 4444, 2444, 404 ), Vector( 0, -105, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.pev.spawnflags |= 1024; // No Shockroach
	pMonster.KeyValue( "displayname", "trigger_hurt" );
	
	@pMonster = g_EntityFuncs.Create( "monster_shocktrooper", Vector( 3800, 1410, 404 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.pev.spawnflags |= 1024; // No Shockroach
	pMonster.KeyValue( "displayname", "trigger_hurt" );
	
	@pMonster = g_EntityFuncs.Create( "monster_shocktrooper", Vector( 4444, 1524, 404 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.pev.spawnflags |= 1024; // No Shockroach
	pMonster.KeyValue( "displayname", "trigger_hurt" );
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 3870, 1920, -332 ), Vector( 0, 180, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.KeyValue( "displayname", "it is bullsquid or bullchicken?" );
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4300, 1920, -332 ), Vector( 0, 0, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.KeyValue( "displayname", "it is bullsquid or bullchicken?" );
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4100, 1676, -332 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.KeyValue( "displayname", "it is bullsquid or bullchicken?" );
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4100, 2136, -332 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 234.0;
	pMonster.KeyValue( "displayname", "it is bullsquid or bullchicken?" );
}

void LevelA14()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4130, 1920, 36 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "i cut my finger with the fucking chair :C" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 3600, 2190, 36 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "Impossible is not in my dictionary! MHUAHAHA!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4636, 2236, 36 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "can i edit host_framerate? :3" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4095, 1605, 532 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "I'm not a mapper. I SUCK BALLS AT IT" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4360, 1420, -332 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "canyondoom4 lover\nDear Tu3sday's Avenger: Can we have the RMF of your map? :)" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 3830, 1420, -332 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "look how they massacred my svengine boi :C" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 3830, 2400, -332 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "UNRELEASED SVEN CO-OP 64 FOOTAGE" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4370, 2400, -332 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "how many zombies do you want in your section?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4096, 1916, 404 ), Vector( 0, 90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "ooOO very menacing monster" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
}

void InitSectionB()
{
	g_EntityFuncs.FireTargets( "giegue_bgm1", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_spawn2", null, null, USE_OFF, 0.0f, 0.0f );
	
	if ( Math.RandomLong( 1, 1 ) == 1 ) // temp
	{
		level = lvlAreaB;
		level_selection = -1;
		HUDDisplay( null );
		
		g_EntityFuncs.FireTargets( "giegue_spawn3", null, null, USE_ON, 0.0f, 0.0f );
		g_EntityFuncs.FireTargets( "giegue_bgm2a", null, null, USE_ON, 0.0f, 0.0f );
		g_EntityFuncs.FireTargets( "giegue_wide_maxspeed", null, null, USE_TOGGLE, 0.0f, 0.0f );
		
		for ( int iPlayerIndex = 1; iPlayerIndex <= g_Engine.maxClients; iPlayerIndex++ )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayerIndex );
			if ( pPlayer !is null && pPlayer.IsConnected() )
			{
				g_PlayerFuncs.ConcussionEffect( pPlayer, 0.0, 0.0, 0.0 );
				
				CBaseEntity@ pDummy = g_EntityFuncs.Create( "info_target", pPlayer.pev.origin, g_vecZero, false );
				g_EntityFuncs.SetModel( pDummy, "models/error.mdl" );
				pDummy.pev.targetname = "giegue_b2a_d" + pPlayer.entindex();
				pDummy.pev.renderfx = 18;
				pDummy.pev.rendermode = 4;
				@pDummy.pev.aiment = pPlayer.edict();
				pDummy.pev.movetype = MOVETYPE_FOLLOW;
				
				CBaseMonster@ pModel = cast< CBaseMonster@ >( g_EntityFuncs.Create( "monster_generic", pPlayer.pev.origin, g_vecZero, true ) );
				g_EntityFuncs.SetModel( pModel, "models/player.mdl" );
				g_EntityFuncs.DispatchSpawn( pModel.edict() );
				pModel.pev.targetname = "giegue_b2a_m" + pPlayer.entindex();
				@pModel.pev.owner = pPlayer.edict();
				@pModel.pev.aiment = pDummy.edict();
				pModel.pev.movetype = MOVETYPE_FOLLOW;
				pModel.pev.renderfx = 18;
				pModel.pev.nextthink = -1;
				
				CBaseEntity@ pCamera = g_EntityFuncs.Create( "trigger_camera", pPlayer.pev.origin, g_vecZero, true );
				//pCamera.pev.target = "giegue_b2a_d" + pPlayer.entindex();
				pCamera.pev.targetname = "giegue_b2a_c" + pPlayer.entindex();
				pCamera.pev.spawnflags = 530; // Follow Player + Force View + Ignore Hold Time
				pCamera.KeyValue( "hud_health", "1" );
				pCamera.KeyValue( "hud_flashlight", "1" );
				pCamera.KeyValue( "hud_weapons", "1" );
				g_EntityFuncs.DispatchSpawn( pCamera.edict() );
				g_EntityFuncs.FireTargets( "giegue_b2a_c" + pPlayer.entindex(), pPlayer, pPlayer, USE_ON, 0.0f, 0.01f );
				
				pPlayer.pev.rendermode = 4;
			}
		}
		g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @WideModelUpdate );
	}
	g_PlayerFuncs.RespawnAllPlayers();
}

HookReturnCode WideModelUpdate( CBasePlayer@ pPlayer, uint& out dummy )
{
	// this hook will be removed as soon as the section ends
	CBaseMonster@ pModel = cast< CBaseMonster@ >( g_EntityFuncs.FindEntityByTargetname( null, "giegue_b2a_m" + pPlayer.entindex() ) );
	if ( pModel !is null )
	{
		if ( pPlayer.pev.flags & FL_ONGROUND == 0 )
		{
			if ( pModel.pev.sequence != 8 )
			{
				pModel.pev.sequence = 8;
				pModel.pev.frame = 0;
			}
		}
		else
			pModel.pev.sequence = pPlayer.pev.gaitsequence;
		
		switch ( pModel.pev.sequence )
		{
			case 3: pModel.pev.frame += 2.50; break; // run
			case 4: pModel.pev.frame += 1.50; break; // walk
			case 8: pModel.pev.frame += 0.33; break; // jump
			default: pModel.pev.frame += 0.75;
		}
		
		if ( pModel.pev.frame >= 256 )
			pModel.pev.frame = 0;
	}
	
	CBaseEntity@ pCamera = g_EntityFuncs.FindEntityByTargetname( null, "giegue_b2a_c" + pPlayer.entindex() );
	if ( pCamera !is null )
	{
		Math.MakeVectors( pPlayer.pev.v_angle );
		Vector newOrigin = pPlayer.pev.origin + g_Engine.v_forward * 128;
		g_EntityFuncs.SetOrigin( pCamera, newOrigin );
	}
	
	return HOOK_CONTINUE;
}

void InitSectionC( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
	CBaseEntity@ pDelete = null;
	for ( int iPlayerIndex = 1; iPlayerIndex <= g_Engine.maxClients; iPlayerIndex++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayerIndex );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			g_EntityFuncs.FireTargets( "giegue_b2a_c" + pPlayer.entindex(), null, null, USE_OFF, 0.0f, 0.0f );
			@pDelete = g_EntityFuncs.FindEntityByTargetname( null, "giegue_b2a_c" + pPlayer.entindex() ); g_EntityFuncs.Remove( pDelete );
			@pDelete = g_EntityFuncs.FindEntityByTargetname( null, "giegue_b2a_d" + pPlayer.entindex() ); g_EntityFuncs.Remove( pDelete );
			@pDelete = g_EntityFuncs.FindEntityByTargetname( null, "giegue_b2a_m" + pPlayer.entindex() ); g_EntityFuncs.Remove( pDelete );
			pPlayer.pev.rendermode = 0;
		}
	}
	
	g_EntityFuncs.FireTargets( "giegue_bgm2a", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_bgm2b", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_spawn3", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_spawn4", null, null, USE_OFF, 0.0f, 0.0f );
	
	g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink );
	
	g_EntityFuncs.FireTargets( "giegue_spawn5", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_bgm3", null, null, USE_ON, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_cvar_set", null, null, USE_TOGGLE, 0.0f, 0.0f );
	
	g_PlayerFuncs.RespawnAllPlayers();
	
	level = lvlAreaC;
	HUDDisplay( null );
	SpawnHelper( 20, 10 );
	
	CBaseEntity@ pCounter = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_counter" );
	pCounter.pev.health = 3;
	g_EntityFuncs.FireTargets( "giegue_button1_ceC", null, null, USE_TOGGLE, 0.0f, 0.0f );
}

void LevelC0()
{
	CBaseEntity@ pMonster = null;
	
	for ( int i = 0; i < 9; i++ )
	{
		@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4318, 2346 - ( 64 * i ), 818 ), Vector( 0, -90, 0 ), false );
		pMonster.pev.targetname = "giegue_goal_button";
		pMonster.pev.health = pMonster.pev.max_health = 1000.0;
		pMonster.KeyValue( "displayname", "i copy" );
		pMonster.KeyValue( "TriggerCondition", "4" );
		pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
		
		@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 3884, 2346 - ( 64 * i ), 818 ), Vector( 0, -90, 0 ), false );
		pMonster.pev.targetname = "giegue_goal_button";
		pMonster.pev.health = pMonster.pev.max_health = 1000.0;
		pMonster.KeyValue( "displayname", "i paste" );
		pMonster.KeyValue( "TriggerCondition", "4" );
		pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	}
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4100, 2208, 818 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 1000.0;
	pMonster.KeyValue( "displayname", "*insert lame javascript joke*" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4192, 1820, 1138 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 1000.0;
	pMonster.KeyValue( "displayname", "does anyone remember that barnacle flight map?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4000, 1828, 1138 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 1000.0;
	pMonster.KeyValue( "displayname", "legends say i get better while drunk. i call bullshit" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 3942, 1820, 1138 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 1000.0;
	pMonster.KeyValue( "displayname", "DON'T DO SCRIPTING AT 3 AM PLEASE JUST NO." );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	
	@pMonster = g_EntityFuncs.Create( "monster_zombie", Vector( 4000, 2016, 1138 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 1000.0;
	pMonster.KeyValue( "displayname", "why do you keep reading these names?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
}

void LevelC3()
{
	CBaseEntity@ pMonster1 = null;
	CBaseEntity@ pMonster2 = null;
	CBaseEntity@ pMonster3 = null;
	
	/* STACK 1 */
	@pMonster1 = g_EntityFuncs.Create( "monster_houndeye", Vector( 3712, 1920, 818 ), Vector( 0, -55, 0 ), true );
	pMonster1.pev.targetname = "giegue_goal_button";
	pMonster1.pev.health = pMonster1.pev.max_health = 375.0;
	pMonster1.KeyValue( "classify", "7" );
	pMonster1.KeyValue( "TriggerCondition", "4" );
	pMonster1.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pMonster1.KeyValue( "displayname", "Who uses do-while loops...?" );
	g_EntityFuncs.DispatchSpawn( pMonster1.edict() );
	pMonster1.pev.takedamage = DAMAGE_NO;
	pMonster1.pev.flags |= FL_GODMODE;
	
	@pMonster2 = g_EntityFuncs.Create( "monster_pitdrone", Vector( 3712, 1920, 818 ), Vector( 0, -55, 0 ), true );
	pMonster2.pev.targetname = "giegue_goal_button";
	pMonster2.pev.health = pMonster2.pev.max_health = 250.0;
	pMonster2.KeyValue( "classify", "7" );
	pMonster2.KeyValue( "displayname", "wen open source sc?" );
	g_EntityFuncs.DispatchSpawn( pMonster2.edict() );
	@pMonster2.pev.owner = pMonster1.edict();
	pMonster2.pev.takedamage = DAMAGE_NO;
	pMonster2.pev.flags |= FL_GODMODE;
	
	@pMonster3 = g_EntityFuncs.Create( "monster_alien_slave", Vector( 3712, 1920, 818 ), Vector( 0, -55, 0 ), true );
	pMonster3.pev.targetname = "giegue_goal_button";
	pMonster3.pev.health = pMonster3.pev.max_health = 125.0;
	pMonster3.KeyValue( "classify", "7" );
	pMonster3.KeyValue( "displayname", "This is a bastardized hack" );
	g_EntityFuncs.DispatchSpawn( pMonster3.edict() );
	@pMonster3.pev.owner = pMonster2.edict();
	
	g_Scheduler.SetTimeout( "UpdateMonsterStack", 0.25, EHandle( pMonster1 ), EHandle( pMonster2 ), EHandle( pMonster3 ) );
	
	/* STACK 2 */
	@pMonster1 = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4482, 1920, 818 ), Vector( 0, -125, 0 ), true );
	pMonster1.pev.targetname = "giegue_goal_button";
	pMonster1.pev.health = pMonster1.pev.max_health = 375.0;
	pMonster1.KeyValue( "classify", "7" );
	pMonster1.KeyValue( "TriggerCondition", "4" );
	pMonster1.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pMonster1.KeyValue( "displayname", "WHY ARE YOU RUNNING?" );
	g_EntityFuncs.DispatchSpawn( pMonster1.edict() );
	pMonster1.pev.takedamage = DAMAGE_NO;
	pMonster1.pev.flags |= FL_GODMODE;
	
	@pMonster2 = g_EntityFuncs.Create( "monster_shocktrooper", Vector( 4482, 1920, 818 ), Vector( 0, -125, 0 ), true );
	pMonster2.pev.spawnflags = 1024; // No Shockroach
	pMonster2.pev.targetname = "giegue_goal_button";
	pMonster2.pev.health = pMonster2.pev.max_health = 250.0;
	pMonster2.KeyValue( "classify", "7" );
	pMonster2.KeyValue( "displayname", "everyone created fantastic sections APPRECIATE THE MAPPERS" );
	g_EntityFuncs.DispatchSpawn( pMonster2.edict() );
	@pMonster2.pev.owner = pMonster1.edict();
	pMonster2.pev.takedamage = DAMAGE_NO;
	pMonster2.pev.flags |= FL_GODMODE;
	
	@pMonster3 = g_EntityFuncs.Create( "monster_zombie", Vector( 4482, 1920, 818 ), Vector( 0, -125, 0 ), true );
	pMonster3.pev.targetname = "giegue_goal_button";
	pMonster3.pev.health = pMonster3.pev.max_health = 125.0;
	pMonster3.KeyValue( "classify", "7" );
	pMonster3.KeyValue( "displayname", "i studied the wrong stack :C" );
	g_EntityFuncs.DispatchSpawn( pMonster3.edict() );
	@pMonster3.pev.owner = pMonster2.edict();
	
	g_Scheduler.SetTimeout( "UpdateMonsterStack", 0.25, EHandle( pMonster1 ), EHandle( pMonster2 ), EHandle( pMonster3 ) );
	
	/* STACK 3 */
	@pMonster1 = g_EntityFuncs.Create( "monster_headcrab", Vector( 4100, 2218, 818 ), Vector( 0, -90, 0 ), true );
	pMonster1.pev.targetname = "giegue_goal_button";
	pMonster1.pev.health = pMonster1.pev.max_health = 375.0;
	pMonster1.KeyValue( "classify", "7" );
	pMonster1.KeyValue( "TriggerCondition", "4" );
	pMonster1.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pMonster1.KeyValue( "displayname", "lmao" );
	g_EntityFuncs.DispatchSpawn( pMonster1.edict() );
	pMonster1.pev.takedamage = DAMAGE_NO;
	pMonster1.pev.flags |= FL_GODMODE;
	
	@pMonster2 = g_EntityFuncs.Create( "monster_gonome", Vector( 4100, 2218, 818 ), Vector( 0, -90, 0 ), true );
	pMonster2.pev.targetname = "giegue_goal_button";
	pMonster2.pev.health = pMonster2.pev.max_health = 250.0;
	pMonster2.KeyValue( "classify", "7" );
	pMonster2.KeyValue( "displayname", "Jump n' Slash, baby!" );
	g_EntityFuncs.DispatchSpawn( pMonster2.edict() );
	@pMonster2.pev.owner = pMonster1.edict();
	pMonster2.pev.takedamage = DAMAGE_NO;
	pMonster2.pev.flags |= FL_GODMODE;
	
	@pMonster3 = g_EntityFuncs.Create( "monster_alien_controller", Vector( 4100, 2218, 818 ), Vector( 0, -90, 0 ), true );
	pMonster3.pev.targetname = "giegue_goal_button";
	pMonster3.pev.health = pMonster3.pev.max_health = 125.0;
	pMonster3.KeyValue( "classify", "7" );
	pMonster3.KeyValue( "displayname", "irrelevant monster" );
	g_EntityFuncs.DispatchSpawn( pMonster3.edict() );
	@pMonster3.pev.owner = pMonster2.edict();
	
	g_Scheduler.SetTimeout( "UpdateMonsterStack", 0.25, EHandle( pMonster1 ), EHandle( pMonster2 ), EHandle( pMonster3 ) );
}

void LevelC4()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 3940, 2160, 820 ), Vector( 0, -90, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "please let me throw you stand above me :3\npls pls pls pls pls pls pls" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	pMonster.pev.flags |= FL_NOTARGET;
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4260, 2160, 820 ), Vector( 0, -90, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "please let me throw you stand above me :3\npls pls pls pls pls pls pls" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	pMonster.pev.flags |= FL_NOTARGET;
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4100, 2080, 820 ), Vector( 0, -90, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "please let me throw you stand above me :3\npls pls pls pls pls pls pls" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	pMonster.pev.flags |= FL_NOTARGET;
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 4300, 1540, 820 ), Vector( 0, 180, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "please let me throw you stand above me :3\npls pls pls pls pls pls pls" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	pMonster.pev.flags |= FL_NOTARGET;
	
	@pMonster = g_EntityFuncs.Create( "monster_bullchicken", Vector( 3880, 1540, 820 ), Vector( 0, 0, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "please let me throw you stand above me :3\npls pls pls pls pls pls pls" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	pMonster.pev.flags |= FL_NOTARGET;
}

void LevelC5()
{
	CBaseEntity@ pCrab = null;
	
	@pCrab = g_EntityFuncs.Create( "monster_headcrab", Vector( 3952, 2206, 818 ), Vector( 0, -65, 0 ), false );
	pCrab.pev.targetname = "giegue_goal_button";
	pCrab.KeyValue( "TriggerCondition", "4" );
	pCrab.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pCrab.KeyValue( "classify", "7" );
	pCrab.KeyValue( "displayname", "Poppo!" );
	pCrab.pev.health = pCrab.pev.max_health = 170; // level spawned headcrab
	pCrab.pev.scale = 1.75;
	
	@pCrab = g_EntityFuncs.Create( "monster_headcrab", Vector( 4276, 2304, 818 ), Vector( 0, -65, 0 ), false );
	pCrab.pev.targetname = "giegue_goal_button";
	pCrab.KeyValue( "TriggerCondition", "4" );
	pCrab.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pCrab.KeyValue( "classify", "7" );
	pCrab.KeyValue( "displayname", "Poppo!" );
	pCrab.pev.health = pCrab.pev.max_health = 170;
	pCrab.pev.scale = 1.75;
	
	@pCrab = g_EntityFuncs.Create( "monster_headcrab", Vector( 4210, 2090, 818 ), Vector( 0, -105, 0 ), false );
	pCrab.pev.targetname = "giegue_goal_button";
	pCrab.KeyValue( "TriggerCondition", "4" );
	pCrab.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pCrab.KeyValue( "classify", "7" );
	pCrab.KeyValue( "displayname", "Poppo!" );
	pCrab.pev.health = pCrab.pev.max_health = 170;
	pCrab.pev.scale = 1.75;
	
	@pCrab = g_EntityFuncs.Create( "monster_headcrab", Vector( 4010, 2090, 818 ), Vector( 0, -105, 0 ), false );
	pCrab.pev.targetname = "giegue_goal_button";
	pCrab.KeyValue( "TriggerCondition", "4" );
	pCrab.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	pCrab.KeyValue( "classify", "7" );
	pCrab.KeyValue( "displayname", "Poppo!" );
	pCrab.pev.health = pCrab.pev.max_health = 170;
	pCrab.pev.scale = 1.75;
}

void LevelC6()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_human_grunt", Vector( 3712, 2304, 1042 ), Vector( 0, -65, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.pev.weapons = 8; // Shotgun
	pMonster.KeyValue( "displayname", "BAD SHOTGUNNER!!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_human_grunt", Vector( 4482, 2304, 1042 ), Vector( 0, -115, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "BAD SHOTGUNNER!!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_human_grunt", Vector( 4482, 1920, 978 ), Vector( 0, -125, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "BAD SHOTGUNNER!!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_human_grunt", Vector( 3712, 1920, 978 ), Vector( 0, -55, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "BAD SHOTGUNNER!!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_human_grunt", Vector( 4094, 1924, 1138 ), Vector( 0, -90, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "BAD SHOTGUNNER!!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_human_grunt", Vector( 4094, 1520, 1186 ), Vector( 0, 90, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 200.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "BAD SHOTGUNNER!!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
}

void LevelC7()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_babygarg", Vector( 4100, 2080, 836 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "Where's my box?" );
	pMonster.KeyValue( "TriggerCondition", "2" );
	pMonster.KeyValue( "TriggerTarget", "giegue_bgarg_hurt" );
	pMonster.pev.max_health = 1;
	pMonster.pev.health = 12345;
}

void LevelC8()
{
	if ( level_selection != 8 )
		return;
	
	CBaseEntity@ pButton = g_EntityFuncs.FindEntityByTargetname( null, "giegue_goal_button" );
	if ( pButton !is null )
	{
		// already pressed
		if ( pButton.pev.frame == 0 )
		{
			pButton.pev.solid = SOLID_NOT;
			pButton.pev.movetype = MOVETYPE_NOCLIP;
			
			Vector vecSelfOrigin = pButton.pev.origin;
			
			for ( int iPlayerIndex = 1; iPlayerIndex <= g_Engine.maxClients; iPlayerIndex++ )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayerIndex );
				if ( pPlayer !is null && pPlayer.IsConnected() )
				{
					Vector vecPlayerOrigin = pPlayer.pev.origin;
					
					if ( ( vecPlayerOrigin - vecSelfOrigin ).Length() < 128 )
					{
						Vector vecVelocity = pPlayer.pev.velocity * 2 * flSpeedMultiplier;
						pButton.pev.velocity = vecVelocity;
						
						flSpeedMultiplier -= 0.002;
						if ( flSpeedMultiplier < 0.001 )
							flSpeedMultiplier = 0.001;
					}
				}
			}
			
			float X = vecSelfOrigin.x;
			float Y = vecSelfOrigin.y;
			float Z = vecSelfOrigin.z;
			if ( X < 3472 || X > 4720 || Y < 1296 || Y > 2544 || Z < 818 || Z > 900 )
			{
				// just an effect
				CBaseMonster@ pGib = cast< CBaseMonster@ >( g_EntityFuncs.Create( "monster_headcrab", vecSelfOrigin, g_vecZero, true ) );
				pGib.KeyValue( "bloodcolor", "1" );
				g_EntityFuncs.DispatchSpawn( pGib.edict() );
				pGib.GibMonster();
				
				g_EntityFuncs.Remove( pButton );
				
				CBaseEntity@ pCreate = g_EntityFuncs.FindEntityByTargetname( null, "giegue_button_c8_ce" );
				
				CBasePlayer@ pPlayer = null;
				while ( ( @pPlayer = cast< CBasePlayer@ >( g_EntityFuncs.FindEntityInSphere( pPlayer, pCreate.pev.origin, 128.0, "player", "classname" ) ) ) !is null )
				{
					pPlayer.m_iDeaths++;
					pPlayer.GibMonster();
					
					deaths++;
					g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string( pPlayer.pev.netname ) + " was telefragged by a func_button.\n" );
					
					g_PlayerFuncs.RespawnPlayer( pPlayer, true, true );
				}
				
				g_EntityFuncs.FireTargets( "giegue_button_c8_ce", null, null, USE_TOGGLE, 0.0f, 0.01f );
			}
		}
	}
	
	g_Scheduler.SetTimeout( "LevelC8", 0.000001 );
}

void LevelC11()
{
	if ( level_selection != 11 )
		return;
	
	for ( int iPlayerIndex = 1; iPlayerIndex <= g_Engine.maxClients; iPlayerIndex++ )
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayerIndex );
		if ( pPlayer !is null && pPlayer.IsConnected() )
		{
			if ( pPlayer.pev.gravity != 0.7 )
			{
				pPlayer.pev.gravity = 0.7;
			}
		}
	}
	
	g_Scheduler.SetTimeout( "LevelC11", 0.5 );
}

void LevelC12()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_robogrunt", Vector( 3712, 2304, 1042 ), Vector( 0, -65, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 256.0;
	pMonster.pev.weapons = 8; // Shotgun
	pMonster.KeyValue( "displayname", "how many minutes did you spend (or waste) reading all these names?" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_robogrunt", Vector( 4482, 2304, 1042 ), Vector( 0, -115, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 256.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "NOT THE SATCHELS!" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_robogrunt", Vector( 3712, 1534, 1042 ), Vector( 0, 0, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 256.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "TURN DOWN YOUR VOLUME. I'm not responsible for any ear damage." );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_robogrunt", Vector( 4482, 1534, 1042 ), Vector( 0, 180, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.pev.health = pMonster.pev.max_health = 256.0;
	pMonster.pev.weapons = 8;
	pMonster.KeyValue( "displayname", "now this is just plain silly... :C" );
	pMonster.KeyValue( "TriggerCondition", "4" );
	pMonster.KeyValue( "TriggerTarget", "giegue_goal_counter" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
}

void LevelC13()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_alien_voltigore", Vector( 3712, 1920, 836 ), Vector( 0, -55, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "old meme that should stay dead" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_alien_voltigore", Vector( 4478, 1920, 836 ), Vector( 0, -125, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "func_vehicle but it's a monster_alien_voltigore" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
	
	@pMonster = g_EntityFuncs.Create( "monster_alien_voltigore", Vector( 4096, 1700, 836 ), Vector( 0, -180, 0 ), true );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "is_player_ally", "1" );
	pMonster.KeyValue( "displayname", "okay hear me out\nwhat if, just what if\nnatural selection\nbut with xen/race-x monsters?" );
	g_EntityFuncs.DispatchSpawn( pMonster.edict() );
}

void LevelC14()
{
	CBaseEntity@ pMonster = null;
	
	@pMonster = g_EntityFuncs.Create( "monster_gargantua", Vector( 4100, 2208, 836 ), Vector( 0, -90, 0 ), false );
	pMonster.pev.targetname = "giegue_goal_button";
	pMonster.KeyValue( "displayname", "me angy me burn" );
	
	CBaseEntity@ pDoor = null;
	while ( ( @pDoor = g_EntityFuncs.FindEntityByTargetname( pDoor, "giegue_door_wreckage" ) ) !is null )
	{
		pDoor.pev.takedamage = DAMAGE_YES;
		pDoor.pev.spawnflags = 32 + 64; // Show HUD Info + Inmune to Clients
		pDoor.pev.health = 50;
		pDoor.KeyValue( "displayname", "JUST LIKE 2019 THIS MAPPER SUCKS" );
	}
}

void InitSectionD()
{
	g_EntityFuncs.FireTargets( "giegue_bgm3", null, null, USE_OFF, 0.0f, 0.0f );
	g_EntityFuncs.FireTargets( "giegue_spawn5", null, null, USE_OFF, 0.0f, 0.0f );
	
	level = 37;
	level_selection = -1;
	HUDDisplay( null );
	
	g_EntityFuncs.FireTargets( "giegue_spawn6", null, null, USE_ON, 0.0f, 0.0f );
	g_PlayerFuncs.RespawnAllPlayers();
}

void SpawnHelper( int level, int time )
{
	CBaseEntity@ pEntity = g_EntityFuncs.Create( "multi_manager", g_vecZero, g_vecZero, true );
	pEntity.pev.targetname = "giegue_hint_timer";
	pEntity.KeyValue( "giegue_set_hint" + level, "0" );
	pEntity.KeyValue( "giegue_hint", string( time ) );
	if ( level == 23 ) pEntity.KeyValue( "giegue_set_hint23_s", string( time ) );
	g_EntityFuncs.DispatchSpawn( pEntity.edict() );
	g_EntityFuncs.FireTargets( "giegue_hint_timer", null, null, USE_TOGGLE, 0.0f, 0.1f );
	if ( level == 26 )
	{
		pEntity.KeyValue( "giegue_set_hint26_s", string( time ) );
		g_EntityFuncs.FireTargets( "giegue_area3_sides", null, null, USE_OFF, 0.0f, float( time ) + 0.1f );
		g_EntityFuncs.FireTargets( "giegue_area3_top_c", null, null, USE_OFF, 0.0f, float( time ) + 0.1f );
		g_EntityFuncs.FireTargets( "giegue_area3_bottom_c", null, null, USE_OFF, 0.0f, float( time ) + 0.1f );
	}
}

void ChumtoadSpawn( CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster )
{
	if ( pMonster !is null )
	{
		// the chumtoad should not be able to be injured in any way
		pMonster.pev.takedamage = DAMAGE_NO;
		pMonster.pev.flags |= FL_GODMODE;
		pMonster.pev.scale = 2;
	}
}

}

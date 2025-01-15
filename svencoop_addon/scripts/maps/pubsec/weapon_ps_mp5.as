//MP5 script for pubsec by Meryilla
//Modified from Kerncore's CS16 Weapon scripts
#include "base_ps"

namespace PSWeaponMP5
{

// Animations
enum MP5Animations
{
	LONGIDLE = 0,
	IDLE,
	LAUNCH,
	RELOAD,
	DEPLOY,
	FIRE1,
	FIRE2,
	FIRE3
};

// Models
string W_MODEL  	= "models/w_9mmar.mdl";
string V_MODEL  	= "models/v_9mmar.mdl";
string P_MODEL  	= "models/p_9mmar.mdl";
string SHELL  		= "models/shell.mdl";
int MAG_BDYGRP  	= 11;
// Sprites
// Sounds
array<string> 		WeaponSoundEvents = {
					"items/cliprelease1.wav",
					"items/clipinsert1.wav"				
};
array<string>		WeaponFireSounds = {
					"weapons/hks1.wav",
					"weapons/hks2.wav",
					"weapons/hks3.wav"
};
string SHOOT_EMPTY 	= "hl/weapons/357_cock1.wav";
// Information
int MAX_CARRY   	= 150;
int MAX_CLIP    	= 30;
int DEFAULT_GIVE 	= MAX_CLIP * 6;
int WEIGHT      	= 5;
int FLAGS       	= ITEM_FLAG_NOAUTOSWITCHEMPTY + ITEM_FLAG_NOAUTORELOAD;
uint DAMAGE     	= 19;
uint SLOT       	= 2;
uint POSITION   	= 18;
float RPM       	= 0.08f;
uint MAX_SHOOT_DIST	= 8192;
int AIM_SPEED   	= 270;

class weapon_ps_mp5 : ScriptBasePlayerWeaponEntity, TSBASE::WeaponBase
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private int m_iShell;
	private int m_iBurstCount = 0, m_iBurstLeft = 0;
	private float m_flNextBurstFireTime = 0;	
	private int GetBodygroup()
	{
		return 0;
	}

	void Spawn()
	{
		Precache();
		CommonSpawn( W_MODEL, DEFAULT_GIVE );
                self.pev.movetype = MOVETYPE_NONE;
                self.pev.spawnflags = 1280;
		self.pev.scale = 1.1;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		//Models
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( SHELL );
		m_iShell = g_Game.PrecacheModel( SHELL );
		//Sounds
		TSBASE::PrecacheSounds( WeaponFireSounds );
		TSBASE::PrecacheSound( SHOOT_EMPTY );
		TSBASE::PrecacheSounds( WeaponSoundEvents );
		//Sprites
		CommonSpritePrecache();
		g_Game.PrecacheGeneric( "sprites/pubsec/hud/" + self.pev.classname + ".txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= MAX_CARRY;
		info.iAmmo1Drop	= MAX_CLIP;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= MAX_CLIP;
		info.iSlot  	= SLOT;
		info.iPosition 	= POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= FLAGS;
		info.iWeight 	= WEIGHT;

		return true;
	}

bool AddToPlayer( CBasePlayer@ pPlayer )
	{
	
		@m_pPlayer = pPlayer;

		{
			string pOrigin = "" + self.pev.origin.x + " " +
								  self.pev.origin.y + " " +
								  self.pev.origin.z;
			string pAngles = "" + self.pev.angles.x + " " +
								  self.pev.angles.y + " " +
								  self.pev.angles.z;

			dictionary@ pValues = {{"origin", pOrigin}, {"angles", pAngles},{"spawnflags", "1280"}, {"targetname", "weapon_spawn"}};
			CBasePlayerWeapon@ pNew = cast<CBasePlayerWeapon>(g_EntityFuncs.CreateEntity(self.GetClassname(), @pValues, true));
		}
		
		self.pev.targetname = "";
		self.pev.globalname = "";


		CBasePlayerItem@ pItem1 = pPlayer.HasNamedPlayerItem("weapon_ps_m16");
		CBasePlayerItem@ pItem2 = pPlayer.HasNamedPlayerItem("weapon_ps_spas12");

		if(pItem1 !is null) // Player has a weapon in this category already
		{
			m_pPlayer.RemovePlayerItem(pItem1); // Remove the existing weapon first
		}

		if(pItem2 !is null) // Player has a weapon in this category already
		{
			m_pPlayer.RemovePlayerItem(pItem2); // Remove the existing weapon first
		}
                m_pPlayer.SwitchWeapon(self);
		return CommonAddToPlayer( pPlayer );
	}

	bool Deploy()
	{
		return Deploy( V_MODEL, P_MODEL, DEPLOY, "mp5", GetBodygroup(), (7.0/10.0) );
	}

	bool PlayEmptySound()
	{
		return CommonPlayEmptySound( SHOOT_EMPTY );
	}

	void Holster( int skiplocal = 0 )
	{
		m_iBurstLeft = 0;	
		CommonHolster();

		BaseClass.Holster( skiplocal );
	}
	
	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + RPM;
			return;
		}	
		
		if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		{
			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Cannot fire whilst jumping!\n" );
			return;
		}
		
//		if( m_pPlayer.pev.velocity.Length2D() > ( 0.5 * m_pPlayer.GetMaxSpeed() ) )
//		{
//			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Cannot fire whilst running!\n" );
//			return;
//		}

		if( m_pPlayer.pev.velocity.Length2D() > ( 0.5 * m_pPlayer.GetMaxSpeed() ) )
                {
		  m_pPlayer.SetMaxSpeedOverride( 125 );
                }

		self.m_flNextPrimaryAttack = WeaponTimeBase() + RPM;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.5f;
		
		Vector vecSpread = VECTOR_CONE_1DEGREES * 1.04f * 1.41f;

		vecSpread = vecSpread * (m_iShotsFired * 0.0f);
		ShootWeapon( WeaponFireSounds[ Math.RandomLong( 0, 2 ) ], 1, vecSpread, MAX_SHOOT_DIST, DAMAGE );
		self.SendWeaponAnim( FIRE1 + Math.RandomLong( 0, 2 ), 0, GetBodygroup() );		


		//if( m_pPlayer.pev.velocity.Length2D() > 0 )
		//	AngleRecoil( -0.25, 0.1, 0);
		//else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		//	AngleRecoil( -0.2, 0.3, 0 );
		//else
		//	AngleRecoil( -0.1, 0, 0 );


		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBack( 0.25, 0.1, 0.08, 0.01, 1, 0.5, 1 );
		else if( m_pPlayer.pev.flags & FL_DUCKING != 0 )
			KickBack( 0, 0, 0.018, 0, 0.5, 0.2, 1 );
		else
			KickBack( 0.15, 0, 0.022, 0.002, 0.875, 0.35, 1 );			
		
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		ShellEject( m_pPlayer, m_iShell, Vector( 22, 11, -15 ), false, false );

	}
	
		

	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;
		self.m_iClip = 0;
                m_pPlayer.SetMaxSpeedOverride( 155 );
		Reload( MAX_CLIP, RELOAD, (8.0/5.0), GetBodygroup() );
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flNextPrimaryAttack + 0.1 < g_Engine.time )
			m_iShotsFired = 0;

		if( self.m_flNextPrimaryAttack + 0.39 < g_Engine.time )
                        m_pPlayer.SetMaxSpeedOverride( 270 );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;


		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
		case 0:	
			iAnim = LONGIDLE;	
			break;
		
		case 1:
			iAnim = IDLE;
			break;
			
		default:
			iAnim = IDLE;
			break;
		}
		self.SendWeaponAnim( iAnim, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 12 );
	}
}

string GetName()
{
	return "weapon_ps_mp5";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "PSWeaponMP5::weapon_ps_mp5", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "pubsec/hud", "9mm" );
}

}
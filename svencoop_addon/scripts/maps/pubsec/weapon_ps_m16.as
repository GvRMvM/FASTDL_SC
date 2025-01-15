//M16 script for pubsec by Meryilla
//Modified from Kerncore's CS16 Weapon scripts
#include "base_ps"
namespace PSWeaponM16
{

// Animations
enum M16Animations
{
	DRAW = 0,
	HOLSTER,
	IDLE,
	FIDGET,
	SHOOT_1,
	SHOOT_2,
	RELOAD_M16,
	LAUNCH,
	RELOAD_M203
};

// Models
string W_MODEL  	= "models/w_m16.mdl";
string V_MODEL  	= "models/pubsec/weapons/v_m16.mdl";
string P_MODEL  	= "models/p_m16.mdl";
string SHELL 		= "models/shell.mdl";
int MAG_BDYGRP  	= 12;

// Sprites

// Sounds
array<string> 		WeaponSoundEvents = {
					"weapons/m16_draw.wav",
					"weapons/m16_magout_metallic.wav",
					"weapons/m16_magin_metallic.wav",
					"weapons/m16_charge.wav"
};
string SHOOT_S		= "ins2/wpn/m4a1/shoot.ogg";
string SHOOT_EMPTY 	= "hl/weapons/357_cock1.wav";

// Information
int MAX_CARRY   	= 120;
int MAX_CLIP    	= 30;
int DEFAULT_GIVE 	= MAX_CLIP * 5;
int WEIGHT      	= 5;
int FLAGS       	= ITEM_FLAG_NOAUTOSWITCHEMPTY + ITEM_FLAG_NOAUTORELOAD;
uint DAMAGE     	= 40;
uint SLOT       	= 2;
uint POSITION   	= 20;
float RPM       	= 0.075f;
uint MAX_SHOOT_DIST	= 8192;
int AIM_SPEED = 160;

class weapon_ps_m16 : ScriptBasePlayerWeaponEntity, TSBASE::WeaponBase
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private int m_iShell;		
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
		self.pev.scale = 1.2;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		//Models
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		m_iShell = g_Game.PrecacheModel( SHELL );
		//Entity
		//g_Game.PrecacheOther( GetAmmoName() );
		//Sounds
		TSBASE::PrecacheSound( SHOOT_S );
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

		CBasePlayerItem@ pItem1 = pPlayer.HasNamedPlayerItem("weapon_ps_mp5");
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
		return Deploy( V_MODEL, P_MODEL, DRAW, "m16", GetBodygroup(), (30.0/30.0) );
	}

	bool PlayEmptySound()
	{
		return CommonPlayEmptySound( SHOOT_EMPTY );
	}

	void Holster( int skiplocal = 0 )
	{
		CommonHolster();
		BaseClass.Holster( skiplocal );
	}
	

	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
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
		
		if( WeaponSelectFireMode == TSBASE::SELECTFIRE_SEMI && m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 )
			return;			
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + RPM;
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.5f;
		
		Vector vecSpread;

		if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		{
			vecSpread = VECTOR_CONE_1DEGREES * 1.35 * (0.4 + (m_iShotsFired * 0.2));
		}
		else if( m_pPlayer.pev.velocity.Length2D() > 140 )
		{
			vecSpread = VECTOR_CONE_1DEGREES * 1.35 * (0.07 + (m_iShotsFired * 0.125));
		}
		else
		{
			vecSpread = VECTOR_CONE_1DEGREES * 1.09;
		}

		vecSpread = vecSpread * (m_iShotsFired * 0.0f); // do vector math calculations here to make the Spread worse	
		ShootWeapon( SHOOT_S, 1, vecSpread, MAX_SHOOT_DIST, DAMAGE );

		if( Math.RandomLong( 1, 2 ) == 1 )
			self.SendWeaponAnim( SHOOT_1, 0, GetBodygroup() );
		else
			self.SendWeaponAnim( SHOOT_2, 0, GetBodygroup() );


		//if( m_pPlayer.pev.velocity.Length2D() > 0 )
		//	AngleRecoil( -2.25, 0.4, 0);
		//else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		//	AngleRecoil( -2.25, 0.75, 0 );
		//else
		//	AngleRecoil( -1.5, 0.4, 0 );


		if( m_pPlayer.pev.velocity.Length2D() > 0 )
			KickBackTS( 1.95, 0.3, 0.3, 0.03, 3.4, 3.75, true );
		else if( m_pPlayer.pev.flags & FL_DUCKING != 0 )
			KickBackTS( 0.65, 0.175, 0.167, 0.02, 3.4, 1.875, true );
		else
			KickBackTS( 1.3, 0.2, 0.2, 0.0225, 3.75, 2.25, true );

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;

		ShellEject( m_pPlayer, m_iShell, Vector( 21, 12, -9 ), false, false );		
	}	

        void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.3f;

		switch( WeaponZoomMode )
		{
			case TSBASE::MODE_FOV_NORMAL:
			{
				WeaponZoomMode = TSBASE::MODE_FOV_ZOOM;

				ApplyFoVSniper( 45, AIM_SPEED, "m16", false );
				break;
			}
			case TSBASE::MODE_FOV_ZOOM:
			{
				WeaponZoomMode = TSBASE::MODE_FOV_NORMAL;

				ResetFoV( "m16" );
				break;
			}
		}
	}


	void Reload()
	{
		if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;
		self.m_iClip = 0;
                m_pPlayer.SetMaxSpeedOverride( 155 );
		Reload( MAX_CLIP, RELOAD_M16, (35.0/10.0), GetBodygroup() );		
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
			iAnim = FIDGET;	
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
	return "weapon_ps_m16";
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "PSWeaponM16::weapon_ps_m16", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "pubsec/hud", "556" );
}

}
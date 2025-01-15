//Mk23 script for pubsec by Meryilla
//Modified from Kerncore's CS16 Weapon scripts
#include "base_ps"

namespace PSWeaponMK23
{

// Animations
enum MK23_Animations
{
        LONGIDLE,
	IDLE_1,
        IDLE_2,
	FIRE1,
	FIRE_LAST,
	RELOAD_EMPTY,
        RELOAD,
        DEPLOY,
        IDLE_3
};

// Models
string W_MODEL  	= "models/pubsec/weapons/kimber/w_kimber.mdl";
string V_MODEL  	= "models/pubsec/weapons/kimber/v_kimber.mdl";
string P_MODEL  	= "models/pubsec/weapons/kimber/p_kimber.mdl";
string A_MODEL  	= "models/w_9mmclip.mdl";
string SHELL 		= "models/shell.mdl";
int MAG_BDYGRP  	= 14;
// Sprites
// Sounds
array<string> 		WeaponSoundEvents = {
					"pubsec/weapons/pistol-empty.wav",
					"weapons/glock_magin.wav",
					"weapons/glock_magout.wav",
					"weapons/glock_slideforward.wav"					
};
string SHOOT_S  	= "pubsec/weapons/mk23/shoot.ogg";
string SHOOT_EMPTY 	= "hl/weapons/357_cock1.wav";
// Information
int MAX_CARRY   	= 40;
int MAX_CLIP    	= 8;
int DEFAULT_GIVE 	= MAX_CLIP * 6;
int WEIGHT      	= 5;
int FLAGS       	= ITEM_FLAG_NOAUTOSWITCHEMPTY + ITEM_FLAG_NOAUTORELOAD;
uint DAMAGE     	= 33;
uint SLOT       	= 1;
uint POSITION   	= 10;
float RPM       	= 0.14f;
uint MAX_SHOOT_DIST	= 4096;
string AMMO_TYPE 	= "ts_5.7mm";

//Buy Menu Information
string WPN_NAME 	= "KIMBER Custom TLE II";
uint WPN_PRICE  	= 185;
string AMMO_NAME 	= "KIMBER Magazine";
uint AMMO_PRICE  	= 25;

class weapon_ps_mk23 : ScriptBasePlayerWeaponEntity, TSBASE::WeaponBase
{
	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}
	private int m_iShell;
	private bool ALT_ANIM;	
	private int GetBodygroup()
	{
		return 0;
	}

	void Spawn()
	{
		Precache();
		CommonSpawn( W_MODEL, DEFAULT_GIVE );
                self.pev.movetype = MOVETYPE_NONE;
                //self.pev.spawnflags = 1280;
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		//Models
		g_Game.PrecacheModel( W_MODEL );
		g_Game.PrecacheModel( V_MODEL );
		g_Game.PrecacheModel( P_MODEL );
		g_Game.PrecacheModel( A_MODEL );
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
        //
	//	{
	//		string pOrigin = "" + self.pev.origin.x + " " +
	//							  self.pev.origin.y + " " +
	//							  self.pev.origin.z;
	//		string pAngles = "" + self.pev.angles.x + " " +
	//							  self.pev.angles.y + " " +
	//							  self.pev.angles.z;
        //
	//		dictionary@ pValues = {{"origin", pOrigin}, {"angles", pAngles},{"spawnflags", "1280"}, {"targetname", "weapon_spawn"}};
	//		CBasePlayerWeapon@ pNew = cast<CBasePlayerWeapon>(g_EntityFuncs.CreateEntity(self.GetClassname(), @pValues, true));
	//	}
		
		self.pev.targetname = "";
		self.pev.globalname = "";

		return CommonAddToPlayer( pPlayer );
	}

	bool Deploy()
	{
		ALT_ANIM = false;
		return Deploy( V_MODEL, P_MODEL, DEPLOY, "onehanded", GetBodygroup(), (30.0/30.0) );
	}

	bool PlayEmptySound()
	{
		return CommonPlayEmptySound( SHOOT_EMPTY );
	}

	void Holster( int skiplocal = 0 )
	{
		CommonHolster();
		ALT_ANIM = false;
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


		if( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 )
			return;

		Vector vecSpread;

		if( m_pPlayer.pev.velocity.Length2D() > 0 ) // is the player moving
		{
			vecSpread = VECTOR_CONE_1DEGREES * 1.255f;
		}
		else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		{
			vecSpread = VECTOR_CONE_2DEGREES * 1.5f;
		}
		else
		{
			vecSpread = VECTOR_CONE_1DEGREES * 1.15f;
		}

		vecSpread = vecSpread * (m_iShotsFired * 0.2); // do vector math calculations here to make the Spread worse

		ShootWeapon( SHOOT_S, 1, vecSpread, MAX_SHOOT_DIST, DAMAGE, DMG_SNIPER | DMG_NEVERGIB );
		self.m_flNextPrimaryAttack = WeaponTimeBase() + RPM;
		
		if( ALT_ANIM )
		{
			if( self.m_iClip > 0 )
			{
				self.SendWeaponAnim( FIRE1, 0, GetBodygroup() );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
			}
			else
			{
				self.SendWeaponAnim( FIRE_LAST, 0, GetBodygroup() );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0f;
			}		
		}
		else
		{
			if( self.m_iClip > 0 )
			{
				self.SendWeaponAnim( FIRE1, 0, GetBodygroup() );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
			}
			else
			{
				self.SendWeaponAnim( FIRE_LAST, 0, GetBodygroup() );
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 20.0f;
			}			
		}

		//if( m_pPlayer.pev.velocity.Length2D() > 0 )
		//	AngleRecoil( -2.25, 0.75, 0);
		//else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		//	AngleRecoil( -2.25, 0.75, 0 );
		//else
		//	AngleRecoil( -1.5, 0.5, 0 );

//		PunchAngle( Vector( Math.RandomFloat( -1.8, -1.2 ), (Math.RandomLong( 0, 1 ) < 0.5) ? -0.85f : 1.15f, Math.RandomFloat( -0.5, 0.5 ) ) );			

		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		m_pPlayer.pev.punchangle.x -= 2;

		ShellEject( m_pPlayer, m_iShell, Vector( 15, 8, -6 ), false, false );
	}

	void Reload()
	{
	        if( self.m_iClip == MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || m_pPlayer.pev.button & IN_USE != 0 )
			return;
                m_pPlayer.SetMaxSpeedOverride( 155 );
		self.m_iClip = 0;

		if ( ALT_ANIM )
		{
			Reload( MAX_CLIP, RELOAD, (8.0/5.0), GetBodygroup() );
		}
		else
		{
			Reload( MAX_CLIP, RELOAD_EMPTY, (8.0/5.0), GetBodygroup() );
		}
		
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if( self.m_flNextPrimaryAttack + 0.2 < g_Engine.time ) // wait 0.2 seconds before reseting how many shots the player fired
			m_iShotsFired = 0;

		if( self.m_flNextPrimaryAttack + 0.39 < g_Engine.time )
                        m_pPlayer.SetMaxSpeedOverride( 270 );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( ALT_ANIM )
		{
			self.SendWeaponAnim( IDLE_1, 0, GetBodygroup() );
		}
		else 
		{
			self.SendWeaponAnim( IDLE_1, 0, GetBodygroup() );
		}
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 5, 7 );
	}
}

class ammo_mk23 : ScriptBasePlayerAmmoEntity, TSBASE::AmmoBase
{
	void Spawn()
	{
		Precache();

		CommonSpawn( A_MODEL, MAG_BDYGRP );
		self.pev.scale = 1;
	}

	void Precache()
	{
		//Models
		g_Game.PrecacheModel( A_MODEL );
		//Sounds
		CommonPrecache();
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		return CommonAddAmmo( pOther, MAX_CLIP, MAX_CARRY, AMMO_TYPE );
	}
}

string GetAmmoName()
{
	return "ammo_mk23";
}

string GetName()
{
	return "weapon_ps_mk23";
}

void Register()
{		
	g_CustomEntityFuncs.RegisterCustomEntity( "PSWeaponMK23::ammo_mk23", GetAmmoName() );
	g_CustomEntityFuncs.RegisterCustomEntity( "PSWeaponMK23::weapon_ps_mk23", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "pubsec/hud", AMMO_TYPE );		
}

}
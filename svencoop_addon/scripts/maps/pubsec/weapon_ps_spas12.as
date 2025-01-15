//MP5 script for pubsec by Meryilla

//Modified from Kerncore's CS16 Weapon scripts

#include "base_ps"



namespace PSWeaponSPAS12

{


// Animations

enum SPAS12Animations

{

	SM_IDLE = 0,

	SHOOT1,

	PUMP,

	RELOAD_MIDDLE,

	RELOAD_END,

	RELOAD_START,

	DRAW,

	REHOLSTER,

	IDLE4,

	DEEPIDLE

};


// Models
string 
W_MODEL  	= "models/w_shotgun.mdl";

string V_MODEL  	= "models/pubsec/weapons/v_shotgun.mdl";

string P_MODEL  	= "models/p_shotgun.mdl";

string SHELL  		= "models/shotgunshell.mdl";

int MAG_BDYGRP  	= 1;

// Sprites

// Sounds

array<string> 		WeaponSoundEvents = {

					"weapons/scock1.wav",

					"weapons/reload1.wav"

};


string SHOOT_S  	= "weapons/sbarrel1.wav";

string SHOOT_EMPTY 	= "hl/weapons/357_cock1.wav";

// Information

int MAX_CARRY   	= 64;

int MAX_CLIP            = 8;

int DEFAULT_GIVE 	= MAX_CLIP * 9;

int WEIGHT      	= 5;

int FLAGS       	= ITEM_FLAG_NOAUTOSWITCHEMPTY + ITEM_FLAG_NOAUTORELOAD;

uint DAMAGE     	= 12;

uint SLOT       	= 2;

uint POSITION   	= 14;

float RPM_PUMP  	= 0.35f;

float RPM_SEMI  	= 0.3f;

uint MAX_SHOOT_DIST	= 3000;

uint PELLETS    	= 8;

Vector CONE( 0.0675f, 0.0675f, 0 );


class weapon_ps_spas12 : ScriptBasePlayerWeaponEntity, TSBASE::WeaponBase

{
	private CBasePlayer@ m_pPlayer

	{

		get const 	{
 return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() );
 }

		set
       	{
 self.m_hPlayer = EHandle( @value );
 }

	}

	private int m_iShell;

	private int m_iPumpAnim;

	private float m_flNextReload;

	private bool m_fShotgunReload = false;

	private bool m_fNeedPump = false;

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

		TSBASE::PrecacheSound( SHOOT_S );

		TSBASE::PrecacheSound( SHOOT_EMPTY );TSBASE::PrecacheSounds( WeaponSoundEvents );

		//Sprites

		CommonSpritePrecache();

		g_Game.PrecacheGeneric( "sprites/pubsec/hud/" + self.pev.classname + ".txt" );

	}



	bool GetItemInfo( ItemInfo& out info )

	{

		info.iMaxAmmo1 	= MAX_CARRY;

		info.iAmmo1Drop	= MAX_CLIP;                info.iMaxAmmo2 	= -1;

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
		CBasePlayerItem@ pItem2 = pPlayer.HasNamedPlayerItem("weapon_ps_m16");

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

		return Deploy( V_MODEL, P_MODEL, DRAW, "shotgun", GetBodygroup(), (6.0/10.0) );
	
}

	

bool PlayEmptySound()
	
{

		return CommonPlayEmptySound( SHOOT_EMPTY );
	
}


	void Holster( int skiplocal = 0 )
	
{

		m_fShotgunReload = false;

		//m_fNeedPump = false;

		CommonHolster();


		BaseClass.Holster( skiplocal );

	}

	
	void PumpAction()

	{

		self.SendWeaponAnim( PUMP, 0, GetBodygroup() );
	
		
		SetThink( ThinkFunction( this.EjectBrassThink ) );

		self.pev.nextthink = g_Engine.time + 0.45f;
		
		
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;

		m_fNeedPump = false;

	}


	void PrimaryAttack()

	{

		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )

		{

			self.PlayEmptySound();

			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

			return;

		}


		
		if( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 )

			return;	

		
		if( m_fNeedPump )

		{

//			PumpAction();

			return;

		}

		else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )

		{

			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Cannot fire whilst jumping!\n" );

			return;

		}


//		else if( m_pPlayer.pev.velocity.Length2D() > ( 0.5 * m_pPlayer.GetMaxSpeed() ) )

//		{

//			g_EngineFuncs.ClientPrintf( m_pPlayer, print_center, "Cannot fire whilst running!\n" );

//			return;

//		}


		else if( m_pPlayer.pev.velocity.Length2D() > ( 0.5 * m_pPlayer.GetMaxSpeed() ) )
                {
		  m_pPlayer.SetMaxSpeedOverride( 125 );
                  self.m_flNextPrimaryAttack = WeaponTimeBase() + RPM_PUMP;

	          self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.5f;
		
  m_fNeedPump = true;

                }

			
		else

		{

			self.m_flNextPrimaryAttack = WeaponTimeBase() + RPM_PUMP;

			self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.5f;
		
			m_fNeedPump = true;

		}


	
		self.SendWeaponAnim( SHOOT1, 0, GetBodygroup() );

		ShootWeapon( SHOOT_S, PELLETS, CONE, MAX_SHOOT_DIST, DAMAGE, DMG_LAUNCH );



		//if( m_pPlayer.pev.velocity.Length2D() > 0 )
		//	AngleRecoil( -3, 0, 0);
		//else if( !( m_pPlayer.pev.flags & FL_ONGROUND != 0 ) )
		//	AngleRecoil( -2.5, 0.75, 0 );
		//else
		//	AngleRecoil( -2.5, 0, 0 );

				PunchAngle( Vector( Math.RandomFloat( -9, -8 ), (Math.RandomLong( 0, 1 ) < 0.5) ? -1.0 : 1.25, Math.RandomFloat( -0.5, 0.5 ) ) );
					
	
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		
	}



        void SecondaryAttack()
        {
             if( m_fNeedPump )
             {
		self.m_flNextSecondaryAttack = WeaponTimeBase() + RPM_PUMP;
		PumpAction();

                return;
             }
             else if( m_pPlayer.m_afButtonPressed & IN_ATTACK2 == 0 )
		{
			self.m_flNextSecondaryAttack = WeaponTimeBase() + RPM_PUMP;
			return;		
		}	
             else if( self.m_iClip != 0 )
             {
		self.m_flNextSecondaryAttack = WeaponTimeBase() + RPM_PUMP;
                PumpAction();
                self.m_iClip = self.m_iClip - 1;
                return;
             }
             else
             {
               return;
             }
        }

	void EjectBrassThink()

	{

		SetThink( null );


		ShellEject( m_pPlayer, m_iShell, Vector( 28, 18, -12.5f ), false, false, TE_BOUNCE_SHOTSHELL );

	}



	void ItemPostFrame()

	{

		if( m_fShotgunReload )

		{

			if( (m_pPlayer.pev.button & IN_ATTACK != 0) && m_flNextReload <= g_Engine.time )

			{

				if( self.m_iClip <= 0 )

				{

					self.Reload();

				}

				else

				{

					self.m_flTimeWeaponIdle = g_Engine.time + m_flNextReload;

					m_fShotgunReload = false;

				}

			}

			else if( (self.m_iClip >= MAX_CLIP && m_pPlayer.pev.button & (IN_RELOAD | IN_ATTACK2 | IN_ALT1) != 0) && m_flNextReload <= g_Engine.time )

			{

				// reload debounce has timed out

				self.SendWeaponAnim( RELOAD_END, 0, GetBodygroup() );


				m_fShotgunReload = false;

				m_fNeedPump = false;
				
				self.m_flTimeWeaponIdle = g_Engine.time + 1.5f;

			}

		}

		BaseClass.ItemPostFrame();

	}

	

void Reload()

	{
                m_pPlayer.SetMaxSpeedOverride( 155 );
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == MAX_CLIP || m_pPlayer.pev.button & IN_USE != 0 )

			return;


		if( m_flNextReload > WeaponTimeBase() )

			return;


		// don't reload until recoil is done

		if( self.m_flNextPrimaryAttack > WeaponTimeBase() && !m_fShotgunReload )

			return;


		// check to see if we're ready to reload

		if( !m_fShotgunReload )

		{

			self.SendWeaponAnim( RELOAD_START, 0, GetBodygroup() );


			m_pPlayer.m_flNextAttack = (30.0/40.0);
 //Always uses a relative time due to prediction
			self.m_flTimeWeaponIdle = WeaponTimeBase() + (30.0/40.0);

			m_flNextReload = self.m_flNextPrimaryAttack = WeaponTimeBase() + (30.0/40.0);


			m_fShotgunReload = true;
			return;

		}

		else if( m_fShotgunReload )

		{
			if( self.m_flTimeWeaponIdle > WeaponTimeBase() )

				return;


			if( self.m_iClip == MAX_CLIP )
	
		{

				m_fShotgunReload = false;

				return;

			}



			self.SendWeaponAnim( RELOAD_MIDDLE, 0, GetBodygroup() );

			m_flNextReload = self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = WeaponTimeBase() + (8/25.0);


			// Add them to the clip
			self.m_iClip += 1;

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

		}

		BaseClass.Reload();

	}



	void WeaponIdle()

	{

		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );


		if( self.m_flNextPrimaryAttack + 0.39 < g_Engine.time )
                        m_pPlayer.SetMaxSpeedOverride( 270 );


		if( self.m_flTimeWeaponIdle < g_Engine.time )

		{

			if( self.m_iClip <= 0 && !m_fShotgunReload && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) != 0 )

			{

				self.Reload();

			}

			else if( m_fShotgunReload )

			{

				if( self.m_iClip != MAX_CLIP && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )

				{

					self.Reload();

				}

				else

				{

					// reload debounce has timed out
 self.SendWeaponAnim( RELOAD_END, 0, GetBodygroup() );

					m_fNeedPump = false;	
				

					m_fShotgunReload = false;

					self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;

				}

			}

			else

			{

				int iAnim;

				float flIdleTime;

				switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
	
			{

				case 0:
	
				iAnim = SM_IDLE;

					flIdleTime = (23.0/10);
				
	break;


				
	case 1:

					iAnim = IDLE4;

					flIdleTime = (23.0/10);

					break;


					
case 2:

					iAnim = DEEPIDLE;

					flIdleTime = (47.0/10);

					break;


					
default:

					iAnim = SM_IDLE;

					break;

				}

				self.SendWeaponAnim( iAnim, 0, GetBodygroup() );

				self.m_flTimeWeaponIdle = WeaponTimeBase() + flIdleTime;

			}

		}

	}

}



string GetName()

{

	return "weapon_ps_spas12";

}



void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "PSWeaponSPAS12::weapon_ps_spas12", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "pubsec/hud", "buckshot" );


}



}
//Credit to Gaftherman for making trigger_votemenu and Giegue for making game_custom_equip.

namespace levi
{
	void MapInit()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "levi::trigger_votemenu", "trigger_votemenu" );
		g_CustomEntityFuncs.RegisterCustomEntity( "levi::CCustomEquip", "game_custom_equip" );
	}
	
	/* Gaftherman */
	class trigger_votemenu : ScriptBaseEntity
	{
		dictionary dictKeyValues;
		dictionary dictFinalResults;

		array<CTextMenu@> g_VoteMenu = 
		{
			null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null,
			null, null, null, null, null, null, null, null,
			null
		};

		const array<string> strKeyValues
		{
			get const { return dictKeyValues.getKeys(); }
		}

		void Spawn()
		{
			if(self.pev.health <= 0) self.pev.health = 15;
			if(string(self.pev.netname).IsEmpty()) self.pev.netname = "Vote Menu";

			BaseClass.Spawn();
		}

		bool KeyValue(const string& in szKey, const string& in szValue)
		{
			dictKeyValues[szKey] = szValue;
			return true;
		}

		void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
		{
			dictFinalResults.deleteAll();

			if( self.pev.SpawnFlagBitSet( 1 ) && pActivator !is null && pActivator.IsPlayer() )
			{
				CTextMenu@ g_SingleVoteMenu = CTextMenu( TextMenuPlayerSlotCallback( this.MainCallback ) );
				g_SingleVoteMenu.SetTitle( string( self.pev.netname ) );
				
				for(uint ui = 0; ui < strKeyValues.length(); ui++)
				{
					g_SingleVoteMenu.AddItem(strKeyValues[ui]);
				}

				g_SingleVoteMenu.Register();
				g_SingleVoteMenu.Open( int(self.pev.health), 0, cast<CBasePlayer@>(pActivator) );
			}
			else
			{
				for(int i = 1; i <= g_Engine.maxClients; i++) 
				{
					CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);

					if(pPlayer !is null && pPlayer.IsConnected()) 
					{
						int eidx = pPlayer.entindex();
		
						if( g_VoteMenu[eidx] is null )
						{
							@g_VoteMenu[eidx] = CTextMenu( TextMenuPlayerSlotCallback( this.MainCallback ) );
							g_VoteMenu[eidx].SetTitle( string( self.pev.netname ) );

							for(uint ui = 0; ui < strKeyValues.length(); ui++)
							{
								g_VoteMenu[eidx].AddItem(strKeyValues[ui]);
							}

							g_VoteMenu[eidx].Register();
						}
						g_VoteMenu[eidx].Open( int(self.pev.health), 0, pPlayer );
					}
				}
			}
			g_Scheduler.SetTimeout( @this, "Results", float(self.pev.health) + 3.0f );
		}

		void MainCallback( CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem )
		{
			if( pItem !is null && strKeyValues.find(pItem.m_szName) >= 0 )
			{
				int value;

				if( dictFinalResults.exists(pItem.m_szName) )
				{
					dictFinalResults.get(pItem.m_szName, value);
					dictFinalResults.set(pItem.m_szName, value+1);
				}
				else
				{
					dictFinalResults.set(pItem.m_szName, 1);
				}
			}
		}

		void Results()
		{
			array<string> Names = dictFinalResults.getKeys();
			array<array<string>> AllValuesInOne;
			array<string> SameValue;

			int LatestHigherNumber = 0; 

			for(uint i = 0; i < Names.length(); ++i)
			{   
				int value;
				dictFinalResults.get(Names[i], value);
				AllValuesInOne.insertLast({Names[i], value});
			}

			for(uint i = 0; i < AllValuesInOne.length(); ++i)
			{   
				if( atoi(AllValuesInOne[i][1]) > LatestHigherNumber )
				{
					SameValue.resize(0);

					LatestHigherNumber = atoi(AllValuesInOne[i][1]);
					SameValue.insertLast(AllValuesInOne[i][0]);
				}
				else if( atoi(AllValuesInOne[i][1]) == LatestHigherNumber )
				{
					SameValue.insertLast(AllValuesInOne[i][0]);
				}
			}

			if( SameValue.length() <= 0 )
			{
				g_EntityFuncs.FireTargets( self.pev.message, self, self, USE_TOGGLE, 0.0f );
			}
			else
			{
				string FindName = SameValue[Math.RandomLong(0, SameValue.length()-1)];
				if(dictKeyValues.exists(FindName))
				{
					string value;
					dictKeyValues.get(FindName, value); 
					g_EntityFuncs.FireTargets( value, self, self, USE_TOGGLE, 0.0f );
				}
			}

			g_EntityFuncs.FireTargets( self.pev.target, self, self, USE_TOGGLE, 0.0f );
		}
	}

	/* Giegue */
    class CCustomEquip : ScriptBaseEntity
	{
		dictionary dItems;
		
		bool KeyValue( const string& in szKey, const string& in szValue )
		{
			if ( szKey.StartsWith( "weapon_" ) || szKey.StartsWith( "ammo_" ) || szKey.StartsWith( "item_" ) )
			{
				dItems[ szKey ] = szValue;
				return true;
			}
			else
				return BaseClass.KeyValue( szKey, szValue );
		}
		
		void Spawn()
		{
			// Classic base trigger initialization
			self.pev.solid = SOLID_TRIGGER;
			self.pev.movetype = MOVETYPE_NONE;
			self.pev.effects = EF_NODRAW;
			g_EntityFuncs.SetOrigin( self, self.pev.origin );
			g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
			g_EntityFuncs.SetModel( self, self.pev.model );
		}
		
		void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue = 0.0f )
		{
			if ( pActivator.IsPlayer() )
			{
				CBasePlayer@ pPlayer = cast< CBasePlayer@ >( pActivator );
				KeyValueBuffer@ pPlayerPhysics = g_EngineFuncs.GetPhysicsKeyBuffer( pPlayer.edict() );
				
				pPlayer.RemoveAllItems( false );
				RemoveAllAmmo( pPlayer );
				pPlayer.SetItemPickupTimes( 0 );
				pPlayer.pev.health = 100;
				pPlayer.pev.armorvalue = 0;
				pPlayer.m_fLongJump = false;
				pPlayerPhysics.SetValue( "slj", "0" );
				
				array< string >@ item = dItems.getKeys();
				for ( uint itemIndex = 0; itemIndex < item.length(); itemIndex++ )
				{
					for ( uint itemTimes = 0; itemTimes < atoui( string( dItems[ item[ itemIndex ] ] ) ); itemTimes++ )
					{
						pPlayer.GiveNamedItem( item[ itemIndex ], SF_NORESPAWN );
					}
				}
			}
			else
			{
				for ( int i = 1; i <= g_Engine.maxClients; i++ )
				{
					CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );
					if ( pPlayer !is null && pPlayer.IsConnected() )
					{
						KeyValueBuffer@ pPlayerPhysics = g_EngineFuncs.GetPhysicsKeyBuffer( pPlayer.edict() );
						
						pPlayer.RemoveAllItems( false );
						RemoveAllAmmo( pPlayer );
						pPlayer.SetItemPickupTimes( 0 );
						pPlayer.pev.health = 100;
						pPlayer.pev.armorvalue = 0;
						pPlayer.m_fLongJump = false;
						pPlayerPhysics.SetValue( "slj", "0" );
						
						array< string >@ item = dItems.getKeys();
						for ( uint itemIndex = 0; itemIndex < item.length(); itemIndex++ )
						{
							for ( uint itemTimes = 0; itemTimes < atoui( string( dItems[ item[ itemIndex ] ] ) ); itemTimes++ )
							{
								pPlayer.GiveNamedItem( item[ itemIndex ], SF_NORESPAWN );
							}
						}
					}
				}
			}
		}
		
		void RemoveAllAmmo( CBasePlayer@ pPlayer )
		{
			// manual it is
			int AMMO_9MM = g_PlayerFuncs.GetAmmoIndex( "9mm" );
			int AMMO_357 = g_PlayerFuncs.GetAmmoIndex( "357" );
			int AMMO_SHOTGUN = g_PlayerFuncs.GetAmmoIndex( "buckshot" );
			int AMMO_CROSSBOW = g_PlayerFuncs.GetAmmoIndex( "bolts" );
			int AMMO_SAW = g_PlayerFuncs.GetAmmoIndex( "556" );
			int AMMO_M16GRENADE = g_PlayerFuncs.GetAmmoIndex( "ARgrenades" );
			int AMMO_RPG = g_PlayerFuncs.GetAmmoIndex( "rockets" );
			int AMMO_GAUSS = g_PlayerFuncs.GetAmmoIndex( "uranium" );
			int AMMO_SNIPER = g_PlayerFuncs.GetAmmoIndex( "m40a1" );
			int AMMO_SPORE = g_PlayerFuncs.GetAmmoIndex( "sporeclip" );
			
			pPlayer.m_rgAmmo( AMMO_9MM, 0 );
			pPlayer.m_rgAmmo( AMMO_357, 0 );
			pPlayer.m_rgAmmo( AMMO_SHOTGUN, 0 );
			pPlayer.m_rgAmmo( AMMO_CROSSBOW, 0 );
			pPlayer.m_rgAmmo( AMMO_SAW, 0 );
			pPlayer.m_rgAmmo( AMMO_M16GRENADE, 0 );
			pPlayer.m_rgAmmo( AMMO_RPG, 0 );
			pPlayer.m_rgAmmo( AMMO_GAUSS, 0 );
			pPlayer.m_rgAmmo( AMMO_SNIPER, 0 );
			pPlayer.m_rgAmmo( AMMO_SPORE, 0 );
		}
	}
}

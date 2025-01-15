namespace kezaeiv
{
    dictionary info =
    {
        // Daño al impacto de cada mini ball
        { 'damage', 30.0f },

        // Sprite de la bola grande
        { 'energy_sprite', 'sprites/nhth1.spr' },

        // sprite de la expansion de la bola grande (sus aros)
        { 'energy_expansion', 'sprites/laserbeam.spr' },

        // Velocidad de subida de la bola grande
        { 'energy_zspeed', 200 },

        // Sonido al spawnear de la bola grande
        { 'energy_sound_spawn', 'ragemap2023/kezaeiv/wizard/wiz_spawn_sfx.ogg' },

        // maxima altura que se puede subir desde la posicion del tor
        { 'energy_zmax', 280 },

        // Sonido a efectuar en el momento que la mini ball es disparada
        { 'mball_sound_shoot', 'ragemap2023/kezaeiv/xl2.wav' },

        // Sonido a efectuar en el momento que la mini ball llego a su objetivo
        { 'mball_sound_touch', 'ragemap2023/kezaeiv/xl2.wav' },

        // Velocidad de la mini ball
        { 'mball_speed', 1200 },

        // Cantidad de mini balls por jugador
        { 'mball_max', 6 },

        // sprite de la mini ball
        { 'mball_sprite', 'sprites/nhth1.spr' },

        // sprite de la mini ball al explotar
        { 'mball_explosion', 'sprites/ragemap2023/kezaeiv/zxlp_purple.spr' },

        // sprite del beam de la mini ball
        { 'mball_beam', 'sprites/laserbeam.spr' },

        // sprite del disco
        { 'mball_disk', 'sprites/laserbeam.spr' }
    };

    void TorHVR( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE UseType, float delay )
    {
        CBaseMonster@ tor = cast<CBaseMonster@>( g_EntityFuncs.FindEntityByTargetname( null, 'kezaeiv_mordekai' ) );

        if( tor is null || !tor.IsAlive() )
            return;

        CBaseEntity@ pHVR = g_EntityFuncs.Create( 'kz_energyball', g_vecZero, g_vecZero, false, tor.edict() );
    }

    void MapInit()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( 'kezaeiv::CEnergyBall', 'kz_energyball' );
        g_CustomEntityFuncs.RegisterCustomEntity( 'kezaeiv::CMiniEnergyBall', 'kz_minienergyball' );
        g_Game.PrecacheOther( 'kz_energyball' );
        g_Game.PrecacheOther( 'kz_minienergyball' );
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_knife.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_minigun.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_raptor.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_schofield.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_shotgun.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_tommy.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_xl2.txt');
		g_Game.PrecacheGeneric('sprites/ragemap2023/kezaeiv/weapon_kezaeiv_srs_xpml21.txt');
		 
    }

    class CEnergyBall : ScriptBaseEntity
    {
        private int m_iCount;
        private array<int> iPlayers;

        void Spawn()
        {
            Precache();
			
		
            pev.rendermode = kRenderTransAdd;
            pev.renderamt = 255;
            pev.scale = 3.0;

            pev.movetype = MOVETYPE_FLY;
            pev.solid = SOLID_NOT;

            g_EntityFuncs.SetModel( self, string( info[ 'energy_sprite' ] ) );
			g_EntityFuncs.SetSize( pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );

            g_EntityFuncs.SetOrigin( self, pev.owner.vars.origin + Vector(0,0,100) );

            pev.velocity.z = int( info[ 'energy_zspeed' ] );
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, string( info[ 'energy_sound_spawn' ] ), 1, ATTN_NORM, 0, 100 );

            SetThink( ThinkFunction( this.FlyThink ) );
            pev.nextthink = g_Engine.time + 0.1;

            BaseClass.Spawn();
        }

        void Precache()
        {
            g_Game.PrecacheGeneric( string( info[ 'energy_expansion' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'energy_sprite' ] ) );
            g_SoundSystem.PrecacheSound( string( info[ 'energy_sound_spawn' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'energy_sound_spawn' ] ) );
            BaseClass.Precache();
        }

        void FrameAdvance()
        {
            if( pev.frame >= 10 )
            {
                pev.frame = 0;
            }
            else
            {
                pev.frame++;
            }
        }

		bool InArena( Vector VecPos )
        {
            return ( VecPos.x <= -3420 && VecPos.x >= -6116 && VecPos.y <= -388 && VecPos.y >= -2788 && VecPos.z <= 1188 && VecPos.z >= 412 );
        }
		
        void FlyThink()
        {
            FrameAdvance();
            pev.nextthink = g_Engine.time + 0.05;

            if( pev.velocity == g_vecZero || pev.origin.z > pev.owner.vars.origin.z + int( info[ 'energy_zmax' ] ) )
            {
				pev.velocity = g_vecZero;

                iPlayers.resize(0);

                for( int i = 1; i <= g_Engine.maxClients; i++ )
                {
                    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );

                    if( pPlayer !is null
                    and pPlayer.IsAlive()
                    and pPlayer.IsConnected()
                    and InArena( pPlayer.pev.origin ) )
                    {
                        iPlayers.insertLast(i);
                    }
                }

                SetThink( ThinkFunction( this.ShootThink ) );
            }
            else
            {
                NetworkMessage Message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
                    Message.WriteByte( TE_BEAMTORUS );
                    Message.WriteCoord( pev.origin.x );
                    Message.WriteCoord( pev.origin.y );
                    Message.WriteCoord( pev.origin.z );
                    Message.WriteCoord( pev.origin.x );
                    Message.WriteCoord( pev.origin.y );
                    Message.WriteCoord( pev.origin.z + 120 );
                    Message.WriteShort( g_EngineFuncs.ModelIndex( string( info[ 'energy_expansion' ] ) ) );
                    Message.WriteByte( 0 );
                    Message.WriteByte( 10 );
                    Message.WriteByte( 8 ); // Life
                    Message.WriteByte( 8 );
                    Message.WriteByte( 0 );
                    Message.WriteByte( atoui( pev.rendercolor.x ) );
                    Message.WriteByte( atoui( pev.rendercolor.y ) );
                    Message.WriteByte( atoui( pev.rendercolor.z ) );
                    Message.WriteByte( int( pev.renderamt ) );
                    Message.WriteByte( 0 );
                Message.End();
            }
        }

        private int m_iPlayerIndex = -1;

        void ShootThink()
        {
            FrameAdvance();

            int m_iCap = int( info[ 'mball_max' ] ) * g_PlayerFuncs.GetNumPlayers();
            if( m_iCap > 50 )
                m_iCap = 50;

            if( m_iCount >= m_iCap || iPlayers.length() < 1  )
            {
                g_EntityFuncs.Remove( self );
                return;
            }

            pev.nextthink = g_Engine.time + 0.20; // medio segundo

            m_iPlayerIndex++;

            if( m_iPlayerIndex >= int( iPlayers.length() ) )
            {
                m_iPlayerIndex = 0;
            }

            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayers[ m_iPlayerIndex ] );

            if( pPlayer !is null && pPlayer.IsAlive() && pPlayer.FVisibleFromPos( pPlayer.pev.origin, pev.origin ) )
            {
                CBaseEntity@ pHVR = g_EntityFuncs.Create( 'kz_minienergyball', g_vecZero, g_vecZero, false, self.pev.owner );

                if( pHVR !is null )
                {
                    g_EntityFuncs.SetOrigin( pHVR, pev.origin );
                    Vector Direccion = ( pPlayer.pev.origin - pev.origin ).Normalize();
                    pHVR.pev.velocity = Direccion  * int( info[ 'mball_speed' ] );
                }
            }
            m_iCount++;
        }
    }

    class CMiniEnergyBall : ScriptBaseEntity
    {
        void Spawn()
        {
            Precache();

            pev.rendermode = kRenderTransAdd;
            pev.renderamt = 255;
            pev.movetype = MOVETYPE_FLY;
            pev.solid = SOLID_TRIGGER;
            g_EntityFuncs.SetModel( self, string( info[ 'mball_sprite' ] ) );
			g_EntityFuncs.SetSize( pev, Vector( -1, -1, -1 ), Vector( 1, 1, 1 ) );
            SetTouch( TouchFunction( this.ZapTouch ) );
            SetThink( ThinkFunction( this.FlyThink ) );
            pev.nextthink = g_Engine.time + 0.1;
            g_SoundSystem.EmitAmbientSound( self.edict(), pev.origin, string( info[ 'mball_sound_shoot' ] ), 1.0, ATTN_NORM, 0, Math.RandomLong( 90, 95 ) );
            BaseClass.Spawn();
        }

        void Precache()
        {
            g_SoundSystem.PrecacheSound( string( info[ 'mball_sound_shoot' ] ) );
            g_SoundSystem.PrecacheSound( string( info[ 'mball_sound_touch' ] ) );
			g_Game.PrecacheGeneric( 'sprites/ragemap2023/kezaeiv/zxlp_purple.spr' );
			g_Game.PrecacheModel( 'sprites/ragemap2023/kezaeiv/zxlp_purple.spr' );
            g_Game.PrecacheGeneric( string( info[ 'mball_sound_shoot' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'mball_sound_touch' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'mball_sprite' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'mball_explosion' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'mball_beam' ] ) );
            g_Game.PrecacheGeneric( string( info[ 'mball_disk' ] ) );
            BaseClass.Precache();
        }

        void FrameAdvance()
        {
            if( pev.frame >= 10 )
            {
                pev.frame = 0;
            }
            else
            {
                pev.frame++;
            }
        }

        void FlyThink()
        {
            FrameAdvance();

			if( pev.velocity == g_vecZero )
			{
            	SetThink( null );
				Explode();
			}
			else
			{
				NetworkMessage message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
					message.WriteByte( TE_BEAMFOLLOW );
					message.WriteShort( g_EntityFuncs.EntIndex( self.edict() ) );
					message.WriteShort( g_EngineFuncs.ModelIndex( string( info[ 'mball_beam' ] ) ) );
					message.WriteByte( 10 );	// Fade time
					message.WriteByte( 3 );		// Scale
					message.WriteByte( 120 );	// R
					message.WriteByte( 0 );		// G
					message.WriteByte( 200 );	// B
					message.WriteByte( int( pev.renderamt ) );
				message.End();
			}

            pev.nextthink = g_Engine.time + 0.1;
		}

        void ZapTouch( CBaseEntity@ pOther )
        {
            SetTouch( null );
			Explode();
        }

		void Explode()
		{
            TraceResult tr;

            g_Utility.TraceLine( pev.origin, Vector( 0, 0, -90 ), ignore_monsters, self.edict(), tr );

            if( ( pev.origin - tr.vecEndPos ).Length() < 20 )
            {
                /* - 1 Disco */
                NetworkMessage Message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
                    Message.WriteByte( TE_BEAMDISK );
                    Message.WriteCoord( pev.origin.x);
                    Message.WriteCoord( pev.origin.y);
                    Message.WriteCoord( pev.origin.z + 10 );
                    Message.WriteCoord( pev.origin.x);
                    Message.WriteCoord( pev.origin.y);
                    Message.WriteCoord( pev.origin.z + 650 ); // 650 es el radio
                    Message.WriteShort( g_EngineFuncs.ModelIndex( string( info[ 'mball_disk' ] ) ) );
                    Message.WriteByte( 0 ); // Start frame
                    Message.WriteByte( 1 ); // Tiempo de vida
                    Message.WriteByte( 2 ); // Hold time
                    Message.WriteByte(1);
                    Message.WriteByte(0);
                    Message.WriteByte( 120 );    // R
                    Message.WriteByte( 0 );        // G
                    Message.WriteByte( 200 );    // B
                    Message.WriteByte( int( pev.renderamt ) );
                    Message.WriteByte( 0 );
                Message.End();
            }

            CSprite@ pSprite = g_EntityFuncs.CreateSprite( string( info[ 'mball_explosion' ] ), pev.origin, true, 10.0f );

            if( pSprite !is null )
            {
                // Render settings, mirar abajo
                pSprite.SetTransparency( kRenderTransAdd, 255, 255, 255, 255, 0 );
                // SetTransparency( int renderMode, int r, int g, int b, int renderAmount, int renderFx )
                pSprite.AnimateAndDie( 31.0f );         // framerate
                pSprite.SetScale( 2.65f );               // scale
            }

            g_SoundSystem.EmitAmbientSound( self.edict(), pev.origin, string( info[ 'mball_sound_touch' ] ), 1.0, ATTN_NORM, 0, Math.RandomLong( 90, 95 ) );
			g_WeaponFuncs.RadiusDamage( pev.origin, pev, pev.owner.vars, float( info[ 'damage' ] ), 125, self.Classify(), ( DMG_SHOCK | DMG_SHOCK_GLOW ) );
            g_EntityFuncs.Remove( self );
		}
    }
}
#include "cof/special/weapon_coflantern"

namespace dex
{
    void PushEnemy( CBaseEntity@ self )
    {
        CBaseMonster@ pZombies = null;

        while( ( @pZombies = cast<CBaseMonster@>( g_EntityFuncs.FindEntityByClassname( pZombies, 'monster_zombi*' ) ) ) !is null )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( Math.RandomLong( 1, g_PlayerFuncs.GetNumPlayers() ) );

            if( pPlayer !is null and pZombies.m_hEnemy.GetEntity() is null )
            {
                pZombies.PushEnemy( pPlayer, pPlayer.pev.origin );
            }
        }
    }
    
    void MapInit()
    {
        RegisterCoFLANTERN();
    }
}
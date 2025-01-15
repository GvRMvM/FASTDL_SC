/**
 * Ragemap 2023: Nih's part
 */

namespace Ragemap2023Nih
{
	CScheduledFunction@ resetObserverModeScheduleNih = null;
	//int m_iNextPlayerToFixNih = 5;
	int m_iNextPlayerToFixNih = 1;
	int m_SadPlayerNih = 1;

	void NihStartObserving(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		@resetObserverModeScheduleNih = g_Scheduler.SetInterval( "NihChangeObserverMode", 0.1, g_Scheduler.REPEAT_INFINITE_TIMES);
		//g_EntityFuncs.FireTargets( 'count_living', null, null, USE_ON, 0.0f, 5.0f );
	}

	void NihChangeObserverMode()
	{
		CBasePlayer@ pPlayer;

		for( ; m_iNextPlayerToFixNih <= g_Engine.maxClients; ++m_iNextPlayerToFixNih )
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex( m_iNextPlayerToFixNih );

			if( pPlayer !is null && pPlayer.IsPlayer() && pPlayer.IsConnected() && !pPlayer.IsAlive() )
			{
				Observer@ o = pPlayer.GetObserver();

				if (o.IsObserver() == true   )  { //must check if he is an observer, otherwise you will be unable to move in free roam or change camera direction in free chase...
					o.SetObserverModeControlEnabled(false); //
					o.SetMode(OBS_CHASE_LOCKED);
				}

			}
		}

		m_iNextPlayerToFixNih = 1; //1 is minimum https://github.com/baso88/SC_AngelScript/issues/59
	}

	void NihStopObserving(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		g_Scheduler.RemoveTimer( resetObserverModeScheduleNih );
	}

	array<int> spawnPointsNih = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
	
	void NihSpawnAloneAndSad(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{

		CBasePlayer@ pPlayer;

		for( ; m_SadPlayerNih <= g_Engine.maxClients; ++m_SadPlayerNih )
		{
			@pPlayer = g_PlayerFuncs.FindPlayerByIndex( m_SadPlayerNih );

			if( pPlayer !is null && pPlayer.IsPlayer() && pPlayer.IsConnected() )
			{
							
				uint randomSpawnPointSlotNih = Math.RandomLong(0 , spawnPointsNih.length() - 1 );
				int randomSpawnPointNih = spawnPointsNih[randomSpawnPointSlotNih];
				string m_SadPlayerNihString = randomSpawnPointNih;
				pPlayer.pev.targetname = 'nihplayer' + m_SadPlayerNihString;
				spawnPointsNih.removeAt(randomSpawnPointSlotNih);
				
				if( spawnPointsNih.length() == 0 ) 
				{
					break;
				}
				
			}
		}
		
			g_EntityFuncs.FireTargets( 'spawn_nih', null, null, USE_OFF, 0.0f, 0.0f );
			g_EntityFuncs.FireTargets( 'nih_newspawn', null, null, USE_ON, 0.0f, 0.0f );
			g_EntityFuncs.FireTargets( 'nih_respawn', null, null, USE_ON, 0.0f, 0.2f );
			g_EntityFuncs.FireTargets( 'nih_newspawn', null, null, USE_OFF, 0.0f, 0.5f );
			g_EntityFuncs.FireTargets( 'nih_killremainders', null, null, USE_ON, 0.0f, 1.0f );
	}	
}

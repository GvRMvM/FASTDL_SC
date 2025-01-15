/**
 * Ragemap 2023: I_ka's part
 */

#include "ika_weapon_noisemaker"
#include "ika_weapon_noisemaker_noreg"
#include "trigger_observer"

namespace Ragemap2023Ika
{
    /**
     * Map initialisation handler.
     * @return void
     */
    void MapInit()
    {
        IkaNoisemaker::Register();
        IkaNoiseNoreg::Register();
        TriggerObserver::Init();
    }

    /**
     * Map activation handler.
     * @return void
     */
    void MapActivate()
    {
        // Entity for dead survivor observation monitor
        dictionary oTriggerObserver = {
            {"origin",              "-4096 2808 1776"},
            {"angles",              "0 0 0"},
            {"targetname",          "ika_deadobserver_main"},
            {"spawnflags",          "1"}
        };
        CBaseEntity@ pTriggerObserver = g_EntityFuncs.CreateEntity("trigger_observer", oTriggerObserver);
    }

    /**
     * Map hook: Shutdown part.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void Shutdown(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        for (int i = 1; i <= g_Engine.maxClients; i++) {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                continue;
            }

            // Reset team
            pPlayer.SetClassification(CLASS_PLAYER);

            // Exit observer
            if (pPlayer.GetObserver().IsObserver()) {
                pPlayer.GetObserver().StopObserver(true);
            }
        }
    }
}

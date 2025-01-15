/**
 * Ragemap 2023: Adambean's part
 */

namespace Ragemap2023Adambean
{
    /*
     * -------------------------------------------------------------------------
     * Constants & enumerators
     * -------------------------------------------------------------------------
     */

    /** @var string Entity prefix for this map part. */
    const string ENT_PREFIX = "adambean_";

    /** @var string Entity prefix for player cameras. */
    const string ENT_PLAYER_CAMERA_PREFIX = ENT_PREFIX + "player_camera";



    /*
     * -------------------------------------------------------------------------
     * Globals
     * -------------------------------------------------------------------------
     */

    /** @global ALERT_TYPE g_uiAlertType Alert mode to use for debugging messages. */
    ALERT_TYPE g_uiAlertType = Ragemap2023::g_uiAlertType;



    /*
     * -------------------------------------------------------------------------
     * Life cycle functions
     * -------------------------------------------------------------------------
     */

    /**
     * Map initialisation handler.
     * @return void
     */
    void MapInit()
    {
        // g_Module.ScriptInfo.SetAuthor("Adam \"Adambean\" Reece");
        // g_Module.ScriptInfo.SetContactInfo("www.reece.wales");
    }

    /**
     * Map activation handler.
     * @return void
     */
    void MapActivate()
    {
        @g_pInstance = MapPart();

        if (!g_pInstance.Initialise()) {
            g_Game.AlertMessage(at_error, "[Ragemap 2023] Adambean's part encountered errors initialising.\n");

            @g_pInstance = null;
            g_EntityFuncs.FireTargets(ENT_PREFIX + "start_mm", null, null, USE_KILL);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "start_ok", null, null, USE_KILL);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "start_spr", null, null, USE_KILL);
            return;
        }

        g_Game.AlertMessage(g_uiAlertType, "[Ragemap 2023] Adambean's part ready.\n");
        g_EntityFuncs.FireTargets(ENT_PREFIX + "start_ok", null, null, USE_TOGGLE);
    }



    /**
     * Adambean's map part game play class.
     */
    final class MapPart
    {
        /*
         * -------------------------------------------------------------------------
         * Variables
         * -------------------------------------------------------------------------
         */

        /** @var bool m_fChasing The chase is on! */
        bool m_fChasing;

        /** @var EHandle[] m_hSpawnPointsLobby Spawn points at the lobby. (info_player_deathmatch) */
        array<EHandle> m_hSpawnPointsLobby;

        /** @var EHandle[] m_hSpawnPointsInChase Spawn points in the chase. (info_player_deathmatch) */
        array<EHandle> m_hSpawnPointsInChase;

        /** @var EHandle[] m_hSpawnPointsSpectator Spawn points spectating. (info_player_deathmatch) */
        array<EHandle> m_hSpawnPointsSpectator;

        /** @var EHandle[] m_hSpawnPointsEnd Spawn points for the end. (info_player_deathmatch) */
        array<EHandle> m_hSpawnPointsEnd;

        /** @var EHandle m_hChaseZone Player chase zone entity. (game_zone_player) */
        EHandle m_hChaseZone;

        /** @var EHandle m_hSaltShaker Salt shaker entity. (item_generic) */
        EHandle m_hSaltShaker;

        /** @var EHandle m_hPlayerCameraTmpl Player camera template entity. (trigger_camera) */
        EHandle m_hPlayerCameraTmpl;

        /** @var EHandle[] m_hPlayerCameras Player camera entities. (trigger_camera) */
        array<EHandle> m_hPlayerCameras;

        /** @var EHandle[] m_hEscapedPlayers List of escaped players. */
        array<EHandle> m_hEscapedPlayers;

        /** @var bool m_fCvarMpDisableAutoclimb Original value of CVAR "mp_disable_autoclimb". */
        bool m_fCvarMpDisableAutoclimb;

        /** @var float m_flCvarSvAiraccelerate Original value of CVAR "sv_airaccelerate". */
        float m_flCvarSvAiraccelerate;



        /*
         * -------------------------------------------------------------------------
         * Life cycle functions
         * -------------------------------------------------------------------------
         */

        /**
         * Constructor.
         */
        MapPart()
        {
            m_fChasing                  = false;
            m_fCvarMpDisableAutoclimb   = g_EngineFuncs.CVarGetFloat("mp_disable_autoclimb") >= 1.0f ? true : false;
            m_flCvarSvAiraccelerate     = g_EngineFuncs.CVarGetFloat("sv_airaccelerate");
        }



        /*
         * -------------------------------------------------------------------------
         * Helper functions
         * -------------------------------------------------------------------------
         */

        /**
         * Change player spawn point.
         * @return void
         */
        void ChangePlayerSpawnPoint(string szName)
        {
            for (uint i = 0; i < m_hSpawnPointsLobby.length(); i++) {
                if (m_hSpawnPointsLobby[i].IsValid()) {
                    m_hSpawnPointsLobby[i].GetEntity().Use(null, null, szName == "lobby" ? USE_ON : USE_OFF);
                }
            }

            for (uint i = 0; i < m_hSpawnPointsInChase.length(); i++) {
                if (m_hSpawnPointsInChase[i].IsValid()) {
                    m_hSpawnPointsInChase[i].GetEntity().Use(null, null, szName == "chase" ? USE_ON : USE_OFF);
                }
            }

            for (uint i = 0; i < m_hSpawnPointsSpectator.length(); i++) {
                if (m_hSpawnPointsSpectator[i].IsValid()) {
                    m_hSpawnPointsSpectator[i].GetEntity().Use(null, null, szName == "spectator" ? USE_ON : USE_OFF);
                }
            }

            for (uint i = 0; i < m_hSpawnPointsEnd.length(); i++) {
                if (m_hSpawnPointsEnd[i].IsValid()) {
                    m_hSpawnPointsEnd[i].GetEntity().Use(null, null, szName == "end" ? USE_ON : USE_OFF);
                }
            }
        }

        /**
         * Respawn players outside the chase zone.
         * @return void
         */
        void RespawnPlayersOutsideChaseZone()
        {
            if (!m_hChaseZone.IsValid()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->RespawnPlayersOutsideChaseZone(): Player chase zone entity not found.\n");
                return;
            }

            for (int i = 1; i <= g_Engine.maxClients; i++) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                    continue;
                }

                if (pPlayer.IsAlive() && g_Utility.IsPlayerInVolume(pPlayer, m_hChaseZone.GetEntity())) {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->RespawnPlayersOutsideChaseZone(): Skipping player \"%1\".\n", g_Utility.GetPlayerLog(pPlayer.edict()));
                } else {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->RespawnPlayersOutsideChaseZone(): Respawning player \"%1\".\n", g_Utility.GetPlayerLog(pPlayer.edict()));

                    pPlayer.Respawn();
                    g_EntityFuncs.FireTargets(ENT_PREFIX + "respawn_one", pPlayer, null, USE_TOGGLE);
                    g_EntityFuncs.FireTargets(ENT_PREFIX + "weaponstrip_one", pPlayer, null, USE_TOGGLE);
                }
            }
        }

        /**
         * Make a player solid again. (Only needed for SC version <= 5.25)
         * @param  CBasePlayer@ pPlayer Player entity
         * @return void
         */
        void MakePlayerSolidAgain(CBasePlayer@ pPlayer)
        {
            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                return;
            }

            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->MakePlayerSolidAgain(): Making player \"%1\" solid again.\n", g_Utility.GetPlayerLog(pPlayer.edict()));

            pPlayer.pev.solid = SOLID_SLIDEBOX;
            // g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You are now back to being solid.\n");
        }

        /**
         * Get a camera entity handle for a player.
         * @param  CBasePlayer@ pPlayer Player entity
         * @return EHandle              Entity handle to a "trigger_camera", or to nothing if not found
         */
        EHandle GetCameraForPlayer(CBasePlayer@ pPlayer)
        {
            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                return EHandle(null);
            }

            uint uiPlayer = g_EntityFuncs.EntIndex(pPlayer.edict());
            if (m_hPlayerCameras.length() < uiPlayer) {
                return EHandle(null);
            }

            return m_hPlayerCameras[uiPlayer - 1];
        }



        /*
         * -------------------------------------------------------------------------
         * Functions
         * -------------------------------------------------------------------------
         */

        /**
         * Initialise.
         * @return bool Success
         */
        bool Initialise()
        {
            uint uiErrors = 0;
            CBaseEntity@ pEntity;



            // Find spawn points at the lobby
            @pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "spawn_adambean")) !is null) {
                m_hSpawnPointsLobby.insertLast(EHandle(pEntity));
            }

            if (m_hSpawnPointsLobby.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Spawn point entities \"%1\" not found.\n", "spawn_adambean");
                ++uiErrors;
            }

            // Find spawn points in the chase
            @pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "spawn_adambean_in_chase")) !is null) {
                m_hSpawnPointsInChase.insertLast(EHandle(pEntity));
            }

            if (m_hSpawnPointsInChase.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Spawn point entities \"%1\" not found.\n", "spawn_adambean_in_chase");
                ++uiErrors;
            }

            // Find spawn points spectating
            @pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "spawn_adambean_spectator")) !is null) {
                m_hSpawnPointsSpectator.insertLast(EHandle(pEntity));
            }

            if (m_hSpawnPointsSpectator.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Spawn point entities \"%1\" not found.\n", "spawn_adambean_spectator");
                ++uiErrors;
            }

            // Find spawn points for the end
            @pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "spawn_adambean_end")) !is null) {
                m_hSpawnPointsEnd.insertLast(EHandle(pEntity));
            }

            if (m_hSpawnPointsEnd.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Spawn point entities \"%1\" not found.\n", "spawn_adambean_end");
                ++uiErrors;
            }

            // Find player chase zone entity
            @pEntity = null;
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, ENT_PREFIX + "in_chase_zone")) !is null) {
                m_hChaseZone = EHandle(pEntity);
            } else {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Player chase zone entity \"%1\" not found.\n", ENT_PREFIX + "in_chase_zone");
                ++uiErrors;
            }

            // Find salt shaker entity
            @pEntity = null;
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, ENT_PREFIX + "salt_shaker")) !is null) {
                m_hSaltShaker = EHandle(pEntity);
            } else {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Salt shaker entity \"%1\" not found.\n", ENT_PREFIX + "salt_shaker");
                ++uiErrors;
            }



            // << Player cameras
            // Find player camera template entity
            @pEntity = null;
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, ENT_PLAYER_CAMERA_PREFIX + "_tmpl")) is null) {
                g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Player camera template entity \"%1\" not found.\n", ENT_PLAYER_CAMERA_PREFIX + "_tmpl");
                ++uiErrors;
            }
            m_hPlayerCameraTmpl = EHandle(pEntity);

            // Create player cameras
            for (int i = 1; i <= g_Engine.maxClients; i++) {
                string szPlayerCamera = ENT_PLAYER_CAMERA_PREFIX + formatUInt(i);

                CBaseEntity@ pPlayerCamera;
                if ((@pPlayerCamera = g_EntityFuncs.FindEntityByTargetname(null, szPlayerCamera)) is null) {
                    dictionary oPlayerCamera = {
                        {"origin",              formatFloat(m_hPlayerCameraTmpl.GetEntity().pev.origin.x) + " " + formatFloat(m_hPlayerCameraTmpl.GetEntity().pev.origin.y) + " " + formatFloat(m_hPlayerCameraTmpl.GetEntity().pev.origin.z)},
                        {"angles",              formatFloat(m_hPlayerCameraTmpl.GetEntity().pev.angles.x) + " " + formatFloat(m_hPlayerCameraTmpl.GetEntity().pev.angles.y) + " " + formatFloat(m_hPlayerCameraTmpl.GetEntity().pev.angles.z)},
                        {"max_player_count",    formatUInt(1)},
                        {"spawnflags",          formatUInt(m_hPlayerCameraTmpl.GetEntity().pev.spawnflags)}
                    };
                    @pPlayerCamera = g_EntityFuncs.CreateEntity("trigger_camera", oPlayerCamera);

                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->Initialise(): Player camera %1 entity created.\n", i);
                }

                if (pPlayerCamera is null) {
                    g_Game.AlertMessage(at_error, "Ragemap2023Adambean::MapPart->Initialise(): Player camera %1 entity could not be created.\n", i);
                    ++uiErrors;
                    continue;
                }

                m_hPlayerCameras.insertLast(EHandle(pPlayerCamera));
            }
            // >> Player cameras



            return (0 == uiErrors);
        }

        /**
         * Reset the chase.
         * @return void
         */
        void ResetChase()
        {
            if (m_fChasing) {
                // Currently a chase, it needs to end first
                g_EntityFuncs.FireTargets(ENT_PREFIX + "end_chase_mm", null, null, USE_TOGGLE);
                return;
            }

            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->ResetChase(): Resetting chase.\n");

            // Spawn points: Change to lobby
            ChangePlayerSpawnPoint("lobby");

            // Player stuffs
            for (int i = 1; i <= g_Engine.maxClients; i++) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                    continue;
                }

                // Reset escaped status
                pPlayer.pev.targetname = "";

                // Reset basic properties
                pPlayer.pev.movetype    = MOVETYPE_WALK;
                pPlayer.pev.solid       = SOLID_SLIDEBOX;
                pPlayer.pev.takedamage  = DAMAGE_AIM;

                // Reset collision with other players
                if (g_Game.GetGameVersion() >= 526) {
                    // Good method (SC 5.26+ only)
                    pPlayer.pev.iuser4 = 0;
                } else {
                    // Crap method (SC < 5.26 only)
                    pPlayer.pev.solid = SOLID_SLIDEBOX;
                }
            }

            // Forget all escaped players
            while (m_hEscapedPlayers.length() >= 1) {
                m_hEscapedPlayers.removeAt(0);
            }

            // Respawn everyone
            g_EntityFuncs.FireTargets(ENT_PREFIX + "respawn_all", null, null, USE_TOGGLE);

            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->ResetChase(): The chase has been reset.\n");
        }

        /**
         * Start the chase.
         * @return void
         */
        void StartChase()
        {
            if (m_fChasing) {
                return; // Already chasing
            }
            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->StartChase(): Starting chase.\n");

            m_fChasing = true;
            g_EngineFuncs.CVarSetFloat("mp_disable_autoclimb", 0.0f);
            g_EngineFuncs.CVarSetFloat("sv_airaccelerate", 1.0f);

            // Spawn points: Change to chase zone
            ChangePlayerSpawnPoint("chase");

            // Map stuffs
            g_EntityFuncs.FireTargets(ENT_PREFIX + "spr",                   null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "light_lobby_spr",       null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "music",                 null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "chase_playerclip",      null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "setorigin_on",          null, null, USE_TOGGLE);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "light_spr",             null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "fall_hurt",             null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "room5_oil_hurt",        null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "room6_freezer_hurt",    null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "ets_spr_mm",            null, null, USE_ON);

            // Spawn an appropriate amount of monsters
            CBaseEntity@ pMonsterSpawner;
            float flMonsterCount = Math.Ceil(g_PlayerFuncs.GetNumPlayers() / 4);
            if ((@pMonsterSpawner = g_EntityFuncs.FindEntityByTargetname(pMonsterSpawner, ENT_PREFIX + "monster_spawn")) is null) {
                pMonsterSpawner.KeyValue("monstercount", formatFloat(flMonsterCount));
            }
            g_EntityFuncs.FireTargets(ENT_PREFIX + "monster_spawn", null, null, USE_ON);

            // Wake up those sleepy stukabats on the ceiling
            g_EntityFuncs.FireTargets(ENT_PREFIX + "stukabat_wake", null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "stukabat_wake", null, null, USE_OFF);

            // Respawn everyone not in the chase zone
            RespawnPlayersOutsideChaseZone();

            // Player stuffs
            for (int i = 1; i <= g_Engine.maxClients; i++) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                    continue;
                }

                // Reset escaped status
                pPlayer.pev.targetname = "";

                // Prevent collision with other players
                if (g_Game.GetGameVersion() >= 526) {
                    // Good method (SC 5.26+ only)
                    pPlayer.pev.iuser4 = 1;
                } else {
                    // Crap method (SC < 5.26 only)
                    pPlayer.pev.solid = SOLID_NOT;

                    float flSolidReset = Math.RandomFloat(1.0f, 2.0f);
                    /*
                    string szSolidResetMsg;
                    snprintf(szSolidResetMsg, "You are non-solid now for %1 seconds.\n", formatFloat(flSolidReset));
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, szSolidResetMsg);
                    */
                    g_Scheduler.SetTimeout(this, "MakePlayerSolidAgain", flSolidReset, @pPlayer);
                }

                // Get player camera
                EHandle hPlayerCamera = GetCameraForPlayer(pPlayer);
                if (hPlayerCamera.IsValid()) {
                    // Turn on camera
                    hPlayerCamera.GetEntity().Use(pPlayer, null, USE_ON, 0.0f);
                }
            }

            // Spawn points: Change to spectator zone
            ChangePlayerSpawnPoint("spectator");

            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->StartChase(): The chase is on!\n");
        }

        /**
         * End the chase.
         * @return void
         */
        void EndChase()
        {
            if (!m_fChasing) {
                return; // Not chasing
            }
            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->EndChase(): Ending chase.\n");

            m_fChasing = false;
            g_EngineFuncs.CVarSetFloat("mp_disable_autoclimb", m_fCvarMpDisableAutoclimb ? 1.0f : 0.0f);
            g_EngineFuncs.CVarSetFloat("sv_airaccelerate", m_flCvarSvAiraccelerate);

            // Spawn points: Change to end
            ChangePlayerSpawnPoint("end");

            // Map stuffs
            g_EntityFuncs.FireTargets(ENT_PREFIX + "spr",                   null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "light_lobby_spr",       null, null, USE_ON);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "music",                 null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "chase_playerclip",      null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "setorigin_off",         null, null, USE_TOGGLE);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "light_spr",             null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "fall_hurt",             null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "room5_oil_hurt",        null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "room6_freezer_hurt",    null, null, USE_OFF);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "monster_spawn",         null, null, USE_OFF);

            // For math stuff later
            uint uiPlayers = uint(g_PlayerFuncs.GetNumPlayers());
            uint uiEscaped = m_hEscapedPlayers.length();

            // Player stuffs
            for (int i = 1; i <= g_Engine.maxClients; i++) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                    continue;
                }

                // Mark anyone not escaped as caught
                string szPlayerTargetname = pPlayer.pev.targetname;
                if (szPlayerTargetname.IsEmpty()) {
                    pPlayer.pev.targetname = ENT_PREFIX + "player_caught";
                }

                // Reset basic properties
                pPlayer.pev.movetype    = MOVETYPE_WALK;
                pPlayer.pev.solid       = SOLID_SLIDEBOX;
                pPlayer.pev.takedamage  = DAMAGE_AIM;

                // Reset collision with other players
                if (g_Game.GetGameVersion() >= 526) {
                    // Good method (SC 5.26+ only)
                    pPlayer.pev.iuser4 = 0;
                } else {
                    // Crap method (SC < 5.26 only)
                    pPlayer.pev.solid = SOLID_SLIDEBOX;
                }

                // Get player camera
                EHandle hPlayerCamera = GetCameraForPlayer(pPlayer);
                if (hPlayerCamera.IsValid()) {
                    // Turn off camera
                    hPlayerCamera.GetEntity().Use(pPlayer, null, USE_OFF, 0.0f);
                }
            }

            // Reward escaped players and spare them a deep salty burial
            if (uiEscaped >= 1) {
                for (uint i = 0; i < uiEscaped; i++) {
                    CBasePlayer@ pPlayer = cast<CBasePlayer>(m_hEscapedPlayers[i].GetEntity());
                    if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                        continue;
                    }

                    pPlayer.pev.targetname = ENT_PREFIX + "player_escaped";
                    pPlayer.pev.frags += 1995; // Earthworm Jim II <3
                }
            }

            // Play the salt silo scene if we have at least one player caught
            if (uiEscaped < uiPlayers) {
                g_EntityFuncs.FireTargets(ENT_PREFIX + "silo_mm", null, null, USE_TOGGLE);
            }

            // Special messages if at least two players were present
            if (uiPlayers >= 2) {
                if (uiEscaped < 1) {
                    // What a blunder
                    g_EntityFuncs.FireTargets(ENT_PREFIX + "all_caught_mm", null, null, USE_TOGGLE);
                } else if (uiEscaped == uiPlayers) {
                    // haha really?
                    g_EntityFuncs.FireTargets(ENT_PREFIX + "all_escaped_mm", null, null, USE_TOGGLE);
                }
            }

            // Respawn everyone
            g_EntityFuncs.FireTargets(ENT_PREFIX + "respawn_all", null, null, USE_TOGGLE);

            // Remove NPCs
            g_EntityFuncs.FireTargets(ENT_PREFIX + "npc*", null, null, USE_KILL);

            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023Adambean::MapPart->EndChase(): The chase is over!\n");
        }

        /**
         * Run the chase.
         * @return void
         */
        void RunChase()
        {
            if (!m_fChasing) {
                return; // Not chasing
            }

            // << Players
            uint uiPlayersInChase = 0;

            for (int i = 1; i <= g_Engine.maxClients; i++) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                    continue;
                }

                bool fIsInChase = g_Utility.IsPlayerInVolume(pPlayer, m_hChaseZone.GetEntity());

                // Prevent collision with other players
                if (g_Game.GetGameVersion() >= 526) {
                    // Good method (SC 5.26+ only)
                    pPlayer.pev.iuser4 = 1;
                } else if (!fIsInChase) {
                    // Crap method (SC < 5.26 only), only for spectators
                    pPlayer.pev.solid = SOLID_NOT;
                }

                if (!fIsInChase) {
                    continue;
                }
                ++uiPlayersInChase;

                // Get player camera
                EHandle hPlayerCamera = GetCameraForPlayer(pPlayer);

                // Respawn player if they've died
                if (!pPlayer.IsAlive()) {
                    // Turn off camera
                    if (hPlayerCamera.IsValid()) {
                        hPlayerCamera.GetEntity().Use(pPlayer, null, USE_OFF, 0.0f);
                    }

                    // Respawn player
                    pPlayer.Respawn();
                    pPlayer.pev.targetname = ENT_PREFIX + "player_caught";
                    g_EntityFuncs.FireTargets(ENT_PREFIX + "respawn_one", pPlayer, null, USE_TOGGLE);
                    g_EntityFuncs.FireTargets(ENT_PREFIX + "weaponstrip_one", pPlayer, null, USE_TOGGLE);
                    continue;
                }

                if (hPlayerCamera.IsValid()) {
                    // Turn on camera
                    hPlayerCamera.GetEntity().Use(pPlayer, null, USE_ON, 0.0f);

                    // Update player camera position
                    g_EntityFuncs.SetOrigin(hPlayerCamera.GetEntity(), Vector(
                        pPlayer.pev.origin.x,
                        m_hPlayerCameraTmpl.GetEntity().pev.origin.y,
                        pPlayer.pev.origin.z + 48.0f
                    ));
                }

                // << Handle player side-view movements
                if (
                    pPlayer.pev.movetype == MOVETYPE_WALK
                    && (
                        (pPlayer.pev.button & IN_FORWARD) != 0
                        || (pPlayer.pev.button & IN_BACK) != 0
                        || (pPlayer.pev.button & IN_MOVERIGHT) != 0
                        || (pPlayer.pev.button & IN_MOVELEFT) != 0
                    )
                ) {
                    bool fOnGround      = pPlayer.pev.FlagBitSet(FL_ONGROUND);
                    float flMaxSpeed    = ((pPlayer.pev.button & IN_DUCK) != 0 || (pPlayer.pev.button & IN_RUN) != 0) ? 80.0f : 200.0f;
                    float flAccel       = (fOnGround ? 60.0f : 10.0f);
                    float flStrafeComp  = (fOnGround ? 16.2f : 8.1f);

                    if ((pPlayer.pev.button & IN_FORWARD) != 0) {
                        // Moving north
                        pPlayer.pev.angles.y    = 90.0f;
                        pPlayer.pev.velocity.y  = Math.min(flMaxSpeed, pPlayer.pev.velocity.y + flAccel);
                        pPlayer.pev.velocity.x  = Math.max(0.0f, pPlayer.pev.velocity.x - flAccel);
                    } else if ((pPlayer.pev.button & IN_BACK) != 0) {
                        // Moving south
                        pPlayer.pev.angles.y    = 270.0f;
                        pPlayer.pev.velocity.y  = -Math.min(flMaxSpeed, -pPlayer.pev.velocity.y + flAccel);
                        pPlayer.pev.velocity.x  = Math.max(0.0f, pPlayer.pev.velocity.x - flAccel);
                    } else if ((pPlayer.pev.button & IN_MOVERIGHT) != 0) {
                        // Moving east
                        pPlayer.pev.angles.y    = 0.0f;
                        pPlayer.pev.velocity.x  = Math.min(flMaxSpeed, pPlayer.pev.velocity.x + flAccel);
                        pPlayer.pev.velocity.y  = Math.max(0.0f, pPlayer.pev.velocity.y - flAccel) + flStrafeComp;
                    } else if ((pPlayer.pev.button & IN_MOVELEFT) != 0) {
                        // Moving west
                        pPlayer.pev.angles.y    = 180.0f;
                        pPlayer.pev.velocity.x  = -Math.min(flMaxSpeed, -pPlayer.pev.velocity.x + flAccel);
                        pPlayer.pev.velocity.y  = Math.max(0.0f, pPlayer.pev.velocity.y - flAccel) + flStrafeComp;
                    }

                    pPlayer.pev.fixangle = FAM_FORCEVIEWANGLES;
                }
                // >> Handle player side-view movements
            }
            // >> Players

            // Anyone left in the chase?
            if (uiPlayersInChase < 1) {
                g_EntityFuncs.FireTargets(ENT_PREFIX + "end_chase_mm", null, null, USE_TOGGLE);
                return;
            }
        }

        /**
         * A player has escaped from the chase.
         * @param  CBasePlayer@ pPlayer Player entity
         * @return void
         */
        void EscapedChase(CBasePlayer@ pPlayer)
        {
            if (!m_fChasing) {
                return; // Not chasing
            }

            if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
                return;
            }

            // Record player as escaped
            m_hEscapedPlayers.insertLast(EHandle(pPlayer));

            // Get player camera
            EHandle hPlayerCamera = GetCameraForPlayer(pPlayer);
            if (hPlayerCamera.IsValid()) {
                // Turn off camera
                hPlayerCamera.GetEntity().Use(pPlayer, null, USE_OFF, 0.0f);
            }

            // Respawn player
            pPlayer.Respawn();
            g_EntityFuncs.FireTargets(ENT_PREFIX + "respawn_one", pPlayer, null, USE_TOGGLE);
            g_EntityFuncs.FireTargets(ENT_PREFIX + "weaponstrip_one", pPlayer, null, USE_TOGGLE);
        }
    }

    MapPart@ g_pInstance;



    /*
     * -------------------------------------------------------------------------
     * Map hooks
     * -------------------------------------------------------------------------
     */

    /**
     * Map hook: Reset the chase.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void ResetChase(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.ResetChase();
    }

    /**
     * Map hook: Start the chase.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void StartChase(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.StartChase();
    }

    /**
     * Map hook: End the chase.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void EndChase(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.EndChase();
    }

    /**
     * Map hook: Run the chase.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @return void
     */
    void RunChase(CBaseEntity@ pActivator)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.RunChase();
    }

    /**
     * Map hook: A player has escaped from the chase.
     * @param  CBaseEntity@|null pActivator Activator entity
     * @param  CBaseEntity@|null pCaller    Caller entity
     * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
     * @param  float             flValue    Use value, or unspecified to assume `0.0f`
     * @return void
     */
    void EscapedChase(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        if (pActivator is null) {
            return;
        }

        if (!pActivator.IsPlayer()) {
            return;
        }

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);
        if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
            return;
        }

        g_pInstance.EscapedChase(pPlayer);
    }
}

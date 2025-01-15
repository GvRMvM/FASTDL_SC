/*======================================*/
/*==== Ragemap 2023 Script - v 1.00 ====*/
/*======================================*/



/*
 * -------------------------------------------------------------------------
 * Includes
 * -------------------------------------------------------------------------
 */

#include "CustomHUD"
#include "weapon_custom/v9/weapon_custom"



namespace Ragemap2023
{
    /*
     * -------------------------------------------------------------------------
     * Constants & enumerators
     * -------------------------------------------------------------------------
     */

    /** @var bool Enable debug messages printed to console, and enable '/part mappername' and '/skip' chat commands for non-admins. */
    const bool DEBUG_MODE = false;

    /** @var bool Play parts in a random order. */
    const bool RANDOM_PART_ORDER = true;

    /** @var float Vote to skip part: Duration of vote. */
    const float VOTE_SKIP_DURAITON = 20.0f;

    /** @var float Vote to skip part: Percentage required to pass. */
    const float VOTE_SKIP_PASS_PERCENTAGE = 66.66667f;

    /** @var float Vote to skip part: Delay until next vote allowed. */
    const float VOTE_SKIP_DELAY = 300.0f;

    /** @var string Entity suffix for a mapper's boot entity. */
    const string MAPPER_BOOT_ENT_SUFFIX = "_boot";

    /** @var string Entity suffix for a mapper's shutdown entity. */
    const string MAPPER_SHUTDOWN_ENT_SUFFIX = "_shutdown";

    /** @var string Entity prefix for a mapper's spawn point(s). */
    const string MAPPER_SPAWN_ENT_PREFIX = "spawn_";

    /** @var string Item group name for hat item_inventory entities. */
    const string HAT_ITEM_GROUP = "ragehats";



    /*
    * -------------------------------------------------------------------------
    * Globals
    * -------------------------------------------------------------------------
    */

    /** @global ALERT_TYPE g_uiAlertType Alert mode to use for debugging messages. */
    ALERT_TYPE g_uiAlertType = DEBUG_MODE ? at_console : at_aiconsole;

    /** @global string[] g_szMaps Maps, expected to be prefixed with "ragemap2023". */
    array<string> g_szMaps = {"a", "b", "c", "d"};

    /**
     * @global string[] g_a_szMappers
     * These are the mapper's names if the script needs to print it on screen or something.
     * @see g_szMaps Indexed by map. (0 = A, 1 = B, ...)
     */
    array<array<string>> g_a_szMappers = {
        {
            // Map A
            "Hezus",
            "Nih",
            // "Unused block 3",
            "Erty",
            "Outerbeast",
            "Adambean",
        },
        {
            // Map B
            "I_ka",
            // "Unused block 2",
            "kezaeiv",
            "AlexCorruptor",
            "eyeling",
            // "Unused block 6",
        },
        {
            // Map C
            // "Unused block 1",
            "Dex",
            "Giegue",
            "SEACAT08",
            "Boss/Ending",
            "Levi",
        }
    };

    /**
     * @global string[][] g_a_szMapperTags
     * A more simple version of the mappers's name, in case they have special characters in them.
     * These should be used in all mapper related entity names.
     * @see g_szMaps Indexed by map. (0 = A, 1 = B, ...)
     */
    array<array<string>> g_a_szMapperTags = {
        {
            // Map A
            "hezus",
            "nih",
            // "block3",
            "erty",
            "outerbeast",
            "adambean",
        },
        {
            // Map B
            "ika",
            // "block2",
            "alexc",
            "kezaeiv",
            "eyeling",
            // "block6",
        },
        {
            // Map C
            // "block1",
            "dex",
            "giegue",
            "seacat08",
            "boss",
            "levi",
        },
    };



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
        // Precache mapper HUD icons
        g_Game.PrecacheModel("sprites/ragemap2023/ragemap2023.spr");
        g_Game.PrecacheModel("sprites/ragemap2023/channelicon_intro.spr");
        g_Game.PrecacheModel("sprites/ragemap2023/channelicon_outro.spr");
        for (uint uiMap = 0; uiMap < g_a_szMapperTags.length(); uiMap++) {
            for (uint uiMapperTag = 0; uiMapperTag < g_a_szMapperTags[uiMap].length(); uiMapperTag++) {
                if (g_a_szMapperTags[uiMap][uiMapperTag].IsEmpty()) {
                    continue;
                }

                g_Game.PrecacheModel("sprites/ragemap2023/channelicon_" + g_a_szMapperTags[uiMap][uiMapperTag] + ".spr");
            }
        }

        // Custom weapons
        WeaponCustomMapInit();
    }

    /**
    * Map activation handler.
    * @return void
    */
    void MapActivate()
    {
        // Initialise map
        @g_pMap = Map();
        if (!g_pMap.Initialise()) {
            g_Game.AlertMessage(at_error, "[Ragemap 2023] Map encountered errors initialising.\n");
            @g_pMap = null;
            return;
        }
        g_Game.AlertMessage(g_uiAlertType, "[Ragemap 2023] Map ready.\n");

        // Register hooks
        g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @Ragemap2023::UpdateHudHook);
        g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @Ragemap2023::UpdateHudHook);
        g_Hooks.RegisterHook(Hooks::Player::ClientSay, @Ragemap2023::ClientSay);

        // Begin first part
        g_pMap.MoveToPart();

        // Custom weapons
        WeaponCustomMapActivate();
    }



    /**
     * Ragemap 2023
     */
    final class Map
    {
        /*
        * -------------------------------------------------------------------------
        * Variables
        * -------------------------------------------------------------------------
        */

        /** @var string[] m_a_szMappers Mapper names for this map. */
        array<string> m_a_szMappers;

        /** @var string[] m_a_szMappers Mapper tags for this map. */
        array<string> m_a_szMapperTags;

        /** @var uint[] m_a_uiPartOrder Order of parts. */
        array<uint> m_a_uiPartOrder;

        /** @var int m_iPartActive Current part active by part order. */
        int m_iPartActive = -1;

        /** @var uint m_uiPartTransitionTimer Current part active. */
        uint m_uiPartTransitionTimer = 0;

        /** @var HUDTextParams m_sTransitionHudTextParams Transition HUD text parameters. */
        HUDTextParams m_sTransitionHudTextParams;

        /** @var Vote@ m_pVoteSkip Vote to skip the current map part. */
        Vote@ m_pVoteSkip;

        /** @var float m_flVoteSkipTime The time a vote to skip a part was last run. */
        float m_flVoteSkipTime = -1.0;



        /*
         * -------------------------------------------------------------------------
         * Life cycle functions
         * -------------------------------------------------------------------------
         */

        /**
         * Constructor.
         */
        Map()
        {
            m_uiPartTransitionTimer = 0;

            m_sTransitionHudTextParams.x            = -1;
            m_sTransitionHudTextParams.y            = 0.8;
            m_sTransitionHudTextParams.effect       = 0;
            m_sTransitionHudTextParams.r1           = 255;
            m_sTransitionHudTextParams.g1           = 255;
            m_sTransitionHudTextParams.b1           = 255;
            m_sTransitionHudTextParams.a1           = 0;
            m_sTransitionHudTextParams.r2           = 255;
            m_sTransitionHudTextParams.g2           = 255;
            m_sTransitionHudTextParams.b2           = 255;
            m_sTransitionHudTextParams.a2           = 0;
            m_sTransitionHudTextParams.fadeinTime   = 0;
            m_sTransitionHudTextParams.fadeoutTime  = 1;
            m_sTransitionHudTextParams.holdTime     = 1;
            m_sTransitionHudTextParams.fxTime       = 0;
            m_sTransitionHudTextParams.channel      = 3;

            @m_pVoteSkip = Vote("ragemap2023VoteSkip", "Skip this part of the map?", VOTE_SKIP_DURAITON, VOTE_SKIP_PASS_PERCENTAGE);
            m_pVoteSkip.SetVoteBlockedCallback(@Ragemap2023::VoteSkipBlocked);
            m_pVoteSkip.SetVoteEndCallback(@Ragemap2023::VoteSkipEnd);
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
            // Which map are we running?
            int iMapNumber = GetMapNumber();
            if (iMapNumber < 0) {
                g_Game.AlertMessage(at_error, "Ragemap2023::Map->Initialise(): Map number invalid.\n");
                return false;
            }

            // Build mapper name and tag lists
            m_a_szMappers.insertLast("Intro");
            m_a_szMapperTags.insertLast("intro");
            for (uint i = 0; i < g_a_szMappers[iMapNumber].length(); i++) {
                if (g_a_szMappers[iMapNumber][i].IsEmpty() || g_a_szMapperTags[iMapNumber][i].IsEmpty()) {
                    continue;
                }

                // Do not include mapper parts without a spawn point
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->Initialise(): Looking for spawn point named \"%1\"...\n", MAPPER_SPAWN_ENT_PREFIX + g_a_szMapperTags[iMapNumber][i]);
                CBaseEntity@ eMapperSpawnPoint = g_EntityFuncs.FindEntityByTargetname(null, MAPPER_SPAWN_ENT_PREFIX + g_a_szMapperTags[iMapNumber][i]);
                if (eMapperSpawnPoint is null) {
                    g_Game.AlertMessage(at_warning, "Ragemap2023::Map->Initialise(): Excluding part for %1, no spawn points found.\n", g_a_szMappers[iMapNumber][i]);
                    continue;
                }

                m_a_szMappers.insertLast(g_a_szMappers[iMapNumber][i]);
                m_a_szMapperTags.insertLast(g_a_szMapperTags[iMapNumber][i]);
            }
            m_a_szMappers.insertLast("Outro");
            m_a_szMapperTags.insertLast("outro");

            if (m_a_szMappers.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023::Map->Initialise(): Mapper names empty.\n");
                return false;
            }

            if (m_a_szMapperTags.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023::Map->Initialise(): Mapper tags empty.\n");
                return false;
            }

            if (m_a_szMappers.length() != m_a_szMapperTags.length()) {
                g_Game.AlertMessage(at_error, "Ragemap2023::Map->Initialise(): Mapper names count doesn't match mapper tags count.\n");
                return false;
            }

            if (m_a_szMapperTags.length() >= 3) {
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->Initialise(): Mappers are");
                for (uint i = 1; i < m_a_szMapperTags.length() - 1; i++) {
                    g_Game.AlertMessage(g_uiAlertType, " %1", m_a_szMapperTags[i]);
                }
                g_Game.AlertMessage(g_uiAlertType, "\n");
            } else {
                g_Game.AlertMessage(at_warning, "Ragemap2023::Map->Initialise(): No mapper sections found.\n");
            }

            // Disable all spawn points in the whole map
            CBaseEntity@ eSpawnPoint = null;
            while ((@eSpawnPoint = g_EntityFuncs.FindEntityByClassname(eSpawnPoint, "info_player_deathmatch")) !is null) {
                eSpawnPoint.Use(null, null, USE_OFF);
            }

            // Generate part order
            GeneratePartOrder();
            // SetupMapTransitions();

            return true;
        }

        /**
         * Get a number for the map we're running.
         * @return int Part number (0 = A, 1 = B, ...)
         */
        int GetMapNumber()
        {
            string szCurrentMap = g_Engine.mapname;

            if (!szCurrentMap.StartsWith("ragemap2023") || szCurrentMap.Length() < 12) {
                return -1; // Not Ragemap 2023
            }

            int iMapNumber = -1;
            if (szCurrentMap.SubString(11, 1) == "_" && szCurrentMap.Length() >= 13) {
                // Determine map number by the mapper's name and tag, e.g. for "ragemap2023_Adambean" search for "Adambean"
                for (uint i = 0; i < g_a_szMappers.length(); i++) {
                    for (uint j = 0; j < g_a_szMappers[i].length(); j++) {
                        if (szCurrentMap.SubString(12) == g_a_szMappers[i][j]) {
                            iMapNumber = i;
                            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->GetMapNumber(): Assuming map number %1 by mapper name \"%2\".\n", (iMapNumber + 1), g_a_szMappers[i][j]);
                            break;
                        }

                        if (szCurrentMap.SubString(12) == g_a_szMapperTags[i][j]) {
                            iMapNumber = i;
                            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->GetMapNumber(): Assuming map number %1 by mapper tag \"%2\".\n", (iMapNumber + 1), g_a_szMapperTags[i][j]);
                            break;
                        }
                    }
                }
            } else {
                // Determine map number by it's letter, e.g. "ragemap2023a" would be "a"
                iMapNumber = g_szMaps.find(szCurrentMap.SubString(11, 1));
                if (iMapNumber >= 0) {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->GetMapNumber(): Detected map number %1.\n", (iMapNumber + 1));
                }
            }

            return iMapNumber;
        }

        /**
         * Generate map part ordering.
         * @return void
         */
        void GeneratePartOrder()
        {
            if (RANDOM_PART_ORDER) {
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->GeneratePartOrder(): Generating random part order...\n");

                while (m_a_uiPartOrder.length() < m_a_szMappers.length() - 2) {
                    uint uiNextPart = Math.RandomLong(1, m_a_szMappers.length() - 2);

                    if (m_a_uiPartOrder.find(uiNextPart) >= 0) {
                        continue; // Already inserted
                    }

                    m_a_uiPartOrder.insertLast(uiNextPart);
                }
            } else {
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->GeneratePartOrder(): Generating part order...\n");

                for (uint i = 0; i < m_a_szMappers.length(); i++) {
                    m_a_uiPartOrder.insertLast(i);
                }
            }

            // Intro is first
            m_a_uiPartOrder.insertAt(0, 0);
            // Outro is last
            m_a_uiPartOrder.insertLast(m_a_szMappers.length() - 1);

            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->GeneratePartOrder(): Part order decided:");
            for (uint i = 1; i < m_a_uiPartOrder.length() - 1; i++) {
                g_Game.AlertMessage(g_uiAlertType, " %1", m_a_szMapperTags[m_a_uiPartOrder[i]]);
            }
            g_Game.AlertMessage(g_uiAlertType, "\n");
        }

        /**
         * Set up map transitions.
         * @return void
         */
        void SetupMapTransitions()
        {
            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->SetupMapTransitions(): Starting...\n");
            CBaseEntity@ eTeleporter;

            for (uint i = 0; i < m_a_szMappers.length(); i++) {
                string szTeleporter = "teleporter_" + m_a_szMapperTags[m_a_uiPartOrder[i]];
                @eTeleporter = g_EntityFuncs.FindEntityByTargetname(null, szTeleporter);
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->SetupMapTransitions(): Setting up target for %1.\n", szTeleporter);

                if (eTeleporter !is null) {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->SetupMapTransitions(): %1 now linked to destination_%2.\n", eTeleporter.pev.targetname, m_a_szMapperTags[m_a_uiPartOrder[i + 1]]);
                    g_EntityFuncs.DispatchKeyValue(eTeleporter.edict(), "target", "destination_" + m_a_szMapperTags[m_a_uiPartOrder[i + 1]]);
                }
            }
        }

        /**
         * Move to a different part of the map.
         * @param  string szJumpToTag Next part (by mapper tag) to jump to, or empty for usual rotation
         * @return void
         */
        void MoveToPart(string szJumpToTag = "")
        {
            if (szJumpToTag.IsEmpty() && m_uiPartTransitionTimer >= 1) {
                m_uiPartTransitionTimer--;
                g_PlayerFuncs.HudMessageAll(m_sTransitionHudTextParams, "Next part will start in " + m_uiPartTransitionTimer + " second(s).");
                g_Scheduler.SetTimeout("MoveToPart", 1.0f);
                return;
            }

            // Determine next part
            string szFromPart   = m_iPartActive >= 0 ? m_a_szMappers[m_a_uiPartOrder[m_iPartActive]] : "";
            string szFromTag    = m_iPartActive >= 0 ? m_a_szMapperTags[m_a_uiPartOrder[m_iPartActive]] : "";
            string szToPart     = "";
            string szToTag      = "";

            if (szJumpToTag.IsEmpty()) {
                // Implicitly move on to next in rotation
                if (m_iPartActive >= int(m_a_uiPartOrder.length())) {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): All parts complete.\n");
                    return;
                }

                m_iPartActive++;
                m_uiPartTransitionTimer = 0;

                szToPart  = m_a_szMappers[m_a_uiPartOrder[m_iPartActive]];
                szToTag   = m_a_szMapperTags[m_a_uiPartOrder[m_iPartActive]];

                // Don't play the same part twice in a row
                if (szFromTag == szToTag) {
                    g_Scheduler.SetTimeout("MoveToPart", 1.0f);
                    return;
                }
            } else {
                // Explicit by command
                m_uiPartTransitionTimer = 0;

                for (uint i = 0; i < m_a_uiPartOrder.length(); i++) {
                    if (szJumpToTag == m_a_szMapperTags[m_a_uiPartOrder[i]]) {
                        m_iPartActive   = i;
                        szToPart        = m_a_szMappers[m_a_uiPartOrder[i]];
                        szToTag         = m_a_szMapperTags[m_a_uiPartOrder[i]];
                        break;
                    }
                }
            }

            if (szToPart.IsEmpty() || szToTag.IsEmpty()) {
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Destination part not found.\n");
                return;
            }

            // Shutdown the part we're on
            if (!szFromPart.IsEmpty() && !szFromTag.IsEmpty()) {
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Part for %1 is finishing.\n", szFromPart);

                CBaseEntity@ ePartShutdownEntity = g_EntityFuncs.FindEntityByTargetname(null, szFromTag + MAPPER_SHUTDOWN_ENT_SUFFIX);
                if (ePartShutdownEntity !is null) {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Firing shutdown entity for %1.\n", szFromPart);
                    ePartShutdownEntity.Use(null, null, USE_TOGGLE);
                }
                g_EntityFuncs.FireTargets(MAPPER_SPAWN_ENT_PREFIX + szFromTag, null, null, USE_OFF);
            }

            // Reset map CVARs
            g_EngineFuncs.CVarSetFloat("mp_allowmonsterinfo",           1.0f);
            g_EngineFuncs.CVarSetFloat("mp_allowplayerinfo",            1.0f);
            g_EngineFuncs.CVarSetFloat("mp_ammo_droprules",             1.0f);
            g_EngineFuncs.CVarSetFloat("mp_ammo_respawndelay",          -2.0f);
            g_EngineFuncs.CVarSetFloat("mp_banana",                     0.0f);
            g_EngineFuncs.CVarSetFloat("mp_barnacle_paralyze",          1.0f);
            g_EngineFuncs.CVarSetFloat("mp_disable_autoclimb",          0.0f);
            g_EngineFuncs.CVarSetFloat("mp_disable_pcbalancing",        0.0f);
            g_EngineFuncs.CVarSetFloat("mp_disable_player_rappel",      0.0f);
            g_EngineFuncs.CVarSetFloat("mp_disablegaussjump",           0.0f);
            g_EngineFuncs.CVarSetFloat("mp_dropweapons",                1.0f);
            g_EngineFuncs.CVarSetFloat("mp_falldamage",                 1.0f);
            g_EngineFuncs.CVarSetFloat("mp_flashlight",                 1.0f);
            g_EngineFuncs.CVarSetFloat("mp_forcerespawn",               1.0f);
            g_EngineFuncs.CVarSetFloat("mp_fraglimit",                  0.0f);
            g_EngineFuncs.CVarSetFloat("mp_grapple_mode",               0.0f);
            g_EngineFuncs.CVarSetFloat("mp_hevsuit_voice",              0.0f);
            g_EngineFuncs.CVarSetFloat("mp_item_respawndelay",          -2.0f);
            g_EngineFuncs.CVarSetFloat("mp_modelselection",             1.0f);
            g_EngineFuncs.CVarSetFloat("mp_multiplespawn",              1.0f);
            g_EngineFuncs.CVarSetFloat("mp_no_akimbo_uzis",             0.0f);
            g_EngineFuncs.CVarSetFloat("mp_noblastgibs",                0.0f);
            g_EngineFuncs.CVarSetFloat("mp_npckill",                    1.0f);
            g_EngineFuncs.CVarSetFloat("mp_observer_cyclic",            0.0f);
            g_EngineFuncs.CVarSetFloat("mp_observer_mode",              0.0f);
            g_EngineFuncs.CVarSetFloat("mp_respawndelay",               5.0f);
            g_EngineFuncs.CVarSetFloat("mp_suitpower",                  1.0f);
            g_EngineFuncs.CVarSetFloat("mp_survival_startdelay",        30.0f);
            g_EngineFuncs.CVarSetFloat("mp_survival_starton",           1.0f);
            g_EngineFuncs.CVarSetFloat("mp_survival_supported",         0.0f);
            g_EngineFuncs.CVarSetFloat("mp_timelimit",                  1440.0f);
            g_EngineFuncs.CVarSetFloat("mp_weapon_droprules",           1.0f);
            g_EngineFuncs.CVarSetFloat("mp_weapon_respawndelay",        -2.0f);
            g_EngineFuncs.CVarSetFloat("mp_weaponfadedelay",            60.0f);
            g_EngineFuncs.CVarSetFloat("mp_weaponstay",                 0.0f);
            g_EngineFuncs.CVarSetFloat("npc_dropweapons",               0.0f);
            g_EngineFuncs.CVarSetFloat("plrstart_zoffset",              0.0f);
            g_EngineFuncs.CVarSetFloat("sv_accelerate",                 10.0f);
            g_EngineFuncs.CVarSetFloat("sv_ai_enemy_detection_mode",    0.0f);
            g_EngineFuncs.CVarSetFloat("sv_airaccelerate",              10.0f);
            g_EngineFuncs.CVarSetFloat("sv_friction",                   4.0f);
            g_EngineFuncs.CVarSetFloat("sv_gravity",                    800.0f);
            g_EngineFuncs.CVarSetFloat("sv_maxspeed",                   270.0f);
            g_EngineFuncs.CVarSetFloat("sv_maxvelocity",                4096.0f);
            g_EngineFuncs.CVarSetFloat("sv_wateraccelerate",            10.0f);
            g_EngineFuncs.CVarSetFloat("sv_waterfriction",              1.0f);
            g_EngineFuncs.CVarSetFloat("sv_zmax",                       12288.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_357",                0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_9mmhandgun",         0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_crossbow",           0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_displacer",          0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_eagle",              0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_mp5",                0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_rpg",                0.0f);
            g_EngineFuncs.CVarSetFloat("weaponmode_shotgun",            0.0f);

            // Boot the part we're going to
            if (!szToPart.IsEmpty() && !szToTag.IsEmpty()) {
                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Changing to part for %1.\n", szToPart);

                CBaseEntity@ ePartBootEntity = g_EntityFuncs.FindEntityByTargetname(null, szToTag + MAPPER_BOOT_ENT_SUFFIX);
                if (ePartBootEntity !is null) {
                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Firing boot entity for %1.\n", szToPart);
                    ePartBootEntity.Use(null, null, USE_TOGGLE);
                }
                g_EntityFuncs.FireTargets(MAPPER_SPAWN_ENT_PREFIX + szToTag, null, null, USE_ON);
            }

            // Player specific resets
            for (int i = 1; i <= g_Engine.maxClients; i++) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
                if (
                    pPlayer is null
                    || !pPlayer.IsPlayer()
                    || !pPlayer.IsConnected()
                ) {
                    continue;
                }

                // Reset basic properties
                pPlayer.pev.targetname  = "";
                pPlayer.pev.target      = "";
                pPlayer.pev.movetype    = MOVETYPE_WALK;
                pPlayer.pev.solid       = SOLID_SLIDEBOX;
                pPlayer.pev.takedamage  = DAMAGE_AIM;
                pPlayer.pev.health      = 100.0f;
                pPlayer.pev.max_health  = 100.0f;
                pPlayer.pev.armorvalue  = 0.0f;
                pPlayer.pev.armortype   = 100.0f;

                // Fully re-equip each player
                g_PlayerFuncs.ApplyMapCfgToPlayer(pPlayer, true);

                // Remove long jump
                pPlayer.m_fLongJump = false;
                KeyValueBuffer@ pPlayerPhysics = g_EngineFuncs.GetPhysicsKeyBuffer(pPlayer.edict());
                pPlayerPhysics.SetValue("slj", "0");

                // Remove all items
                if (!HAT_ITEM_GROUP.IsEmpty()) { // Apart from rage hats
                    InventoryList@ pPlayerInventory = pPlayer.get_m_pInventory();
                    InventoryList@ pPlayerInventoryNext;
                    CItemInventory@ pItem;

                    while (pPlayerInventory !is null && pPlayerInventory.hItem.IsValid() && pPlayerInventory.hItem.GetEntity() !is null) {
                        @pPlayerInventoryNext   = pPlayerInventory.pNext;
                        @pItem                  = cast<CItemInventory>(pPlayerInventory.hItem.GetEntity());

                        if (pItem !is null) {
                            if (pItem.m_szItemGroup == HAT_ITEM_GROUP) {
                                g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Keeping item \"%1\" with player \"%2\".\n", pItem.m_szItemName, g_Utility.GetPlayerLog(pPlayer.edict()));
                            } else {
                                if (g_Game.GetGameVersion() >= 526) {
                                    g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Forcing item \"%1\" from player \"%2\".\n", pItem.m_szItemName, g_Utility.GetPlayerLog(pPlayer.edict()));
                                    // This WILL crash prior to SC 5.26
                                    pItem.Return();
                                }
                            }
                        }

                        @pPlayerInventory = pPlayerInventoryNext;
                    }
                } else {
                    g_InventoryMisc.RemoveAllFromHolder(pPlayer);
                }

                // Update HUD icon immediately
                UpdateHud(pPlayer);

                // Exit observer mode
                if (pPlayer.GetObserver().IsObserver()) {
                    pPlayer.GetObserver().StopObserver(false);
                }
            }

            // Respawn all players
            g_PlayerFuncs.RespawnAllPlayers(true, true);
            g_Game.AlertMessage(g_uiAlertType, "Ragemap2023::Map->MoveToPart(): Part for %1 is now active.\n", szToPart);
        }
    }

    /**
     * Handle client say.
     * @param  SayParameters@ pParams Say parameters
     * @return HookReturnCode         Hook return code
     */
    HookReturnCode ClientSay(SayParameters@ pParams)
    {
        if (g_pMap is null) {
            return HOOK_CONTINUE;
        }

        CBasePlayer@ pPlayer = pParams.GetPlayer();
        if (
            pPlayer is null
            || !pPlayer.IsPlayer()
            || !pPlayer.IsConnected()
        ) {
            return HOOK_CONTINUE;
        }

        const CCommand@ args = pParams.GetArguments();

        // << These commands can only be used when debugging mode is on, or by server administrators
        if (DEBUG_MODE || g_PlayerFuncs.AdminLevel(pPlayer) >= ADMIN_YES) {
            // << Jump to a different map part
            if (args[0] == "/part" && args.ArgC() == 2) {
                bool fMapperTagValid = false;
                for (uint i = 0; i < g_pMap.m_a_szMapperTags.length(); i++) {
                    if (args[1] == g_pMap.m_a_szMapperTags[i]) {
                        fMapperTagValid = true;
                        g_pMap.MoveToPart(args[1]);
                        break;
                    }
                }

                if (!fMapperTagValid) {
                    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Ragemap 2023] Invalid mapper name (Usage: /part mappername.)\n", "Mapper's name should be spelled as stored in the map script.\n");
                    // g_Game.AlertMessage(at_console, "[Ragemap 2023] Invalid mapper name (Usage: /part mappername.)\nMapper's name should be spelled as stored in the map script.\n");
                }

                return HOOK_CONTINUE;
            }
            // >> Jump to a different map part

            // << Skip the current map part
            if (args[0] == "/skip") {
                PartFinished(null, null, USE_ON, 0);
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Ragemap 2023] Skipping current part.\n");
                g_Game.AlertMessage(at_console, "[Ragemap 2023] Skipping current part by \"%1\".\n", g_Utility.GetPlayerLog(pPlayer.edict()));

                return HOOK_CONTINUE;
            }
            // >> Skip the current map part
        }
        // >> These commands can only be used when debugging mode is on, or by server administrators

        // << Vote to skip the current map part
        if (args[0] == "/skip" || args[0] == "/voteskip") {
            // Don't allow this during the map intro or outro
            if (g_pMap.m_iPartActive <= 0) {
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[Ragemap 2023] Cannot skip during the intro.\n");

                return HOOK_CONTINUE;
            }

            // Skip the current map part if only one person is present
            if (g_PlayerFuncs.GetNumPlayers() == 1) {
                PartFinished(null, null, USE_ON, 0);
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Ragemap 2023] Skipping current part.\n");
                g_Game.AlertMessage(at_console, "[Ragemap 2023] Skipping current part by \"%1\".\n", g_Utility.GetPlayerLog(pPlayer.edict()));

                return HOOK_CONTINUE;
            }

            // Enforce a gap between votes
            if (g_pMap.m_flVoteSkipTime >= 0.0f && g_Engine.time < g_pMap.m_flVoteSkipTime + VOTE_SKIP_DELAY) {
                string szVoteSkipMsg;
                snprintf(szVoteSkipMsg, "[Ragemap 2023] You must wait %1 seconds before starting another vote to skip this part.\n", formatFloat(g_pMap.m_flVoteSkipTime - g_Engine.time));
                g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, szVoteSkipMsg);

                return HOOK_CONTINUE;
            }

            // Start the vote
            g_pMap.m_flVoteSkipTime = g_Engine.time + VOTE_SKIP_DELAY + VOTE_SKIP_DURAITON;
            g_pMap.m_pVoteSkip.Start();
            g_Game.AlertMessage(at_console, "[Ragemap 2023] Vote to skip current part started by \"%1\".\n", g_Utility.GetPlayerLog(pPlayer.edict()));

            return HOOK_CONTINUE;
        }
        // >> Vote to skip the current map part

        return HOOK_CONTINUE;
    }

    /**
     * Update player HUD.
     * @param  CBasePlayer@|null pPlayer Player entity, or null for all players
     * @return void
     */
    void UpdateHud(CBasePlayer@ pPlayer)
    {
        if (g_pMap is null || g_pMap.m_iPartActive < 0 || uint(g_pMap.m_iPartActive) >= g_pMap.m_a_szMapperTags.length()) {
            return;
        }

        string szCurrentMapperTag = g_pMap.m_a_szMapperTags[g_pMap.m_a_uiPartOrder[g_pMap.m_iPartActive]];
        if (szCurrentMapperTag.IsEmpty()) {
            return;
        }

        HUDSpriteParams sHudSpriteParams;
        sHudSpriteParams.channel        = 0;
        sHudSpriteParams.flags          = HUD_ELEM_NO_BORDER;
        sHudSpriteParams.x              = -0.02;
        sHudSpriteParams.y              = 0.02825;
        sHudSpriteParams.color1         = RGBA_WHITE;
        sHudSpriteParams.color2         = RGBA_WHITE;
        sHudSpriteParams.fadeinTime     = 0.0;
        sHudSpriteParams.fadeoutTime    = 0.0;
        sHudSpriteParams.holdTime       = 3600.0;
        sHudSpriteParams.fxTime         = 1;
        sHudSpriteParams.effect         = HUD_EFFECT_NONE;
        sHudSpriteParams.spritename     = "ragemap2023/channelicon_" + szCurrentMapperTag + ".spr";

        g_PlayerFuncs.HudCustomSprite(pPlayer, sHudSpriteParams);
    }

    /**
     * Update player HUD. (Hook event.)
     * @param  CBasePlayer@   pPlayer Player entity
     * @return HookReturnCode         Hook return code
     */
    HookReturnCode UpdateHudHook(CBasePlayer@ pPlayer)
    {
        UpdateHud(pPlayer);
        return HOOK_CONTINUE;
    }

    /**
    * Handle a blockage on the part skip vote.
    * @param  Vote@ pVote  Skip part vote
    * @param  float flTime Time the vote was blocked at
    * @return void
    */
    void VoteSkipBlocked(Vote@ pVote, float flTime)
    {
        if (g_pMap is null) {
            return;
        }

        g_pMap.m_flVoteSkipTime = flTime + VOTE_SKIP_DELAY;
        g_Game.AlertMessage(at_console, "[Ragemap 2023] Vote to skip current part blocked.\n");
    }

    /**
    * Handle the end of the part skip vote.
    * @param  Vote@ pVote   Skip part vote
    * @param  bool  fPassed Whether the vote passed or not
    * @param  int   iVoters Count of voters
    * @return void
    */
    void VoteSkipEnd(Vote@ pVote, bool fResult, int iVoters)
    {
        if (g_pMap is null) {
            return;
        }

        g_pMap.m_flVoteSkipTime = g_Engine.time + VOTE_SKIP_DELAY;

        if (!fResult) {
            g_Game.AlertMessage(at_console, "[Ragemap 2023] Vote to skip current part failed.\n");
            return;
        }

        PartFinished(null, null, USE_ON, 0);
        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[Ragemap 2023] Skipping current part.\n");
        g_Game.AlertMessage(at_console, "[Ragemap 2023] Vote to skip current part passed.\n");
    }

    /**
     * Check if a player is a contributor to this map.
     * @param  CBasePlayer@ pPlayer Player entity
     * @return bool
     */
    bool IsPlayerMapContributor(CBasePlayer@ pPlayer)
    {
        if (
            pPlayer is null
            || !pPlayer.IsPlayer()
            || !pPlayer.IsConnected()
        ) {
            return false;
        }

        string szAuthId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if (szAuthId.IsEmpty()) {
            return false;
        }

        return (
            szAuthId == "STEAM_0:1:179439"          // Hezus
            || szAuthId == "STEAM_0:1:338750"       // Adambean
            || szAuthId == "STEAM_0:0:77731187"     // AlexCorruptor
            || szAuthId == "STEAM_0:1:90776118"     // Dex
            || szAuthId == "STEAM_0:1:4765200"      // Erty
            || szAuthId == "STEAM_1:1:217577025"    // eyeling
            || szAuthId == "STEAM_0:1:27140071"     // Gauna
            || szAuthId == "STEAM_0:0:24677737"     // Giegue
            || szAuthId == "STEAM_0:0:77228727"     // KEZÆIV
            || szAuthId == "STEAM_0:0:148021263"    // I_ka
            || szAuthId == "STEAM_0:0:196301438"    // Levi
            || szAuthId == "STEAM_0:1:1636573"      // Nih
            || szAuthId == "STEAM_0:1:50024001"     // Outerbeast
            || szAuthId == "STEAM_0:1:234181379"    // SEACAT08
        );
    }

    Map@ g_pMap;
}

/**
 * Bridge function for map hook to namespaced "MoveToPart" function.
 * @param  string szJumpToTag Next part (by mapper tag) to jump to, or empty for usual rotation
 * @return void
 */
void MoveToPartBridge(string szJumpToTag = "")
{
    if (Ragemap2023::g_pMap is null) {
        return;
    }

    Ragemap2023::g_pMap.MoveToPart(szJumpToTag);
}

/**
 * Map hook: Begin thinker for when a part is finished.
 * @param  CBaseEntity@|null pActivator Activator entity, typically a "trigger_script"
 * @param  CBaseEntity@|null pCaller    Caller entity
 * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
 * @param  float             flValue    Use value, or unspecified to assume `0.0f`
 * @return void
 */
void PartFinished(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if (Ragemap2023::g_pMap is null) {
        return;
    }

    g_Scheduler.SetTimeout("MoveToPartBridge", 0.001f, "");
}

/**
 * Map hook: Ticket system start.
 * @param  CBaseEntity@|null pActivator Activator entity, typically a "trigger_script"
 * @param  CBaseEntity@|null pCaller    Caller entity
 * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
 * @param  float             flValue    Use value, or unspecified to assume `0.0f`
 * @return void
 */
void TicketStart(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    CustomHUD::TicketStart();
}

/**
 * Map hook: Ticket system update.
 * @param  CBaseEntity@|null pActivator Activator entity, typically a "trigger_script"
 * @param  CBaseEntity@|null pCaller    Caller entity
 * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
 * @param  float             flValue    Use value, or unspecified to assume `0.0f`
 * @return void
 */
void UpdateTickets(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    CustomHUD::UpdateTickets();
}

/**
 * Map hook: Ticket system end.
 * @param  CBaseEntity@|null pActivator Activator entity, typically a "trigger_script"
 * @param  CBaseEntity@|null pCaller    Caller entity
 * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
 * @param  float             flValue    Use value, or unspecified to assume `0.0f`
 * @return void
 */
void TicketEnd(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    CustomHUD::TicketEnd();
}

/**
 * Map hook: Cheeky hat.
 * @param  CBaseEntity@|null pActivator Activator entity, typically a "trigger_script"
 * @param  CBaseEntity@|null pCaller    Caller entity
 * @param  USE_TYPE          useType    Use type, or unspecified to assume `USE_TOGGLE`
 * @param  float             flValue    Use value, or unspecified to assume `0.0f`
 * @return void
 */
void SpecialBonusHat(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if (pActivator is null) {
        return;
    }

    CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);
    if (!Ragemap2023::IsPlayerMapContributor(pPlayer)) {
        return;
    }

    string szAuthId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
    if (szAuthId == "STEAM_0:1:90776118") { // So rude!
        pPlayer.TakeDamage(null, null, 65535.0f, DMG_BULLET|DMG_ALWAYSGIB);
        return;
    }

    if (!Ragemap2023::HAT_ITEM_GROUP.IsEmpty()) { // Apart from rage hats
        InventoryList@ pPlayerInventory = pPlayer.get_m_pInventory();
        InventoryList@ pPlayerInventoryNext;
        CItemInventory@ pItem;

        while (pPlayerInventory !is null && pPlayerInventory.hItem.IsValid() && pPlayerInventory.hItem.GetEntity() !is null) {
            @pPlayerInventoryNext   = pPlayerInventory.pNext;
            @pItem                  = cast<CItemInventory>(pPlayerInventory.hItem.GetEntity());

            if (pItem !is null && pItem.m_szItemGroup == Ragemap2023::HAT_ITEM_GROUP) {
                return;
            }
        }
    }

    dictionary oItem = {
        {"origin",                                  "8192.0 8192.0 8192.0"},
        {"angles",                                  "0.0 0.0 0.0"},
        {"carried_sequence",                        "1"},
        {"carried_sequencename",                    "carried"},
        {"collect_limit",                           "1"},
        {"delay",                                   "0"},
        {"effect_damage",                           "100.0"},
        {"effect_friction",                         "100.0"},
        {"effect_glow",                             "0 0 0"},
        {"effect_gravity",                          "100.0"},
        {"effect_respiration",                      "0.0"},
        {"effect_speed",                            "100.0"},
        {"holder_can_drop",                         "1"},
        {"holder_keep_on_death",                    "1"},
        {"holder_keep_on_respawn",                  "1"},
        {"holder_timelimit_wait_until_activated",   "1"},
        {"item_group_canthave_num",                 "1"},
        {"item_group_canthave",                     Ragemap2023::HAT_ITEM_GROUP},
        {"item_group",                              Ragemap2023::HAT_ITEM_GROUP},
        {"item_name",                               "ragehat_sunhat_special"},
        {"maxhullsize",                             "0 0 0"},
        {"minhullsize",                             "0 0 0"},
        {"model",                                   "models/ragemap2023/gauna/hat_sun.mdl"},
        {"rendercolor",                             "0 0 0"},
        {"return_timelimit",                        "0.0"},
        {"scale",                                   "1.5"},
        {"sequencename",                            "idle"},
        {"weight",                                  "1.0"},
        {"spawnflags",                              "1408"}
    };

    CItemInventory@ pItem = cast<CItemInventory>(g_EntityFuncs.CreateEntity("item_inventory", oItem, true));
    if (pItem is null) {
        return;
    }

    pItem.Use(pPlayer, pPlayer, USE_ON, 0.0f);
    if (!pItem.m_hHolder.IsValid()) {
        pItem.Destroy();
    }
}

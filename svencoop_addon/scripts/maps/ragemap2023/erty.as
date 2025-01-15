namespace Ragemap2023Erty
{
    /*
     * -------------------------------------------------------------------------
     * Constants & enumerators
     * -------------------------------------------------------------------------
     */

    /** @var int Number of segments in charge display */
    const int DISPLAY_SEGMENTS = 20;

    /** @var float Threshold for when to turn display green */
    const float DISPLAY_GREEN_THRESHOLD = 0.5f;

    /** @var float How likely is it for accidents to happen to less than 5 players? */
    const float DEFAULT_ACCIDENT_RATE = 0.01f;

    /** @var array<string> Things our silly little hamsters may say */
    const array<string> HAMSTER_SAY = {
        "Look at me I'm a hamster!",
        "Sqeak! Sqeeeaaak!",
        "I'm a good fuzzy ball of fur",
        "I LOVE this wheel! <3",
        "Gotta get those gains!"
    };

    /** @var string A lil helper for those with camera cursor issues */
    const string cursorInfoPath = "ragemap2023/erty/mousecursorinfo.spr";

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
        // g_Module.ScriptInfo.SetAuthor("Erty");
        g_Game.PrecacheModel(cursorInfoPath);
    }

    /**
     * Map activation handler.
     * @return void
     */
    void MapActivate()
    {
        @g_pInstance = MapPart();

        if (!g_pInstance.Initialise()) {
            g_Game.AlertMessage(at_console, "Ragemap 2023: Erty's part encountered errors initialising.\n");

            @g_pInstance = null;
            return;
        }

        g_Game.AlertMessage(at_console, "Ragemap 2023: Erty's part ready.\n");
    }


    /**
     * Ragemap 2023: Example's part
     */
    final class MapPart
    {
        /*
         * -------------------------------------------------------------------------
         * Variables
         * -------------------------------------------------------------------------
         */

        /** @var int m_iLeakAmount How much charge to leak per second */
        int m_iLeakAmount;

        /** @var int m_iMaxCharge How endowed our juice containers are */
        int m_iMaxCharge;

        /** @var int m_iCurrentCharge How much pee is stored in our balls as of right now */
        int m_iCurrentCharge;

        /** @var int m_iNumPlayers Number of players registered at the start of the part */
        int m_iNumPlayers = 1;

        /** @var EHandle[] m_hChargeDisplays Displays charge in chunks of 10% item_generic */
        array<EHandle> m_hChargeDisplays;

        /** @var EHandle m_hData Holds variables like score and charge and sets initial+max charge info_target */
        EHandle m_hData;

        /** @var dictionary m_dHamsterWheels Nice players get to run in the wheel, as a treat */
        dictionary m_dHamsterWheels;
        dictionary m_dHamsterWheelLastSound;

        /** @var dictionary m_dLastHamsterSay When was the last time that damn hamster spoke? */
        dictionary m_dLastHamsterSay;

        /** @var float m_fLastElecFault When was the last time we had to turn it off and on again? */
        float m_fLastElecFault;

        /** @var float m_fAccidentBaseChance How likely accidents are to happen */
        float m_fAccidentBaseChance;

        HUDTextParams msgParams0;
        HUDTextParams msgParams1;
        HUDSpriteParams sHudSpriteParams;


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
            // ... initialise variables (just above) with defaults values here
            m_iLeakAmount = 1;
            m_dLastHamsterSay = { {"erty_hamsterwheel", -20.0f}, {"erty_hamsterwheel2", -20.0f} };
            m_fLastElecFault = 10.0f;  // grace period of 10 seconds extra at start, as a treat
            m_fAccidentBaseChance = DEFAULT_ACCIDENT_RATE;

            msgParams0.x            = -1;
            msgParams0.y            = 0.2;
            msgParams0.effect       = 0;
            msgParams0.r1           = 100;
            msgParams0.g1           = 100;
            msgParams0.b1           = 100;
            msgParams0.a1           = 0;
            msgParams0.r2           = 240;
            msgParams0.g2           = 100;
            msgParams0.b2           = 0;
            msgParams0.a2           = 0;
            msgParams0.fadeinTime   = 0.5;
            msgParams0.fadeoutTime  = 1;
            msgParams0.holdTime     = 10;
            msgParams0.fxTime       = 0;
            msgParams0.channel      = 5;

            msgParams1 = msgParams0;
            msgParams1.y = 0.4;
            msgParams1.channel = 6;


            sHudSpriteParams.channel        = 15;
            sHudSpriteParams.flags          = HUD_ELEM_NO_BORDER | HUD_SPR_MASKED;
            sHudSpriteParams.x              = -0.05;
            sHudSpriteParams.y              = 0.65;
            sHudSpriteParams.color1         = RGBA_WHITE;
            sHudSpriteParams.color2         = RGBA_WHITE;
            sHudSpriteParams.fadeinTime     = 0.0;
            sHudSpriteParams.fadeoutTime    = 0.0;
            sHudSpriteParams.holdTime       = 3600.0;
            sHudSpriteParams.fxTime         = 1;
            sHudSpriteParams.effect         = HUD_EFFECT_NONE;
            sHudSpriteParams.spritename     = cursorInfoPath;
        }


        /*
         * -------------------------------------------------------------------------
         * Helper functions
         * -------------------------------------------------------------------------
         */

        // ... private functions you would call from inside the class here

        void AdjustDifficulty()
        {
            if (m_hData.IsValid()) {
                CBaseEntity@ pData = m_hData.GetEntity();
                CustomKeyvalues@ pCustom = pData.GetCustomKeyvalues();
                CustomKeyvalue kvPlayerCount(pCustom.GetKeyvalue("$i_playercount"));

                if (kvPlayerCount.Exists()) {
                    m_iNumPlayers = kvPlayerCount.GetInteger();
                }
            }

            m_fAccidentBaseChance = DEFAULT_ACCIDENT_RATE * (1 + Math.Floor(float(m_iNumPlayers) / 5.0f));

            // g_Game.AlertMessage(at_console, "Ragemap2023Erty::MapPart->AdjustDifficulty(): Accident base chance now at \"%1\"\n", m_fAccidentBaseChance);
        }

        void LeakCharge() { DrainCharge(m_iLeakAmount); }
        void LeakChargeBig() { DrainCharge(m_iLeakAmount + 2); }

        void DrainCharge(uint uiAmount)
        {
            if (!m_hData.IsValid()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->LeakCharge(): No battery found to leak :(\n");
                return;
            }

            CBaseEntity@ pData = m_hData.GetEntity();
            CustomKeyvalues@ pCustom = pData.GetCustomKeyvalues();
            CustomKeyvalue kvCharge(pCustom.GetKeyvalue("$i_charge"));

            if (!kvCharge.Exists()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->LeakCharge(): Battery has no custom charge to leak :(\n");
                return;
            }

            int m_iCharge = kvCharge.GetInteger();

            if (m_iCharge < 1) {
                m_iCharge = 0;
            } else {
                m_iCharge -= uiAmount;
            }

            pCustom.SetKeyvalue("$i_charge", m_iCharge);
            m_iCurrentCharge = m_iCharge;

            UpdateChargeDisplays();
        }

        void Recharge(uint uiAmount)
        {
            if (!m_hData.IsValid()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->Recharge(): No battery found to recharge :(\n");
                return;
            }

            CBaseEntity@ pData = m_hData.GetEntity();
            CustomKeyvalues@ pCustom = pData.GetCustomKeyvalues();
            CustomKeyvalue kvCharge(pCustom.GetKeyvalue("$i_charge"));

            if (!kvCharge.Exists()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->Recharge(): Battery has no balls to fill with pee :(\n");
                return;
            }

            int m_iCharge = int(kvCharge.GetInteger());

            if (m_iCharge == m_iMaxCharge) {
                return;
            }

            if (m_iNumPlayers == 1) {
                uiAmount *= 2;  // Let's be nice to lonely players
            }

            m_iCharge += uiAmount;

            if (m_iCharge > m_iMaxCharge) {
                m_iCharge = m_iMaxCharge;
            }

            pCustom.SetKeyvalue("$i_charge", int(m_iCharge));
            m_iCurrentCharge = m_iCharge;

            UpdateChargeDisplays();
        }

        void UpdateChargeDisplays()
        {
            // TODO: Remove:
            // g_Game.AlertMessage(at_console, "Ragemap2023Erty::MapPart->UpdateChargeDisplays(): Charge is currently at \"%1\".\n", m_iCurrentCharge);
            
            float m_fFraction = float(m_iCurrentCharge) / float(m_iMaxCharge);

            for (uint i = 0; i < m_hChargeDisplays.length(); i++) {
                if (m_hChargeDisplays[i].IsValid()) {
                    CBaseEntity@ pDisplay = m_hChargeDisplays[i].GetEntity();
                    pDisplay.pev.sequence = uint(Math.Ceil(m_fFraction * float(DISPLAY_SEGMENTS)));
                    
                    if (m_fFraction > DISPLAY_GREEN_THRESHOLD) {
                        pDisplay.pev.skin = 1;
                    } else {
                        pDisplay.pev.skin = 0;
                    }
                }
            }
        }

        void RegisterJuiced()
        {
            if (!m_hData.IsValid()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->RegisterJuiced(): Data entity not found\n");
                return;
            }

            CBaseEntity@ pData = m_hData.GetEntity();
            CustomKeyvalues@ pCustom = pData.GetCustomKeyvalues();

            CustomKeyvalue kvJuiced(pCustom.GetKeyvalue("$i_juiced"));
            CustomKeyvalue kvGamerJuice(pCustom.GetKeyvalue("$i_gamerjuice"));

            if (!kvJuiced.Exists()) {
                pCustom.SetKeyvalue("$i_juiced", 1);
                return;
            }
            int m_iJuiced = kvJuiced.GetInteger() + 1;
            pCustom.SetKeyvalue("$i_juiced", m_iJuiced);
            
            if (!kvGamerJuice.Exists()) {
                pCustom.SetKeyvalue("$i_gamerjuice", 1);
                return;
            }
            int m_iGamerJuice = kvGamerJuice.GetInteger() + 1;
            pCustom.SetKeyvalue("$i_gamerjuice", m_iGamerJuice);
        }

        void OutroSum()
        {
            if (!m_hData.IsValid()) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->RegisterJuiced(): Data entity not found\n");
                return;
            }

            CBaseEntity@ pData = m_hData.GetEntity();
            CustomKeyvalues@ pCustom = pData.GetCustomKeyvalues();

            CustomKeyvalue kvJuiced(pCustom.GetKeyvalue("$i_juiced"));
            CustomKeyvalue kvSalt(pCustom.GetKeyvalue("$i_salt"));

            int m_iJuiced = 0;
            if (kvJuiced.Exists()) {
                m_iJuiced = kvJuiced.GetInteger();
            }
            
            int m_iSalt = 0;
            if (kvSalt.Exists()) {
                m_iSalt = kvSalt.GetInteger();
            }

            string szOutroMessage;
            snprintf( szOutroMessage,
                "You crushed a total of %1 SALTY GAMERS!\n"
                + "During your shift you produced %2 bottles of salt!",
                m_iJuiced, m_iSalt );
            
            string szOutroMessage2;
            if (m_iSalt < 10) {
                msgParams1.r1 = 200;
                msgParams1.g1 = 10;
                msgParams1.b1 = 5;
                szOutroMessage2 = "THIS IS UNACCEPTABLE!\nTROLL DUNG CLEANING DUTY FOR AN ENTIRE WEEK!";
            } else {
                szOutroMessage2 = "Well done! You might even have earned a wage for this month!";
            }

            g_PlayerFuncs.HudMessageAll(msgParams0, szOutroMessage);
            g_Game.AlertMessage(at_console, szOutroMessage);    // Display in console as well. Happy now, SV BOY?

            g_PlayerFuncs.HudMessageAll(msgParams1, szOutroMessage2);
            g_Game.AlertMessage(at_console, szOutroMessage2);
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

            // ... perform some basic pre-flight checks here if needed

            // Päronsplit is the best ice cream I WILL FIGHT YOU ON THIS
            @pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "erty_chargedisplay")) !is null) {
                m_hChargeDisplays.insertLast(EHandle(pEntity));
            }

            // Looks like we messed up and won't be getting any cute boys tonight, gang
            if (m_hChargeDisplays.length() < 1) {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->Initialise(): No charge display entities \"%1\" found.\n", "erty_chargedisplay");
                ++uiErrors;
            }

            // The rum tells me we should tell gang about our secret (the secret is juice)
            @pEntity = null;
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "erty_vars")) !is null) {
                m_hData = EHandle(pEntity);

                CBaseEntity@ pData = m_hData.GetEntity();   // TODO: could just have used pEntity here, right? silly brain
                CustomKeyvalues@ pCustom = pData.GetCustomKeyvalues();
                CustomKeyvalue kvCharge(pCustom.GetKeyvalue("$i_charge"));

                if (!kvCharge.Exists())
                {
                    g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->Initialise(): No pee in the balls :(\n");
                    ++uiErrors;
                }

                m_iMaxCharge = int(kvCharge.GetInteger());
                m_iCurrentCharge = m_iMaxCharge;

                UpdateChargeDisplays();
            } else {
                g_Game.AlertMessage(at_error, "Ragemap2023Erty::MapPart->Initialise(): Battery entity \"%1\" not found.\n", "erty_vars");
                ++uiErrors;
            }

            @pEntity = null;
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "erty_hamsterwheel")) !is null)
            {
                m_dHamsterWheels.set("erty_hamsterwheel", EHandle(pEntity));
                m_dHamsterWheelLastSound.set("erty_hamsterwheel", -1.0f);
            }

            @pEntity = null;
            if ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "erty_hamsterwheel2")) !is null)
            {
                m_dHamsterWheels.set("erty_hamsterwheel2", EHandle(pEntity));
                m_dHamsterWheelLastSound.set("erty_hamsterwheel2", -1.0f);
            }

            return (0 == uiErrors);
        }

        // ... public functions you would call from outside the class here

    }

    MapPart@ g_pInstance;

    /*
     * -------------------------------------------------------------------------
     * Map hooks
     * -------------------------------------------------------------------------
     */
    
    void AdjustDifficulty(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }
        g_pInstance.AdjustDifficulty();
    }

    void ContinuousChargeLeak(CBaseEntity@ pTriggerScript)
    {
        if (g_pInstance is null) {
            return;
        }
        g_pInstance.LeakCharge();
    }

    void IncreaseLeak(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }
        g_pInstance.m_iLeakAmount++;
    }

    void TestLeakLevel(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);
        if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
            return;
        }

        string szAuthId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        if (szAuthId.IsEmpty()) {
            return;
        }

        if (szAuthId == "STEAM_0:1:179439" || szAuthId == "STEAM_0:1:338750" || szAuthId == "STEAM_0:0:77731187"
            || szAuthId == "STEAM_0:1:4765200" || szAuthId == "STEAM_1:1:217577025" || szAuthId == "STEAM_0:1:27140071"
            || szAuthId == "STEAM_0:0:24677737" || szAuthId == "STEAM_0:0:77228727" || szAuthId == "STEAM_0:0:148021263"
            || szAuthId == "STEAM_0:0:196301438" || szAuthId == "STEAM_0:1:1636573" || szAuthId == "STEAM_0:1:50024001"
            || szAuthId == "STEAM_0:1:234181379") {
            g_EntityFuncs.FireTargets("erty_3isreal_c", null, null, USE_TOGGLE);
        }
    }

    void ContinuousChargeLeakBig(CBaseEntity@ pTriggerScript)
    {
        if (g_pInstance is null) {
            return;
        }
        g_pInstance.LeakChargeBig();
    }

    void DrainCharge(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        CustomKeyvalues@ pCustom = pCaller.GetCustomKeyvalues();
        CustomKeyvalue kvCharge(pCustom.GetKeyvalue("$i_charge"));

        int m_iCharge;
        if (kvCharge.Exists()) {
            m_iCharge = kvCharge.GetInteger();
        } else {
            m_iCharge = 1;
        }
        
        g_pInstance.DrainCharge(m_iCharge);
    }

    void Recharge(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null || pActivator is null || !pActivator.IsPlayer()) {
            return;
        }

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);
        if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
            return;
        }

        CustomKeyvalues@ pCustom = pCaller.GetCustomKeyvalues();
        CustomKeyvalue kvCharge(pCustom.GetKeyvalue("$i_charge"));
        CustomKeyvalue kvSound(pCustom.GetKeyvalue("$s_sound"));

        int m_iCharge;
        if (kvCharge.Exists()) {
            m_iCharge = kvCharge.GetInteger();
        } else {
            m_iCharge = 1;
        }
        
        if (pPlayer.pev.movetype == MOVETYPE_WALK && (pPlayer.pev.button & IN_FORWARD) != 0)
        {
            g_pInstance.Recharge(m_iCharge);

            if (kvSound.Exists()) {
                string m_sSound = kvSound.GetString();
                g_EntityFuncs.FireTargets(m_sSound, null, null, USE_ON);
            }
        }
    }

    void RechargeWheel(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null || pActivator is null || !pActivator.IsPlayer()) {
            return;
        }

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);
        if (pPlayer is null || !pPlayer.IsPlayer() || !pPlayer.IsConnected()) {
            return;
        }

        CustomKeyvalues@ pCustom = pCaller.GetCustomKeyvalues();

        CustomKeyvalue kvWheel(pCustom.GetKeyvalue("$s_wheel"));
        string m_sWheel = "erty_hamsterwheel";
        if (kvWheel.Exists()) {
            m_sWheel = kvWheel.GetString();
        }

        if (!g_pInstance.m_dHamsterWheels.exists(m_sWheel)) {
            g_Game.AlertMessage(at_console, "Ragemap2023Erty::MapPart->RechargeWheel(): Key \"%1\" was not found\n", m_sWheel);
            return;
        }
        EHandle hHamsterWheel = EHandle(g_pInstance.m_dHamsterWheels[m_sWheel]);
        if (!hHamsterWheel.IsValid()) {
            g_Game.AlertMessage(at_console, "Ragemap2023Erty::MapPart->RechargeWheel(): This ain't a dictionary it's a literal dictionary!\n");
            return;
        }
        if (!g_pInstance.m_dLastHamsterSay.exists(m_sWheel)) {
            g_pInstance.m_dLastHamsterSay.set(m_sWheel, -20.0f);
        }

        CustomKeyvalue kvCharge(pCustom.GetKeyvalue("$i_charge"));
        int m_iCharge = 1;
        if (kvCharge.Exists()) {
            m_iCharge = kvCharge.GetInteger();
        }

        CustomKeyvalue kvDir(pCustom.GetKeyvalue("$i_dir"));
        if (!kvDir.Exists()) {
            g_Game.AlertMessage(at_console, "Ragemap2023Erty::MapPart->RechargeWheel(): Goddam hamsterwheel don't know right from left dammit\n");
            return;
        }

        int m_iDir = ((kvDir.GetInteger() % 360) + 360) % 360;
        if (m_iDir > 180) { m_iDir -= 360; }
        float angleDiff = (pPlayer.pev.angles.y - m_iDir + 180) % 360 - 180;

        if (pPlayer.pev.movetype == MOVETYPE_WALK
            && (pPlayer.pev.button & IN_FORWARD) != 0
            && angleDiff < 30.0f && angleDiff > -30.0f) {
            g_pInstance.Recharge(m_iCharge);

            CBaseEntity@ pWheel = hHamsterWheel.GetEntity();
            float rot = pWheel.pev.angles.x;
            rot += 2;
            pWheel.pev.angles.x = rot % 360;

            if (g_Engine.time - float(g_pInstance.m_dHamsterWheelLastSound[m_sWheel]) > 0.75f) {
                g_EntityFuncs.FireTargets(m_sWheel + "_s", null, null, USE_ON);
                g_pInstance.m_dHamsterWheelLastSound.set(m_sWheel, g_Engine.time);
            }

            if (Math.RandomFloat(0.0f, 1.0f) < 0.01f
                && (g_Engine.time - float(g_pInstance.m_dLastHamsterSay[m_sWheel])) > 60.0f)
            {
                g_pInstance.m_dLastHamsterSay.set(m_sWheel, g_Engine.time);
                int sayindex = Math.RandomLong(0, HAMSTER_SAY.length() - 1);
                g_PlayerFuncs.SayTextAll(pPlayer, string(pPlayer.pev.netname) + ": " + HAMSTER_SAY[sayindex] + "\n");
            }
        }
    }

    void RegisterJuiced(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.RegisterJuiced();

        if (Math.RandomFloat(0.0f, 1.0f) < (g_pInstance.m_fAccidentBaseChance * 1.5f))
        {
            g_EntityFuncs.FireTargets("erty_tryblockpipe", null, null, USE_TOGGLE);
        }
    }

    void AttemptSabotage(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        if (Math.RandomFloat(0.0f, 1.0f) < g_pInstance.m_fAccidentBaseChance)
        {
            g_EntityFuncs.FireTargets("erty_elecfault", null, null, USE_TOGGLE);
            g_pInstance.m_fLastElecFault = g_Engine.time;
        }
    }

    void BigSabotage(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        if (Math.RandomFloat(0.0f, 1.0f) < (g_pInstance.m_fAccidentBaseChance * 2)
            && (g_Engine.time - g_pInstance.m_fLastElecFault) > 45.0f)
        {
            g_EntityFuncs.FireTargets("erty_elecfault", null, null, USE_TOGGLE);
            g_pInstance.m_fLastElecFault = g_Engine.time;
        }
    }

    void RegisterLastFixed(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }
        g_pInstance.m_fLastElecFault = g_Engine.time;
    }

    void OutroSum(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_pInstance.OutroSum();
    }

        
    void ActivateCursorHint(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_Game.AlertMessage(at_console, "Oi attempting to activate HUD sprite!\n");

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);

        g_pInstance.sHudSpriteParams.holdTime = 3600.0;

        g_PlayerFuncs.HudCustomSprite(pPlayer, g_pInstance.sHudSpriteParams);
    }

    void DeactivateCursorHint(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        g_Game.AlertMessage(at_console, "Oi attempting to deactivate HUD sprite!\n");

        CBasePlayer@ pPlayer = cast<CBasePlayer>(pActivator);

        g_pInstance.sHudSpriteParams.holdTime = 0.01;

        g_PlayerFuncs.HudCustomSprite(pPlayer, g_pInstance.sHudSpriteParams);
    }

}

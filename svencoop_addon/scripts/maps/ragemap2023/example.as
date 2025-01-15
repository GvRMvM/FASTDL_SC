/**
 * Ragemap 2023: Example's part
 */

namespace Ragemap2023Example
{
    /*
     * -------------------------------------------------------------------------
     * Constants & enumerators
     * -------------------------------------------------------------------------
     */

    // TBD



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
        // Common place to do pre-caching.
    }

    /**
     * Map activation handler.
     * @return void
     */
    void MapActivate()
    {
        @g_pInstance = MapPart();

        if (!g_pInstance.Initialise()) {
            g_Game.AlertMessage(at_console, "Ragemap 2023: Example's part encountered errors initialising.\n");

            @g_pInstance = null;
            return;
        }

        g_Game.AlertMessage(at_console, "Ragemap 2023: Example's part ready.\n");
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

        // TBD



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
        }



        /*
         * -------------------------------------------------------------------------
         * Helper functions
         * -------------------------------------------------------------------------
         */

        // ... private functions you would call from inside the class here



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

            // ... perform some basic pre-flight checks here if needed

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

    /**
     * Map hook: Example of a cyclic function, which would be referenced as `Ragemap2023Example::CyclicExample` from a "trigger_script".
     * @return void
     */
    void CyclicExample(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if (g_pInstance is null) {
            return;
        }

        // ...
    }

    /**
     * Map hook: Example of a time-looped function, which would be referenced as `Ragemap2023Example::TimeLoopedExample` from a "trigger_script".
     * @return void
     */
    void TimeLoopedExample(CBaseEntity@ pActivator)
    {
        if (g_pInstance is null) {
            return;
        }

        // ...
    }
}

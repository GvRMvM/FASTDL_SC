/*============================================*/
/*==== Ragemap 2023 map B script - v 1.00 ====*/
/*============================================*/



/*
 * -------------------------------------------------------------------------
 * Includes
 * -------------------------------------------------------------------------
 */

#include "ragemap2023"
#include "ika"
#include "kezaeiv"



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
    // Shared script
    Ragemap2023::MapInit();

    // I_Ka's part
    Ragemap2023Ika::MapInit();

    // Kezaeiv's part
    kezaeiv::MapInit();
}

/**
 * Map activation handler.
 * @return void
 */
void MapActivate()
{
    // Shared script
    Ragemap2023::MapActivate();

    // I_Ka's part
    Ragemap2023Ika::MapActivate();
}

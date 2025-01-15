/*============================================*/
/*==== Ragemap 2023 map C script - v 1.00 ====*/
/*============================================*/



/*
 * -------------------------------------------------------------------------
 * Includes
 * -------------------------------------------------------------------------
 */

#include "ragemap2023"
#include "dex"
#include "giegue"
#include "levi"



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

    // Giegue's part
    GIEGUE::MapInit();

    // Levi's part
    levi::MapInit();
	
	// Dex's part
	dex::MapInit();
}

/**
 * Map activation handler.
 * @return void
 */
void MapActivate()
{
    // Shared script
    Ragemap2023::MapActivate();
}

/*============================================*/
/*==== Ragemap 2023 map A script - v 1.00 ====*/
/*============================================*/



/*
 * -------------------------------------------------------------------------
 * Includes
 * -------------------------------------------------------------------------
 */

#include "ragemap2023"
#include "adambean"
#include "erty"
#include "nih"
#include "outerbeast"



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

    // Adambean's part
    Ragemap2023Adambean::MapInit();

    // Outerbeast's part
    OUTERBEAST::Init();

    // Erty's part
    Ragemap2023Erty::MapInit();
}

/**
 * Map activation handler.
 * @return void
 */
void MapActivate()
{
    // Shared script
    Ragemap2023::MapActivate();

    // Adambean's part
    Ragemap2023Adambean::MapActivate();

    // Erty's part
    Ragemap2023Erty::MapActivate();
}

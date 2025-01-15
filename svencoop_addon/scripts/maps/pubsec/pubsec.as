#include "weapon_ps_m16"
#include "weapon_ps_mp5"
#include "weapon_ps_spas12"
#include "../point_checkpoint"
#include "weapon_ps_mk23"

void MapInit()
{
	RegisterPointCheckPointEntity();
	PSWeaponM16::Register();
	PSWeaponMP5::Register();
	PSWeaponSPAS12::Register();
	PSWeaponMK23::Register();
	
	g_SurvivalMode.EnableMapSupport();
}

void ActivateSurvival( CBaseEntity@ pActivator, CBaseEntity@ pCaller,
	USE_TYPE useType, float flValue )
{
	g_SurvivalMode.Activate();
}

void DisableSurvival( CBaseEntity@ pActivator, CBaseEntity@ pCaller, 
	USE_TYPE useType, float flValue )
{
    g_SurvivalMode.Disable();
}
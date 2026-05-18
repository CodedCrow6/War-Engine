extends Node

enum SurfaceType {
	CONCRETE, DEFAULT, GRASS, GRAVEL, METAL, MUD, WOOD
}

enum WeaponCaliber {
	# 🟤 Handguns
	PISTOL_9MM,
	PISTOL_45ACP,
	PISTOL_357_MAGNUM,
	PISTOL_22LR,

	# 🟢 SMGs
	SMG_9MM,
	SMG_45ACP,
	SMG_10MM,

	# 🔵 Rifles (Assault / Battle rifles)
	RIFLE_5_56_NATO,
	RIFLE_7_62_NATO,
	RIFLE_5_45X39,
	RIFLE_6_5_GRENDEL,

	# 🔴 Machine guns
	LMG_5_56,
	LMG_7_62,
	MMG_7_62,
	HMG_12_7MM, # .50 BMG class

	# 🟣 Shotguns
	SHOTGUN_12_GAUGE,
	SHOTGUN_20_GAUGE,
	SHOTGUN_410_BORE,

	# ⚫ Snipers
	SNIPER_7_62_NATO,
	SNIPER_338_LAPUA,
	SNIPER_50_BMG,

	# 🟡 Special / Exotic
	EXPLOSIVE_ROUNDS,
	ENERGY,
	TRACER_ONLY
}

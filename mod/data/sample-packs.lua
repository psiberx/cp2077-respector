return {
	{
		name = "clothing",
		items = { kind = "Clothing", tag = false, set = false },
	},
	{
		name = "clothing-mods",
		items = { kind = "Mod", group = "Clothing" },
	},
	{
		name = "clothing-sets",
		items = { kind = "Clothing", set = true },
	},
	{
		name = "clothing-unique",
		items = { kind = "Clothing", tag = "Unique" },
	},
	{
		name = "cyberware",
		items = { kind = "Cyberware" },
	},
	{
		name = "cyberware-iconic",
		items = { kind = "Cyberware", iconic = 1 },
	},
	{
		name = "cyberware-mods",
		items = { kind = "Mod", group = "Cyberware" },
	},
	{
		name = "gog",
		desc = "The stuff you get for buying the game in the GOG or by linking your GOG account.",
		items = { tag = "GOG" },
	},
	{
		name = "johnny",
		desc = "The stuff related to Johnny Silverhand.",
		items = { tag = "Johnny", iconic = 1 },
		vehicles = { kind = "Vehicle", tag = "Johnny" },
	},
	{
		name = "nibbles",
		desc = "The cat food item that needed to obtain Nibbles as a pet.",
		items = { tag = "Nibbles" },
	},
	{
		name = "stash-wall",
		desc = "The weapons that show up on the Stash Wall.",
		items = { set = "Stash Wall" },
	},
	{
		name = "quickhacks",
		items = { kind = "Quickhack" },
	},
	{
		name = "vehicles",
		vehicles = { kind = "Vehicle", set = "Garage" },
	},
	{
		name = "weapons",
		items = { kind = "Weapon", iconic = false },
	},
	{
		name = "weapons-atts",
		items = { kind = "Mod", group = { "Scope", "Muzzle" } },
	},
	{
		name = "weapons-iconic",
		items = { kind = "Weapon", iconic = 1 },
	},
	{
		name = "weapons-mods",
		items = { kind = "Mod", group = { "Ranged", "Melee" } }
	},
	{
		name = "patch-130",
		items = { tag = "DLC: V's New Jackets" },
		vehicles = { tag = "DLC: Atcher Quartz Bandit" },
	},
	{
		name = "patch-150",
		items = { kind = { "Clothing", "Weapon", "Mod" }, tag = "Patch 1.5" },
		vehicles = { kind = "Vehicle", tag = "Patch 1.5" },
	},
	{
		name = "patch-160",
		items = { kind = { "Clothing", "Weapon", "Mod" }, tag = "Patch 1.6" },
	},
}
return {
	{
		name = "clothing",
		items = { kind = "Clothing", tag = false },
	},
	{
		name = "clothing-mods",
		items = { kind = "Mod", group = "Clothing" },
	},
	{
		name = "clothing-sets",
		items = { kind = "Clothing", tag = { "Badge Set", "Corpo Set", "Fixer Set", "Media Set", "Netrunner Set", "Nomad Set", "Rocker Set", "Solo Set", "Techie Set" } },
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
		items = { type = { "Items.mq007_skippy",  "Items.Preset_Ajax_Moron",  "Items.Preset_Burya_Comrade",  "Items.Preset_Carnage_Mox",  "Items.Preset_Copperhead_Genesis",  "Items.Preset_Dian_Yinglong",  "Items.Preset_Grad_Panam",  "Items.Preset_Igla_Sovereign",  "Items.Preset_Katana_Saburo",  "Items.Preset_Katana_Takemura",  "Items.Preset_Liberty_Dex",  "Items.Preset_Nekomata_Breakthrough",  "Items.Preset_Nue_Jackie",  "Items.Preset_Overture_Kerry",  "Items.Preset_Overture_River",  "Items.Preset_Pulsar_Buzzsaw",  "Items.Preset_Silverhand_3516",  "Items.Preset_Tactician_Headsman",  "Items.Preset_Zhuo_Eight_Star" } },
	},
	{
		name = "quickhacks",
		items = { kind = "Quickhack" },
	},
	{
		name = "vehicles",
		vehicles = { kind = "Vehicle", group2 = false },
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
}
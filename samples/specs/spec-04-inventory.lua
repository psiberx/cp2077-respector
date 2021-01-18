--
-- The Inventory section defines items of any kind both to go the backpack and to be equipped.
--
return {
	Inventory = {
		--
		-- Let's look at the full example first to get the overall idea.
		-- And then we will examine every property available for items.
		--
		-- This example defines WIDOW MAKER tech precision rifle.
		-- Each item entry has a comment with the in-game name, category,
		-- sub-category and rarity.
		--

		-- WIDOW MAKER / Weapon / Tech / Legendary
		{
			id = "Preset_Achilles_Nash_Legendary",
			seed = 4114643488,
			slots = {
				-- E255 PERCIPIENT / Rare
				{ slot = "Scope", id = "w_att_scope_long_02", seed = 442254023, upgrade = "Rare" },
				-- COUNTERMASS / Epic
				{ slot = "Mod1", id = "SimpleWeaponMod11" },
				-- WEAKEN / Rare
				{ slot = "Mod2", id = "SimpleWeaponMod13" },
				-- CRUNCH / Epic
				{ slot = "Mod3", id = "SimpleWeaponMod01", upgrade = "Epic" },
				-- CRUNCH / Epic
				{ slot = "Mod4", id = "SimpleWeaponMod01", upgrade = "Epic" },
			},
			equip = 2,
		},

		--
		-- The first and the only required property is `id`.
		-- There are 3 ways to define an item ID:
		--
		-- 1. Item ID as a name.
		{ id = "Preset_Achilles_Nash_Legendary" },

		-- 2. Item ID as a struct.
		{ id = { hash = 0x73677016, length = 36 } },

		-- 3. Item ID as numeruc value.
		{ id = 0x7367701624 },

		--
		-- The next property is `seed`.
		-- The seed is an integer that defines unique instance of the item.
		--
		-- Some items can be actually randomized and have versions with
		-- different stats. In this case the seed is the ID of the version.
		-- The same pair of item ID + seed will always produce the same
		-- version of the item.
		--
		-- But not every item is actually randomizable. Some items will
		-- always have the same stats despite the different seed values.
		--
		{ id = "Preset_Achilles_Nash_Legendary", seed = 4114643488 },

		-- WIP
		-- `upgrade`
		-- `slots`
		-- `quest`
		-- `equip`
		-- `qty`

		-- GORILLA ARMS / Cyberware / Arms / Legendary
		{
			id = "StrongArmsLegendary",
			seed = 2309621426,
			slots = {
				-- KNUCKLES - PHYSICAL DAMAGE / Rare
				{ slot = "Knuckles", id = "PhysicalDamageKnuckles" },
				-- BLACK MARKET BATTERY / Legendary
				{ slot = "Battery", id = "AnimalsStrongArmsBattery1" },
				-- SENSORY AMPLIFER - CRIT DAMAGE / Rare
				{ slot = "Mod", id = "ArmsCyberwareSharedFragment2" },
			},
			equip = true,
		},

		-- GASH ANTIPERSONNEL GRENADE / Grenade / Epic
		{ id = "GrenadeCuttingRegular", equip = 1, qty = 8 },

		-- MAXDOC MK.1 / Consumable / Meds / Uncommon
		{ id = "FirstAidWhiffV0", equip = 3, qty = 149 },
	},
}
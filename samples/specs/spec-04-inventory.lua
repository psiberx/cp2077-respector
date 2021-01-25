--
-- The Inventory section defines items of any kind.
-- Items can go into a backpack or be equipped in the suitable slot.
--
return {
	Inventory = {
		-- This is a complete example of item to get the overall idea.
		-- This example defines WIDOW MAKER tech precision rifle.
		--
		-- When saving items each item entry gets a comment with
		-- the in-game name, category and rarity.

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

		-- The first and the only required property is `id`.
		-- There are 3 ways to define an item ID:

		-- 1. Item ID as a name.
		{ id = "Preset_Achilles_Nash_Legendary" },

		-- 2. Item ID as a struct.
		{ id = { hash = 0x73677016, length = 36 } },

		-- 3. Item ID as numeric value.
		{ id = 0x243677016 },

		-- There is also a shorthand definition on an item,
		-- when other properties are irrelevant:
		 "Preset_Achilles_Nash_Legendary",

		 -- Or with numeric value:
		 0x2473677016,

		-- The next property is `seed`.
		-- The seed is an integer that defines unique instance of the item.
		-- when paired with the item ID
		--
		-- Some items can be actually randomized and have versions with
		-- different stats. In this case the seed is the ID of the version.
		-- The same pair of item ID + seed will always produce the same
		-- version of the item.

		-- WIDOW MAKER / Weapon / Tech / Legendary
		{ id = "Preset_Achilles_Nash_Legendary", seed = 4114643488 },

		-- But not every item is actually randomizable. Some items will
		-- always have the same stats despite the different seed values.
		-- For example all cyberware have fixed stats, so the seed value
		-- doesn't affect cyberware stats.
		--
		-- In such case the seed serves only as a global unique ID of an
		-- item if paired with the item ID. This can be better explained
		-- using another property `qty` which is pretty straight forward
		-- and just defines how many pieces of an item will be produced.
		--
		-- The most basic example of `qty` use is stackable item like
		-- meds or food. This will add 50 heals to the inventory:

		-- MAXDOC MK.1 / Consumable / Meds / Uncommon
		{ id = "FirstAidWhiffV0", qty = 50 },

		-- When used with the equipment it will produce the given number of
		-- individual copies of an item. And every item will have a random seed:

		-- BIODYNE BERSERK MK.1 / Cyberware / Operating System / Uncommon
		{ id = "BerserkC2MK1", qty = 3 },

		-- WIDOW MAKER / Weapon / Tech / Legendary
		{ id = "Preset_Achilles_Nash_Legendary", qty = 3 },

		-- The difference is that all 3 copy of a weapon will have random
		-- different stats. While all 3 cyberware pieces will be the same.
		--
		-- Since item ID + seed serves as a global unique ID, and you can't
		-- have two items with the same global ID, the next combination
		-- doesn't make sence:

		-- BIODYNE BERSERK MK.1 / Cyberware / Operating System / Uncommon
		{ id = "BerserkC2MK1", seed = 1441747907, qty = 3 },

		-- The mod will discard the `qty` value and produce only one item.

		-- The next property is `upgrade`.
		-- It serve two puposes: to scale item up to level of character,
		-- and to upgrade from one rarity level to another.
		--
		-- When set to `true`, the item will be scale up to the character
		-- level but will remain of the same rarity:

		-- WIDOW MAKER / Weapon / Tech / Rare
		{ id = "Preset_Achilles_Nash", upgrade = true },

		-- When set to string with rarity name, such as "Common", "Uncommon",
		-- "Rare", "Epic", "Legendary", the item will be scale up to the character
		-- and upgraded to the given rarity:

		-- WIDOW MAKER / Weapon / Tech / Legendary
		{ id = "Preset_Achilles_Nash", upgrade = "Legendary" },

		-- For some items it's the only way to get all versions. For example,
		-- the ARMADILLO clothing mod. The only way to get the Epic version of
		-- the mod is using `upgrade`. There is no dedicated item ID for each
		-- rarity of that mod:

		-- ARMADILLO / Epic
		{ id = "SimpleFabricEnhancer01", upgrade = "Epic" },

		-- The next property is `slots`.
		-- It defines attachments and mods, and assigns them to the slot of the item.
		--
		-- Each entry of the `slots` has to define a slot name using `slot` property.
		-- Besides that each entry is just an item and everything that was said before
		-- about defining items applies to the attachments and mods.
		--
		-- For most items the names of the slots are easy to remeber or even guess:

		-- ARCHANGEL / Weapon / Power / Legendary
		{
			id = "Preset_Overture_Kerry_Legendary",
			slots = {
				-- OS-1 GIMLETEYE / Uncommon
				{ slot = "Scope", id = "w_att_scope_short_01", seed = 3868463560, upgrade = "Uncommon" },
				-- XC-10 ALECTO / Rare
				{ slot = "Muzzle", id = "w_silencer_04" },
				-- COUNTERMASS / Epic
				{ slot = "Mod1", id = "SimpleWeaponMod11" },
				-- PACIFIER / Epic
				{ slot = "Mod2", id = "SimpleWeaponMod03", upgrade = "Epic" },
			}
		},

		-- In the "Scope" slot here is OS-1 GIMLETEYE scope. And it has both `seed` and
		-- `upgrade` properties. It's because scopes are randomizable and have different
		-- rarities under the same item ID. So this is the only way to specity the exact
		-- version of a scope with the desired stats.
		--
		-- In the "Muzzle" slot here is XC-10 ALECTO silencer. And unlike scope it doesn't
		-- have any properties besides item ID. It's because silencers have fixed stats
		-- and rarity. They cannot be actually randomized or upgraded.
		--
		-- There is also two weapon mods in slots "Mod1" and "Mod2". Ranged weapons can
		-- have up to 4 mods, so there are also "Mod3" and "Mod4". If slot is omitted in
		-- the spec, then it will be empty when the item is loaded.

		-- There are couple of cyberware with unique slot names. Those slot names can be
		-- found in "samples/packs/cyberware.lua". Here an example:

		-- GORILLA ARMS / Cyberware / Arms / Legendary
		{
			id = "StrongArmsLegendary",
			slots = {
				-- KNUCKLES - PHYSICAL DAMAGE / Rare
				{ slot = "Knuckles", id = "PhysicalDamageKnuckles" },
				-- BLACK MARKET BATTERY / Legendary
				{ slot = "Battery", id = "AnimalsStrongArmsBattery1" },
				-- SENSORY AMPLIFER - CRIT DAMAGE / Rare
				{ slot = "Mod", id = "ArmsCyberwareSharedFragment2" },
			}
		},

		-- For the clothing items there is an extra option for `slots` property to get
		-- the max number of mod slots:

		-- TACTICAL HYBRID CORPORATE GLASSES / Clothing / Face / Legendary
		{ id = "Corporate_01_Set_Glasses", slots = "max" },

		-- The next property is `equip`.
		-- This property is used to assign the item to the equipment slot. There is no need
		-- to specify particular equipment area, like "Weapon" or "Head", it's resolved by
		-- the item type automatically.
		--
		-- If there is only one slot for an item type, like "Head", then it's enough to
		-- just set `eauip` to `true` to assign the item to the suitable slot.
		--
		-- If there is more than one slot, for example 3 weapon slots, then the valid
		-- options for `equip` are 1, 2, or 3:

		{ id = "Preset_Achilles_Nash_Legendary", equip = 2 },

		-- The final property is `quest`.
		-- It's used to control ther quest marker on the item.
		-- Just set to `true` or `false` to set or remove the marker:

		-- SKIPPY / Weapon / Smart / Epic
		{ id = "mq007_skippy", quest = false },
	},
}
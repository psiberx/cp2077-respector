--
-- The Crafting section defines crafting components and crafting recipes (specs).
--
return {
	Crafting = {
		Components = {
			CommonItem = 23466,
			UncommonItem = 13685,
			RareItem = 7402,
			RareUpgrade = 15908,
			EpicItem = 1107,
			EpicUpgrade = 4244,
			LegendaryItem = 363,
			LegendaryUpgrade = 612,
			UncommonQuickhack = 1054,
			RareQuickhack = 613,
			EpicQuickhack = 230,
			LegenaryQuickhack = 98,
		},

		Recipes = {
			--
			-- Each recipe is defined by the item ID to craft,
			-- not the item ID of recipe itself as a loot.
			--
			-- When saving recipes mod adds comment with the name
			-- and rarity of the item if rerity is fixed.
			--
			"Preset_Nekomata_Breakthrough", -- BREAKTHROUGH / Epic
			"Preset_Pulsar_Buzzsaw", -- BUZZSAW / Rare
			"SimpleFabricEnhancer01", -- ARMADILLO

			--
			-- If textual item ID is currently unknown then the hash value will be used.
			--
			0xBCFB0A1216, -- OZOB'S NOSE / Legendary
		},
	},
}
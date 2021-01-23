return {
	-- The directory for storing spec files.
	-- Can be any location outside of the mod.
	-- If empty then the "specs" dir of the mod is used.
	specsDir = "",

	-- The defalt spec name.
	-- Used when saving and loading without specifying a spec name (aka quick saving an quick loading).
	defaultSpec = "V",

	-- Default options for saving specs.
	defaultOptions = {

		-- If enabled, the character levels, attributes, skills, and perks will be added to the spec.
		-- If disabled, the character data will NOT be added to the spec.
		character = true,

		-- If enabled, all perks will be saved in the spec, including those not purchased.
		-- If disabled, only purchased perks will be saved.
		allPerks = false,

		-- If enabled, the currently equipped items will be added to the spec.
		-- If disabled, the current equipment will NOT be added to the spec.
		equipment = true,

		-- If enabled, the currently equipped cyberware will be added to the spec.
		-- If disabled, the current cyberware will NOT be added to the spec.
		cyberware = true,

		-- If enabled, items in the backpack will be added to the spec.
		-- If disabled, items in the backpack will NOT be added to the spec.
		backpack = true,

		-- Filter backpack items.
		rarity = false,

		-- If enabled, crafting components will be added to the spec.
		-- If disabled, crafting components will NOT be added to the spec.
		components = true,

		-- If enabled, crafting recipes will be added to the spec.
		-- If disabled, crafting recipes will NOT be added to the spec.
		recipes = true,

		-- If enabled, own vehicles will be added to the spec.
		-- If disabled, vehicles will NOT be added to the spec.
		vehicles = true,

		-- The preferred ItemID format for use in item specs:
		-- "auto" - Use hash name whenever possible.
		-- "hash" - Always use a struct with hash and length values (eg. `{ hash = 0x026C324A, length = 27 }`).
		itemFormat = "auto",

		-- How to save the RNG seed in the item spec:
		-- "auto" - Save the seed only for items that can be randomized.
		-- "always" - Always save the seed for all items.
		keepSeed = "auto",
	},

	-- Enables the GUI.
	useGui = true,

	-- Enables API access using `GetMod()`.
	useModApi = true,

	-- Enables API access using global `Respector` object.
	useGlobalApi = true,
}
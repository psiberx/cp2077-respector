return {
	-- The directory for storing spec files.
	-- Can be any location outside of the mod.
	-- If empty then the "specs" dir of the mod is used.
	specsDir = "",

	-- The defalt spec name.
	-- Used when saving and loading without specifying a spec name (aka quick saving an quick loading).
	defaultSpec = "V",

	-- The preferred ItemID format for use in item specs:
	-- "auto" - Use item name whenever possible.
	-- "hash" - Always use a struct with hash and length values (eg. `{ hash = 0x026C324A, length = 27 }`).
	-- Sets default value for "itemFormat" option when saving specs.
	itemFormat = "auto",

	-- How to save the RNG seed in the item spec:
	-- "auto" - Save the seed only for items that can be randomized.
	-- "always" - Always save the seed for all items.
	-- Sets default value for "keepSeed" option when saving specs.
	keepSeed = "auto",

	-- If enabled, all perks will be saved in the spec, including those not purchased.
	-- If disabled, only purchased perks will be saved.
	-- Sets default value for "exportAllPerks" option when saving specs.
	exportAllPerks = false,

	-- If enabled, crafting components will be added to the spec.
	-- If disabled, crafting components will NOT be added to the spec.
	-- Sets default value for "exportComponents" option when saving specs.
	exportComponents = true,

	-- If enabled, crafting recipes will be added to the spec.
	-- If disabled, crafting recipes will NOT be added to the spec.
	-- Sets default value for "exportRecipes" option when saving specs.
	exportRecipes = true,

	-- Enables API access using `GetMod()`.
	useModApi = true,

	-- Enables mod functions in the global Game object.
	useGlobalApi = true,

	-- Enables the GUI.
	useGui = false,

	-- Hotkey to open / close the GUI.
	-- You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
	openGuiKey = 0x70, -- F1

	-- Hotkey to save spec with currently selected options in the GUI.
	-- You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
	saveSpecKey = 0x71, -- F2
}
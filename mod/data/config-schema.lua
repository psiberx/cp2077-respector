local mod = ...

local function keyCodeDesc(value)
	local keyCodes = mod.load('mod/data/virtual-key-codes')
	for _, keyCode in ipairs(keyCodes) do
		if keyCode.code == value then
			return keyCode.desc
		end
	end
end

return {
	children = {
		{
			name = "specsDir",
			comment = {
				"The directory for storing spec files.",
				"Can be any location outside of the mod.",
				"If empty then the \"specs\" dir of the mod is used.",
			},
			default = "",
		},
		{
			name = "defaultSpec",
			comment = {
				"The defalt spec name.",
				"Used when saving and loading without specifying a spec name (aka quick saving an quick loading).",
			},
			default = "V",
			margin = true,
		},
		{
			name = "itemFormat",
			comment = {
				"The preferred ItemID format for use in item specs:",
				"\"auto\" - Use item name whenever possible.",
				"\"hash\" - Always use a struct with hash and length values (eg. `{ hash = 0x026C324A, length = 27 }`).",
				"Sets default value for \"itemFormat\" option when saving specs.",
			},
			default = "auto",
			margin = true,
		},
		{
			name = "keepSeed",
			comment = {
				"How to save the RNG seed in the item spec:",
				"\"auto\" - Save the seed only for items that can be randomized.",
				"\"always\" - Always save the seed for all items.",
				"Sets default value for \"keepSeed\" option when saving specs.",
			},
			default = "auto",
			margin = true,
		},
		{
			name = "exportAllPerks",
			comment = {
				"If enabled, all perks will be saved in the spec, including those not purchased.",
				"If disabled, only purchased perks will be saved.",
				"Sets default value for \"exportAllPerks\" option when saving specs.",
			},
			default = false,
			margin = true,
		},
		{
			name = "exportComponents",
			comment = {
				"If enabled, crafting components will be added to the spec.",
				"If disabled, crafting components will NOT be added to the spec.",
				"Sets default value for \"exportComponents\" option when saving specs.",
			},
			default = true,
			margin = true,
		},
		{
			name = "exportRecipes",
			comment = {
				"If enabled, crafting recipes will be added to the spec.",
				"If disabled, crafting recipes will NOT be added to the spec.",
				"Sets default value for \"exportRecipes\" option when saving specs.",
			},
			default = true,
			margin = true,
		},
		{
			name = "useModApi",
			comment = {
				"Enables API access using `GetMod()`.",
			},
			default = true,
			margin = true,
		},
		{
			name = "useGlobalApi",
			comment = {
				"Enables API access using global Respector object.",
			},
			default = true,
			margin = true,
		},
		{
			name = "useGui",
			comment = {
				"Enables the GUI.",
			},
			default = false,
			margin = true,
		},
		{
			name = "openGuiKey",
			comment = {
				"Hotkey to open / close the GUI.",
				"You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes",
			},
			comment2 = keyCodeDesc,
			format = "0x%02X",
			default = 0x70,
			margin = true,
		},
		{
			name = "saveSpecKey",
			comment = {
				"Hotkey to save spec with currently selected options in the GUI.",
				"You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes",
			},
			comment2 = keyCodeDesc,
			format = "0x%02X",
			default = 0x71,
			margin = true,
		},
	}
}
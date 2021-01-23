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
			margin = true,
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
			name = "defaultOptions",
			comment = {
				"Default options for saving specs.",
			},
			default = {},
			margin = true,
			children = {
				{
					name = "character",
					comment = {
						"If enabled, the character levels, attributes, skills, and perks will be added to the spec.",
						"If disabled, the character data will NOT be added to the spec.",
					},
					default = true,
					margin = "always",
				},
				{
					name = "allPerks",
					comment = {
						"If enabled, all perks will be saved in the spec, including those not purchased.",
						"If disabled, only purchased perks will be saved.",
					},
					default = false,
					margin = true,
				},
				{
					name = "equipment",
					comment = {
						"If enabled, the currently equipped items will be added to the spec.",
						"If disabled, the current equipment will NOT be added to the spec.",
					},
					default = true,
					margin = true,
				},
				{
					name = "cyberware",
					comment = {
						"If enabled, the currently equipped cyberware will be added to the spec.",
						"If disabled, the current cyberware will NOT be added to the spec.",
					},
					default = true,
					margin = true,
				},
				{
					name = "backpack",
					comment = {
						"If enabled, items in the backpack will be added to the spec.",
						"If disabled, items in the backpack will NOT be added to the spec.",
					},
					default = true,
					margin = true,
				},
				{
					name = "rarity",
					comment = {
						"Filter backpack items.",
					},
					default = false,
					margin = true,
				},
				{
					name = "components",
					comment = {
						"If enabled, crafting components will be added to the spec.",
						"If disabled, crafting components will NOT be added to the spec.",
					},
					default = true,
					margin = true,
				},
				{
					name = "recipes",
					comment = {
						"If enabled, crafting recipes will be added to the spec.",
						"If disabled, crafting recipes will NOT be added to the spec.",
					},
					default = true,
					margin = true,
				},
				{
					name = "vehicles",
					comment = {
						"If enabled, own vehicles will be added to the spec.",
						"If disabled, vehicles will NOT be added to the spec.",
					},
					default = true,
					margin = true,
				},
				{
					name = "itemFormat",
					comment = {
						"The preferred ItemID format for use in item specs:",
						"\"auto\" - Use hash name whenever possible.",
						"\"hash\" - Always use a struct with hash and length values (eg. `{ hash = 0x026C324A, length = 27 }`).",
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
					},
					default = "auto",
					margin = true,
				},
			}
		},
		{
			name = "useGui",
			comment = {
				"Enables the GUI.",
			},
			default = true,
			margin = true,
		},
		{
			name = "openGuiKey",
			comment = {
				"Hotkey to open / close the Respector window.",
				"You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes",
			},
			comment2 = keyCodeDesc,
			format = "0x%02X",
			default = 0x70,
			margin = true,
		},
		{
			name = "openTweakerKey",
			comment = {
				"Hotkey to open / close the Quick Tweaks window.",
				"You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes",
			},
			comment2 = keyCodeDesc,
			format = "0x%02X",
			default = 0x7B,
			margin = true,
		},
		{
			name = "saveSpecKey",
			comment = {
				"Hotkey to save spec using current settings.",
				"You can find key codes here: https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes",
			},
			comment2 = keyCodeDesc,
			format = "0x%02X",
			default = 0x71,
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
				"Enables API access using global `Respector` object.",
			},
			default = true,
			margin = true,
		},
	}
}
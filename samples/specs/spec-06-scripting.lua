--
-- Scripting example:
-- For every legendary clothing mod creates a Corpo Glasses with that mod in each slot.
--

-- This opens access to the mod functions
local ctx = ...

-- Load TweakDb class to access metadata
local TweakDb = ctx.require("mod/helpers/TweakDb")

-- Create instance and load the metadata
local tweakDb = TweakDb:new(true)

-- Table to store our items
local backpack = {}

-- Iterate every legendary clothing mod
for _, mod in tweakDb:filter({ kind = "Mod", group = "Clothing", quality = "Legendary" }) do

	-- Item spec with slots container
	local glasses = {
		id = "Corporate_01_Set_Glasses",
		slots = {}
	}

	-- Put mod in every mod slot
	for index = 1, 3 do
		table.insert(glasses.slots, {
			slot = "Mod" .. index,
			id = mod.type,
		})
	end

	-- Add to the table
	table.insert(backpack, glasses)
end

-- Free database resources
tweakDb:unload()

-- Return the final spec
return {
	Backpack = backpack
}
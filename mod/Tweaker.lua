local mod = ...
local TweakDb = mod.require('mod/helpers/TweakDb')

local Tweaker = {}
Tweaker.__index = Tweaker

function Tweaker:new(respector)
	local this = { respector = respector }

	setmetatable(this, self)

	return this
end

function Tweaker:addPack(packSpec, cheatMode)
	local tweakDb = TweakDb:new(true)

	local itemSpecs = {}
	local itemUpgrade = packSpec.upgrade

	if packSpec.upgrade then
		packSpec.upgrade = nil
	end

	for _, itemMeta in tweakDb:filter(packSpec) do
		local itemSpec = {}

		itemSpec.id = itemMeta.type

		if not itemMeta.quality and itemUpgrade then
			itemSpec.upgrade = itemUpgrade
		end

		if itemMeta.kind == 'Clothing' then
			itemSpec.slots = 'max'
		end

		table.insert(itemSpecs, itemSpec)
	end

	tweakDb:unload()

	self.respector:execSpec({ Backpack = itemSpecs }, { cheat = cheatMode })
end

function Tweaker:addItem(itemSpec, cheatMode)
	self.respector:execSpec({ Inventory = { itemSpec } }, { cheat = cheatMode })
end

function Tweaker:addRecipe(itemId)
	self.respector:usingModule('crafting', function(crafting)
		crafting:addRecipe(itemId)
	end)
end

function Tweaker:getResource(resourceId)
	resourceId = TweakDb.toItemId(resourceId, false)

	return Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), resourceId)
end

function Tweaker:addResource(resourceId, resourceAmount)
	resourceId = TweakDb.toItemId(resourceId, false)

	Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), resourceId, resourceAmount)
end

function Tweaker:hasVehicle(vehicleId)
	return self.respector:usingModule('transport', function(transport)
		return transport:isVehicleUnlocked(vehicleId)
	end)
end

function Tweaker:canHaveVehicle(vehicleId)
	return (vehicleId:find('_player$')) and true or false
end

function Tweaker:addVehicle(vehicleId)
	self.respector:usingModule('transport', function(transport)
		transport:unlockVehicle(vehicleId)
	end)
end

function Tweaker:spawnVehicle(vehicleId)
	self:execHack('SpawnVehicle', vehicleId)
end

function Tweaker:getFact(factName)
	return Game.GetQuestsSystem():GetFactStr(factName) == 1
end

function Tweaker:setFact(factName, factState)
	Game.GetQuestsSystem():SetFactStr(factName, factState and 1 or 0)
end

function Tweaker:execHack(tweakName, ...)
	local tweakFunc = mod.load('mod/hacks/' .. tweakName)

	if type(tweakFunc) == 'function' then
		tweakFunc(select(1, ...))
	end
end

return Tweaker
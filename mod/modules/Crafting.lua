local mod = ...
local str = mod.require('mod/utils/str')
local TweakDb = mod.require('mod/helpers/TweakDb')

local CraftingModule = {}
CraftingModule.__index = CraftingModule

function CraftingModule:new()
	local this = { tweakDb = TweakDb:new() }

	setmetatable(this, CraftingModule)

	return this
end

function CraftingModule:prepare()
	local scriptableSystemsContainer = Game.GetScriptableSystemsContainer()

	self.player = Game.GetPlayer()
	self.transactionSystem = Game.GetTransactionSystem()
	self.craftingSystem = scriptableSystemsContainer:Get(CName.new('CraftingSystem'))
	self.playerCraftBook = self.craftingSystem:GetPlayerCraftBook()
end

function CraftingModule:release()
	self.player = nil
	self.transactionSystem = nil
	self.craftingSystem = nil
	self.playerCraftBook = nil
end

function CraftingModule:getComponents()
	local components = mod.load('mod/data/crafting-components')
	local componentSpecs = {}

	for componentAlias, component in pairs(components) do
		local componentId = ItemID.new(TweakDBID.new(component.type))
		local componentQty = self.transactionSystem:GetItemQuantity(self.player, componentId)

		componentSpecs[componentAlias] = componentQty
	end

	return componentSpecs
end

function CraftingModule:getRecipes()
	self.tweakDb:load('mod/data/tweakdb-meta')

	local recipeSpecs = {}

	for itemKey, itemMeta in self.tweakDb:iterate() do
		local itemId = self.tweakDb:getTweakDbId(itemKey)

		if self.craftingSystem:IsRecipeKnown(itemId, self.playerCraftBook) then
			local recipeSpec = {}

			if itemMeta.type == '' then
				recipeSpec[1] = itemKey
			else
				recipeSpec[1] = str.without(itemMeta.type, 'Items.')
			end

			recipeSpec._comment = self.tweakDb:describe(itemMeta)
			recipeSpec._order = self.tweakDb:order(itemMeta)

			table.insert(recipeSpecs, recipeSpec)
		end
	end

	self.tweakDb:unload()

	if #recipeSpecs > 0 then
		table.sort(recipeSpecs, function(a, b) return a._order < b._order end)

		return recipeSpecs
	end

	return nil
end

function CraftingModule:setComponents(componentSpecs)
	local components = mod.load('mod/data/crafting-components')

	for componentAlias, componentQty in pairs(componentSpecs) do
		local component = components[componentAlias]
		local componentId = ItemID.new(TweakDBID.new(component.type))
		local currentQty = self.transactionSystem:GetItemQuantity(self.player, componentId)

		if currentQty ~= componentQty then
			self.transactionSystem:GiveItem(self.player, componentId, componentQty - currentQty)
		end
	end
end

function CraftingModule:setRecipes(recipeSpecs)
	for _, itemType in ipairs(recipeSpecs) do
		if type(itemType) == 'string' then
			itemType = str.with(itemType, 'Items.')
		end

		local itemId = self.tweakDb:getTweakDbId(itemType)

		self.playerCraftBook:AddRecipe(itemId, {}, 1)
	end
end

function CraftingModule:applySpec(specData)
	if specData.Crafting then
		if specData.Crafting.Components then
			self:setComponents(specData.Crafting.Components)
		end

		if specData.Crafting.Recipes then
			self:setRecipes(specData.Crafting.Recipes)
		end
	end
end

function CraftingModule:fillSpec(specData, specOptions)
	if specOptions.exportComponents or specOptions.exportRecipes then
		specData.Crafting = {}

		if specOptions.exportComponents then
			local componentData = self:getComponents()

			if componentData then
				specData.Crafting.Components = componentData
			end
		end

		if specOptions.exportRecipes then
			local recipeData = self:getRecipes()

			if recipeData then
				specData.Crafting.Recipes = recipeData
			end
		end
	end
end

return CraftingModule
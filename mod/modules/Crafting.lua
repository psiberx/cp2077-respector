local mod = ...
local TweakDb = mod.require('mod/helpers/TweakDb')

local CraftingModule = {}
CraftingModule.__index = CraftingModule

function CraftingModule:new()
	local this = { tweakDb = TweakDb:new() }

	setmetatable(this, self)

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

function CraftingModule:fillSpec(specData, specOptions)
	if specOptions.components or specOptions.recipes then
		specData.Crafting = {}

		if specOptions.components then
			local componentData = self:getComponents()

			if componentData then
				specData.Crafting.Components = componentData
			end
		end

		if specOptions.recipes then
			local recipeData = self:getRecipes()

			if recipeData then
				specData.Crafting.Recipes = recipeData
			end
		end
	end
end

function CraftingModule:applySpec(specData)
	if specData.Crafting then
		if specData.Crafting.Components then
			self:setComponents(specData.Crafting.Components)
		end

		if specData.Crafting.Recipes then
			self:addRecipes(specData.Crafting.Recipes)
		end
	end
end

function CraftingModule:getComponents()
	local components = mod.load('mod/data/crafting-components')
	local componentSpecs = {}

	for componentAlias, component in pairs(components) do
		local componentId = ItemID.new(TweakDBID.new(component.id))
		local componentQty = self.transactionSystem:GetItemQuantity(self.player, componentId)

		componentSpecs[componentAlias] = componentQty
	end

	return componentSpecs
end

function CraftingModule:setComponents(componentSpecs)
	local components = mod.load('mod/data/crafting-components')

	for componentAlias, componentQty in pairs(componentSpecs) do
		local component = components[componentAlias]
		local componentId = ItemID.new(TweakDBID.new(component.id))
		local currentQty = self.transactionSystem:GetItemQuantity(self.player, componentId)

		if currentQty ~= componentQty then
			self.transactionSystem:GiveItem(self.player, componentId, componentQty - currentQty)
		end
	end
end

function CraftingModule:getRecipes()
	self.tweakDb:load('mod/data/tweakdb-meta')

	local recipeSpecs = {}

	for itemKey, itemMeta in self.tweakDb:each() do
		if self:isRecipeKnown(itemKey) then
			local recipeSpec = {}

			if itemMeta.id == '' then
				recipeSpec[1] = itemKey
			else
				recipeSpec[1] = TweakDb.toItemAlias(itemMeta.id)
			end

			recipeSpec._comment = self.tweakDb:describe(itemMeta)
			recipeSpec._order = self.tweakDb:order(itemMeta)

			table.insert(recipeSpecs, recipeSpec)
		end
	end

	self.tweakDb:unload()

	if #recipeSpecs == 0 then
		return nil
	end

	self.tweakDb:sort(recipeSpecs)

	return recipeSpecs
end

function CraftingModule:isRecipeKnown(tweakId)
	tweakId = TweakDb.toItemTweakId(tweakId)

	return self.craftingSystem:IsRecipeKnown(tweakId, self.playerCraftBook)
end

function CraftingModule:addRecipe(tweakId)
	tweakId = TweakDb.toItemTweakId(tweakId)

	self.playerCraftBook:AddRecipe(tweakId, {}, 1)
end

function CraftingModule:addRecipes(recipeSpecs)
	for _, itemId in ipairs(recipeSpecs) do
		self:addRecipe(itemId)
	end
end

return CraftingModule
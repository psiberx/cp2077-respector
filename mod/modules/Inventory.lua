local mod = ...
local Quality = mod.require('mod/enums/Quality')
local RarityFilter = mod.require('mod/enums/RarityFilter')
local TweakDb = mod.require('mod/helpers/TweakDb')
local SimpleDb = mod.require('mod/helpers/SimpleDb')

-- ME-THRILL
local slotBlocker = { hash = 0x4C882AC5, length = 25 }

local InventoryModule = {}
InventoryModule.__index = InventoryModule

function InventoryModule:new()
	local this = {
		tweakDb = TweakDb:new(),
		equipAreaDb = SimpleDb:new(),
	}

	setmetatable(this, self)

	return this
end

function InventoryModule:prepare()
	local scriptableSystemsContainer = Game.GetScriptableSystemsContainer()
	local equipmentSystem = scriptableSystemsContainer:Get(CName.new('EquipmentSystem'))

	self.player = Game.GetPlayer()
	self.transactionSystem = Game.GetTransactionSystem()
	self.inventoryManager = Game.GetInventoryManager()
	self.playerEquipmentData = equipmentSystem:GetPlayerData(self.player)
	self.playerInventoryData = self.playerEquipmentData:GetInventoryManager()
	self.craftingSystem = scriptableSystemsContainer:Get(CName.new('CraftingSystem'))
	self.gameRPGManager = GetSingleton('gameRPGManager')
	self.forceItemQuality = Game['gameRPGManager::ForceItemQuality;GameObjectgameItemDataCName']
	self.itemModSystem = scriptableSystemsContainer:Get(CName.new('ItemModificationSystem'))

	self.tweakDb:load('mod/data/tweakdb-meta')
	self.equipAreaDb:load('mod/data/equipment-areas')

	self.attachmentSlots = mod.load('mod/data/attachment-slots')

	self.playerEquipmentData['EquipItemInSlot'] = self.playerEquipmentData['EquipItem;ItemIDInt32BoolBoolBool']
	self.playerEquipmentData['GetItemInEquipSlotArea'] = self.playerEquipmentData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']
	self.playerEquipmentData['GetSlotIndexInArea'] = self.playerEquipmentData['GetSlotIndex;ItemIDgamedataEquipmentArea']
end

function InventoryModule:release()
	self.player = nil
	self.transactionSystem = nil
	self.inventoryManager = nil
	self.playerEquipmentData = nil
	self.playerInventoryData = nil
	self.craftingSystem = nil
	self.gameRPGManager = nil
	self.forceItemQuality = nil
	self.itemModSystem = nil

	self.tweakDb:unload()
	self.equipAreaDb:unload()

	self.attachmentSlots = nil
end

function InventoryModule:fillSpec(specData, specOptions)
	if specOptions.equipment then
		specData.Equipment = self:getEquipmentItems(specOptions)
	end

	if specOptions.cyberware then
		specData.Cyberware = self:getCyberwareItems(specOptions)
	end

	if specOptions.backpack then
		specData.Backpack = self:getBackpackItems(specOptions)
	end
end

function InventoryModule:applySpec(specData, specOptions)
	local equipedSlots = {}
	local updateEquipment = false
	local updateCyberware = false
	local updateInventory = false

	if specData.Equipment and #specData.Equipment > 0 then
		self:applyItemSpecs(specData.Equipment, specOptions, equipedSlots)
		updateEquipment = true
	end

	if specData.Cyberware and #specData.Cyberware > 0 then
		self:applyItemSpecs(specData.Cyberware, specOptions, equipedSlots)
		updateCyberware = true
	end

	if specData.Backpack and #specData.Backpack > 0 then
		self:applyItemSpecs(specData.Backpack, specOptions)
	end

	if specData.Inventory and #specData.Inventory > 0 then
		self:applyItemSpecs(specData.Inventory, specOptions, equipedSlots)
		updateInventory = true
	end

	if updateEquipment or updateCyberware or updateInventory then
		self:equipUsedSlots(equipedSlots)

		mod.after(0.5, function()
			if updateEquipment then
				self:unequipUnusedSlots({ kind = { 'Weapon', 'Clothing', 'Grenade', 'Consumable' } }, equipedSlots)
			end

			if updateCyberware then
				self:unequipUnusedSlots({ kind = 'Cyberware' }, equipedSlots)
			end
		end)
	end
end

function InventoryModule:getEquipmentItems(specOptions)
	local equipmentItemIds = {}

	for _, equipArea in self.equipAreaDb:filter({ kind = { 'Weapon', 'Clothing', 'Grenade', 'Consumable' } }) do
		for slotIndex = 1, equipArea.max do
			local itemId = self.playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.id.hash ~= 0 then
				table.insert(equipmentItemIds, itemId)
			end
		end
	end

	return self:getItemsById(equipmentItemIds, specOptions)
end

function InventoryModule:getCyberwareItems(specOptions)
	local cyberwareItemIds = {}

	for _, equipArea in self.equipAreaDb:filter({ kind = 'Cyberware' }) do
		for slotIndex = 1, equipArea.max do
			local itemId = self.playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.id.hash ~= 0 then
				table.insert(cyberwareItemIds, itemId)
			end
		end
	end

	return self:getItemsById(cyberwareItemIds, specOptions)
end

function InventoryModule:getBackpackItems(specOptions)
	local itemIds = {}

	-- 'Progression Shard' -- It's a bug that it's stored?
	local baseCriteria = { kind = { 'Weapon', 'Clothing', 'Cyberware', 'Mod', 'Grenade', 'Consumable', 'Quickhack' } }
	local extraCriteria

	if specOptions.rarity then
		extraCriteria = RarityFilter.asCriteria(specOptions.rarity)
	end

	local backpackData = self.playerInventoryData:GetPlayerInventoryItemsExcludingLoadout()

	for _, itemData in ipairs(backpackData) do
		local itemMatch = false

		if extraCriteria then
			if extraCriteria.quality ~= nil and not itemMatch then
				local itemQualityIndex = Quality.toValue(self.gameRPGManager:GetItemDataQuality(itemData).value)
				local criteriaQualityIndex = Quality.toValue(extraCriteria.quality)
				if itemQualityIndex >= criteriaQualityIndex then
					itemMatch = true
				end
			end

			if extraCriteria.iconic ~= nil and not itemMatch then
				local itemIconic = self.gameRPGManager:IsItemDataIconic(itemData)
				if extraCriteria.iconic == itemIconic then
					itemMatch = true
				end
			end
		else
			itemMatch = true
		end

		if itemMatch then
			local itemId = itemData:GetID()
			local itemMeta = self.tweakDb:resolve(itemId.id)

			--if not itemMeta or self.tweakDb:match(itemMeta, baseCriteria) then
			if itemMeta and self.tweakDb:match(itemMeta, baseCriteria) then
				table.insert(itemIds, itemData:GetID())
			end
		end
	end

	local itemSpecs = self:getItemsById(itemIds, specOptions)

	if itemSpecs and #itemSpecs > 0 then
		self.tweakDb:sort(itemSpecs)
	end

	return itemSpecs
end

function InventoryModule:getItemsById(itemIds, specOptions)
	local itemSpecs = {}
	local itemSpecsByTweakDbId = {}

	for _, itemId in ipairs(itemIds) do
		local itemData = self.transactionSystem:GetItemData(self.player, itemId)

		-- Sometimes equipment system bugs out and gives ItemID for an actually empty slot.
		-- When this happens, GetItemData() will return nil, so we have to check that.
		if itemData ~= nil then
			local itemKey = TweakDb.toKey(itemId.id)
			local itemMeta = self.tweakDb:resolve(itemKey)
			local itemQty = self.transactionSystem:GetItemQuantity(self.player, itemId)
			local itemQuality = self.gameRPGManager:GetItemDataQuality(itemData).value
			local itemSkip = false

			if itemData:HasTag('Quest') then
				itemSkip = true

			elseif itemSpecsByTweakDbId[itemKey] and itemMeta and not itemMeta.rng then
				local itemSpec = itemSpecsByTweakDbId[itemKey]

				if itemMeta.quality or itemSpec.upgrade == itemQuality then
					if not itemSpec.qty then
						itemSpec.qty = 1
					end

					itemSpec.qty = itemSpec.qty + itemQty

					itemSkip = true
				end
			end

			if not itemSkip then
				local itemSpec = {}
				local itemEquipArea, itemSlotIndex

				if self:isEquipped(itemId) then
					local itemEquipAreaData = self.playerEquipmentData:GetEquipAreaFromItemID(itemId)

					itemEquipArea = self.equipAreaDb:find({ type = itemEquipAreaData.areaType.value })
					itemSlotIndex = self.playerEquipmentData:GetSlotIndex(itemId) + 1
				end

				if itemMeta ~= nil then
					if itemMeta.type ~= '' and specOptions.itemFormat == 'auto' then
						itemSpec.id = TweakDb.toItemAlias(itemMeta.type)
					elseif specOptions.itemFormat == 'struct' then
						itemSpec.id = TweakDb.toStruct(itemKey)
					else
						itemSpec.id = itemKey
					end

					if itemMeta.rng or specOptions.keepSeed == 'always' then
						itemSpec.seed = itemId.rng_seed
					end

					if itemMeta.quality == nil then
						itemSpec.upgrade = itemQuality
					end

					itemSpec._comment = self.tweakDb:describe(itemMeta, true)
					itemSpec._order = self.tweakDb:order(itemMeta, true)
				else
					if specOptions.itemFormat == 'struct' then
						itemSpec.id = TweakDb.toStruct(itemKey)
					else
						itemSpec.id = itemKey
					end

					itemSpec.seed = itemId.rng_seed
					itemSpec.upgrade = itemQuality

					itemSpec._comment = '???'
					itemSpec._order = self.tweakDb:orderLast()

					if itemEquipArea then
						itemSpec._comment = itemSpec._comment .. ' / ' .. itemEquipArea.name
						itemSpec._order = itemSpec._order .. '::' .. itemEquipArea.name
					end
				end

				if (not itemMeta or not itemMeta.quality) and itemQuality ~= 'Invalid' then
					itemSpec._comment = itemSpec._comment .. ' / ' .. itemQuality
				end

				self:appendStatsComment(itemSpec, itemMeta, itemData)

				local itemParts = itemData:GetItemParts()
				local itemPartsBySlots = {}

				for _, part in ipairs(itemParts) do
					if part then
						local slotId = part:GetSlotID(part)
						local slotMeta = self.tweakDb:resolve(slotId)

						if slotMeta and slotMeta.kind == 'Slot' then
							itemPartsBySlots[slotMeta.type] = part:GetItemID(part)
						end
					end
				end

				if not itemMeta or (itemMeta.kind ~= 'Mod' and itemMeta.kind ~= 'Quickhack') then
					for _, slotMeta in ipairs(self.attachmentSlots) do
						local slotId = self.tweakDb:toSlotTweakId(slotMeta.type)

						if itemData:HasPartInSlot(slotId) then
							if itemSpec.slots == nil then
								itemSpec.slots = {}
								itemSpec._inline = false
							end

							local partSpec = {}

							local partId = itemPartsBySlots[slotMeta.type]
							local partMeta = self.tweakDb:resolve(partId.id)

							local partData = self.inventoryManager:CreateItemData(partId, self.player)
							local partQuality = self.gameRPGManager:GetItemDataQuality(partData).value

							partSpec.slot = slotMeta.slot

							if partMeta ~= nil then
								if partMeta.type ~= '' and specOptions.itemFormat == 'auto' then
									partSpec.id = TweakDb.toItemAlias(partMeta.type)
								elseif specOptions.itemFormat == 'struct' then
									partSpec.id = TweakDb.toStruct(partId.id)
								else
									partSpec.id = TweakDb.toKey(partId.id)
								end

								if partMeta.rng or specOptions.keepSeed == 'always' then
									partSpec.seed = partId.rng_seed
								end

								if partMeta.quality == nil then
									partSpec.upgrade = partQuality
								end

								partSpec._comment = self.tweakDb:describe(partMeta)
							else
								if specOptions.itemFormat == 'struct' then
									partSpec.id = TweakDb.toStruct(partId.id)
								else
									partSpec.id = TweakDb.toKey(partId.id)
								end

								partSpec.seed = partId.rng_seed
								partSpec.upgrade = partQuality

								partSpec._comment = '???'
							end

							if (not partMeta or partMeta.quality == nil) and partQuality ~= 'Invalid' then
								partSpec._comment = partSpec._comment .. ' / ' .. partQuality
							end

							self:appendStatsComment(partSpec, partMeta, partData)

							table.insert(itemSpec.slots, partSpec)
						end
					end
				end

				if itemEquipArea then
					if itemEquipArea.max > 1 then
						itemSpec.equip = itemSlotIndex
					else
						itemSpec.equip = true
					end
				end

				if itemMeta and itemMeta.quest then
					itemSpec.quest = itemData:HasTag('Quest')
				else
					if itemData:HasTag('Quest') then
						itemSpec.quest = true
					end
				end

				if itemQty > 1 then
					itemSpec.qty = itemQty
				end

				table.insert(itemSpecs, itemSpec)

				itemSpecsByTweakDbId[TweakDb.toKey(itemId.id)] = itemSpec
			end
		end
	end

	if #itemSpecs == 0 then
		return nil
	end

	return itemSpecs
end

function InventoryModule:appendStatsComment(itemSpec, itemMeta, itemData)
	if itemMeta and itemMeta.kind == 'Mod' and itemMeta.group == 'Scope' then
		local ads = itemData:GetStatValueByType('AimInTime')
		local range = itemData:GetStatValueByType('EffectiveRange')

		itemSpec._comment = itemSpec._comment .. '\n' .. ('ADS Time %.2f%% / Range +%.2f'):format(ads, range)
	end
end

function InventoryModule:applyItemSpecs(itemSpecs, specOptions, equipedSlots)
	for _, itemSpec in ipairs(itemSpecs) do
		self:applyItemSpec(itemSpec, specOptions, equipedSlots)
	end
end

function InventoryModule:applyItemSpec(itemSpec, specOptions, equipedSlots)
	itemSpec = self:completeItemSpec(itemSpec)

	local removedParts = {}

	-- Resolve item

	local tweakId = TweakDb.toItemTweakId(itemSpec.id)
	local itemMeta = self.tweakDb:resolve(tweakId) or { rng = true }
	local itemId, itemCopy

	if itemMeta.stack then
		itemCopy = 1
		if not itemSpec.qty then
			itemSpec.qty = 1
		end
	else
		if itemSpec.seed then
			-- Cannot have more than one item with the same seed
			itemCopy = 1

			--if itemSpec.qty and itemSpec.qty > 1 then
			--	print(warning)
			--end
		else
			itemCopy = (itemSpec.qty or 1)
		end
	end

	for _ = 1, itemCopy do
		itemId = TweakDb.toItemId(tweakId, itemSpec.seed)

		local itemEquip = itemSpec.equip == true or type(itemSpec.equip) == 'number'
		local itemEquipIndex = itemSpec.equip and math.max(1, type(itemSpec.equip) == 'number' and itemSpec.equip or 1)

		-- Add item to inventory

		local skipCopy = false
		local currentQty = self.transactionSystem:GetItemQuantity(self.player, itemId)
		local currentEquipIndex = self.playerEquipmentData:GetSlotIndex(itemId) + 1

		if itemMeta.stack then
			self.transactionSystem:GiveItem(self.player, itemId, itemSpec.qty - currentQty)
		else
			-- Never add the exact same item (hash + seed) if it's already in inventory
			if currentQty == 0 then
				self.transactionSystem:GiveItem(self.player, itemId, 1)
			else
				if self:isEquipped(itemId) then
					if not equipedSlots then
						skipCopy = true
					else
						if itemMeta.kind == 'Clothing' or itemMeta.group == 'Operating System' then
							self.playerEquipmentData:RemoveItemFromEquipSlot(itemId)
							self:unequipItem(itemId)
						elseif not itemEquip or itemEquipIndex ~= currentEquipIndex then
							self:unequipItem(itemId)
						end
					end
				end
			end
		end

		local itemData = self.transactionSystem:GetItemData(self.player, itemId)

		if itemData ~= nil and not skipCopy then
			local itemType = itemData:GetItemType().value

			-- Guarantee max number of slots

			if itemSpec.slots == 'max' then -- and itemMeta.kind == 'Clothing'
				for _, part in ipairs(itemData:GetItemParts()) do
					local slotId = part:GetSlotID(part)
					local partItemId = part:GetItemID(part)

					if partItemId.id.hash == slotBlocker.hash and partItemId.id.length == slotBlocker.length then
						self.itemModSystem:RemoveItemPart(self.player, itemId, slotId, true)
						table.insert(removedParts, partItemId)
					end
				end
			end

			-- Manage mods and attachments

			if type(itemSpec.slots) == 'table' then -- and (itemMeta.kind == 'Weapon' or itemMeta.kind == 'Clothing' or itemMeta.kind == 'Cyberware')
				for _, slotMeta in ipairs(self.attachmentSlots) do
					local slotId = TweakDb.toTweakId(slotMeta.type)

					if itemData:HasPartInSlot(slotId) then
						local partItemId = self.itemModSystem:RemoveItemPart(self.player, itemId, slotId, true)

						if partItemId then
							table.insert(removedParts, partItemId)
						end
					end
				end

				for key, slotSpec in pairs(itemSpec.slots) do
					if type(slotSpec) == 'string' then
						slotSpec = {
							id = slotSpec
						}
					end

					if type(key) == 'string' then
						slotSpec.slot = key
					end

					if slotSpec.slot and slotSpec.id then
						local slotId = self.tweakDb:toSlotTweakId(slotSpec.slot, itemMeta.mod and itemMeta or itemType)
						local partItemId = self:applyItemSpec(slotSpec, specOptions)

						self.itemModSystem:InstallItemPart(self.player, itemId, partItemId, slotId)
					end
				end
			end

			-- Keep item up to level

			self.craftingSystem:SetItemLevel(itemData)

			-- Upgrade item quality

			if itemSpec.upgrade then
				local itemQuality

				if type(itemSpec.upgrade) == 'string' then
					itemQuality = itemSpec.upgrade

					if itemMeta and type(itemMeta.max) == 'string' and not specOptions.cheat then
						itemQuality = Quality.min(itemQuality, itemMeta.max)
					end
				else
					itemQuality = self.gameRPGManager:GetItemDataQuality(itemData).value
				end

				self.forceItemQuality(self.player, itemData, CName.new(itemQuality))
			end

			-- Equip item

			if itemEquip then
				if equipedSlots then
					local itemEquipAreaData = self.playerEquipmentData:GetEquipAreaFromItemID(itemId)
					local itemEquipArea = self.equipAreaDb:find({ type = itemEquipAreaData.areaType.value })

					if not equipedSlots[itemEquipArea.type] then
						equipedSlots[itemEquipArea.type] = {}
					end

					equipedSlots[itemEquipArea.type][itemEquipIndex] = itemId
				end
			end

			-- Force quest flag

			if itemSpec.quest ~= nil then
				if itemSpec.quest then
					if not itemData:HasTag('Quest') then
						itemData:SetDynamicTag('Quest')
					end
				else
					if itemData:HasTag('Quest') then
						itemData:RemoveDynamicTag('Quest')
					end
				end
			end
		end
	end

	if #removedParts > 0 then
		mod.after(1.5, function()
			for _, partItemId in ipairs(removedParts) do
				if self.playerEquipmentData:HasItemInInventory(partItemId) then
					self.transactionSystem:RemoveItem(self.player, partItemId, 1)
					--self.craftingSystem:DisassembleItem(self.player, slotItemId, 1)
				end
			end
		end)
	end

	return itemId
end

function InventoryModule:completeItemSpec(itemSpec)
	if type(itemSpec) ~= 'table' then
		itemSpec = { id = itemSpec }
	end

	return itemSpec
end

function InventoryModule:isEquipped(itemId)
	return self.playerEquipmentData:IsEquipped(itemId)
end

function InventoryModule:equipItem(itemId, slotIndex)
	if not self.playerEquipmentData:IsEquipped(itemId) then
		self.playerEquipmentData:EquipItemInSlot(itemId, slotIndex - 1, false, false, false)
	end
end

function InventoryModule:unequipItem(itemId)
	if self.playerEquipmentData:IsEquipped(itemId) then
		self.playerEquipmentData:UnequipItem(itemId)
	end
end

function InventoryModule:equipUsedSlots(equipedSlots)
	for equipAreaType, equipedItems in pairs(equipedSlots) do
		for slotIndex, itemId in pairs(equipedItems) do
			local equipArea = self.equipAreaDb:find({ type = equipAreaType })

			if not self:isEquipped(itemId) then
				if equipArea.kind == 'Clothing' or equipArea.type == 'SystemReplacementCW' then
					mod.after(0.15, function()
						self:equipItem(itemId, slotIndex)
					end)
				else
					self:equipItem(itemId, slotIndex)
				end
			end
		end
	end
end

function InventoryModule:unequipUnusedSlots(slotCriteria, equipedSlots)
	for _, equipArea in self.equipAreaDb:filter(slotCriteria) do
		for slotIndex = 1, equipArea.max do
			if not equipedSlots or not equipedSlots[equipArea.type] or not equipedSlots[equipArea.type][slotIndex] then
				local equipedItemId = self.playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

				if equipedItemId and equipedItemId.id.hash ~= 0 then
					self:unequipItem(equipedItemId)
				end
			end
		end
	end
end

return InventoryModule
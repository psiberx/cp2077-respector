local mod = ...
local str = mod.require('mod/utils/str')
local TweakDb = mod.require('mod/helpers/TweakDb')

local InventoryModule = {}
InventoryModule.__index = InventoryModule

function InventoryModule:new()
	local this = { tweakDb = TweakDb:new() }

	setmetatable(this, InventoryModule)

	return this
end

function InventoryModule:prepare()
	local scriptableSystemsContainer = Game.GetScriptableSystemsContainer()
	local equipmentSystem = scriptableSystemsContainer:Get(CName.new('EquipmentSystem'))

	self.player = Game.GetPlayer()
	self.transactionSystem = Game.GetTransactionSystem()
	self.equipmentPlayerData = equipmentSystem:GetPlayerData(self.player)
	self.equipmentPlayerData['EquipItemInSlot'] = self.equipmentPlayerData['EquipItem;ItemIDInt32BoolBoolBool']
	self.equipmentPlayerData['GetItemInEquipSlotArea'] = self.equipmentPlayerData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']
	self.equipmentPlayerData['GetSlotIndexInArea'] = self.equipmentPlayerData['GetSlotIndex;ItemIDgamedataEquipmentArea']
	self.craftingSystem = scriptableSystemsContainer:Get(CName.new('CraftingSystem'))
	self.gameRPGManager = GetSingleton('gameRPGManager')
	self.forceItemQuality = Game['gameRPGManager::ForceItemQuality;GameObjectgameItemDataCName']
	self.itemModSystem = scriptableSystemsContainer:Get(CName.new('ItemModificationSystem'))

	self.partSlots = mod.load('mod/data/attachment-slots')
end

function InventoryModule:release()
	self.player = nil
	self.transactionSystem = nil
	self.equipmentPlayerData = nil
	self.craftingSystem = nil
	self.gameRPGManager = nil
	self.forceItemQuality = nil
	self.itemModSystem = nil
end

function InventoryModule:addItem(itemSpec)
	if type(itemSpec) ~= 'table' then
		itemSpec = { id = itemSpec }
	end

	if type(itemSpec.id) ~= 'table' and type(itemSpec.id) ~= 'string' then
		itemSpec.id = tostring(itemSpec.id)
	end

	-- Resolve item

	local tweakDbId = self.tweakDb:getTweakDbId(itemSpec.id)
	local itemMeta = self.tweakDb:resolve(tweakDbId) or { rng = true }
	local itemCopy
	local itemId

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
		itemId = self.tweakDb:getItemId(tweakDbId, itemSpec.seed)

		-- Add item to inventory

		local currentQty = self.transactionSystem:GetItemQuantity(self.player, itemId)

		if itemMeta.stack then
			self.transactionSystem:GiveItem(self.player, itemId, itemSpec.qty - currentQty)
		else
			-- Never add the exact same item (hash + seed) if it's already in inventory
			if currentQty == 0 then
				self.transactionSystem:GiveItem(self.player, itemId, 1)
			end
		end

		local itemData = self.transactionSystem:GetItemData(self.player, itemId)

		-- Add mods and attachments

		if itemSpec.slots then
			for _, slotName in ipairs(self.partSlots) do
				local slotId = self.tweakDb:getSlotId(slotName)
				local slotItemIds = {}

				if itemData:HasPartInSlot(slotId) then
					local slotItemId = self.itemModSystem:RemoveItemPart(self.player, itemId, slotId, false)

					table.insert(slotItemIds, slotItemId)
				end

				if #slotItemIds > 0 then
					mod.defer(0.05, function()
						for _, slotItemId in ipairs(slotItemIds) do
							self.craftingSystem:DisassembleItem(self.player, slotItemId, 1)
						end
					end)
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

				local slotId = self.tweakDb:getSlotId(slotSpec.slot, itemMeta)
				local partItemId = self:addItem(slotSpec)

				self.itemModSystem:InstallItemPart(self.player, itemId, partItemId, slotId)
			end
		end

		-- Upgrade item

		if itemSpec.upgrade ~= nil and itemSpec.upgrade ~= false then
			local itemQuality

			if type(itemSpec.upgrade) == 'string' then
				itemQuality = itemSpec.upgrade
			else
				itemQuality = self.gameRPGManager:GetItemDataQuality(itemData).value
			end

			self.craftingSystem:SetItemLevel(itemData)
			self.forceItemQuality(self.player, itemData, CName.new(itemQuality))
		end

		-- Equip item

		if itemSpec.equip ~= nil then
			local slotIndex = math.max(1, type(itemSpec.equip) == 'number' and itemSpec.equip or 1)

			if self.equipmentPlayerData:IsEquipped(itemId) then
				self.equipmentPlayerData:RemoveItemFromEquipSlot(itemId)
				self.equipmentPlayerData:UnequipItem(itemId)
			end

			mod.defer(0.05, function()
				self.equipmentPlayerData:EquipItemInSlot(itemId, slotIndex - 1, false, false, false)
			end)
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

	return itemId
end

function InventoryModule:addItems(itemSpecs)
	self.tweakDb:load('mod/data/tweakdb-meta')

	for _, itemSpec in ipairs(itemSpecs) do
		self:addItem(itemSpec)
	end

	self.tweakDb:unload()
end

function InventoryModule:autoScaleItems()
	local currentLevel = Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), 'Level')

	-- This triggers the items with auto-scaling feature to update to the current character level
	Game.SetLevel('Level', currentLevel)

	if mod.debug then
		print(('[DEBUG] Respector: Updating auto-scale items to level %d.'):format(currentLevel))
	end
end

function InventoryModule:getItems(specOptions)
	self.tweakDb:load('mod/data/tweakdb-meta')

	local itemSpecs = {}

	local equipAreas = mod.load('mod/data/equipment-areas')

	for _, equipArea in ipairs(equipAreas) do
		for slotIndex = 1, equipArea.max do
			local itemId = self.equipmentPlayerData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.tdbid.hash ~= 0 then
				local itemData = self.transactionSystem:GetItemData(self.player, itemId)

				-- Sometimes equipment system bugs out and gives ItemID for an actually empty slot.
				-- When this happens, GetItemData() will return nil, so we have to check that.
				if itemData ~= nil then
					local itemSpec = {}

					local itemId2 = self.tweakDb:extract(itemId)
					local itemMeta = self.tweakDb:resolve(itemId.tdbid)

					local itemQty = self.transactionSystem:GetItemQuantity(self.player, itemId)
					local itemQuality = self.gameRPGManager:GetItemDataQuality(itemData).value

					if itemMeta ~= nil then
						if itemMeta.type == '' or specOptions.itemFormat == 'hash' then
							itemSpec.id = itemId2.id
						else
							itemSpec.id = str.without(itemMeta.type, 'Items.')
						end

						if itemMeta.rng or specOptions.keepSeed == 'always' then
							itemSpec.seed = itemId2.rng_seed
						end

						if itemMeta.quality == nil or specOptions.exportQuality == 'always' then
							itemSpec.upgrade = itemQuality ~= 'Common' and itemQuality or true
							--elseif itemMeta.kind == 'Weapon' or itemMeta.kind == 'Clothing' then
							--	itemSpec.upgrade = true
						end

						itemSpec._comment = self.tweakDb:describe(itemMeta, true)
					else
						itemSpec.id = itemId2.id
						itemSpec.seed = itemId2.rng_seed
						itemSpec.upgrade = itemQuality
						itemSpec._comment = '??? / ' .. equipArea.name
					end

					if (not itemMeta or itemMeta.quality == nil) and itemQuality ~= 'Invalid' then
						itemSpec._comment = itemSpec._comment .. ' / ' .. itemQuality
					end

					for _, slotName in ipairs(self.partSlots) do
						local slotId = self.tweakDb:getSlotId(slotName)

						if itemData:HasPartInSlot(slotId) then
							if itemSpec.slots == nil then
								itemSpec.slots = {}
								itemSpec._inline = false
							end

							local partSpec = {}

							-- We can't use the obvious function due to this error:
							-- Error: Function 'GetItemPart' parameter 0 must be gameInnerItemData.
							--local partItemData = itemData:GetItemPart(slotId)

							-- So we remove the part to get the item id
							local partId = self.itemModSystem:RemoveItemPart(self.player, itemId, slotId, false)

							-- Get everything we need
							local partData = self.transactionSystem:GetItemData(self.player, partId)
							local partQuality = self.gameRPGManager:GetItemDataQuality(partData).value

							-- Then we put the part back as if nothing happened
							self.itemModSystem:InstallItemPart(self.player, itemId, partId, slotId)

							local partId2 = self.tweakDb:extract(partId)
							local partMeta = self.tweakDb:resolve(partId.tdbid)

							partSpec.slot = self.tweakDb:getSlotAlias(slotName, itemMeta)

							if partMeta ~= nil then
								if specOptions.itemFormat == 'hash' then
									partSpec.id = partId2.id
								else
									partSpec.id = str.without(partMeta.type, 'Items.')
								end

								if partMeta.rng or specOptions.keepSeed == 'always' then
									partSpec.seed = partId2.rng_seed
								end

								if partMeta.quality == nil or specOptions.exportQuality == 'always' then
									partSpec.upgrade = partQuality ~= 'Common' and partQuality or true
								end

								--partSpec._comment = string.upper(partMeta.name)
								partSpec._comment = self.tweakDb:describe(partMeta)
							else
								partSpec.id = partId2.id
								partSpec.seed = partId2.rng_seed
								partSpec.upgrade = partQuality
								partSpec._comment = '???'
							end

							if (not partMeta or partMeta.quality == nil) and partQuality ~= 'Invalid' then
								partSpec._comment = partSpec._comment .. ' / ' .. partQuality
							end

							table.insert(itemSpec.slots, partSpec)
						end
					end

					if equipArea.max > 1 then
						itemSpec.equip = slotIndex
					else
						itemSpec.equip = true
					end

					if itemQty > 1 then
						itemSpec.qty = itemQty
					end

					table.insert(itemSpecs, itemSpec)
				end
			end
		end
	end

	self.tweakDb:unload()

	if #itemSpecs == 0 then
		return nil
	end

	return itemSpecs
end

function InventoryModule:applySpec(specData)
	if specData.Inventory then
		self:addItems(specData.Inventory)
		self:autoScaleItems()
	end
end

function InventoryModule:fillSpec(specData, specOptions)
	local inventoryData = self:getItems(specOptions)

	if inventoryData then
		specData.Inventory = inventoryData
	end
end

return InventoryModule
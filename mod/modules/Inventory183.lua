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
	self.playerEquipmentData = equipmentSystem:GetPlayerData(self.player)
	self.playerEquipmentData['EquipItemInSlot'] = self.playerEquipmentData['EquipItem;ItemIDInt32BoolBoolBool']
	self.playerEquipmentData['GetItemInEquipSlotArea'] = self.playerEquipmentData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']
	self.playerEquipmentData['GetSlotIndexInArea'] = self.playerEquipmentData['GetSlotIndex;ItemIDgamedataEquipmentArea']
	self.craftingSystem = scriptableSystemsContainer:Get(CName.new('CraftingSystem'))
	self.gameRPGManager = GetSingleton('gameRPGManager')
	self.forceItemQuality = Game['gameRPGManager::ForceItemQuality;GameObjectgameItemDataCName']
	self.itemModSystem = scriptableSystemsContainer:Get(CName.new('ItemModificationSystem'))

	self.partSlots = mod.load('mod/data/attachment-slots')
end

function InventoryModule:release()
	self.player = nil
	self.transactionSystem = nil
	self.playerEquipmentData = nil
	self.craftingSystem = nil
	self.gameRPGManager = nil
	self.forceItemQuality = nil
	self.itemModSystem = nil

	self.partSlots = nil
end

function InventoryModule:getItems(specOptions)
	self.tweakDb:load('mod/data/tweakdb-meta')

	local itemSpecs = {}
	local itemReEquips = {}

	local equipAreas = mod.load('mod/data/equipment-areas')

	for _, equipArea in ipairs(equipAreas) do
		for slotIndex = 1, equipArea.max do
			local itemId = self.playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

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

					for _, slotMeta in ipairs(self.partSlots) do
						local slotId = self.tweakDb:getSlotTweakDbId(slotMeta.type)

						if itemData:HasPartInSlot(slotId) then
							if itemSpec.slots == nil then
								itemSpec.slots = {}
								itemSpec._inline = false

								-- This will prevent the spam of the stats system
								-- Otherwise it'll react on every slot / mod iteraction
								-- and the event queue will be overflowed very quickly
								if slotMeta.criteria.kind == 'Clothing' then
									self:unequipItem(itemId)

									table.insert(itemReEquips, 1, {
										itemId = itemId,
										equipArea = equipArea,
										slotIndex = slotIndex,
									})
								end
							end

							local partSpec = {}

							-- Can't use the function due to this error:
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

							--partSpec.slot = self.tweakDb:getSlotAlias(slotMeta.type, itemMeta)
							partSpec.slot = slotMeta.slot

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

	if #itemReEquips > 0 then
		mod.defer(0.2, function()
			for _, itemReEquip in ipairs(itemReEquips) do
				self:equipItem(itemReEquip.itemId, itemReEquip.slotIndex)
			end
		end)
	end

	return itemSpecs
end

function InventoryModule:completeSpec(itemSpec)
	if type(itemSpec) ~= 'table' then
		itemSpec = { id = itemSpec }
	end

	if type(itemSpec.id) ~= 'table' and type(itemSpec.id) ~= 'string' then
		itemSpec.id = tostring(itemSpec.id)
	end
end

function InventoryModule:addItem(itemSpec)
	self:completeSpec(itemSpec)

	local removedParts = {}

	-- Resolve item

	local tweakDbId = self.tweakDb:getItemTweakDbId(itemSpec.id)
	local itemMeta = self.tweakDb:resolve(tweakDbId) or { rng = true }
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
		itemId = self.tweakDb:getItemId(tweakDbId, itemSpec.seed)

		local itemEquip = itemSpec.equip == true or type(itemSpec.equip) == 'number'
		local itemEquipIndex = itemSpec.equip and math.max(1, type(itemSpec.equip) == 'number' and itemSpec.equip or 1)

		-- Add item to inventory

		local currentQty = self.transactionSystem:GetItemQuantity(self.player, itemId)
		local currentEquipIndex = self.playerEquipmentData:GetSlotIndex(itemId) + 1

		if itemMeta.stack then
			self.transactionSystem:GiveItem(self.player, itemId, itemSpec.qty - currentQty)
		else
			-- Never add the exact same item (hash + seed) if it's already in inventory
			if currentQty == 0 then
				self.transactionSystem:GiveItem(self.player, itemId, 1)
			else
				-- Need to be delicate with equipping / unequipping armor
				if self:isEquipped(itemId) then
					if not itemEquip or itemEquipIndex ~= currentEquipIndex or itemMeta.kind == 'Clothing' then
						self:unequipItem(itemId)
					end
				end
			end
		end

		local itemData = self.transactionSystem:GetItemData(self.player, itemId)

		-- Manage mods and attachments

		for _, slotMeta in ipairs(self.partSlots) do
			local slotId = self.tweakDb:getTweakDbId(slotMeta.type)

			if itemData:HasPartInSlot(slotId) then
				local partItemId = self.itemModSystem:RemoveItemPart(self.player, itemId, slotId, true)

				if partItemId then
					table.insert(removedParts, partItemId)
				end
			end
		end

		if itemSpec.slots then
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
					local slotId = self.tweakDb:getSlotTweakDbId(slotSpec.slot, itemMeta)
					local partItemId = self:addItem(slotSpec)

					self.itemModSystem:InstallItemPart(self.player, itemId, partItemId, slotId)
				end
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

		if itemEquip then
			if not self:isEquipped(itemId) then
				self:equipItem(itemId, itemEquipIndex)
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

	--if #removedParts > 0 then
	--	mod.defer(0.8, function()
	--		for _, partItemId in ipairs(removedParts) do
	--			self.transactionSystem:RemoveItem(self.player, partItemId, 1)
	--			--self.craftingSystem:DisassembleItem(self.player, slotItemId, 1)
	--		end
	--	end)
	--end

	return itemId
end

function InventoryModule:addItems(itemSpecs)
	self.tweakDb:load('mod/data/tweakdb-meta')

	for _, itemSpec in ipairs(itemSpecs) do
		self:addItem(itemSpec)
	end

	self.tweakDb:unload()
end

function InventoryModule:isEquipped(itemId)
	return self.playerEquipmentData:IsEquipped(itemId)
end

function InventoryModule:unequipItem(itemId)
	if self.playerEquipmentData:IsEquipped(itemId) then
		self.playerEquipmentData:RemoveItemFromEquipSlot(itemId)
		self.playerEquipmentData:UnequipItem(itemId)
	end
end

function InventoryModule:equipItem(itemId, slotIndex)
	mod.defer(0.15, function()
		self.playerEquipmentData:EquipItemInSlot(itemId, slotIndex - 1, false, false, false)
	end)
end

function InventoryModule:forceEquipItem(itemId, slotIndex)
	self:unequipItem(itemId)
	self:equipItem(itemId, slotIndex)
end

function InventoryModule:updateAutoScalingItems()
	local currentLevel = Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), 'Level')

	-- This triggers the items with auto-scaling feature to update to the current character level
	Game.SetLevel('Level', currentLevel)

	if mod.debug then
		print(('[DEBUG] Respector: Auto-scale items updated to level %d.'):format(currentLevel))
	end
end

function InventoryModule:applySpec(specData)
	if specData.Inventory then
		self:addItems(specData.Inventory)
		self:updateAutoScalingItems()
	end
end

function InventoryModule:fillSpec(specData, specOptions)
	local inventoryData = self:getItems(specOptions)

	if inventoryData then
		specData.Inventory = inventoryData
	end
end

return InventoryModule
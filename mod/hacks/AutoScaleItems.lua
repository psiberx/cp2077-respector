local mod = ...
local TweakDb = mod.require('mod/helpers/TweakDb')
local SimpleDb = mod.require('mod/helpers/SimpleDb')

return function()
	local player = Game.GetPlayer()
	local transactionSystem = Game.GetTransactionSystem()
	local inventoryManager = Game.GetInventoryManager()
	local equipmentSystem = Game.GetScriptableSystemsContainer():Get(CName.new('EquipmentSystem'))
	local craftingSystem = Game.GetScriptableSystemsContainer():Get(CName.new('CraftingSystem'))
	local playerEquipmentData = equipmentSystem:GetPlayerData(player)

	playerEquipmentData['GetItemInEquipSlotArea'] = playerEquipmentData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']

	local tweakDb = TweakDb:new(true)
	local equipAreaDb = SimpleDb:new('mod/data/equipment-areas')

	for _, equipArea in equipAreaDb:each() do
		for slotIndex = 1, equipArea.max do
			local itemId = playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.id.hash ~= 0 then
				local itemData = transactionSystem:GetItemData(player, itemId)

				if itemData ~= nil then
					craftingSystem:SetItemLevel(itemData)

					for _, part in ipairs(itemData:GetItemParts()) do
						if part then
							local slotId = part:GetSlotID(part)
							local slotMeta = tweakDb:resolve(slotId)

							if slotMeta and slotMeta.kind == 'Slot' then
								local partId = part:GetItemID(part)
								local partData = inventoryManager:CreateItemData(partId, player)

								craftingSystem:SetItemLevel(partData)
							end
						end
					end
				end
			end
		end
	end

	equipAreaDb:unload()
	tweakDb:unload()
end
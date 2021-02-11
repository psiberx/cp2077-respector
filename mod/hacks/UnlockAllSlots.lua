local mod = ...
local SimpleDb = mod.require('mod/helpers/SimpleDb')

local dummyClothingMod = { hash = 0x4C882AC5, length = 25 }

return function()
	local player = Game.GetPlayer()
	local transactionSystem = Game.GetTransactionSystem()
	local itemModSystem = Game.GetScriptableSystemsContainer():Get(CName.new('ItemModificationSystem'))
	local equipmentSystem = Game.GetScriptableSystemsContainer():Get(CName.new('EquipmentSystem'))
	local playerEquipmentData = equipmentSystem:GetPlayerData(player)

	playerEquipmentData['GetItemInEquipSlotArea'] = playerEquipmentData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']

	local equipAreaDb = SimpleDb:new('mod/data/equipment-areas')

	for _, equipArea in equipAreaDb:filter({ kind = 'Clothing' }) do
		for slotIndex = 1, equipArea.max do
			local itemId = playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.id.hash ~= 0 then
				local itemData = transactionSystem:GetItemData(player, itemId)

				if itemData ~= nil then
					for _, part in ipairs(itemData:GetItemParts()) do
						local slotId = part:GetSlotID(part)
						local partId = part:GetItemID(part)

						if partId.id.hash == dummyClothingMod.hash and partId.id.length == dummyClothingMod.length then
							itemModSystem:RemoveItemPart(player, itemId, slotId, true)
							transactionSystem:RemoveItem(player, partId, 1)
						end
					end
				end
			end
		end
	end

	equipAreaDb:unload()
end
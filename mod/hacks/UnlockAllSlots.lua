local mod = ...
local SimpleDb = mod.require('mod/helpers/SimpleDb')
local TweakDb = mod.require('mod/helpers/TweakDb')

return function()
	local player = Game.GetPlayer()
	local transactionSystem = Game.GetTransactionSystem()
	local itemModSystem = Game.GetScriptableSystemsContainer():Get(CName.new('ItemModificationSystem'))
	local equipmentSystem = Game.GetScriptableSystemsContainer():Get(CName.new('EquipmentSystem'))
	local playerEquipmentData = equipmentSystem:GetPlayerData(player)

	playerEquipmentData['GetItemInEquipSlotArea'] = playerEquipmentData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']

	local equipAreaDb = SimpleDb:new('mod/data/equipment-areas')

	for _, equipArea in equipAreaDb:filter({ kind = { 'Clothing', 'Weapon' } }) do
		for slotIndex = 1, equipArea.max do
			local itemId = playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.id.hash ~= 0 then
				local itemData = transactionSystem:GetItemData(player, itemId)

				if itemData ~= nil then
					for _, part in ipairs(itemData:GetItemParts()) do
						local slotId = part:GetSlotID(part)
						local partId = part:GetItemID(part)
						local tweakId = TweakDBID.new(partId.id)

                        if TweakDb.isSlotBlocker(tweakId) then
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
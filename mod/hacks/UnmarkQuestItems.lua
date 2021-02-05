local mod = ...
local SimpleDb = mod.require('mod/helpers/SimpleDb')

return function()
	local player = Game.GetPlayer()
	local transactionSystem = Game.GetTransactionSystem()
	local equipmentSystem = Game.GetScriptableSystemsContainer():Get(CName.new('EquipmentSystem'))
	local playerEquipmentData = equipmentSystem:GetPlayerData(player)

	playerEquipmentData['GetItemInEquipSlotArea'] = playerEquipmentData['GetItemInEquipSlot;gamedataEquipmentAreaInt32']

	local equipAreaDb = SimpleDb:new('mod/data/equipment-areas')

	for _, equipArea in equipAreaDb:filter({ kind = { 'Weapon', 'Clothing' } }) do
		for slotIndex = 1, equipArea.max do
			local itemId = playerEquipmentData:GetItemInEquipSlotArea(equipArea.type, slotIndex - 1)

			if itemId.tdbid.hash ~= 0 then
				local itemData = transactionSystem:GetItemData(player, itemId)

				if itemData ~= nil then
					if itemData:HasTag('Quest') then
						itemData:RemoveDynamicTag('Quest')
					end
				end
			end
		end
	end

	equipAreaDb:unload()
end
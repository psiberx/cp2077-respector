local mod = ...
local str = mod.require('mod/utils/str')
local Quality = mod.require('mod/enums/Quality')
local SimpleDb = mod.require('mod/helpers/SimpleDb')

local TweakDb = {}
TweakDb.__index = TweakDb

setmetatable(TweakDb, { __index = SimpleDb })

local searchSchema = {
	{ field = 'name', weight = 1 },
	{ field = 'tag', weight = 2 },
	{ field = 'set', weight = 2 },
	{ field = 'kind', weight = 2 },
	{ field = 'type', weight = 3 },
}

local kindOrders = {
	['Weapon'] = 1,
	['Clothing'] = 2,
	['Cyberware'] = 3,
	['Mod'] = 11,
	['Grenade'] = 21,
	['Consumable'] = 22,
	['Progression'] = 23,
	['Quickhack'] = 31,
	['Junk'] = 71,
	['Recipe'] = 81,
	['Component'] = 82,
	['Misc'] = 91,
	['Shard'] = 92,
}

local groupOrders = {
	['Head'] = 11,
	['Face'] = 12,
	['Outer Torso'] = 13,
	['Inner Torso'] = 14,
	['Legs'] = 15,
	['Feet'] = 16,
	['Special'] = 17,
}

local itemModPrefixes = {
	['Clo_Face'] = 'FaceFabricEnhancer',
	['Clo_Feet'] = 'FootFabricEnhancer',
	['Clo_Head'] = 'HeadFabricEnhancer',
	['Clo_InnerChest'] = 'InnerChestFabricEnhancer',
	['Clo_Legs'] = 'LegsFabricEnhancer',
	['Clo_OuterChest'] = 'OuterChestFabricEnhancer',
	--['Cyb_Ability'] = 'ModPrefix',
	['Cyb_Launcher'] = 'ProjectileLauncher',
	['Cyb_MantisBlades'] = 'MantisBlades',
	['Cyb_NanoWires'] = 'NanoWires',
	['Cyb_StrongArms'] = 'StrongArms',
	--['Fla_Launcher'] = 'ModPrefix',
	--['Fla_Rifle'] = 'ModPrefix',
	--['Fla_Shock'] = 'ModPrefix',
	--['Fla_Support'] = 'ModPrefix',
	['Wea_AssaultRifle'] = 'GenericWeaponMod',
	['Wea_Fists'] = 'GenericWeaponMod',
	['Wea_Hammer'] = 'GenericWeaponMod',
	['Wea_Handgun'] = 'GenericWeaponMod',
	['Wea_HeavyMachineGun'] = 'GenericWeaponMod',
	['Wea_Katana'] = 'GenericWeaponMod',
	['Wea_Knife'] = 'GenericWeaponMod',
	['Wea_LightMachineGun'] = 'GenericWeaponMod',
	['Wea_LongBlade'] = 'GenericWeaponMod',
	['Wea_Melee'] = 'GenericWeaponMod',
	['Wea_OneHandedClub'] = 'GenericWeaponMod',
	['Wea_PrecisionRifle'] = 'GenericWeaponMod',
	['Wea_Revolver'] = 'GenericWeaponMod',
	['Wea_Rifle'] = 'GenericWeaponMod',
	['Wea_ShortBlade'] = 'GenericWeaponMod',
	['Wea_Shotgun'] = 'GenericWeaponMod',
	['Wea_ShotgunDual'] = 'GenericWeaponMod',
	['Wea_SniperRifle'] = 'GenericWeaponMod',
	['Wea_SubmachineGun'] = 'GenericWeaponMod',
	['Wea_TwoHandedClub'] = 'GenericWeaponMod',
}

function TweakDb:load(path)
	if not path or path == true then
		path = 'mod/data/tweakdb-meta'
	end

	SimpleDb.load(self, path)
end

function TweakDb:resolve(tweakId)
	return self:get(TweakDb.toKey(tweakId))
end

function TweakDb:resolvable(tweakId)
	return self:has(TweakDb.toKey(tweakId))
end

function TweakDb:search(term)
	return SimpleDb.search(self, term, searchSchema)
end

function TweakDb:complete(itemMeta)
	if itemMeta and itemMeta.ref and itemMeta.ref ~= true then
		local refMeta = self:get(itemMeta.ref)

		for prop, value in pairs(refMeta) do
			if itemMeta[prop] == nil then
				itemMeta[prop] = value
			end
		end

		itemMeta.ref = true
	end

	return itemMeta
end

function TweakDb:isTaggedAsSet(itemMeta)
	return itemMeta.set and itemMeta.kind ~= 'Pack' and itemMeta.set:find(' Set$')
end

function TweakDb:describe(itemMeta, extended, sets, ellipsis)
	local comment = ''

	if itemMeta.name then
		comment = itemMeta.name
	end

	if sets and self:isTaggedAsSet(itemMeta) then
		comment = string.upper(itemMeta.set) .. ': ' .. comment
	end

	if ellipsis then
		comment = str.ellipsis(comment, ellipsis)
	end

	if extended then
		comment = comment .. ' / ' .. itemMeta.kind

		if itemMeta.kind ~= 'Pack' then
			if itemMeta.group then
				comment = comment .. ' / ' .. itemMeta.group
			end

			if itemMeta.kind == 'Weapon' or (itemMeta.kind == 'Mod' and itemMeta.group == 'Cyberware') then
				comment = comment ..  ' / ' .. itemMeta.group2
			end
		end
	end

	if itemMeta.quality then
		comment = comment .. ' / ' .. itemMeta.quality
	elseif itemMeta.kind == 'Pack' and itemMeta.max then
		comment = comment .. ' / ' .. itemMeta.max
	end

	return comment
end

function TweakDb:order(itemMeta, orderKind, orderPrefix)
	local order = ''

	if orderPrefix then
		order = orderPrefix .. '|'
	end

	if orderKind then
		order = order .. ('%02d'):format(kindOrders[itemMeta.kind] or 99) .. '|'
	end

	if itemMeta.kind == 'Mod' then
		order = order .. itemMeta.group .. '|'

		if itemMeta.group == 'Cyberware' then
			order = order .. itemMeta.group2 .. '|'
		end
	elseif itemMeta.kind == 'Pack' then
		if itemMeta.pack == 'Clothing' and itemMeta.set == false and itemMeta.tag == false then
			order = order .. 'Z' .. ('%02d'):format(groupOrders[itemMeta.group] or 99)
		end
	elseif self:isTaggedAsSet(itemMeta) then
		order = order .. itemMeta.set .. '|'
	end

	if itemMeta.name then
		order = order .. itemMeta.name
	elseif itemMeta.id then
		order = order .. TweakDb.toItemAlias(itemMeta.id)
	end

	if itemMeta.quality then
		order = order .. '|' .. Quality.toValue(itemMeta.quality)
		--order = order .. '|' .. (Quality.maxValue() - Quality.toValue(itemMeta.quality))
	elseif itemMeta.kind == 'Pack' and itemMeta.max then
		order = order .. '|' .. Quality.toValue(itemMeta.max)
	else
		order = order .. '|0'
	end

	if itemMeta.name and itemMeta.id then
		order = order .. '|' .. TweakDb.toItemAlias(itemMeta.id)
	end

	return string.upper(order)
end

function TweakDb:orderLast()
	return '99'
end

function TweakDb:sort(items)
	SimpleDb.sort(self, items, '_order')
end

function TweakDb.toKey(data)
	if type(data) == 'number' then
		return data
	end

	if type(data) == 'string' then
		data = TweakDb.toTweakId(data)
	end

	if type(data) == 'userdata' then
		data = TweakDb.extract(data)
	end

	if type(data) == 'table' then
		return data.length * 0x100000000 + data.hash
		--return (data.length << 32 | data.hash)
	end

	return 0
end

function TweakDb.isRealKey(key)
	return key <= 0xFFFFFFFFFF
end

function TweakDb.toStruct(data)
	if type(data) == 'table' then
		return data
	end

	if type(data) == 'number' then
		-- { hash = data & 0xFFFFFFFF, length = data >> 32 }
		local length = math.floor(data / 0x100000000)
		local hash = data - (length * 0x100000000)
		return { hash = hash, length = length }
	end

	if type(data) == 'string' then
		data = TweakDb.toTweakId(data)
	end

	if type(data) == 'userdata' then
		return TweakDb.extract(data)
	end

	return nil
end

function TweakDb.toType(tweakId, prefix)
	if type(tweakId) == 'string' then
		return str.with(tweakId, prefix)
	end

	return ''
end

function TweakDb.toAlias(tweakId, prefix)
	return tweakId

	--if type(tweakId) == 'string' then
	--	return str.without(tweakId, prefix)
	--end
	--
	--return ''
end

function TweakDb.toTweakId(tweakId, prefix)
	if type(tweakId) == 'number' then
		tweakId = TweakDb.toStruct(tweakId)
	end

	if type(tweakId) == 'table' then
		return TweakDBID.new(tweakId.hash, tweakId.length)
	end

	if type(tweakId) == 'string' then
		local hashHex, lenHex = tweakId:match('^<TDBID:([0-9A-Z]+):([0-9A-Z]+)>$')
		if hashHex and lenHex then
			return TweakDBID.new(tonumber(hashHex, 16), tonumber(lenHex, 16))
		elseif tweakId:find('%.') then
			return TweakDBID.new(tweakId)
		else
			return TweakDBID.new(str.with(tweakId, prefix))
		end
	end

	if type(tweakId) == 'userdata' then
		return tweakId
	end
end

function TweakDb.toItemId(tweakId, seed)
	if type(tweakId) == 'string' then
		tweakId = TweakDb.toItemTweakId(tweakId)
	end

	if seed then
		return ItemID.new(tweakId, seed)
	elseif seed == false then
		return ItemID.new(tweakId)
	else
		return GetSingleton('gameItemID'):FromTDBID(tweakId)
	end
end

function TweakDb.toItemTweakId(tweakId)
	return TweakDb.toTweakId(tweakId, 'Items.')
end

function TweakDb.toItemType(alias)
	return TweakDb.toType(alias, 'Items.')
end

function TweakDb.toItemAlias(type)
	return TweakDb.toAlias(type, 'Items.')
end

function TweakDb.toVehicleTweakId(tweakId)
	return TweakDb.toTweakId(tweakId, 'Vehicle.')
end

function TweakDb.toVehicleType(alias)
	return TweakDb.toType(alias, 'Vehicle.')
end

function TweakDb.toVehicleAlias(type)
	return TweakDb.toAlias(type, 'Vehicle.')
end

function TweakDb:toSlotTweakId(slotAlias, itemMeta)
	if slotAlias == 'Muzzle' then
		slotAlias = 'PowerModule'
	end

	local slotName = str.with(slotAlias, 'AttachmentSlots.')
	local tweakId = TweakDBID.new(slotName)

	if not self:resolvable(tweakId) then
		if type(itemMeta) == 'table' and itemMeta.mod then
			if slotAlias == 'Mod' and itemMeta.kind == 'Cyberware' and itemMeta.group == 'Arms' then
				slotName = 'AttachmentSlots.ArmsCyberwareGeneralSlot'
			else
				local index = string.match(slotAlias, '%d$')

				if index ~= nil then
					slotName = 'AttachmentSlots.' .. itemMeta.mod .. index
				else
					slotName = 'AttachmentSlots.' .. itemMeta.mod .. slotAlias
				end
			end

			tweakId = TweakDBID.new(slotName)
		elseif type(itemMeta) == 'string' then
			local modPrefix = itemModPrefixes[itemMeta]

			if modPrefix then
				local index = string.match(slotAlias, '%d$')

				if index ~= nil then
					slotName = 'AttachmentSlots.' .. modPrefix .. index
				else
					slotName = 'AttachmentSlots.' .. modPrefix .. slotAlias
				end

				tweakId = TweakDBID.new(slotName)
			end
		end
	end

	return tweakId
end

function TweakDb.toSlotType(alias)
	return TweakDb.toType(alias, 'AttachmentSlots.')
end

function TweakDb.localize(tweakId)
	tweakId = TweakDb.toTweakId(tweakId)

	return {
		name = Game.GetLocalizedTextByKey(Game['TDB::GetLocKey;TweakDBID'](TweakDBID.new(tweakId, '.displayName'))),
		comment = Game.GetLocalizedTextByKey(Game['TDB::GetLocKey;TweakDBID'](TweakDBID.new(tweakId, '.localizedDescription'))),
	}
end

function TweakDb.extract(data)
	if data.hash then
		return { hash = data.hash, length = data.length }
	end

	if data.id then
		return { id = { data.id.hash, length = data.id.length }, rng_seed = data.rng_seed }
	end

	return data
end

return TweakDb
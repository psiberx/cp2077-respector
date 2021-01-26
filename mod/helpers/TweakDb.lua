local mod = ...
local str = mod.require('mod/utils/str')
local Quality = mod.require('mod/enums/Quality')
local SimpleDb = mod.require('mod/helpers/SimpleDb')

local TweakDb = {}
TweakDb.__index = TweakDb

setmetatable(TweakDb, { __index = SimpleDb })

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

function TweakDb:load(path)
	if not path or path == true then
		path = 'mod/data/tweakdb-meta'
	end

	SimpleDb.load(self, path)
end

function TweakDb:resolve(tweakId)
	local key = TweakDb.toKey(tweakId)

	return self.db and self.db[key] or nil
end

function TweakDb:resolvable(tweakId)
	local key = TweakDb.toKey(tweakId)

	return self.db[key] ~= nil
end

function TweakDb:search(term)
	return SimpleDb.search(self, term, { 'name', 'tag', 'type' })
end

function TweakDb:isTaggedAsSet(itemMeta)
	return itemMeta.tag and itemMeta.tag:find(' Set$')
end

function TweakDb:describe(itemMeta, extended, sets, ellipsis)
	local comment = ''

	if itemMeta.name then
		comment = itemMeta.name
	end

	if sets and self:isTaggedAsSet(itemMeta) then
		comment = string.upper(itemMeta.tag) .. ': ' .. comment
	end

	if ellipsis then
		comment = str.ellipsis(comment, ellipsis)
	end

	if extended then
		comment = comment .. ' / ' .. itemMeta.kind

		if itemMeta.group then
			comment = comment .. ' / ' .. itemMeta.group
		end

		if itemMeta.kind == 'Weapon' or (itemMeta.kind == 'Mod' and itemMeta.group == 'Cyberware') then
			comment = comment ..  ' / ' .. itemMeta.group2
		end
	end

	if itemMeta.quality then
		comment = comment .. ' / ' .. itemMeta.quality
		--comment = comment:gsub('^' .. itemMeta.quality:upper() .. ' ', '') .. ' / ' .. itemMeta.quality
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
	elseif self:isTaggedAsSet(itemMeta) then
		order = order .. itemMeta.tag .. '|'
	end

	if itemMeta.name then
		order = order .. itemMeta.name
	elseif itemMeta.type then
		order = order .. TweakDb.toItemAlias(itemMeta.type)
	end

	if itemMeta.quality then
		order = order .. '|' .. Quality.toValue(itemMeta.quality)
		--order = order .. '|' .. (Quality.maxValue() - Quality.toValue(itemMeta.quality))
	end

	return string.upper(order)
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
		return (data.length << 32 | data.hash)
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
		return { hash = data & 0xFFFFFFFF, length = data >> 32 }
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
	if type(tweakId) == 'string' then
		return str.without(tweakId, prefix)
	end

	return ''
end

function TweakDb.toTweakId(tweakId, prefix)
	if type(tweakId) == 'number' then
		tweakId = TweakDb.toStruct(tweakId)
	end

	if type(tweakId) == 'table' then
		return TweakDBID.new(tweakId.hash, tweakId.length)
	end

	if type(tweakId) == 'string' then
		return TweakDBID.new(str.with(tweakId, prefix))
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

	if itemMeta and itemMeta.mod and not self:resolvable(tweakId) then
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
	end

	return tweakId
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
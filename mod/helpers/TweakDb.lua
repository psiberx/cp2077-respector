local mod = ...
local str = mod.require('mod/utils/str')
local SimpleDb = mod.require('mod/helpers/SimpleDb')

local TweakDb = {}
TweakDb.__index = TweakDb

setmetatable(TweakDb, { __index = SimpleDb })

local qualityIndices = {
	['Common'] = 1,
	['Uncommon'] = 2,
	['Rare'] = 3,
	['Epic'] = 4,
	['Legendary'] = 5,
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

local RealToItemID = ToItemID
local FakeToItemID = function (o) return o end
local RealToTweakDBID = ToTweakDBID
local FakeToTweakDBID = function (o) return o end

function TweakDb:resolve(tweakDbId)
	if mod.env.is183() then
		tweakDbId = self:extract(tweakDbId)
	end

	return self.db and self.db[self.key(tweakDbId)] or nil
end

function TweakDb:resolvable(tweakDbId)
	if mod.env.is183() then
		tweakDbId = self:extract(tweakDbId)
	end

	return self.db[self.key(tweakDbId)] ~= nil
end

function TweakDb:search(term)
	return SimpleDb.search(self, term, { name = 1, tag = 2 })
end

function TweakDb:describe(itemMeta, extended, sets, ellipsis)
	local comment = ''

	if itemMeta.name then
		comment = itemMeta.name
		--comment = string.upper(itemMeta.name)
	end

	if sets and itemMeta.kind == 'Clothing' and itemMeta.tag == 'Set' then
		comment = string.upper(itemMeta.group2) .. ': ' .. comment
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
	elseif itemMeta.kind == 'Clothing' and itemMeta.tag == 'Set' then
		order = order .. itemMeta.group2 .. '|'
	end

	if itemMeta.name then
		order = order .. string.upper(itemMeta.name)
	else
		order = order .. string.upper(str.without(itemMeta.type, 'Items.'))
	end

	if itemMeta.quality then
		order = order .. '|' .. self:getQualityIndex(itemMeta.quality)
	end

	return order
end

function TweakDb:sort(items)
	SimpleDb.sort(self, items, '_order')
end

function TweakDb:getQualityIndex(qualityName)
	return qualityIndices[qualityName] or 0
end

function TweakDb:getTweakDbId(data, prefix)
	if type(data) == 'table' then
		return TweakDBID.new(data.hash, data.length)
	end

	if type(data) == 'number' then
		data = TweakDb.struct(data)

		return TweakDBID.new(data.hash, data.length)
	end

	if type(data) == 'string' then
		if prefix then
			data = str.with(data, prefix)
		end

		return TweakDBID.new(data)
	end

	if type(data) == 'userdata' then
		return data
	end
end

function TweakDb:getItemTweakDbId(data)
	return self:getTweakDbId(data, 'Items.')
end

function TweakDb:getItemId(tweakDbId, seed)
	if type(tweakDbId) == 'string' then
		tweakDbId = self:getItemTweakDbId(tweakDbId)
	end

	if seed then
		return ItemID.new(tweakDbId, seed)
	else
		return GetSingleton('gameItemID'):FromTDBID(tweakDbId)
		--return ItemID.new(tweakDbId, 1)
	end
end

function TweakDb:getSlotTweakDbId(slotAlias, itemMeta)
	if slotAlias == 'Muzzle' then
		slotAlias = 'PowerModule'
	end

	local slotName = str.with(slotAlias, 'AttachmentSlots.')
	local tweakDbId = TweakDBID.new(slotName)

	if itemMeta and itemMeta.mod and not self:resolvable(tweakDbId) then
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

		tweakDbId = TweakDBID.new(slotName)
	end

	return tweakDbId
end

--function TweakDb:getSlotAlias(slotType, itemMeta)
--	if type(slotType) == 'userdata' then
--		local slotMeta = self:resolve(slotType)
--
--		if type(slotMeta) == 'string' then
--			slotType = slotMeta
--		elseif type(slotMeta) == 'table' then
--			return slotMeta.name
--		else
--			return ''
--		end
--	end
--
--	local slotAlias = str.without(slotType, 'AttachmentSlots.')
--
--	if slotAlias == 'PowerModule' then
--		slotAlias = 'Muzzle'
--	end
--
--	if itemMeta and itemMeta.mod then
--		if string.match(slotAlias, '^' .. itemMeta.mod) then
--			local uniquePart = string.sub(slotAlias, string.len(itemMeta.mod) + 1)
--			if string.match(uniquePart, '^%d$') then
--				slotAlias = 'Mod' .. uniquePart
--			else
--				slotAlias = uniquePart
--			end
--		elseif slotAlias == 'ArmsCyberwareGeneralSlot' and itemMeta.kind == 'Cyberware' and itemMeta.group == 'Arms' then
--			slotAlias = 'Mod'
--		end
--	end
--
--	return slotAlias
--end

function TweakDb:extract(id)
	if mod.env.is183() then
		ToItemID = FakeToItemID
		ToTweakDBID = FakeToTweakDBID

		local data = (load('return ' .. tostring(id)))()

		ToItemID = RealToItemID
		ToTweakDBID = RealToTweakDBID

		return data
	end

	if id.id then
		return { id = { id.id.hash, length = id.id.length }, rng_seed = id.rng_seed }
	end

	if id.hash then
		return { hash = id.hash, length = id.length }
	end

	return id
end

function TweakDb.key(struct)
	return (struct.length << 32 | struct.hash)
end

function TweakDb.struct(key)
	return { hash = key & 0xFFFFFFFF, length = key >> 32 }
end

return TweakDb
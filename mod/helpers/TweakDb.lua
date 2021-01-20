local mod = ...
local str = mod.require('mod/utils/str')

local TweakDb = {}
TweakDb.__index = TweakDb

local qualityIndices = {
	['Common'] = 1,
	['Uncommon'] = 2,
	['Rare'] = 3,
	['Epic'] = 4,
	['Legendary'] = 5,
}

local RealToItemID = ToItemID
local FakeToItemID = function (o) return o end
local RealToTweakDBID = ToTweakDBID
local FakeToTweakDBID = function (o) return o end

function TweakDb:new()
	local this = {}

	setmetatable(this, TweakDb)

	return this
end

function TweakDb:load(path)
	self.db = mod.load(path)
end

function TweakDb:unload()
	self.db = nil
end

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

function TweakDb:iterate()
	return pairs(self.db)
end

function TweakDb:filter(criteria)
	local key, item

	return function()
		while true do
			key, item = next(self.db, key)

			if item == nil then
				return nil
			end

			local match = self:match(item, criteria)

			if match then
				return item
			end
		end
	end
end

function TweakDb:filtered(criteria)
	local result = {}

	for _, item in pairs(self.db) do
		if self:match(item, criteria) then
			table.insert(result, item)
		end
	end

	return result
end

function TweakDb:match(item, criteria)
	local match = true

	for field, condition in pairs(criteria) do
		if type(condition) == 'table' then
			match = false
			for _, value in ipairs(condition) do
				if item[field] == value then
					match = true
					break
				end
			end
		elseif type(condition) == 'boolean' then
			if (item[field] and true or false) ~= condition then
				match = false
				break
			end
		else
			if item[field] ~= condition then
				match = false
				break
			end
		end
	end

	return match
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

function TweakDb:getSlotAlias(slotType, itemMeta)
	if type(slotType) == 'userdata' then
		local slotMeta = self:resolve(slotType)

		if type(slotMeta) == 'string' then
			slotType = slotMeta
		elseif type(slotMeta) == 'table' then
			return slotMeta.name
		else
			return ''
		end
	end

	local slotAlias = str.without(slotType, 'AttachmentSlots.')

	if slotAlias == 'PowerModule' then
		slotAlias = 'Muzzle'
	end

	if itemMeta and itemMeta.mod then
		if string.match(slotAlias, '^' .. itemMeta.mod) then
			local uniquePart = string.sub(slotAlias, string.len(itemMeta.mod) + 1)
			if string.match(uniquePart, '^%d$') then
				slotAlias = 'Mod' .. uniquePart
			else
				slotAlias = uniquePart
			end
		elseif slotAlias == 'ArmsCyberwareGeneralSlot' and itemMeta.kind == 'Cyberware' and itemMeta.group == 'Arms' then
			slotAlias = 'Mod'
		end
	end

	return slotAlias
end

function TweakDb:describe(itemMeta, extended)
	local comment = ''

	if itemMeta.name then
		comment = string.upper(itemMeta.name)
	end

	if extended then
		comment = comment .. ' / ' .. itemMeta.kind

		if itemMeta.group then
			comment = comment .. ' / ' .. itemMeta.group
		end

		if itemMeta.kind == 'Mod' and itemMeta.group == 'Cyberware' then
			comment = comment ..  ' / ' .. itemMeta.group2
		elseif itemMeta.kind == 'Clothing' and itemMeta.tag == 'Set' then
			comment = string.upper(itemMeta.group2) .. ': ' .. comment
		end
	end

	if itemMeta.quality then
		comment = comment .. ' / ' .. itemMeta.quality
	end

	return comment
end

function TweakDb:order(itemMeta)
	local order = ''

	if itemMeta.kind == 'Mod' then
		order = order .. itemMeta.group .. '::'

		if itemMeta.group == 'Cyberware' then
			order = order .. itemMeta.group2 .. '::'
		end
	elseif itemMeta.kind == 'Clothing' and itemMeta.tag == 'Set' then
		order = order .. itemMeta.group2 .. '::'
	end

	if itemMeta.name then
		order = order .. string.upper(itemMeta.name)
	else
		order = order .. string.upper(str.without(itemMeta.type, 'Items.'))
	end

	if itemMeta.quality then
		order = order .. '::' .. self:getQualityIndex(itemMeta.quality)
	end

	return order
end

function TweakDb:getQualityIndex(qualityName)
	return qualityIndices[qualityName] or 0
end

function TweakDb:extract(id)
	ToItemID = FakeToItemID
	ToTweakDBID = FakeToTweakDBID

	local data = (load('return ' .. tostring(id)))()

	ToItemID = RealToItemID
	ToTweakDBID = RealToTweakDBID

	return data
end

function TweakDb.key(struct)
	return (struct.hash << 8 | struct.length)
end

function TweakDb.struct(key)
	return { hash = key >> 8, length = key & 0xFF }
end

return TweakDb
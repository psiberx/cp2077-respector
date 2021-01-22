local Rarity = {}
Rarity.__index = Rarity

local rarityNames = {
	'Common', -- 1
	'Uncommon', -- 2
	'Rare', -- 3
	'Epic', -- 4
	'Legendary', -- 5
}

local rarityValues = {
	['Common'] = 1,
	['Uncommon'] = 2,
	['Rare'] = 3,
	['Epic'] = 4,
	['Legendary'] = 5,
}

local rarityColors = {
	['Common'] = 0xffcccccc,
	['Uncommon'] = 0xff85ed1e, -- #1eed85
	['Rare'] = 0xffff9936,
	['Epic'] = 0xffff42bd, -- #a537ff
	['Legendary'] = 0xff3195fa,
}

--function Rarity:new(value)
--	local this = { value = value }
--
--	setmetatable(this, self)
--
--	return this
--end

function Rarity.toName(value)
	return rarityNames[value]
end

function Rarity.toValue(name)
	return rarityValues[name]
end

function Rarity.toColor(name)
	return rarityColors[name]
end

function Rarity.all()
	return rarityNames
end

function Rarity.upTo(max)
	local list = {}

	for _, rarity in ipairs(rarityNames) do
		table.insert(list, rarity)

		if rarity == max then
			break
		end
	end

	return list
end

return Rarity
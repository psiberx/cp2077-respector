local Quality = {}
--Quality.__index = Quality

local qualityNames = {
	'Common', -- 1
	'Uncommon', -- 2
	'Rare', -- 3
	'Epic', -- 4
	'Legendary', -- 5
}

local qualityValues = {
	['Common'] = 1,
	['Uncommon'] = 2,
	['Rare'] = 3,
	['Epic'] = 4,
	['Legendary'] = 5,
}

local qualityColors = {
	['Common'] = 0xffcccccc,
	['Uncommon'] = 0xff85ed1e, -- #1eed85
	['Rare'] = 0xffff9936,
	['Epic'] = 0xffff42bd, -- #a537ff
	['Legendary'] = 0xff3195fa,
}

--function Quality:new(value)
--	local this = { value = value }
--
--	setmetatable(this, self)
--
--	return this
--end

function Quality.toName(value)
	return qualityNames[value]
end

function Quality.toValue(name)
	return qualityValues[name]
end

function Quality.maxValue()
	return #qualityNames
end

function Quality.toColor(name)
	return qualityColors[name]
end

function Quality.all()
	return qualityNames
end

function Quality.upTo(max)
	local list = {}

	for _, quality in ipairs(qualityNames) do
		table.insert(list, quality)

		if quality == max then
			break
		end
	end

	return list
end

return Quality
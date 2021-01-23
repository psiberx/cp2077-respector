local RarityFilter = {}
RarityFilter.__index = RarityFilter

local values = {
	false,
	'Iconic',
	'Rare',
	'Rare+Iconic',
	'Epic',
	'Epic+Iconic',
	'Legendary',
	'Legendary+Iconic'
}

local labels = {
	'Any rarity',
	'Iconic only',
	'Rare and higher',
	'Rare and higher or Iconic',
	'Epic and higher',
	'Epic and higher or Iconic',
	'Legendary only',
	'Legendary or Iconic',
}

function RarityFilter:new(value)
	local this = { value = value }

	setmetatable(this, self)

	return this
end

function RarityFilter.asCriteria(value)
	if not value then
		return nil
	end

	local criteria = {}

	value:gsub('([^%+$]+)', function(token)
		if token == 'Iconic' then
			criteria.iconic = true
		else
			criteria.quality = token
		end
	end)

	return criteria
end

function RarityFilter.all()
	return values
end

function RarityFilter.labels()
	return labels
end

return RarityFilter
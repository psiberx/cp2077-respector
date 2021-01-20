local array = {}

function array.find(list, value)
	for index, item in ipairs(list) do
		if item == value then
			return index
		end
	end

	return nil
end

function array.map(list, mapper)
	local result = {}
	local isCallback = type(mapper) == 'function'

	for index, item in ipairs(list) do
		if isCallback then
			result[index] = mapper(item, index)
		else
			result[index] = item[mapper]
		end
	end

	return result
end

return array
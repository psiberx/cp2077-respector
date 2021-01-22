local array = {}

function array.find(items, value)
	for index, item in ipairs(items) do
		if item == value then
			return index
		end
	end

	return nil
end

function array.map(items, mapper)
	local result = {}
	local isCallback = type(mapper) == 'function'

	for index, item in ipairs(items) do
		if isCallback then
			result[index] = mapper(item, index)
		else
			result[index] = item[mapper]
		end
	end

	return result
end

function array.sort(items, sorter)
	table.sort(items, function(a, b)
		if sorter then
			return a[sorter] < b[sorter]
		end

		return a < b
	end)
end

function array.limit(items, limit)
	while #items > limit do
		table.remove(items)
	end
end

--function array.splice(items, start, count)
--end

return array
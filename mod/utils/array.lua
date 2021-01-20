local array = {}

function array.find(list, value)
	for index, item in ipairs(list) do
		if item == value then
			return index
		end
	end

	return nil
end

return array
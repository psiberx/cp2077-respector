local fs = {}

function fs.isfile(path)
	local f = io.open(path, 'r')

	if f == nil then
		return false
	end

	io.close(f)

	return true
end

return fs
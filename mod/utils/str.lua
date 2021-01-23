local str = {}

function str.trim(s)
	return (s:gsub('^%s*(.-)%s*$', '%1'))
end

function str.rtrim(s)
	return (s:gsub('^(.-)%s*$', '%1'))
end

function str.ucfirst(s)
    return (s:gsub('^%l', string.upper))
end

function str.with(s, prefix, suffix)
	if prefix and not s:find('^' .. prefix) then
		s = prefix .. s
	end
	
	if suffix and not s:find(suffix .. '$') then
		s = s .. suffix
	end

	return s
end

function str.without(s, prefix, suffix)
	if prefix then
		s = s:gsub('^' .. prefix, '')
	end

	if suffix then
		s = s:gsub(suffix .. '$', '')
	end

	return s
end

function str.isempty(s)
	return s == nil or s == ''
end

function str.nonempty(...)
	for i = 1, select('#', ...) do
		local s = select(i, ...)
		if s ~= nil and s ~= '' then
			return s
		end
	end

	return nil
end

function str.ellipsis(s, limit, ending)
	if not ending then
		ending = '...'
	end

	if s:len() - ending:len() <= limit then
		return s
	end

	return str.rtrim(s:sub(1, limit)) .. ending
end

--function str.padnul(s, len)
--	return s .. string.rep('\0', len - s:len())
--end

--function str.stripnul(s)
--	return (string.gsub(s, '\0.+$', ''))
--end

return str
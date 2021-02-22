local export = {}

function export.table(t, max, depth)
	if type(t) ~= 'table' then
		return ''
	end

	max = max or 63
	depth = depth or 0

	local dumpStr = '{\n'
	local indent = string.rep('\t', depth)

	for k, v in pairs(t) do
		local kstr = ''
		if type(k) == 'string' then
			kstr = string.format('[\'%s\'] = ', k)
		end

		local vstr = tostring(v)
		if type(v) == 'string' then
			vstr = string.format('\'%s\'', tostring(v))
		elseif type(v) == 'table' then
			if depth < max then
				vstr = export.table(v, max, depth + 1)
			else
				vstr = '...'
			end
		end

		dumpStr = string.format('%s\t%s%s%s,\n', dumpStr, indent, kstr, vstr)
	end

	return string.format('%s%s}', dumpStr, indent)
end

function export.keys(t, max, depth)
	if type(t) ~= 'table' then
		return ''
	end

	max = max or 63
	depth = depth or 0

	local dumpStr = '{\n'
	local indent = string.rep('\t', depth)

	for k, v in pairs(t) do
		local kstr = tostring(k)
		if type(k) == 'string' then
			kstr = string.format('[\'%s\']', k)
		end

		local vstr = ''
		if type(v) == 'table' and depth < max then
			vstr = ' = ' .. export.keys(v, max, depth + 1)
		else
			vstr = ' = ...'
		end

		dumpStr = string.format('%s\t%s%s%s,\n', dumpStr, indent, kstr, vstr)
	end

	return string.format('%s%s}', dumpStr, indent)
end

return export
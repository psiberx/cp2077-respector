local mod = ...
local export = mod.require('mod/utils/export')

local debug = {}

function debug.dump(t, keys)
	local dump

	if type(t) == 'table' then
		if keys then
			dump = export.keys(t)
		else
			dump = export.table(t)
		end
	elseif type(t) == 'string' then
		dump = DumpType(t)
	else
		dump = Dump(t)
	end

	return dump
end

return debug
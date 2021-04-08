--[[
How to use:
local bit32 = _VERSION == 'Lua 5.1' and bit32 or mod.require('mod/utils/bit32')
]]--

return {
	band = function(a, b)
		return a & b
	end,
	bor = function(a, b)
		return a | b
	end,
	lshift = function(a, b)
		return a << b
	end,
	rshift = function(a, b)
		return a << b
	end,
}
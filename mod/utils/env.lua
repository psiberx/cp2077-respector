local env = {}
local win

--function env.is(ver)
--	return GetVersion() == ver
--end

function env.isWin()
	if win == nil then
		win = package.config:sub(1, 1) == '\\'
		--win = os.tmpname():sub(1, 1) == '\\'
	end
	
	return win
end

return env
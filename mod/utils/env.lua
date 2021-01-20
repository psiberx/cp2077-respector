local env = {}
local win, cet183

function env.is183()
	if cet183 == nil then
		cet183 = GetVersion == nil
	end

	return cet183
end

function env.isWin()
	if win == nil then
		win = package.config:sub(1, 1) == '\\'
		--win = os.tmpname():sub(1, 1) == '\\'
	end
	
	return win
end

return env
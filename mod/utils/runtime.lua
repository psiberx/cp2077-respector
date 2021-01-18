local runtime = {}
local win

function runtime.win()
	if win == nil then
		win = package.config:sub(1, 1) == '\\'
--		win = os.tmpname():sub(1, 1) == '\\'
	end
	
	return win
end

return runtime
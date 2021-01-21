local mod = ...
local api = mod.require('mod/ui/api')

local cli = {}

function cli.init(respector)
	api.init(respector)
end

function cli.getModApi()
	return api
end

function cli.registerGlobalApi()
	Respector = api

	if mod.debug then
		print(('[DEBUG] Respector: Registered global API.'))
	end
end

function cli.unregisterGlobalApi()
	if Respector then
		Respector = nil

		if mod.debug then
			print(('[DEBUG] Respector: Unregistered global API.'))
		end
	end
end

return cli
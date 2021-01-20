local mod = ...

local respector
local api = {}

function api.LoadSpec(specName, _)
	if specName == api then
		specName = _
	end

	return respector:loadSpec(specName)
end

function api.SaveSpec(specName, specOptions, _)
	if specName == api then
		specName, specOptions = specOptions, _
	end

	return respector:saveSpec(specName, specOptions)
end

function api.SaveSnap()
	return respector:saveSpec(nil, { timestamp = true })
end

local cli = {}

function cli.init(_respector)
	respector = _respector
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

--function cli.registerGameApi()
--	Game['LoadSpec'] = api['LoadSpec']
--	Game['SaveSpec'] = api['SaveSpec']
--	Game['SaveSpecSnap'] = api['SaveSpecSnap']
--
--	if mod.debug then
--		print(('[DEBUG] Respector: Registered Game object API.'))
--	end
--end

--function cli.unregisterGameApi()
--	if Game['LoadSpec'] then
--		Game['LoadSpec'] = nil
--		Game['SaveSpec'] = nil
--		Game['SaveSpecSnap'] = nil
--
--		if mod.debug then
--			print(('[DEBUG] Respector: Unregistered Game object API.'))
--		end
--	end
--end

return cli
local mod = ...

local api = {
	respector = nil
}

function api.LoadSpec(specName)
	return api.respector:loadSpec(specName)
end

function api.SaveSpec(specName, specOptions)
	return api.respector:saveSpec(specName, specOptions)
end

function api.SaveSnap()
	return api.respector:saveSpec(nil, { timestamp = true })
end

local cli = {}

function cli.init(respector)
	if mod.debug then
		print(('[DEBUG] Respector: Initializing CLI...'))
	end

	api.respector = respector
end

function cli.getModApi()
	return api
end

function cli.registerGlobalApi()
	Respector = {}
	Respector['LoadSpec'] = api['LoadSpec']
	Respector['SaveSpec'] = api['SaveSpec']
	Respector['SaveSnap'] = api['SaveSnap']

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
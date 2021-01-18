local mod = ...

local api = {
	respector = nil
}

function api.LoadSpec(specName)
	return api.respector:loadSpec(specName)
end

function api.SaveSpec(specName)
	return api.respector:saveSpec(specName)
end

function api.SaveSpecSnap()
	return api.respector:saveSpec(nil, { timestamp = true })
end

local cli = {}

function cli.init(respector)
	if mod.debug then
		print(('[DEBUG] Respector: Initializing CLI.'))
	end

	api.respector = respector
end

function cli.getModApi()
	return api
end

function cli.registerGlobalApi()
	if mod.debug then
		print(('[DEBUG] Respector: Registering global API.'))
	end

	Game['LoadSpec'] = api['LoadSpec']
	Game['SaveSpec'] = api['SaveSpec']
	Game['SaveSpecSnap'] = api['SaveSpecSnap']
end

function cli.unregisterGlobalApi()
	if Game['LoadSpec'] then
		if mod.debug then
			print(('[DEBUG] Respector: Unregistering global API.'))
		end

		Game['LoadSpec'] = nil
		Game['SaveSpec'] = nil
		Game['SaveSpecSnap'] = nil
	end
end

return cli
local mod = ...

local api = {}
local respector

function api.init(_respector)
	respector = _respector
end

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

function api.ExecSpec(specData, _)
	if specData == api then
		specData = _
	end

	return respector:execSpec(specData)
end

return api
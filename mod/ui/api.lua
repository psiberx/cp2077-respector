local api = {}

local respector, tweaker

function api.init(_respector, _tweaker)
	respector = _respector
	tweaker = _tweaker
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

function api.ExecSpec(specData, specOptions, _)
	if specData == api then
		specData, specOptions = specOptions, _
	end

	return respector:execSpec(specData, specOptions)
end

function api.SpawnVehicle(vehicleTweakId, spawnDistance, unlockDoors, _)
	if vehicleTweakId == api then
		vehicleTweakId, spawnDistance, unlockDoors = spawnDistance, unlockDoors, _
	end

	return tweaker:spawnVehicle(vehicleTweakId, spawnDistance, unlockDoors)
end

return api
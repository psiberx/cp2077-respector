local mod = ...
local TweakDb = mod.require('mod/helpers/TweakDb')

local TransportModule = {}
TransportModule.__index = TransportModule

function TransportModule:new()
	local this = { tweakDb = TweakDb:new() }

	setmetatable(this, self)

	return this
end

function TransportModule:prepare()
	self.vehicleSystem = Game.GetVehicleSystem()
end

function TransportModule:release()
	self.vehicleSystem = nil
end

function TransportModule:fillSpec(specData, specOptions)
	if specOptions.vehicles then
		local vehicleSpecs = self:getVehicles()

		if vehicleSpecs then
			specData.Vehicles = vehicleSpecs
		end
	end
end

function TransportModule:applySpec(specData)
	if specData.Vehicles then
		self:unlockVehicles(specData.Vehicles)
	end
end

function TransportModule:getVehicles()
	self.tweakDb:load('mod/data/tweakdb-meta')

	local vehicleSpecs = {}
	local vehicles = self.vehicleSystem:GetPlayerUnlockedVehicles()

	for _, vehicle in ipairs(vehicles) do
		local vehicleMeta = self.tweakDb:resolve(vehicle.recordID)

		local vehicleSpec = {}

		vehicleSpec[1] = TweakDb.toVehicleAlias(vehicleMeta.type)
		vehicleSpec._comment = self.tweakDb:describe(vehicleMeta)
		vehicleSpec._order = self.tweakDb:order(vehicleMeta)

		table.insert(vehicleSpecs, vehicleSpec)
	end

	self.tweakDb:unload()

	if #vehicleSpecs == 0 then
		return nil
	end

	self.tweakDb:sort(vehicleSpecs)

	return vehicleSpecs
end

function TransportModule:unlockVehicle(vehicle)
	local vehicleType = TweakDb.toVehicleType(vehicle)

	self.vehicleSystem:EnablePlayerVehicle(vehicleType, true, false)
end

function TransportModule:unlockVehicles(vehicles)
	for _, vehicle in ipairs(vehicles) do
		self:unlockVehicle(vehicle)
	end
end

function TransportModule:isVehicleUnlocked(vehicle)
	local tweakId = TweakDb.toVehicleTweakId(vehicle)

	local vehicles = self.vehicleSystem:GetPlayerUnlockedVehicles()

	for _, vehicle in ipairs(vehicles) do
		if tostring(tweakId) == tostring(vehicle.recordID) then
			return true
		end
	end

	return false
end

return TransportModule
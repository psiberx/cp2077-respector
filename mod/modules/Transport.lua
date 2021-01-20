local mod = ...
local str = mod.require('mod/utils/str')
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
		self:setVehicles(specData.Vehicles)
	end
end

function TransportModule:getVehicles()
	if mod.env.is183() then
		return nil
	end

	self.tweakDb:load('mod/data/tweakdb-meta')

	local vehicleSpecs = {}
	local vehicles = self.vehicleSystem:GetPlayerUnlockedVehicles()

	for _, vehicle in ipairs(vehicles) do
		local vehicleMeta = self.tweakDb:resolve(vehicle.recordID)

		local vehicleSpec = {}

		vehicleSpec[1] = str.without(vehicleMeta.type, 'Vehicle.')
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

function TransportModule:setVehicles(vehicles)
	for _, vehicle in ipairs(vehicles) do
		self.vehicleSystem:EnablePlayerVehicle(str.with(vehicle, 'Vehicle.', true, false))
	end
end

return TransportModule
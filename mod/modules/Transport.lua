local mod = ...
local str = mod.require('mod/utils/str')

local TransportModule = {}
TransportModule.__index = TransportModule

function TransportModule:new()
	local this = {}

	setmetatable(this, TransportModule)

	return this
end

function TransportModule:prepare()
	self.vehicleSystem = Game.GetVehicleSystem()
end

function TransportModule:release()
	self.vehicleSystem = nil
end

function TransportModule:getVehicles()
	return nil
end

function TransportModule:setVehicles(vehicles)
	for _, vehicle in ipairs(vehicles) do
		self.vehicleSystem:EnablePlayerVehicle(str.with(vehicle, 'Vehicle.', true, false))
	end
end

function TransportModule:applySpec(specData)
	if specData.Transport then
		self:setVehicles(specData.Transport)
	end
end

function TransportModule:fillSpec(specData)
	local transportData = self:getVehicles()

	if transportData then
		specData.Transport = transportData
	end
end

return TransportModule
local mod = ...
local TweakDb = mod.require('mod/helpers/TweakDb')

local Tweaker = {}
Tweaker.__index = Tweaker

function Tweaker:new()
	local this = {}

	setmetatable(this, self)

	return this
end

function Tweaker:spawnVehicle(vehicleTweakId, spawnDistance, unlockDoors)
	vehicleTweakId = TweakDb.toVehicleTweakId(vehicleTweakId)

	if spawnDistance == nil then
		spawnDistance = 7
	end

	if unlockDoors == nil then
		unlockDoors = true
	end

	local player = Game.GetPlayer()

	local forwardVector = player:GetWorldForward()
	local offsetVector = Vector3.new(forwardVector.x * spawnDistance, forwardVector.y * spawnDistance, forwardVector.z)

	local spawnTransform = player:GetWorldTransform()
	local spawnPosition = spawnTransform.Position:ToVector4(spawnTransform.Position)
	spawnPosition = Vector4.new(spawnPosition.x + offsetVector.x, spawnPosition.y + offsetVector.y, spawnPosition.z + offsetVector.z, spawnPosition.w)

	spawnTransform:SetPosition(spawnTransform, spawnPosition)

	local vehicleEntityId = Game.GetPreventionSpawnSystem():RequestSpawn(vehicleTweakId, 1, spawnTransform)

	if unlockDoors then
		mod.every(0.5, function(timer)
			local vehicleHandle = Game.FindEntityByID(vehicleEntityId)

			if vehicleHandle then
				vehicleHandle:GetVehiclePS():UnlockAllVehDoors()

				mod.halt(timer.id)
			end
		end)
	end
end

return Tweaker
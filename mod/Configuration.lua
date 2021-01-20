local mod = ...
local StructWriter = mod.require('mod/helpers/StructWriter')

local Configuration = {}
Configuration.__index = Configuration

function Configuration:new()
	local this = {}

	setmetatable(this, self)

	return this
end

function Configuration:writeConfig(configData)
	local configPath = mod.path('config')
	local configSchema = mod.load('mod/data/config-schema')

	local configWriter = StructWriter:new(configSchema)

	configWriter:writeStruct(configPath, configData or mod.config)

	if mod.debug then
		print(('[DEBUG] Respector: Saved config at %q.'):format(configPath))
	end
end

function Configuration:resetConfig(configData)
	self:writeConfig(configData or {})
end

function Configuration:writeDefaults(defaultsPath)
	local configPath = defaultsPath or mod.path('samples/config/defaults')
	local configWriter = StructWriter:new(mod.load('mod/data/config-schema'))

	configWriter:writeStruct(configPath, {})

	if mod.debug then
		print(('[DEBUG] Respector: Saved config defaults at %q.'):format(configPath))
	end
end

return Configuration
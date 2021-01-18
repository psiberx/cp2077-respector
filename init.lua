-- -------------------------------------------------------------------------- --
-- Base Directory
-- -------------------------------------------------------------------------- --
-- Can be an absolute path or relative to the CET mods directory.
-- Change it if you renamed the directory of the mod.
-- -------------------------------------------------------------------------- --

local baseDir = 'respector'

-- -------------------------------------------------------------------------- --
-- Debug Mode
-- -------------------------------------------------------------------------- --
-- Enables debug output in the console.
-- -------------------------------------------------------------------------- --

local debugMode = false

-- -------------------------------------------------------------------------- --
-- Developer Mode
-- -------------------------------------------------------------------------- --
-- 1. Resets Lua package cache forcing require() to always read the source.
-- 2. Recalculates hashes of known TweakDB names on every mod load.
-- 3. Recompiles the samples on every mod load.
-- 4. Recreates default confing file on every mod load.
-- 5. Enables Developer menu in th GUI.
-- -------------------------------------------------------------------------- --

local devMode = false

-- -------------------------------------------------------------------------- --

if devMode then
	local moduleCore = baseDir .. '/mod/mod'
	local modulePattern = '^%.[\\/]' .. baseDir .. '[./]*'

	for module, _ in pairs(package.loaded) do
		if module:find(modulePattern) or module == moduleCore then
			package.loaded[module] = nil

			if debugMode then
				print(('[DEBUG] Respector: Unloaded module %q.'):format(module))
			end
		end
	end
end

local api = {}
local mod = require(baseDir .. '/mod/mod')

mod.init(devMode, debugMode)

if devMode then
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:run()
end

local Respector = mod.require('mod/Respector')
local respector = Respector:new()

if mod.config.useModApi or mod.config.useGlobalApi then
	local cli = mod.require('mod/ui/cli')

	cli.init(respector)

	if mod.config.useGlobalApi then
		cli.registerGlobalApi()
	else
		cli.unregisterGlobalApi()
	end

	if mod.config.useModApi then
		api = cli.getModApi()
	end
end

if mod.config.useGui then
	local gui = mod.require('mod/ui/gui')

	gui.init(respector)

	registerForEvent('onConsoleOpen', function()
		gui.onConsoleOpen()
	end)

	registerForEvent('onConsoleClose', function()
		gui.onConsoleClose()
	end)

	registerForEvent('onUpdate', function(delta)
		mod.onUpdate(delta)
		gui.onUpdate()
	end)

	registerForEvent('onDraw', function()
		gui.onDraw()
	end)
else
	registerForEvent('onUpdate', function(delta)
		mod.onUpdate(delta)
	end)
end

print(('Respector v.%s loaded.'):format(respector.version))

if mod.config.useGlobalApi then
	print(('Respector: Global API enabled.'))
end

if mod.config.useGui then
	print(('Respector: Console GUI enabled.'))
end

return api
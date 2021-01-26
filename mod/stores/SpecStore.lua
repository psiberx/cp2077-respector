local mod = ...
local fs = mod.require('mod/utils/fs')
local str = mod.require('mod/utils/str')
local StructWriter = mod.require('mod/helpers/StructWriter')

local SpecStore = {}
SpecStore.__index = SpecStore

function SpecStore:new(specsDir, defaultSpec)
	local this = {}

	this.writer = StructWriter:new(mod.load('mod/data/spec-schema'))

	this.specsDir = mod.dir(str.nonempty(specsDir, mod.config.specsDir, 'specs'))
	this.defaultSpec = str.nonempty(defaultSpec, mod.config.defaultSpec, 'V')

	if mod.debug then
		print(('[DEBUG] Respector: Created spec store using %q.'):format(this.specsDir))
	end

	setmetatable(this, self)

	return this
end

function SpecStore:hasSpec(specName)
	if not specName or specName == '' then
		specName = self.defaultSpec
	end

	local specPath = mod.path(self.specsDir .. specName)

	return fs.isfile(specPath)
end

function SpecStore:readSpec(specName)
	if not specName or specName == '' then
		specName = self.defaultSpec
	end

	local specPath = mod.path(self.specsDir .. specName)

	local specChunk = loadfile(specPath)

	if not specChunk then
		return false, specName
	end

	return specChunk(mod), specName
end

function SpecStore:writeSpec(specName, specData, timestamped)
	if type(specData) ~= 'table' then
		return false, specName
	end

	if not specName or specName == '' then
		specName = self.defaultSpec
	end

	if timestamped then
		specName = specName .. '-' .. os.date('%y%m%d-%H%M%S')
	end

	local specPath = mod.path(self.specsDir .. specName)

	if mod.debug then
		print(('[DEBUG] Respector: Writing spec %q...'):format(specPath))
	end

	local success = self.writer:writeStruct(specPath, specData)

	return success, specName
end

return SpecStore
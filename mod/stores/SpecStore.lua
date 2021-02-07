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

function SpecStore:listSpecs()
	local specs = {}

	if type(dir) == 'function' then
		local existingSpecs = dir(self.specsDir)

		for _, specFileInfo in pairs(existingSpecs) do
			local specName = specFileInfo.name:match('^([^.].*)%.lua$')

			if specName  then
				local specFile = io.open(self.specsDir .. specFileInfo.name, 'r')
				local specHeader = specFile:read('l')
				specFile:close()

				if specHeader ~= '-- This is just a placeholder.' then
					local time = specHeader:match('^-- (%d%d%.%d%d%.%d%d%d%d %d%d:%d%d)') -- :%d%d

					if not time then
						time = os.date('%d.%m.%Y %H:%M')
					end

					table.insert(specs, { specName = specName, time = time })
				end
			end
		end
	end

	return specs
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
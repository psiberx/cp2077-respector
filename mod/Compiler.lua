local mod = ...
local str = mod.load('mod/utils/str')
local crc32 = mod.load('mod/utils/crc32')

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
	local this = {}

	setmetatable(this, self)

	return this
end

function Compiler:run()
	self:rehashTweakDbNames()
	self:compileSamplePacks()
	self:writeDefaultConfig()
end

function Compiler:rehashTweakDbNames(namesListPath, hashNamesDbPath, hashNamesCsvPath)
	if not namesListPath then
		namesListPath = mod.path('mod/data/tweakdb-names.txt')
	end

	if not hashNamesDbPath then
		hashNamesDbPath = namesListPath:gsub('%.txt$', '.lua')
	end

	if not hashNamesCsvPath then
		hashNamesCsvPath = namesListPath:gsub('%.txt$', '.csv')
	end

	local TweakDb = mod.require('mod/helpers/TweakDb')

	local fin = io.open(namesListPath)
	local fdb = io.open(hashNamesDbPath, 'w')
	local fcsv = io.open(hashNamesCsvPath, 'w')

	fdb:write('return {\n')

	for name in fin:lines() do
		local hash = crc32.hash(name)
		local length = string.len(name)
		local key = TweakDb.key({ hash = hash, length = length })

		fdb:write(string.format('[0x%016X] = %q, -- { hash = 0x%X, length = %d }\n', key, name, hash, length))
		fcsv:write(string.format('"0x%016X",%q\n', key, name))
	end

	fdb:write('}')

	fin:close()
	fdb:close()
	fcsv:close()

	if mod.debug then
		print(('[DEBUG] Respector: Rehashed TweakDB names using list %q.'):format(namesListPath))
	end
end

function Compiler:compileSamplePacks(samplePacksDir, samplePacks)
	if not samplePacksDir then
		samplePacksDir = mod.dir('samples/packs')
	end

	if not samplePacks then
		samplePacks = mod.load('mod/data/sample-packs')
	end

	local partSlots = mod.load('mod/data/attachment-slots')

	local SpecStore = mod.require('mod/stores/SpecStore')
	local specStore = SpecStore:new(samplePacksDir)

	local TweakDb = mod.require('mod/helpers/TweakDb')
	local tweakDb = TweakDb:new()

	tweakDb:load('mod/data/tweakdb-meta')

	for _, samplePack in ipairs(samplePacks) do
		local specName = samplePack.name
		local specData = {}

		specData._comment = samplePack.desc or ''

		if samplePack.items then
			local itemSpecs = {}

			for itemMeta in tweakDb:filter(samplePack.items) do
				local itemSpec = {}

				itemSpec._comment = tweakDb:describe(itemMeta, true)
				itemSpec._order = tweakDb:order(itemMeta)

				if itemMeta.desc then
					itemSpec._comment = itemSpec._comment .. '\n' .. itemMeta.desc:gsub('%. ', '.\n')

					if not itemSpec._comment:find('%.$') then
						itemSpec._comment = itemSpec._comment .. '.'
					end
				end

				itemSpec.id = str.without(itemMeta.type, 'Items.')

				if samplePack.items.kind == 'Cyberware' then
					local itemSlots = {}

					for _, partSlot in ipairs(partSlots) do
						if tweakDb:match(itemMeta, partSlot.criteria) then
							local matched = true

							if itemMeta.group2 == 'Cyberdeck' then
								local slotsNum = tweakDb:getQualityIndex(itemMeta.quality) + 1

								if partSlot.index > slotsNum then
									matched = false
								end
							end

							if matched then
								table.insert(itemSlots, { slot = partSlot.slot })
							end
						end
					end

					if #itemSlots > 0 then
						itemSpec.slots = itemSlots
						itemSpec._inline = false
					end

				elseif samplePack.name == 'stash-wall' then
					if itemMeta.quest then
						itemSpec.quest = false
					end
				end

				table.insert(itemSpecs, itemSpec)
			end

			tweakDb:sort(itemSpecs)

			specData.Inventory = itemSpecs
		end

		if samplePack.vehicles then
			local vehicleSpecs = {}

			for vehicleMeta in tweakDb:filter(samplePack.vehicles) do
				local vehicleSpec = {}

				vehicleSpec[1] = str.without(vehicleMeta.type, 'Vehicle.')
				vehicleSpec._comment = tweakDb:describe(vehicleMeta)
				vehicleSpec._order = tweakDb:order(vehicleMeta)

				table.insert(vehicleSpecs, vehicleSpec)
			end

			tweakDb:sort(vehicleSpecs)

			specData.Vehicles = vehicleSpecs
		end

		specStore:writeSpec(specName, specData)
	end

	tweakDb:unload()
end

function Compiler:writeDefaultConfig(configPath)
	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:writeDefaults(configPath)
end

function Compiler:writeDefaultSpec()
	local SpecStore = mod.require('mod/stores/SpecStore')
	local specStore = SpecStore:new()

	specStore:writeSpec(nil, {
		_comment = {
			'This is just a placeholder.',
			'If you want to try to load a spec then copy "samples/V.lua" here.',
		}
	})
end

return Compiler
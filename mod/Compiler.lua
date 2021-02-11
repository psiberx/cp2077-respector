local mod = ...
local str = mod.require('mod/utils/str')
local Quality = mod.require('mod/enums/Quality')

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
	local this = {}

	setmetatable(this, self)

	return this
end

function Compiler:run()
	self:rehashTweakDbIds()
	self:collectTweakDbInfo()
	self:compileSamplePacks()
	self:writeDefaultConfig()
end

function Compiler:rehashTweakDbIds(stringsListPath, hashNamesDbPath, hashNamesCsvPath)
	if not stringsListPath then
		stringsListPath = mod.path('mod/data/tweakdb-strings.txt')
	end

	local fin = io.open(stringsListPath, 'r')

	if not fin then
		return
	end

	if not hashNamesDbPath then
		hashNamesDbPath = mod.path('mod/data/tweakdb-names.lua')
	end

	if not hashNamesCsvPath then
		hashNamesCsvPath = mod.path('mod/data/tweakdb-names.csv')
	end

	local fdb = io.open(hashNamesDbPath, 'w')
	local fcsv = io.open(hashNamesCsvPath, 'w')

	fdb:write('return {\n')

	local allowedGroups = {
		Ammo = true,
		AttachmentSlots = true,
		Items = true,
		Vehicle = true,
	}

	for line in fin:lines() do
		local group, name, hash = line:match('^(%w+)%.(.+),(%d+)$')
		local pass = false

		if allowedGroups[group] and not name:find('%.') and not name:find('_inline%d+$') then
			if group == 'Vehicle' then
				pass = name:find('^v_')
			else
				pass = true
			end
		end

		if pass then
			name = group .. '.' .. name

			fdb:write(string.format('[0x%016X] = %q,\n', hash, name))
			fcsv:write(string.format('%s,0x%016X\n', name, hash))
		end
	end

	fdb:write('}')

	fin:close()
	fdb:close()
	fcsv:close()

	if mod.debug then
		print(('[DEBUG] Respector: Rehashed TweakDBIDs using list %q.'):format(stringsListPath))
	end
end

function Compiler:collectTweakDbInfo(outputCsvPath)
	if not outputCsvPath then
		outputCsvPath = mod.path('mod/data/tweakdb-info.csv')
	end

	local fcsv = io.open(outputCsvPath, 'w')

	local TweakDb = mod.require('mod/helpers/TweakDb')
	local tweakDb = TweakDb:new(true)

	local normalize = function(str)
		return str:gsub('"', '""'):gsub('“', '""'):gsub('’', '\''):gsub('–', '-')
	end

	for key, meta in tweakDb:each() do
		local localized = TweakDb.localize(key)

		if localized.name ~= '' or localized.comment ~= '' then
			fcsv:write(string.format('0x%016X,%s,"%s","%s"\n', key, meta.type, normalize(localized.name), normalize(localized.comment)))
		end
	end

	tweakDb:unload()

	fcsv:close()

	if mod.debug then
		print(('[DEBUG] Respector: Collected TweakDB display names and descriptions.'))
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
	local tweakDb = TweakDb:new(true)

	for _, samplePack in ipairs(samplePacks) do
		if mod.debug then
			print(('[DEBUG] Respector: Creating sample pack %q...'):format(samplePack.name))
		end

		local specName = samplePack.name
		local specData = {}

		specData._comment = samplePack.desc or ''

		if samplePack.items then
			local itemSpecs = {}

			samplePack.items.ref = false

			for _, itemMeta in tweakDb:filter(samplePack.items) do
				if itemMeta.kind ~= 'Pack' then
					local itemSpec = {}

					itemSpec._comment = tweakDb:describe(itemMeta, true, true)
					itemSpec._order = tweakDb:order(itemMeta)

					if itemMeta.comment then
						itemSpec._comment = itemSpec._comment .. '\n' .. itemMeta.comment --itemMeta.comment:gsub('([.!?]) ', '%1\n')
					end

					if itemMeta.desc then
						itemSpec._comment = itemSpec._comment .. '\n' .. itemMeta.desc:gsub('([.!?]) ', '%1\n')
					end

					itemSpec.id = TweakDb.toItemAlias(itemMeta.type)

					if samplePack.items.kind == 'Cyberware' then
						local itemSlots = {}

						for _, partSlot in ipairs(partSlots) do
							if tweakDb:match(itemMeta, partSlot.criteria) then
								local matched = true

								if itemMeta.group2 == 'Cyberdeck' then
									local slotsNum = Quality.toValue(itemMeta.quality) + 1

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
			end

			tweakDb:sort(itemSpecs)

			specData.Inventory = itemSpecs
		end

		if samplePack.vehicles then
			local vehicleSpecs = {}

			samplePack.vehicles.ref = false

			for _, vehicleMeta in tweakDb:filter(samplePack.vehicles) do
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
			'If you want to try to load a spec then copy "samples/Noname.lua" here.',
		}
	})
end

return Compiler
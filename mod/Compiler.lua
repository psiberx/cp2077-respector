local mod = ...
local str = mod.load('mod/utils/str')
local crc32 = mod.load('mod/utils/crc32')

local Compiler = {}
Compiler.__index = Compiler

function Compiler:new()
	local this = {}

	setmetatable(this, Compiler)

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

		fdb:write(string.format('[0x%010X] = %q, -- { hash = 0x%X, length = %d }\n', key, name, hash, length))
		fcsv:write(string.format('"0x%010X",%q\n', key, name))
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

				itemSpec._order = tweakDb:order(itemMeta)
				itemSpec._comment = tweakDb:describe(itemMeta, true)

				if itemMeta.desc then
					itemSpec._comment = itemSpec._comment .. '\n' .. itemMeta.desc:gsub('%. ', '.\n')

					if not itemSpec._comment:find('%.$') then
						itemSpec._comment = itemSpec._comment .. '.'
					end
				end

				itemSpec.id = str.without(itemMeta.type, 'Items.')

				if samplePack.name == 'stash-wall' then
					if itemMeta.quest then
						itemSpec.quest = false
					end
				end

				table.insert(itemSpecs, itemSpec)
			end

			table.sort(itemSpecs, function(a, b) return a._order < b._order end)

			specData.Inventory = itemSpecs
		end

		if samplePack.vehicles then
			local vehicleSpecs = {}

			for vehicleMeta in tweakDb:filter(samplePack.vehicles) do
				local vehicleSpec = {}

				vehicleSpec[1] = str.without(vehicleMeta.type, 'Vehicle.')
				vehicleSpec._comment = vehicleMeta.name

				table.insert(vehicleSpecs, vehicleSpec)
			end

			table.sort(vehicleSpecs, function(a, b) return a._comment < b._comment end)

			specData.Transport = vehicleSpecs
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

--local player = Game.GetPlayer()
--local transactionSystem = Game.GetTransactionSystem()
--local partSlots = mod.load('mod/data/attachment-slots')
--
--if itemMeta.kind == 'Cyberware' or itemMeta.kind == 'Weapon' or itemMeta.kind == 'Clothing' then
--	local itemId = tweakDb:getItemId(itemSpec.id)
--
--	transactionSystem:GiveItem(player, itemId, 1)
--
--	local slots = transactionSystem:GetAvailableSlotsOnItem(player, itemId)
--
--	for _, slotTweakDbId in pairs(slots) do
--		--print(itemMeta.type, tweakDb:getSlotAlias(slotTweakDbId, itemMeta))
--	end
--
--	--local itemData = transactionSystem:GetItemData(player, itemId)
--
--	--for _, slotName in ipairs(partSlots) do
--	--	local slotId = tweakDb:getSlotId(slotName)
--	--
--	--	if itemData:HasPlacementSlot(slotId) or itemData:HasAttachmentSlot(slotId) then
--	--		print(itemMeta.type, tweakDb:getSlotAlias(slotName, itemMeta))
--	--	end
--	--end
--
--	transactionSystem:RemoveItem(player, itemId, 1)
--end

return Compiler
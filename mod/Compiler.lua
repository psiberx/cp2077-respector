local mod = ...
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
	self:collectPerkInfo()
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
		hashNamesDbPath = mod.path('mod/data/tweakdb-ids.lua')
	end

	if not hashNamesCsvPath then
		hashNamesCsvPath = mod.path('mod/data/tweakdb-ids.csv')
	end

	local TweakDb = mod.require('mod/helpers/TweakDb')

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
		local group, name = line:match('^(%w+)%.(.+)$')
		local valid = false

		if not group then
			name = line:match('^(<TDBID:[0-9A-Z]+:[0-9A-Z]+>)$')
			if name then
				valid = true
			end
		elseif allowedGroups[group] and not name:find('%.') and not name:find('_inline%d+$') then
			valid = (group ~= 'Vehicle' or name:find('^v_'))
			if valid then
				name = group .. '.' .. name
			end
		end

		if valid then
            local hash = TweakDb.toKey(name)

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
	local tweakDb = TweakDb:new('mod/data/tweakdb-ids')

	local normalize = function(str)
		return str:gsub('"', '""'):gsub('“', '""'):gsub('’', '\''):gsub('–', '-')
	end

	local bool = function(value)
		return value and 'TRUE' or 'FALSE'
	end

	local boolopt = function(value)
		return value and 'TRUE' or ''
	end

	local iconicModId = TweakDBID('Quality.IconicItem')

	for key, id in tweakDb:each() do
		local record = TweakDB:GetRecord(TweakDb.toTweakId(key))

		if record and record:IsA('gamedataBaseObject_Record') then
			local name = GetLocalizedTextByKey(record:DisplayName())
			local desc = ''
			local ability = ''
			local category = ''
			local quality = ''
			local craftable = false
			local iconic = false

			if record:IsA('gamedataItem_Record') and (record:ItemCategory() or record:IsPart()) then
				desc = GetLocalizedTextByKey(record:LocalizedDescription())
				category = record:IsPart() and 'Mod' or NameToString(record:ItemCategory():Name())

				local qualityData = record:Quality()
				if qualityData and qualityData:Value() > 0 then
					quality = ('%d-%s'):format(qualityData:Value() + 1, qualityData:Name())
				end

				local attachData = record:GetOnAttachItem(0)
				if attachData then
					local uiData = attachData:UIData()
					if uiData then
						ability = GetLocalizedText(uiData:LocalizedDescription())
					end
				end

				local craftingData = record:CraftingData()
				if craftingData then
					craftable = true
				end

				for _, statMod in ipairs(record:StatModifiers()) do
                    if statMod:GetID() == iconicModId then
                        iconic = true
                        break
                    end
				end
			elseif record:IsA('gamedataVehicle_Record') then
				category = 'Vehicle'
			end

			if name ~= '' and category ~= '' then
				fcsv:write(('0x%016X,%s,"%s","%s","%s","%s","%s","%s","%s"\n'):format(
				    key, id, normalize(name), normalize(desc), normalize(ability),
				    category, quality, boolopt(iconic), bool(craftable)
				))
			end
		end
	end

	tweakDb:unload()

	fcsv:close()

	if mod.debug then
		print(('[DEBUG] Respector: Collected TweakDB display names and descriptions.'))
	end
end

function Compiler:collectPerkInfo(outputInfoPath, outputSchemaPath)
	if not outputInfoPath then
		outputInfoPath = mod.path('mod/data/perks-info.lua')
	end

	if not outputSchemaPath then
		outputSchemaPath = mod.path('mod/data/perks-schema.lua')
	end

	local finfo = io.open(outputInfoPath, 'w')
	finfo:write('return {\n')

	local fschema = io.open(outputSchemaPath, 'w')
	fschema:write('return {\n')

	local sep = false

    --for _, attrRec in ipairs(TweakDB:GetRecords('gamedataAttribute_Record')) do
    --    local attr = attrRec:EnumName()
    --    for _, skillRec in ipairs(attrRec:Proficiencies()) do
    --      local skill = skillRec:EnumName().value

    local skillMetas = {
        { id = "Proficiencies.Athletics", name = "Athletics", attr = "Body" },
        { id = "Proficiencies.Demolition", name = "Annihilation", attr = "Body" },
        { id = "Proficiencies.Brawling", name = "Street Brawler", attr = "Body" },
        { id = "Proficiencies.Assault", name = "Assault", attr = "Reflexes" },
        { id = "Proficiencies.Gunslinger", name = "Handguns", attr = "Reflexes" },
        { id = "Proficiencies.Kenjutsu", name = "Blades", attr = "Reflexes" },
        { id = "Proficiencies.Crafting", name = "Crafting", attr = "TechnicalAbility" },
        { id = "Proficiencies.Engineering", name = "Engineering", attr = "TechnicalAbility" },
        { id = "Proficiencies.Hacking", name = "Breach Protocol", attr = "Intelligence" },
        { id = "Proficiencies.CombatHacking", name = "Quickhacking", attr = "Intelligence" },
        { id = "Proficiencies.Stealth", name = "Stealth", attr = "Cool" },
        { id = "Proficiencies.ColdBlood", name = "Cold Blood", attr = "Cool" },
    }

    for _, skillMeta in ipairs(skillMetas) do
        local skillRec = TweakDB:GetRecord(skillMeta.id)
        local skill = skillMeta.name:gsub('[^%w]', '')
        local attr = skillMeta.attr

        if sep then
            finfo:write('\n')
        else
            sep = true
        end

        finfo:write(('\t-- %s\n'):format(skillMeta.name))

        fschema:write('{\n')
        fschema:write(('\tname = %q,\n'):format(skill))
        fschema:write('\tscope = "Perks",\n')
        fschema:write('\tchildren = {\n')

        for _, areaRec in ipairs(skillRec:PerkAreas()) do
            local req = math.max(3, areaRec:Requirement():ValueToCheck())
            for _, perkRec in ipairs(areaRec:Perks()) do
                local type = perkRec:EnumName().value
                local max = perkRec:GetLevelsCount()
                local name = GetLocalizedText(perkRec:Loc_name_key())
                local desc = GetLocalizedText(perkRec:Loc_desc_key()):gsub('{.+}', 'X')
                local alias = name:gsub('%s%l', string.upper):gsub('[^%w]', ''):gsub('^200', 'TwoHundred')

                finfo:write(
                    ('\t{ alias = %q, type = %q, max = %d, attr = %q, req = %d, skill = %q, name = %q, desc = %q },\n')
                    :format(alias, type, max, attr, req, skill, name, desc)
                )

                fschema:write(('\t\t{ name = %q, comment = perkDescription },\n'):format(alias))
            end
        end

        local traitRec = skillRec:Trait()
        local type = traitRec:EnumName().value
        local req = traitRec:Requirement():ValueToCheck()
        local max = 999
        local name = GetLocalizedText(traitRec:Loc_name_key())
        local desc = GetLocalizedText(traitRec:Loc_desc_key()):gsub('{.+}', 'X')
        local alias = name:gsub('%s%l', string.upper):gsub('[^%w]', '')

        finfo:write(
            ('\t{ alias = %q, type = %q, max = %d, attr = %q, trait = true, req = %d, skill = %q, name = %q, desc = %q },\n')
            :format(alias, type, max, attr, req, skill, name, desc)
        )

        fschema:write(('\t\t{ name = %q, comment = perkDescription },\n'):format(alias))
        fschema:write('\t},\n')
        fschema:write('},\n')
    end

    finfo:write('}')
    finfo:close()

    fschema:write('}')
    fschema:close()
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

					itemSpec.id = TweakDb.toItemAlias(itemMeta.id)

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

				vehicleSpec[1] = vehicleMeta.id
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
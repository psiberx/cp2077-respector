local mod = ...

local CharacterModule = {}
CharacterModule.__index = CharacterModule

function CharacterModule:new()
	local this = {}

	setmetatable(this, self)

	return this
end

function CharacterModule:prepare()
	local player = Game.GetPlayer()
	local scriptableSystemsContainer = Game.GetScriptableSystemsContainer()
	local playerDevSystem = scriptableSystemsContainer:Get(CName.new('PlayerDevelopmentSystem'))

	self.playerId = player:GetEntityID()
	self.statsSystem = Game.GetStatsSystem()
	self.playerDevData = playerDevSystem:GetDevelopmentData(player)

	self.aliases = mod.load('mod/data/dev-type-aliases')
	self.perksDb = mod.load('mod/data/perks')
end

function CharacterModule:release()
	self.playerId = nil
	self.statsSystem = nil
	self.playerDevData = nil

	self.aliases = nil
	self.perksDb = nil
end

function CharacterModule:fillSpec(specData, specOptions)
	if specOptions.character then
		local characterSchema = (mod.load('mod/data/spec-schema'))['children'][1]
		local characterData = self:getExpirience(characterSchema, specOptions)

		specData.Character = characterData
	end
end

function CharacterModule:applySpec(specData)
	if specData.Character then
		self:setLevels({
			Level = specData.Character.Level,
			StreetCred = specData.Character.StreetCred
		})

		if specData.Character.Attributes then
			self:setAttributes(specData.Character.Attributes)
		end

		if specData.Character.Skills then
			self:setSkills(specData.Character.Skills)
		end

		if specData.Character.Progression then
			self:setProgression(specData.Character.Progression)
		end

		if specData.Character.Perks then
			-- Need to wait after updating character level
			mod.defer(0.25, function()
				self:setPerks(specData.Character.Perks)
			end)
		end

		if specData.Character.Points then
			mod.defer(0.5, function()
				self:setPoints(specData.Character.Points, specData.Character.Perks)
			end)
		end
	end
end

function CharacterModule:getExpirience(schema, specOptions)
	local data = {}
	local count = 0

	for _, node in ipairs(schema.children) do
		if node.children then
			local children = self:getExpirience(node, specOptions)
			if children ~= nil then
				data[node.name] = children
				count = count + 1
			end
		elseif node.name then
			if schema.scope == 'Perks' then
				local perk = self.perksDb[node.name]
				local perkType = perk.type
				local perkLevel
				if perk.trait then
					perkLevel = self.playerDevData:GetTraitLevel(perkType)
				else
					perkLevel = self.playerDevData:GetPerkLevel(perkType)
				end
				if perkLevel > 0 or specOptions.allPerks then
					data[node.name] = math.max(0, math.floor(perkLevel))
					count = count + 1
				end
			elseif schema.scope == 'Progression' then
				local statType = self.aliases[node.name] or node.name
				local statLevel = self.playerDevData:GetCurrentLevelProficiencyExp(statType)
				if statLevel > 0 then
					data[node.name] = math.floor(statLevel)
					count = count + 1
				end
			elseif schema.scope == 'Points' then
				local statType = self.aliases[node.name] or node.name
				data[node.name] = math.floor(self.playerDevData:GetDevPoints(statType))
				count = count + 1
			else
				local statType = self.aliases[node.name] or node.name
				data[node.name] = math.floor(self.statsSystem:GetStatValue(self.playerId, statType))
				count = count + 1
			end
		end
	end

	if count == 0 then
		return nil
	end

	return data
end

function CharacterModule:setLevels(levels)
	for stat, level in pairs(levels) do
		if level then
			local type = self.aliases[stat] or stat
			local current = math.floor(self.statsSystem:GetStatValue(self.playerId, type))

			if current ~= level then
				self.playerDevData:SetLevel(type, level, 'Gameplay')
				--Game.SetLevel(type, level)
			end
		end
	end
end

function CharacterModule:setAttributes(attributes)
	for attribute, level in pairs(attributes) do
		local type = self.aliases[attribute] or attribute
		local current = math.floor(self.statsSystem:GetStatValue(self.playerId, type))

		if current ~= level then
			self.playerDevData:SetAttribute(type, level)
			self.playerDevData:AddDevelopmentPoints(-(level - current), type)
			--Game.SetAtt(type, level)
			--Game.GiveDevPoints('Attribute', -(level - current))
		end
	end
end

function CharacterModule:setSkills(skills)
	for skill, level in pairs(skills) do
		local type = self.aliases[skill] or skill
		local current = math.floor(self.statsSystem:GetStatValue(self.playerId, type))
		
		if current ~= level then
			self.playerDevData:SetLevel(type, level, 'Gameplay')
			--Game.SetLevel(type, level)
		end
	end
end

function CharacterModule:setProgression(progression)
	for skill, exp in pairs(progression) do
		local type = self.aliases[skill] or skill
		local current = math.floor(self.playerDevData:GetCurrentLevelProficiencyExp(type))

		if current ~= exp then
			self.playerDevData:AddExperience((exp - current), type, 'Gameplay')
			--Game.AddExp(type, (exp - current))
		end
	end
end

function CharacterModule:setPoints(points)
	for stat, amount in pairs(points) do
		local type = self.aliases[stat] or stat
		local current = math.floor(self.playerDevData:GetDevPoints(type))

		if current ~= amount then
			self.playerDevData:AddDevelopmentPoints((amount - current), type)
			--Game.GiveDevPoints(type, (amount - current))
		end
	end
end

function CharacterModule:setPerks(perkSpecs)
	self.playerDevData:RemoveAllPerks()

	local havePerkPoints = self.playerDevData:GetDevPoints('Primary')
	local needPerkPoints = 0

	for _, skillPerkSpecs in pairs(perkSpecs) do
		for _, perkLevel in pairs(skillPerkSpecs) do
			needPerkPoints = needPerkPoints + perkLevel
		end
	end

	if needPerkPoints > havePerkPoints then
		self.playerDevData:AddDevelopmentPoints(needPerkPoints - havePerkPoints, 'Primary')
	end

	for _, skillPerkSpecs in pairs(perkSpecs) do
		for perkAlias, perkLevel in pairs(skillPerkSpecs) do
			if perkLevel > 0 then
				local perk = self.perksDb[perkAlias]

				perkLevel = math.min(perkLevel, perk.max)

				for _ = 1, perkLevel do
					if perk.trait then
						self.playerDevData:IncreaseTraitLevel(perk.type)
					else
						self.playerDevData:BuyPerk(perk.type)
					end
				end
			end
		end
	end
end

return CharacterModule
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
	self.attributes = mod.load('mod/data/attributes')
	self.skills = mod.load('mod/data/skills')
	self.perks = mod.load('mod/data/perks')
end

function CharacterModule:release()
	self.playerId = nil
	self.statsSystem = nil
	self.playerDevData = nil

	self.aliases = nil
	self.attributes = nil
	self.skills = nil
	self.perks = nil
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
		elseif specData.Character.Attributes then
			self:setSkills({}) -- Enforce legit levels of skills 
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
				self:setPoints(specData.Character.Points)
			end)
		end

		--self:triggerAutoScaling()
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
				local perk = self.perks[node.name]
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
				local statType = self:getStatType(node.name)
				local statLevel = self.playerDevData:GetCurrentLevelProficiencyExp(statType)
				if statLevel > 0 then
					data[node.name] = math.floor(statLevel)
					count = count + 1
				end
			elseif schema.scope == 'Points' then
				local statType = self:getStatType(node.name)
				data[node.name] = math.floor(self.playerDevData:GetDevPoints(statType))
				count = count + 1
			else
				local statType = self:getStatType(node.name)
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

function CharacterModule:setLevels(levelsSpec)
	for _, statType in ipairs({ 'Level', 'StreetCred' }) do
		if levelsSpec[statType] then
			local statLevel = levelsSpec[statType]
			local playerStatLevel = self:getStatValue(statType)

			if statLevel ~= playerStatLevel then
				self.playerDevData:SetLevel(statType, statLevel, 'Gameplay')

				--Game.SetLevel(type, level)
			end
		end
	end
end

function CharacterModule:setAttributes(attributesSpec)
	for _, attribute in pairs(self.attributes) do
		local attrLevel = attributesSpec[attribute.alias] or attribute.default
		local playerAttrLevel = self:getStatValue(attribute.type)

		if attrLevel ~= playerAttrLevel then
			self.playerDevData:SetAttribute(attribute.type, attrLevel)
			self.playerDevData:AddDevelopmentPoints(-(attrLevel - playerAttrLevel), attribute.type)

			--Game.SetAtt(type, level)
			--Game.GiveDevPoints('Attribute', -(level - current))
		end
	end
end

function CharacterModule:setSkills(skillsSpec)
	for _, skill in pairs(self.skills) do
		local playerAttrLevel = self:getStatValue(skill.attr)
		local playerSkillLevel = self:getStatValue(skill.type)

		local skillLevel = skillsSpec[skill.alias] or skill.default

		if skillLevel > playerAttrLevel then
			skillLevel = playerAttrLevel
		end

		if skillLevel ~= playerSkillLevel then
			self.playerDevData:SetLevel(skill.type, skillLevel, 'Gameplay')

			--Game.SetLevel(type, level)
		end
	end
end

function CharacterModule:setProgression(progressionSpec)
	for skillAlias, skillExp in pairs(progressionSpec) do
		local skill = self.skills[skillAlias]

		if skill then
			local playerSkillExp = self:getProficiencyExp(skill.type)

			if skillExp ~= playerSkillExp then
				self.playerDevData:AddExperience((skillExp - playerSkillExp), skill.type, 'Gameplay')

				--Game.AddExp(type, (exp - current))
			end
		end
	end
end

function CharacterModule:setPerks(perkSpecs)
	self.playerDevData:RemoveAllPerks()

	local purchasePerks = {}
	local purchaseTraits = {}
	local needPerkPoints = 0

	for _, skillPerkSpecs in pairs(perkSpecs) do
		for perkAlias, perkLevel in pairs(skillPerkSpecs) do
			local perk = self.perks[perkAlias]

			if perk and perkLevel > 0 then
				local attrLevel = self:getStatValue(perk.attr)

				if attrLevel >= perk.req then
					perkLevel = math.min(perkLevel, perk.max)

					if perk.trait then
						purchaseTraits[perk.type] = perkLevel
					else
						purchasePerks[perk.type] = perkLevel
					end

					needPerkPoints = needPerkPoints + perkLevel
				end
			end
		end
	end

	local havePerkPoints = self.playerDevData:GetDevPoints('Primary')

	if needPerkPoints > havePerkPoints then
		self.playerDevData:AddDevelopmentPoints(needPerkPoints - havePerkPoints, 'Primary')
	end

	for perkType, perkLevel in pairs(purchasePerks) do
		for _ = 1, perkLevel do
			self.playerDevData:BuyPerk(perkType)
		end
	end

	for traitType, traitLevel in pairs(purchaseTraits) do
		for _ = 1, traitLevel do
			self.playerDevData:IncreaseTraitLevel(traitType)
		end
	end
end

function CharacterModule:setPoints(pointsSpec)
	for _, pointAlias in ipairs({ 'Perk', --[[ 'Attribute' ]] }) do
		if pointsSpec[pointAlias] then
			local pointType = self:getStatType(pointAlias)
			local requestedPoints = pointsSpec[pointAlias]
			local playerPoints = math.floor(self.playerDevData:GetDevPoints(pointType))

			if requestedPoints ~= playerPoints then
				self.playerDevData:AddDevelopmentPoints((requestedPoints - playerPoints), pointType)

				--Game.GiveDevPoints(pointType, (wantPoints - playerPoints))
			end
		end
	end
end

function CharacterModule:triggerAutoScaling()
	local playerLevel = self:getStatValue('Level')

	Game.SetLevel('Level', playerLevel)

	if mod.debug then
		print(('[DEBUG] Respector: Auto-scaled items to level %d.'):format(playerLevel))
	end
end

function CharacterModule:getStatValue(statAlias)
	return math.floor(self.statsSystem:GetStatValue(self.playerId, self:getStatType(statAlias)))
end

function CharacterModule:getProficiencyExp(statAlias)
	return math.floor(self.playerDevData:GetCurrentLevelProficiencyExp(self:getStatType(statAlias)))
end

function CharacterModule:getStatType(alias)
	return self.aliases[alias] or alias
end

return CharacterModule
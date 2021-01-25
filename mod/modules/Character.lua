local mod = ...

local CharacterModule = {}
CharacterModule.__index = CharacterModule

function CharacterModule:new()
	local this = {}

	setmetatable(this, self)

	return this
end

local playerLevelMin = 1
local playerLevelMax = 50

local attrBonus = 7
local attrLevelMin = 3
local attrLevelMax = 20
local attrTotalMin = attrLevelMin * 5
local attrStartMax = attrTotalMin + attrBonus - playerLevelMin

local skillLevelMin = 1
local skillLevelMax = 20

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
		local attrsApplied = false
		local skillsApplied = false

		self:setLevels({
			Level = specData.Character.Level,
			StreetCred = specData.Character.StreetCred
		})

		if specData.Character.Attributes then
			self:setAttributes(specData.Character.Attributes)
			attrsApplied = true
		elseif specData.Character.Level then
			self:setAttributes({}, true) -- Enforce legit attributes levels
			attrsApplied = true
		end

		if specData.Character.Skills then
			self:setSkills(specData.Character.Skills)
			skillsApplied = true
		elseif attrsApplied then
			self:setSkills({}, true) -- Enforce legit skills levels
			skillsApplied = true
		end

		if specData.Character.Progression then
			self:setProgression(specData.Character.Progression)
		end

		if specData.Character.Perks then
			-- Need to wait after updating character level
			mod.defer(0.25, function()
				self:setPerks(specData.Character.Perks)
			end)
		elseif skillsApplied then
			mod.defer(0.25, function()
				self:setPerks({}, true) -- Enforce legit perks
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

function CharacterModule:getLevel()
	return math.tointeger(self:getStatValue('Level'))
end

function CharacterModule:getAttributes()
	local attributesSpec = {}

	for _, attribute in pairs(self.attributes) do
		attributesSpec[attribute.alias] = self:getStatValue(attribute.type)
	end

	return attributesSpec
end

function CharacterModule:getTotalAttributePoints()
	return self:getLevel() + attrStartMax
end

function CharacterModule:getPerkPoints()
	return math.tointeger(self.playerDevData:GetDevPoints('Primary'))
end

function CharacterModule:setLevels(levelsSpec)
	for _, statType in ipairs({ 'Level', 'StreetCred' }) do
		if type(levelsSpec[statType]) == 'number' then
			local statLevel = math.max(playerLevelMin, math.min(playerLevelMax, levelsSpec[statType]))
			local playerStatLevel = self:getStatValue(statType)

			if statLevel ~= playerStatLevel then
				self.playerDevData:SetLevel(statType, statLevel, 'Gameplay')

				--Game.SetLevel(statType, statLevel)

				if statType == 'Level' then
					-- Fix attribute points
					local playerAttrPoints = self.playerDevData:GetDevPoints('Attribute')
					local playerAttrTotalLevel = 0

					for _, attribute in pairs(self.attributes) do
						playerAttrTotalLevel = playerAttrTotalLevel + self:getStatValue(attribute.type)
					end

					local correctAttrPoins = (statLevel + attrBonus - playerLevelMin) - (playerAttrTotalLevel - attrTotalMin)

					if correctAttrPoins ~= playerAttrPoints then
						self.playerDevData:AddDevelopmentPoints(correctAttrPoins - playerAttrPoints, 'Attribute')
					end

					-- Fix perk points
					self.playerDevData:AddDevelopmentPoints(-statLevel, 'Primary')
				end
			end
		end
	end
end

function CharacterModule:setAttributes(attributesSpec, mergeAttrs)
	local playerLevel = math.tointeger(self:getStatValue('Level'))
	local attrExtraLevelMax = playerLevel + attrStartMax - attrTotalMin

	for _, attribute in pairs(self.attributes) do
		local playerAttrLevel = math.tointeger(self:getStatValue(attribute.type))

		local attrLevel = math.tointeger(attributesSpec[attribute.alias])

		if type(attrLevel) == 'number' then
			attrLevel = math.max(attrLevel, attrLevelMin)
			attrLevel = math.min(attrLevel, attrLevelMax)
		elseif mergeAttrs then
			attrLevel = playerAttrLevel
		else
			attrLevel = attrLevelMin
		end

		attrLevel = math.min(attrLevel, attrExtraLevelMax + attrLevelMin)

		if attrLevel ~= playerAttrLevel then
			self.playerDevData:SetAttribute(attribute.type, attrLevel)
			self.playerDevData:AddDevelopmentPoints(-(attrLevel - playerAttrLevel), 'Attribute')

			--Game.SetAtt(type, level)
			--Game.GiveDevPoints('Attribute', -(level - current))
		end

		attrExtraLevelMax = math.max(0, attrExtraLevelMax - attrLevel + attrLevelMin)
	end
end

function CharacterModule:setSkills(skillsSpec, mergeSkills)
	local perkPointsBefore = self:getPerkPoints()

	for _, skill in pairs(self.skills) do
		local playerAttrLevel = self:getStatValue(skill.attr)
		local playerSkillLevel = self:getStatValue(skill.type)

		local skillLevel = skillsSpec[skill.alias]

		if type(skillLevel) == 'number' then
			skillLevel = math.max(skillLevel, skillLevelMin)
			skillLevel = math.min(skillLevel, skillLevelMax)
		elseif skillLevel == true then
			skillLevel = playerAttrLevel
		elseif mergeSkills then
			skillLevel = playerSkillLevel
		else
			skillLevel = skillLevelMin
		end

		if skillLevel > playerAttrLevel then
			skillLevel = playerAttrLevel
		end

		if skillLevel ~= playerSkillLevel then
			self.playerDevData:SetLevel(skill.type, skillLevel, 'Gameplay')

			--Game.SetLevel(type, level)
		end
	end

	mod.defer(0.05, function()
		local perkPointsAfter = self:getPerkPoints()

		-- Fix perk points
		if perkPointsAfter ~= perkPointsBefore then
			self.playerDevData:AddDevelopmentPoints(-(perkPointsAfter - perkPointsBefore), 'Primary')
		end
	end)
end

function CharacterModule:setProgression(progressionSpec)
	for skillAlias, skillExp in pairs(progressionSpec) do
		local skill = self.skills[skillAlias]

		if skill and type(skillExp) == 'number' then
			local playerSkillExp = self:getProficiencyExp(skill.type)

			if skillExp ~= playerSkillExp then
				self.playerDevData:AddExperience((skillExp - playerSkillExp), skill.type, 'Gameplay')

				--Game.AddExp(type, (exp - current))
			end
		end
	end
end

function CharacterModule:setPerks(perkSpecs, mergePerks)
	if not mergePerks then
		self.playerDevData:RemoveAllPerks()
	end

	local adjustPerks = {}
	local adjustTraits = {}
	local needPerkPoints = 0

	for perkAlias, perk in pairs(self.perks) do
		local perkLevel = perkSpecs[perkAlias]

		if not perkLevel and perkSpecs[perk.skill] then
			perkLevel = perkSpecs[perk.skill][perkAlias]
		end

		local playerAttrLevel = self:getStatValue(perk.attr)
		local playerPerkLevel

		if perk.trait then
			playerPerkLevel = self.playerDevData:GetTraitLevel(perk.type)
		else
			playerPerkLevel = self.playerDevData:GetPerkLevel(perk.type)
		end

		playerPerkLevel = math.max(0, playerPerkLevel)

		if playerAttrLevel >= perk.req then
			if type(perkLevel) == 'number' then
				perkLevel = math.max(perkLevel, 0)
				perkLevel = math.min(perkLevel, perk.max)
			elseif perkLevel == true then
				perkLevel = perk.max
			elseif mergePerks then
				perkLevel = playerPerkLevel
			else
				perkLevel = 0
			end
		else
			perkLevel = 0
		end

		local perkDiff = perkLevel - playerPerkLevel

		if perkDiff ~= 0 then
			if perk.trait then
				adjustTraits[perk.type] = perkDiff
			else
				adjustPerks[perk.type] = perkDiff
			end

			needPerkPoints = needPerkPoints + perkDiff
		end
	end

	local havePerkPoints = self.playerDevData:GetDevPoints('Primary')

	if needPerkPoints > havePerkPoints then
		self.playerDevData:AddDevelopmentPoints(needPerkPoints - havePerkPoints, 'Primary')
	end

	for perkType, perkLevel in pairs(adjustPerks) do
		if perkLevel > 0 then
			for _ = 1, perkLevel do
				self.playerDevData:BuyPerk(perkType)
			end
		else
			for _ = perkLevel, 0 do
				self.playerDevData:RemovePerk(perkType)
			end
		end
	end

	for traitType, traitLevel in pairs(adjustTraits) do
		if traitLevel > 0 then
			for _ = 1, traitLevel do
				self.playerDevData:IncreaseTraitLevel(traitType)
			end
		else
			for _ = traitLevel, 0 do
				self.playerDevData:RemoveTrait(traitType)
			end
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
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

local perkPointExtraMax = 9

---@public
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

---@public
function CharacterModule:release()
	self.playerId = nil
	self.statsSystem = nil
	self.playerDevData = nil

	self.aliases = nil
	self.attributes = nil
	self.skills = nil
	self.perks = nil
end

---@public
function CharacterModule:fillSpec(specData, specOptions)
	if specOptions.character then
		local characterSchema = (mod.load('mod/data/spec-schema'))['children'][1]
		local characterData = self:collectExperience(characterSchema, specOptions)

		specData.Character = characterData
	end
end

---@public
function CharacterModule:applySpec(specData)
	if specData.Character then
		self:compatSpec(specData)

		local levelApplied = false
		local attrsApplied = false
		local skillsApplied = false

		local perkExtraPoints = self:getPerkExtraPoints()

		-- Apply player level
		if specData.Character.Level then
			self:applyLevel(specData.Character.Level)
			levelApplied = true
		end

		-- Apply street cred level
		if specData.Character.StreedCred then
			self:applyStreedCred(specData.Character.StreedCred)
		end

		-- Apply attributes
		if specData.Character.Attributes then
			self:applyAttributes(specData.Character.Attributes)
			attrsApplied = true
		elseif levelApplied then
			self:applyAttributes({}, true) -- Enforce legit attributes levels
			attrsApplied = true
		end

		-- Apply skills
		if specData.Character.Skills then
			self:applySkills(specData.Character.Skills)
			skillsApplied = true
		elseif attrsApplied then
			self:applySkills({}, true) -- Enforce legit skills levels
			skillsApplied = true
		end

		-- Apply skills progression
		if specData.Character.Progression then
			self:applyProgression(specData.Character.Progression)
		end

		-- Determine perk extra points
		if specData.Character.PerkShards then
			perkExtraPoints = math.min(specData.Character.PerkShards, perkPointExtraMax)
		end

		-- Apply perks
		if specData.Character.Perks then
			mod.after(0.25, function()
				self:applyPerks(specData.Character.Perks)
				self:enforePerkPoints(perkExtraPoints)
			end)
		elseif skillsApplied then
			mod.after(0.25, function()
				self:applyPerks({}, true) -- Enforce legit perks
				self:enforePerkPoints(perkExtraPoints)
			end)
		end
	end
end

---@private
function CharacterModule:compatSpec(specData)
	if specData.Character and specData.Character.Points and specData.Character.Points.Perk then
		specData.Character.PerkShards = specData.Character.Points.Perk
	end
end

---@public
function CharacterModule:getLevel()
	return math.tointeger(self:getStatValue('Level'))
end

---@private
function CharacterModule:applyLevel(playerLevel)
	playerLevel = math.max(playerLevelMin, math.min(playerLevelMax, playerLevel))

	local currentLevel = self:getStatValue('Level')

	if playerLevel ~= currentLevel then
		self.playerDevData:SetLevel('Level', playerLevel, 'Gameplay')

		self:enforceAttributePoints()
	end
end

---@private
function CharacterModule:applyStreedCred(streetCred)
	streetCred = math.max(playerLevelMin, math.min(playerLevelMax, streetCred))

	local currentLevel = self:getStatValue('StreetCred')

	if streetCred ~= currentLevel then
		self.playerDevData:SetLevel('StreetCred', streetCred, 'Gameplay')
	end
end

---@public
function CharacterModule:getAttributeLevel(attrAlias)
	return self:getStatValue(attrAlias)
end

---@public
function CharacterModule:getAttributeLevels()
	local attributesSpec = {}

	for _, attribute in pairs(self.attributes) do
		attributesSpec[attribute.alias] = self:getStatValue(attribute.type)
	end

	return attributesSpec
end

---@public
function CharacterModule:getAttributeMaxLevel()
	return attrLevelMax
end

---@public
function CharacterModule:getAttributePoints()
	return math.tointeger(self.playerDevData:GetDevPoints('Attribute'))
end

---@public
function CharacterModule:getAttributeEarnedPoints()
	return self:getLevel() + attrStartMax
end

---@public
function CharacterModule:getAttributePointsUsage()
	local usage = {}

	local playerLevel = self:getLevel()

	-- Attribute points earned from leveling up the character
	usage.levelPoints = playerLevel - playerLevelMin

	-- Attribute points earned from the start of the game
	usage.earnedPoints = playerLevel + attrStartMax

	-- Attribute points spent on perks
	usage.usedPoints = 0

	for _, attr in pairs(self.attributes) do
		usage.usedPoints = usage.usedPoints + self:getAttributeLevel(attr.alias)
	end

	-- Available attribute points
	usage.unusedPoints = (playerLevel + attrBonus - playerLevelMin) - (usage.usedPoints - attrTotalMin)

	-- Available attribute points at the momemnt (might be invalid)
	usage.currentPoints = self:getAttributePoints()

	return usage
end

---@private
function CharacterModule:applyAttributes(attributesSpec, mergeAttrs)
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
		end

		attrExtraLevelMax = math.max(0, attrExtraLevelMax - attrLevel + attrLevelMin)
	end
end

---@private
function CharacterModule:enforceAttributePoints()
	local attrPoints = self:getAttributePointsUsage()

	self.playerDevData:AddDevelopmentPoints(attrPoints.unusedPoints - attrPoints.currentPoints, 'Attribute')
end

---@public
function CharacterModule:getSkillLevel(skillAlias)
	return self:getStatValue(skillAlias)
end

---@private
function CharacterModule:applySkills(skillsSpec, mergeSkills)
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
		end
	end
end

---@public
function CharacterModule:getProgressionLevel(skillAlias)
	return math.floor(self.playerDevData:GetCurrentLevelProficiencyExp(self:getStatType(skillAlias)))
end

---@private
function CharacterModule:applyProgression(progressionSpec)
	for skillAlias, skillExp in pairs(progressionSpec) do
		local skill = self.skills[skillAlias]

		if skill and type(skillExp) == 'number' then
			local playerSkillExp = self:getProgressionLevel(skill.type)

			if skillExp ~= playerSkillExp then
				self.playerDevData:AddExperience((skillExp - playerSkillExp), skill.type, 'Gameplay')
			end
		end
	end
end

---@public
function CharacterModule:getPerkLevel(perkAlias)
	local perk = self.perks[perkAlias]
	local perkLevel

	if perk.trait then
		perkLevel = self.playerDevData:GetTraitLevel(perk.type)
	else
		perkLevel = self.playerDevData:GetPerkLevel(perk.type)
	end

	return math.max(0, math.floor(perkLevel))
end

---@public
function CharacterModule:getPerkPoints()
	return math.tointeger(self.playerDevData:GetDevPoints('Primary'))
end

---@public
function CharacterModule:getPerkExtraPoints(cheatMode)
	return self:getPerkPointsUsage(nil, cheatMode).extraPoints
end

---@public
function CharacterModule:getPerkPointsUsage(extraPoints, cheatMode)
	local usage = {}

	-- Perk points earned from leveling up the character
	usage.levelPoints = self:getLevel() - 1

	-- Perk points earned from leveling up the skills
	usage.skillPoints = 0

	for _, skill in pairs(self.skills) do
		local skillLevel = self:getSkillLevel(skill.type)

		usage.skillPoints = usage.skillPoints + skill.perkPoints[skillLevel]
	end

	-- All perk points earned from leveling up
	usage.earnedPoints = usage.levelPoints + usage.skillPoints

	-- Perk points spent on perks
	usage.usedPoints = 0

	for perkAlias, _ in pairs(self.perks) do
		usage.usedPoints = usage.usedPoints + self:getPerkLevel(perkAlias)
	end

	-- Available perk points (might be invalid)
	usage.currentPoints = self:getPerkPoints()
	usage.unusedPoints = usage.currentPoints

	-- Extra perk points earned from Perk Shards
	if extraPoints then
		usage.extraPoints = extraPoints
		usage.unusedPoints = usage.earnedPoints + usage.extraPoints - usage.usedPoints
	else
		usage.extraPoints = (usage.usedPoints + usage.unusedPoints) - (usage.levelPoints + usage.skillPoints)
	end

	-- Validate extra points
	if not cheatMode then
		if usage.extraPoints > perkPointExtraMax then
			local excessPoints = perkPointExtraMax - usage.extraPoints

			usage.extraPoints = usage.extraPoints - excessPoints
			usage.unusedPoints = usage.unusedPoints - excessPoints
		end
	end

	return usage
end

---@private
function CharacterModule:applyPerks(perkSpecs, mergePerks)
	if not mergePerks then
		self.playerDevData:RemoveAllPerks()
	end

	local adjustPerks = {}
	local adjustTraits = {}
	local needPerkPoints = 0

	for perkAlias, perk in pairs(self.perks) do
		local perkLevel = perkSpecs[perkAlias]

		if type(perkLevel) ~= 'number' and perkSpecs[perk.skill] then
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

	--local havePerkPoints = self:getPerkPoints()

	--if needPerkPoints > havePerkPoints then
	--	self.playerDevData:AddDevelopmentPoints(needPerkPoints - havePerkPoints, 'Primary')
	--end

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
			self.playerDevData:RemoveTrait(traitType)
		end
	end
end

---@private
function CharacterModule:enforePerkPoints(perkExtraPoints)
	local perkPoints = self:getPerkPointsUsage(perkExtraPoints)

	if perkPoints.unusedPoints ~= perkPoints.currentPoints then
		self.playerDevData:AddDevelopmentPoints((perkPoints.unusedPoints - perkPoints.currentPoints), 'Primary')
	end
end

---@private
function CharacterModule:setPoints(pointsSpec)
	for _, pointAlias in ipairs({ 'Perk' }) do
		if pointsSpec[pointAlias] then
			local pointType = self:getStatType(pointAlias)
			local requestedPoints = pointsSpec[pointAlias]
			local playerPoints = math.floor(self.playerDevData:GetDevPoints(pointType))

			if requestedPoints ~= playerPoints then
				self.playerDevData:AddDevelopmentPoints((requestedPoints - playerPoints), pointType)
			end
		end
	end
end

---@private
function CharacterModule:getStatType(alias)
	return self.aliases[alias] or alias
end

---@public
function CharacterModule:getStatValue(statAlias)
	return math.floor(self.statsSystem:GetStatValue(self.playerId, self:getStatType(statAlias)))
end

---@private
function CharacterModule:collectExperience(parent, specOptions)
	local data = {}
	local count = 0

	for _, node in ipairs(parent.children) do

		if node.children then
			local children = self:collectExperience(node, specOptions)
			if children ~= nil then
				data[node.name] = children
				count = count + 1
			end

		elseif node.name then
			if parent.scope == 'Perks' then
				local perkLevel = self:getPerkLevel(node.name)
				if perkLevel > 0 or specOptions.allPerks then
					data[node.name] = perkLevel
					count = count + 1
				end

			elseif parent.scope == 'Progression' then
				local statLevel = self:getProgressionLevel(node.name)
				if statLevel > 0 then
					data[node.name] = statLevel
					count = count + 1
				end

			elseif node.scope == 'PerkShards' then
				data[node.name] = self:getPerkExtraPoints()
				count = count + 1

			else
				data[node.name] = self:getStatValue(node.name)
				count = count + 1
			end
		end
	end

	if count == 0 then
		return nil
	end

	return data
end

return CharacterModule
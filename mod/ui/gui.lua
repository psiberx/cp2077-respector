local mod = ...
local str = mod.require('mod/utils/str')
local array = mod.require('mod/utils/array')
local RarityFilter = mod.require('mod/enums/RarityFilter')

local gui = {}

local respector

local drawWindow = false
local windowWidth = 340
local windowHeight = 375
local windowPadding = 7.5
local maxInputLen = 256
local openKey = 0x70
local saveKey = 0x71

local rarityFilterList = RarityFilter.all()
local itemFormatList = { 'auto', 'hash' }
local keepSeedList = { 'auto', 'always' }
local textOptions = { ['specsDir'] = 'specs/', ['defaultSpec'] = 'V' }
local specSections = {
	{ option = 'character', label = 'Character', desc = '(attributes / skills / perks)' },
	{ option = 'equipment', label = 'Equipped gear', desc = '(weapons / clothing / quick)' },
	{ option = 'cyberware', label = 'Equipped cyberware' },
	{ option = 'backpack', label = 'Backpack items' },
	{ option = 'components', label = 'Crafting components' },
	{ option = 'recipes', label = 'Crafting recipes' },
	{ option = 'vehicles', label = 'Own vehicles' },
}
local keyCodes = mod.load('mod/data/virtual-key-codes')

local inputData = {
	specNameSave = '',
	specNameLoad = '',

	specOptions = {},

	globalOptions = {},

	rarityFilterIndex = 0,
	rarityFilterList = 'Any rarity\0Iconic only\0Rare or higher\0Rare or higher + Iconic\0Epic or higher\0Epic or higher + Iconic\0Legendary only\0Legendary only + Iconic\0',
	rarityFilterCount = #rarityFilterList,

	itemFormatIndex = 0,
	itemFormatList = 'Use item name\0Use hash + length\0',
	itemFormatCount = #itemFormatList,

	keepSeedIndex = 0,
	keepSeedList = 'Only if necessary\0For all items\0',
	keepSeedCount = #keepSeedList,

	openKeyIndex = 0,
	saveKeyIndex = 0,
	keyCodeList = '',
	keyCodeCount = #keyCodes,
}

function gui.init(_respector)
	respector = _respector

	gui.configureKeys()

	for optionName, optionValue in pairs(mod.config) do
		if textOptions[optionName] then
			if str.isempty(optionValue) then
				optionValue = textOptions[optionName]
			end

			optionValue = str.padnul(optionValue or '', maxInputLen)
		end

		inputData.globalOptions[optionName] = optionValue
	end

	inputData.specNameSave = inputData.globalOptions.defaultSpec
	inputData.specNameLoad = inputData.globalOptions.defaultSpec

	inputData.specOptions = respector:getSpecOptions()
	inputData.specOptions.timestamp = false

	inputData.rarityFilterIndex = array.find(rarityFilterList, inputData.specOptions.rarity) - 1
	inputData.itemFormatIndex = array.find(itemFormatList, inputData.specOptions.itemFormat) - 1
	inputData.keepSeedIndex = array.find(keepSeedList, inputData.specOptions.keepSeed) - 1

	for index, keyCode in ipairs(keyCodes) do
		inputData.keyCodeList = inputData.keyCodeList .. keyCode.desc .. '\0'

		if keyCode.code == openKey then
			inputData.openKeyIndex = index - 1
		end

		if keyCode.code == saveKey then
			inputData.saveKeyIndex = index - 1
		end
	end
end

function gui.configureKeys()
	openKey = mod.config.openGuiKey
	saveKey = mod.config.saveSpecKey
end

function gui.handleConsoleOpen()
	drawWindow = true
end

function gui.handleConsoleClose()
	drawWindow = false
end

function gui.handleUpdate()
	if ImGui.IsKeyPressed(openKey, false) then
		drawWindow = not drawWindow
	end

	if ImGui.IsKeyPressed(saveKey, false) then
		gui.saveSnap()
	end
end

function gui.handleDraw()
	if not drawWindow then
		return
	end

	ImGui.SetNextWindowPos(0, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(windowWidth + (windowPadding * 2), windowHeight)

	ImGui.Begin('Respector', true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)
	ImGui.BeginTabBar('Respector Tabs')

	if ImGui.BeginTabItem('Save Spec') then
		ImGui.Spacing()

		-- Saving: Spec Name
		ImGui.Text('Spec name:')
		ImGui.PushItemWidth(233)
		inputData.specNameSave = ImGui.InputText('##Save Spec Name', inputData.specNameSave, maxInputLen)

		-- Saving: Save Button
		ImGui.SameLine(248)
		if ImGui.Button('Save', 100, 19) then
			gui.saveSpec()
		end

		ImGui.Spacing()

		-- Saving: Timestamp
		inputData.specOptions.timestamp = ImGui.Checkbox('Add timestamp to the name', inputData.specOptions.timestamp)

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Saving: Sections
		ImGui.Text('Include in the spec:')
		ImGui.Spacing()
		for _, section in ipairs(specSections) do
			--ImGui.Spacing()
			inputData.specOptions[section.option] = ImGui.Checkbox(section.label, inputData.specOptions[section.option])

			if section.option == 'backpack' and inputData.specOptions.backpack then
				ImGui.SameLine()
				ImGui.PushItemWidth(190)
				inputData.rarityFilterIndex = ImGui.Combo('##Backpack Filter', inputData.rarityFilterIndex, inputData.rarityFilterList, inputData.rarityFilterCount)
				inputData.specOptions.rarity = rarityFilterList[inputData.rarityFilterIndex + 1]
			elseif section.desc then
				ImGui.SameLine()
				ImGui.TextColored(0.5, 0.5, 0.5, 1, section.desc)
			end
		end

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Saving: Item Format & Keep Seed
		ImGui.Text('Item format:')
		ImGui.SameLine(181)
		ImGui.Text('Keep seed:')
		ImGui.PushItemWidth(167)
		inputData.itemFormatIndex = ImGui.Combo('##Item Format', inputData.itemFormatIndex, inputData.itemFormatList, inputData.itemFormatCount)
		inputData.specOptions.itemFormat = itemFormatList[inputData.itemFormatIndex + 1]
		ImGui.SameLine(181)
		ImGui.PushItemWidth(167)
		inputData.keepSeedIndex = ImGui.Combo('##Keep Seed', inputData.keepSeedIndex, inputData.keepSeedList, inputData.keepSeedCount)
		inputData.specOptions.keepSeed = keepSeedList[inputData.keepSeedIndex + 1]

		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem('Load Spec') then
		ImGui.Spacing()

		-- Loading: Spec Name
		ImGui.Text('Spec name:')
		ImGui.PushItemWidth(233)
		inputData.specNameLoad = ImGui.InputText('##Load Spec Name', inputData.specNameLoad, maxInputLen)

		-- Loading: Load Button
		ImGui.SameLine(248)
		if ImGui.Button('Load', 100, 19) then
			gui.loadSpec()
		end

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Loading: Recent Specs
		ImGui.Text('Recently saved / loaded specs:')
		ImGui.PushItemWidth(340)
		local lastSpecIndex = ImGui.ListBox('##Load Recent Specs', -1, respector.recentSpecsInfo, #respector.recentSpecsInfo, 14)
		if lastSpecIndex >= 0 then
			inputData.specNameLoad = str.padnul(respector.recentSpecs[lastSpecIndex + 1], maxInputLen)
			lastSpecIndex = -1
		end

		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem('Options') then
		ImGui.Spacing()

		-- Options: Specs Dir
		ImGui.Text('Specs location:')
		ImGui.PushItemWidth(340)
		inputData.globalOptions.specsDir = ImGui.InputText('##Specs Location', inputData.globalOptions.specsDir, maxInputLen)

		ImGui.Spacing()

		-- Options: Default Spec
		ImGui.Text('Default spec name:')
		ImGui.PushItemWidth(340)
		inputData.globalOptions.defaultSpec = ImGui.InputText('##Default Spec', inputData.globalOptions.defaultSpec, maxInputLen)

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Saving: Open GUI Key
		ImGui.Text('Hotkey to open / close the GUI:')
		ImGui.PushItemWidth(170)
		inputData.openKeyIndex = ImGui.Combo('##Open GUI Key', inputData.openKeyIndex, inputData.keyCodeList, inputData.keyCodeCount)
		inputData.globalOptions.openGuiKey = keyCodes[inputData.openKeyIndex + 1].code

		ImGui.Spacing()

		-- Saving: Save Spec Key
		ImGui.Text('Hotkey to save spec with current options:')
		ImGui.PushItemWidth(170)
		inputData.saveKeyIndex = ImGui.Combo('##Save Spec Key', inputData.saveKeyIndex, inputData.keyCodeList, inputData.keyCodeCount)
		inputData.globalOptions.saveSpecKey = keyCodes[inputData.saveKeyIndex + 1].code

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Options: Saving Tip
		ImGui.TextColored(0.5, 0.5, 0.5, 1, 'The changes will take effect after saving.')

		ImGui.Spacing()

		-- Options: Save Button
		if ImGui.Button('Save options', 168, 19) then
			gui.saveConfig()
		end

		-- Options: Reset Button
		ImGui.SameLine(181)
		if ImGui.Button('Reset to defaults', 168, 19) then
			gui.resetConfig()
		end

		ImGui.EndTabItem()
	end

	if mod.dev then
		if ImGui.BeginTabItem('Developer') then
			ImGui.Spacing()

			if ImGui.Button('Rehash TweakDB names', 190, 19) then
				gui.rehashTweakDb()
			end

			ImGui.Spacing()

			if ImGui.Button('Compile sample packs', 190, 19) then
				gui.compileSamples()
			end

			ImGui.Spacing()

			if ImGui.Button('Write default config', 190, 19) then
				gui.writeDefaultConfig()
			end

			ImGui.Spacing()

			if ImGui.Button('Write default spec', 190, 19) then
				gui.writeDefaultSpec()
			end

			ImGui.EndTabItem()
		end
	end

	ImGui.EndTabBar()
	ImGui.End()
end

function gui.saveSpec()
	respector:saveSpec(str.stripnul(inputData.specNameSave), inputData.specOptions)
end

function gui.saveSnap()
	local timestamp = inputData.specOptions.timestamp
	inputData.specOptions.timestamp = true

	respector:saveSpec(str.stripnul(inputData.specNameSave), inputData.specOptions)

	inputData.specOptions.timestamp = timestamp
end

function gui.loadSpec()
	respector:loadSpec(str.stripnul(inputData.specNameLoad))
end

function gui.saveConfig()
	for optionName, optionValue in pairs(inputData.globalOptions) do
		if textOptions[optionName] then
			optionValue = str.stripnul(optionValue)

			if str.isempty(optionValue) then
				optionValue = textOptions[optionName]
			end
		end

		mod.config[optionName] = optionValue
	end

	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:writeConfig()

	respector:loadComponents()

	gui.configureKeys()

	print(('Respector: Configuration saved.'))
end

function gui.resetConfig()
	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:resetConfig({ useGui = true })

	mod.loadConfig()

	respector:loadComponents()

	gui.init(respector)

	print(('Respector: Configuration has been reset to defaults.'))
end

function gui.rehashTweakDb()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:rehashTweakDbNames()
end

function gui.compileSamples()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:compileSamplePacks()
end

function gui.writeDefaultConfig()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:writeDefaultConfig()
end

function gui.writeDefaultSpec()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:writeDefaultSpec()
end

return gui
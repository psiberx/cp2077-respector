local mod = ...
local str = mod.require('mod/utils/str')
local array = mod.require('mod/utils/array')
local RarityFilter = mod.require('mod/enums/RarityFilter')
local PersistentState = mod.require('mod/helpers/PersistentState')

local gui = {}

local respector

local drawWindow = false
local windowWidth = 340
local windowHeight = 375
local windowPadding = 7.5
local maxInputLen = 256
local maxHistoryLen = 50
local openKey = 0x70
local saveKey = 0x71

local textOptions = {
	specsDir = 'specs/',
	defaultSpec = 'V'
}

local specSections = {
	{ option = 'character', label = 'Character', desc = '(attributes / skills / perks)' },
	{ option = 'equipment', label = 'Equipped gear', desc = '(weapons / clothing / quick)' },
	{ option = 'cyberware', label = 'Equipped cyberware' },
	{ option = 'backpack', label = 'Backpack items' },
	{ option = 'components', label = 'Crafting components' },
	{ option = 'recipes', label = 'Crafting recipes' },
	{ option = 'vehicles', label = 'Own vehicles' },
}

local rarityFilterList = RarityFilter.all()
local itemFormatList = { 'auto', 'hash' }
local keepSeedList = { 'auto', 'always' }
local keyCodes = mod.load('mod/data/virtual-key-codes')

local inputData = {
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
	keyCodeList = table.concat(array.map(keyCodes, 'desc'), '\0') .. '\0',
	keyCodeCount = #keyCodes,

	specHistory = {},
	specHistoryList = {},
}

local inputState = {}

local persitentState

function gui.init(_respector)
	respector = _respector

	gui.initHotkeys()
	gui.initHandlers()
	gui.initPersistance()
	gui.initState()
end

function gui.initHotkeys()
	openKey = mod.config.openGuiKey
	saveKey = mod.config.saveSpecKey
end

function gui.initHandlers()
	respector:addEventHandler(gui.onRespectorEvent)
end

function gui.initPersistance()
	persitentState = PersistentState:new(mod.path('specs/.state.lua'))

	if persitentState:isEmpty() then
		persitentState:setState({
			input = inputState,
			history = inputData.specHistory,
		})
	else
		inputState = persitentState:getState('input')
		inputData.specHistory = persitentState:getState('history')
	end
end

function gui.initState()
	-- Init default state
	if not inputState.specNameSave then
		inputState.globalOptions = {}

		for optionName, optionValue in pairs(mod.config) do
			if type(optionValue) ~= 'table' then
				if textOptions[optionName] then
					if str.isempty(optionValue) then
						optionValue = textOptions[optionName]
					end

					optionValue = str.padnul(optionValue or '', maxInputLen)
				end

				inputState.globalOptions[optionName] = optionValue
			end
		end

		inputState.specNameSave = inputState.globalOptions.defaultSpec
		inputState.specNameLoad = inputState.globalOptions.defaultSpec

		inputState.specOptions = respector:getSpecOptions()
		inputState.specOptions.timestamp = false
	end

	inputData.rarityFilterIndex = array.find(rarityFilterList, inputState.specOptions.rarity) - 1
	inputData.itemFormatIndex = array.find(itemFormatList, inputState.specOptions.itemFormat) - 1
	inputData.keepSeedIndex = array.find(keepSeedList, inputState.specOptions.keepSeed) - 1

	for index, keyCode in ipairs(keyCodes) do
		if keyCode.code == openKey then
			inputData.openKeyIndex = index - 1
		end

		if keyCode.code == saveKey then
			inputData.saveKeyIndex = index - 1
		end
	end
	
	inputData.specHistoryList = array.map(inputData.specHistory, gui.formatHistoryEntry)
end

function gui.formatHistoryEntry(entryData)
	return entryData.time .. ' ' .. (entryData.event == 'load' and '>' or '<') .. ' ' .. entryData.specName
end

function gui.onRespectorEvent(eventData)
	for entryIndex, entryData in ipairs(inputData.specHistory) do
		if entryData.specName == eventData.specName then
			table.remove(inputData.specHistory, entryIndex)
			table.remove(inputData.specHistoryList, entryIndex)
			break
		end
	end

	table.insert(inputData.specHistory, 1, eventData)
	table.insert(inputData.specHistoryList, 1, gui.formatHistoryEntry(eventData))

	if #inputData.specHistory > maxHistoryLen then
		table.remove(inputData.specHistory)
		table.remove(inputData.specHistoryList)
	end

	persitentState:flush()
end

function gui.onConsoleOpenEvent()
	drawWindow = true
end

function gui.onConsoleCloseEvent()
	drawWindow = false
end

function gui.onUpdateEvent()
	if ImGui.IsKeyPressed(openKey, false) then
		drawWindow = not drawWindow
	end

	if ImGui.IsKeyPressed(saveKey, false) then
		gui.onSaveSnapHotkey()
	end
end

function gui.onDrawEvent()
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
		inputState.specNameSave = ImGui.InputText('##Save Spec Name', inputState.specNameSave, maxInputLen)

		-- Saving: Save Button
		ImGui.SameLine(248)
		if ImGui.Button('Save', 100, 19) then
			gui.onSaveSpecClick()
		end

		ImGui.Spacing()

		-- Saving: Timestamp
		inputState.specOptions.timestamp = ImGui.Checkbox('Add timestamp to the name', inputState.specOptions.timestamp)

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Saving: Sections
		ImGui.Text('Include in the spec:')
		ImGui.Spacing()
		for _, section in ipairs(specSections) do
			--ImGui.Spacing()
			inputState.specOptions[section.option] = ImGui.Checkbox(section.label, inputState.specOptions[section.option])

			if section.option == 'backpack' and inputState.specOptions.backpack then
				ImGui.SameLine()
				ImGui.PushItemWidth(190)
				inputData.rarityFilterIndex = ImGui.Combo('##Backpack Filter', inputData.rarityFilterIndex, inputData.rarityFilterList, inputData.rarityFilterCount)
				inputState.specOptions.rarity = rarityFilterList[inputData.rarityFilterIndex + 1]
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
		inputState.specOptions.itemFormat = itemFormatList[inputData.itemFormatIndex + 1]
		ImGui.SameLine(181)
		ImGui.PushItemWidth(167)
		inputData.keepSeedIndex = ImGui.Combo('##Keep Seed', inputData.keepSeedIndex, inputData.keepSeedList, inputData.keepSeedCount)
		inputState.specOptions.keepSeed = keepSeedList[inputData.keepSeedIndex + 1]

		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem('Load Spec') then
		ImGui.Spacing()

		-- Loading: Spec Name
		ImGui.Text('Spec name:')
		ImGui.PushItemWidth(233)
		inputState.specNameLoad = ImGui.InputText('##Load Spec Name', inputState.specNameLoad, maxInputLen)

		-- Loading: Load Button
		ImGui.SameLine(248)
		if ImGui.Button('Load', 100, 19) then
			gui.onLoadSpecClick()
		end

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Loading: Recent Specs
		ImGui.Text('Recently saved / loaded specs:')
		ImGui.PushItemWidth(340)
		local lastSpecIndex = ImGui.ListBox('##Load Recent Specs', -1, inputData.specHistoryList, #inputData.specHistoryList, 14)
		if lastSpecIndex >= 0 then
			inputState.specNameLoad = str.padnul(inputData.specHistory[lastSpecIndex + 1].specName, maxInputLen)
			lastSpecIndex = -1
		end

		ImGui.EndTabItem()
	end

	if ImGui.BeginTabItem('Options') then
		ImGui.Spacing()

		-- Options: Specs Dir
		ImGui.Text('Specs location:')
		ImGui.PushItemWidth(340)
		inputState.globalOptions.specsDir = ImGui.InputText('##Specs Location', inputState.globalOptions.specsDir, maxInputLen)

		ImGui.Spacing()

		-- Options: Default Spec
		ImGui.Text('Default spec name:')
		ImGui.PushItemWidth(340)
		inputState.globalOptions.defaultSpec = ImGui.InputText('##Default Spec', inputState.globalOptions.defaultSpec, maxInputLen)

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Saving: Open GUI Key
		ImGui.Text('Hotkey to open / close the GUI:')
		ImGui.PushItemWidth(170)
		inputData.openKeyIndex = ImGui.Combo('##Open GUI Key', inputData.openKeyIndex, inputData.keyCodeList, inputData.keyCodeCount)
		inputState.globalOptions.openGuiKey = keyCodes[inputData.openKeyIndex + 1].code

		ImGui.Spacing()

		-- Saving: Save Spec Key
		ImGui.Text('Hotkey to save spec with current options:')
		ImGui.PushItemWidth(170)
		inputData.saveKeyIndex = ImGui.Combo('##Save Spec Key', inputData.saveKeyIndex, inputData.keyCodeList, inputData.keyCodeCount)
		inputState.globalOptions.saveSpecKey = keyCodes[inputData.saveKeyIndex + 1].code

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Options: Saving Tip
		ImGui.TextColored(0.5, 0.5, 0.5, 1, 'The changes will take effect after saving.')

		ImGui.Spacing()

		-- Options: Save Button
		if ImGui.Button('Save options', 168, 19) then
			gui.onSaveConfigClick()
		end

		-- Options: Reset Button
		ImGui.SameLine(181)
		if ImGui.Button('Reset to defaults', 168, 19) then
			gui.onResetConfigClick()
		end

		ImGui.EndTabItem()
	end

	if mod.dev then
		if ImGui.BeginTabItem('Developer') then
			ImGui.Spacing()

			if ImGui.Button('Rehash TweakDB names', 190, 19) then
				gui.onRehashTweakDbClick()
			end

			ImGui.Spacing()

			if ImGui.Button('Compile sample packs', 190, 19) then
				gui.onCompileSamplesClick()
			end

			ImGui.Spacing()

			if ImGui.Button('Write default config', 190, 19) then
				gui.onWriteDefaultConfigClick()
			end

			ImGui.Spacing()

			if ImGui.Button('Write default spec', 190, 19) then
				gui.onWriteDefaultSpecClick()
			end

			ImGui.EndTabItem()
		end
	end

	ImGui.EndTabBar()
	ImGui.End()
end

function gui.onSaveSpecClick()
	respector:saveSpec(str.stripnul(inputState.specNameSave), inputState.specOptions)

	persitentState:flush()
end

function gui.onLoadSpecClick()
	respector:loadSpec(str.stripnul(inputState.specNameLoad))

	persitentState:flush()
end

function gui.onSaveSnapHotkey()
	local timestamp = inputState.specOptions.timestamp
	inputState.specOptions.timestamp = true

	respector:saveSpec(str.stripnul(inputState.specNameSave), inputState.specOptions)

	inputState.specOptions.timestamp = timestamp

	persitentState:flush()
end

function gui.onSaveConfigClick()
	for optionName, optionValue in pairs(inputState.globalOptions) do
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

	gui.initHotkeys()

	print(('Respector: Configuration saved.'))
end

function gui.onResetConfigClick()
	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:resetConfig({ useGui = true })

	mod.loadConfig()

	respector:loadComponents()

	gui.initHotkeys()
	gui.initState()

	print(('Respector: Configuration has been reset to defaults.'))
end

function gui.onRehashTweakDbClick()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:rehashTweakDbNames()
end

function gui.onCompileSamplesClick()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:compileSamplePacks()
end

function gui.onWriteDefaultConfigClick()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:writeDefaultConfig()
end

function gui.onWriteDefaultSpecClick()
	local Compiler = mod.require('mod/Compiler')
	local compiler = Compiler:new()

	compiler:writeDefaultSpec()
end

return gui
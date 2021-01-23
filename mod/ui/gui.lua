local mod = ...
local str = mod.require('mod/utils/str')
local array = mod.require('mod/utils/array')
local RarityFilter = mod.require('mod/enums/RarityFilter')
local PersistentState = mod.require('mod/helpers/PersistentState')
local tweaker = mod.require('mod/ui/gui-tweaker')

local gui = {}

local respector

local windowWidth = 340
local windowHeight = 375
local windowPadding = 7.5
local maxInputLen = 256
local maxHistoryLen = 50
local openKey
local saveKey

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

local textOptions = {
	specsDir = 'specs/',
	defaultSpec = 'V'
}

local keyCodes = mod.load('mod/data/virtual-key-codes')

local viewData = {
	rarityFilterIndex = 0,
	rarityFilterList = RarityFilter.labels(),
	rarityFilterCount = #rarityFilterList,

	itemFormatIndex = 0,
	itemFormatList = 'Hash name\0Hash + length\0',
	itemFormatCount = #itemFormatList,

	keepSeedIndex = 0,
	keepSeedList = 'Only if necessary\0For all items\0',
	keepSeedCount = #keepSeedList,

	openKeyIndex = 0,
	tweakerKeyIndex = 0,
	saveKeyIndex = 0,
	keyCodeList = table.concat(array.map(keyCodes, 'desc'), '\0') .. '\0',
	keyCodeCount = #keyCodes,

	specHistoryList = {},
}

local userState = {
	showWindow = false,
	expandWindow = true,

	specNameSave = nil,
	specOptions = nil,

	specNameLoad = nil,
	specHistory = {},

	globalOptions = nil,
}

local persitentState

function gui.init(_respector)
	respector = _respector

	gui.initHotkeys()
	gui.initHandlers()
	gui.initPersistance()
	gui.initState()

	-- Detect the console state
	if mod.start then
		userState.showWindow = false
	end

	tweaker.init(respector, userState, persitentState)
end

function gui.initHotkeys()
	openKey = mod.config.openGuiKey or 0x70
	saveKey = mod.config.saveSpecKey or 0x71
end

function gui.initHandlers()
	respector:addEventHandler(gui.onRespectorEvent)
end

function gui.initPersistance()
	persitentState = PersistentState:new(mod.path('specs/.state.lua'))

	if persitentState:isEmpty() then
		persitentState:setState({
			version = respector.version,
			input = userState,
		})
	else
		userState = persitentState:getState('input')
	end
end

function gui.initState(force)
	-- Init default state
	if not userState.globalOptions or force then
		userState.globalOptions = {}

		for optionName, optionValue in pairs(mod.config) do
			if type(optionValue) ~= 'table' then
				if textOptions[optionName] then
					if str.isempty(optionValue) then
						optionValue = textOptions[optionName]
					end

					optionValue = str.padnul(optionValue or '', maxInputLen)
				end

				userState.globalOptions[optionName] = optionValue
			end
		end
	end

	-- Init default state ignoring reset
	if not userState.specOptions then
		userState.specNameSave = userState.globalOptions.defaultSpec
		userState.specNameLoad = userState.globalOptions.defaultSpec

		userState.specOptions = respector:getSpecOptions()
		userState.specOptions.timestamp = false
	end

	viewData.rarityFilterIndex = array.find(rarityFilterList, userState.specOptions.rarity) - 1
	viewData.itemFormatIndex = array.find(itemFormatList, userState.specOptions.itemFormat) - 1
	viewData.keepSeedIndex = array.find(keepSeedList, userState.specOptions.keepSeed) - 1

	for index, keyCode in ipairs(keyCodes) do
		if keyCode.code == openKey then
			viewData.openKeyIndex = index - 1
		end

		if keyCode.code == userState.globalOptions.openTweakerKey then
			viewData.tweakerKeyIndex = index - 1
		end

		if keyCode.code == saveKey then
			viewData.saveKeyIndex = index - 1
		end
	end
	
	viewData.specHistoryList = array.map(userState.specHistory, gui.formatHistoryEntry)
end

function gui.formatHistoryEntry(entryData)
	return entryData.time .. ' ' .. (entryData.event == 'load' and '>' or '<') .. ' ' .. entryData.specName
end

function gui.onRespectorEvent(eventData)
	for entryIndex, entryData in ipairs(userState.specHistory) do
		if entryData.specName == eventData.specName then
			table.remove(userState.specHistory, entryIndex)
			table.remove(viewData.specHistoryList, entryIndex)
			break
		end
	end

	table.insert(userState.specHistory, 1, eventData)
	table.insert(viewData.specHistoryList, 1, gui.formatHistoryEntry(eventData))

	if #userState.specHistory > maxHistoryLen then
		table.remove(userState.specHistory)
		table.remove(viewData.specHistoryList)
	end

	persitentState:flush()
end

function gui.onConsoleOpenEvent()
	userState.showWindow = true

	persitentState:flush()
end

function gui.onConsoleCloseEvent()
	userState.showWindow = false

	persitentState:flush()
end

function gui.onUpdateEvent()
	if ImGui.IsKeyPressed(openKey, false) then
		userState.showWindow = not userState.showWindow
	end

	if ImGui.IsKeyPressed(saveKey, false) then
		gui.onSaveSnapHotkey()
	end

	tweaker.onUpdateEvent()
end

function gui.onDrawEvent()
	if not userState.showWindow then
		return
	end

	ImGui.SetNextWindowPos(0, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(windowWidth + (windowPadding * 2), windowHeight)

	userState.showWindow, userState.expandWindow = ImGui.Begin('Respector', true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)

	if userState.showWindow and userState.expandWindow then
		-- Quick Tweaks Button
		ImGui.SetCursorPos(windowWidth - 100 + windowPadding, 28)
		local clipX, clipY = ImGui.GetItemRectMin()
		ImGui.PushClipRect(clipX, clipY, clipX + 400, clipY + 28 + 17, false)
		ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, 4) -- Tab: ImGui.GetFontSize() * 0.35
		ImGui.PushStyleColor(ImGuiCol.Button, userState.showTweaker and 0xFF51A600 or 0xFF518900)
		ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xFF67BC16)
		if ImGui.Button('Quick Tweaks', 100, 19) then
			tweaker.onQuickButtonClick()
		end
		ImGui.PopStyleColor(2)
		ImGui.PopStyleVar()
		ImGui.PopClipRect()
		ImGui.SetCursorPos(8, 27)

		ImGui.BeginTabBar('Respector Tabs')

		if ImGui.BeginTabItem('Save Spec') then
			ImGui.Spacing()

			-- Saving: Spec Name
			ImGui.Text('Spec name:')
			ImGui.SetNextItemWidth(233)
			userState.specNameSave = ImGui.InputText('##Save Spec Name', userState.specNameSave, maxInputLen)

			-- Saving: Save Button
			ImGui.SameLine(248)
			if ImGui.Button('Save', 100, 19) then
				gui.onSaveSpecClick()
			end

			ImGui.Spacing()

			-- Saving: Timestamp
			userState.specOptions.timestamp = ImGui.Checkbox('Add timestamp to the name', userState.specOptions.timestamp)

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			-- Saving: Sections
			ImGui.Text('Include in the spec:')
			ImGui.Spacing()
			for _, section in ipairs(specSections) do
				--ImGui.Spacing()
				userState.specOptions[section.option] = ImGui.Checkbox(section.label, userState.specOptions[section.option])

				if section.option == 'backpack' and userState.specOptions.backpack then
					ImGui.SameLine()
					ImGui.SetNextItemWidth(205)
					viewData.rarityFilterIndex = ImGui.Combo('##Backpack Filter', viewData.rarityFilterIndex, viewData.rarityFilterList, viewData.rarityFilterCount)
					userState.specOptions.rarity = rarityFilterList[viewData.rarityFilterIndex + 1]
				elseif section.desc then
					ImGui.SameLine()
					ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
					ImGui.Text(section.desc)
					ImGui.PopStyleColor()
				end
			end

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			-- Saving: Item Format & Keep Seed
			ImGui.Text('Item format:')
			ImGui.SameLine(181)
			ImGui.Text('Keep seed:')
			ImGui.SetNextItemWidth(167)
			viewData.itemFormatIndex = ImGui.Combo('##Item Format', viewData.itemFormatIndex, viewData.itemFormatList, viewData.itemFormatCount)
			userState.specOptions.itemFormat = itemFormatList[viewData.itemFormatIndex + 1]
			ImGui.SameLine(181)
			ImGui.SetNextItemWidth(167)
			viewData.keepSeedIndex = ImGui.Combo('##Keep Seed', viewData.keepSeedIndex, viewData.keepSeedList, viewData.keepSeedCount)
			userState.specOptions.keepSeed = keepSeedList[viewData.keepSeedIndex + 1]

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem('Load Spec') then
			ImGui.Spacing()

			-- Loading: Spec Name
			ImGui.Text('Spec name:')
			ImGui.SetNextItemWidth(233)
			userState.specNameLoad = ImGui.InputText('##Load Spec Name', userState.specNameLoad, maxInputLen)

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
			ImGui.SetNextItemWidth(340)
			ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
			ImGui.PushStyleColor(ImGuiCol.Border, 0xff483f3f)
			ImGui.PushStyleColor(ImGuiCol.FrameBg, 0) -- 0.16, 0.29, 0.48, 0.1
			local lastSpecIndex = ImGui.ListBox('##Load Recent Specs', -1, viewData.specHistoryList, #viewData.specHistoryList, 14)
			ImGui.PopStyleColor(2)
			ImGui.PopStyleVar()
			if lastSpecIndex >= 0 then
				userState.specNameLoad = str.padnul(userState.specHistory[lastSpecIndex + 1].specName, maxInputLen)
				lastSpecIndex = -1
			end

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem('Options') then
			ImGui.Spacing()

			-- Options: Specs Dir
			ImGui.Text('Specs location:')
			ImGui.SetNextItemWidth(340)
			userState.globalOptions.specsDir = ImGui.InputText('##Specs Location', userState.globalOptions.specsDir, maxInputLen)

			ImGui.Spacing()

			-- Options: Default Spec
			ImGui.Text('Default spec name:')
			ImGui.SetNextItemWidth(340)
			userState.globalOptions.defaultSpec = ImGui.InputText('##Default Spec', userState.globalOptions.defaultSpec, maxInputLen)

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			-- Saving: Open Respector Key
			ImGui.Text('Hotkey to open / close Respector:')
			ImGui.SetNextItemWidth(120)
			viewData.openKeyIndex = ImGui.Combo('##OpenRespectorKey', viewData.openKeyIndex, viewData.keyCodeList, viewData.keyCodeCount)
			userState.globalOptions.openGuiKey = keyCodes[viewData.openKeyIndex + 1].code

			ImGui.Spacing()

			-- Saving: Open Tweaker Key
			ImGui.Text('Hotkey to open / close Quick Tweaks:')
			ImGui.SetNextItemWidth(120)
			viewData.tweakerKeyIndex = ImGui.Combo('##OpenTweakerKey', viewData.tweakerKeyIndex, viewData.keyCodeList, viewData.keyCodeCount)
			userState.globalOptions.openTweakerKey = keyCodes[viewData.tweakerKeyIndex + 1].code

			ImGui.Spacing()

			-- Saving: Save Spec Key
			ImGui.Text('Hotkey to save spec with current settings:')
			ImGui.SetNextItemWidth(120)
			viewData.saveKeyIndex = ImGui.Combo('##SaveSpecKey', viewData.saveKeyIndex, viewData.keyCodeList, viewData.keyCodeCount)
			userState.globalOptions.saveSpecKey = keyCodes[viewData.saveKeyIndex + 1].code

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

		--if mod.dev then
		--	if ImGui.BeginTabItem('Developer') then
		--		ImGui.Spacing()
		--
		--		if ImGui.Button('Rehash TweakDB names', 190, 19) then
		--			gui.onRehashTweakDbClick()
		--		end
		--
		--		ImGui.Spacing()
		--
		--		if ImGui.Button('Compile sample packs', 190, 19) then
		--			gui.onCompileSamplesClick()
		--		end
		--
		--		ImGui.Spacing()
		--
		--		if ImGui.Button('Write default config', 190, 19) then
		--			gui.onWriteDefaultConfigClick()
		--		end
		--
		--		ImGui.Spacing()
		--
		--		if ImGui.Button('Write default spec', 190, 19) then
		--			gui.onWriteDefaultSpecClick()
		--		end
		--
		--		ImGui.EndTabItem()
		--	end
		--end

		ImGui.EndTabBar()
	end

	ImGui.End()

	tweaker.onDrawEvent()
end

function gui.onSaveSpecClick()
	respector:saveSpec(str.stripnul(userState.specNameSave), userState.specOptions)

	persitentState:flush()
end

function gui.onLoadSpecClick()
	respector:loadSpec(str.stripnul(userState.specNameLoad))

	persitentState:flush()
end

function gui.onSaveSnapHotkey()
	local timestamp = userState.specOptions.timestamp
	userState.specOptions.timestamp = true

	respector:saveSpec(str.stripnul(userState.specNameSave), userState.specOptions)

	userState.specOptions.timestamp = timestamp

	persitentState:flush()
end

function gui.onSaveConfigClick()
	for optionName, optionValue in pairs(userState.globalOptions) do
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

	tweaker.initHotkeys()

	print(('Respector: Configuration saved.'))
end

function gui.onResetConfigClick()
	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:resetConfig({ useGui = true })

	mod.loadConfig()

	respector:loadComponents()

	gui.initHotkeys()
	gui.initState(true)

	tweaker.initHotkeys()
	tweaker.initState(true)

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
local mod = ...
local str = mod.require('mod/utils/str')
local array = mod.require('mod/utils/array')
local RarityFilter = mod.require('mod/enums/RarityFilter')
local PersistentState = mod.require('mod/helpers/PersistentState')
local tweaksGui = mod.require('mod/ui/gui.tweaks')

local gui = {}

local respector

local rarityFilters = RarityFilter.all()
local itemFormatOptions = { 'auto', 'hash' }
local keepSeedOptions = { 'auto', 'always' }

local viewData = {
	maxInputLen = 256,

	specSections = {
		{ option = 'character', label = 'Character', desc = { 'Attributes', 'Skills', 'Perks' } },
		{ option = 'equipment', label = 'Equipped gear', desc = { 'Weapons', 'Clothing', 'Quick use' } },
		{ option = 'cyberware', label = 'Equipped cyberware' },
		{ option = 'backpack', label = 'Backpack items' },
		{ option = 'components', label = 'Crafting components' },
		{ option = 'recipes', label = 'Crafting recipes' },
		{ option = 'vehicles', label = 'Own vehicles' },
	},

	rarityFilterIndex = 0,
	rarityFilterList = RarityFilter.labels(),
	rarityFilterCount = #rarityFilters,

	itemFormatIndex = 0,
	itemFormatList = { 'Hash name', 'Hash + length' },
	itemFormatCount = #itemFormatOptions,

	keepSeedIndex = 0,
	keepSeedList = { 'Only if necessary', 'For all item' },
	keepSeedCount = #keepSeedOptions,

	specHistoryList = {},
	specHistoryMaxLen = 50,

	defaultOptions = {
		specsDir = 'specs/',
		defaultSpec = 'V'
	},
}

local userState = {
	showWindow = true,
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

	gui.initHandlers()
	gui.initPersistance()
	gui.initUserState()
	gui.initViewData()

	-- Detect the console state
	if mod.start then
		userState.showWindow = false
	end

	tweaksGui.init(respector, userState, persitentState)
end

function gui.initHandlers()
	respector:addEventHandler(gui.onRespectorEvent)
end

function gui.initPersistance()
	persitentState = PersistentState:new(mod.path('specs/.state'))

	if persitentState:isEmpty() then
		persitentState:setState({
			version = respector.version,
			input = userState,
		})
	else
		userState = persitentState:getState('input')
	end
end

function gui.initUserState(force)
	-- Init default state
	if not userState.globalOptions or force then
		userState.globalOptions = {}

		for optionName, optionValue in pairs(mod.config) do
			if type(optionValue) ~= 'table' then
				if textOptions[optionName] then
					if str.isempty(optionValue) then
						optionValue = textOptions[optionName]
					end
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
end

function gui.initViewData()
	viewData.fontSize = ImGui.GetFontSize()
	viewData.viewScale = viewData.fontSize / 13

	viewData.windowWidth = 340 * viewData.viewScale
	viewData.windowHeight = 373 * viewData.viewScale
	viewData.windowPadding = 7.5
	viewData.windowOffsetX = 8
	viewData.windowOffsetY = math.ceil(viewData.fontSize * 1.3846) + 9

	viewData.gridGutter = 6
	viewData.gridFullWidth = viewData.windowWidth
	viewData.gridHalfWidth = (viewData.gridFullWidth - viewData.gridGutter) / 2
	viewData.gridOneThirdWidth = math.floor((viewData.gridFullWidth - viewData.gridGutter * 2) / 3 + 0.5)
	viewData.gridTwoThirdsWidth = math.floor((viewData.gridFullWidth - viewData.gridGutter * 2) / 3 * 2 + 0.5)

	viewData.tabRounding = math.floor(viewData.fontSize * 0.35)
	viewData.tweaksButtonWidth = 100 * viewData.viewScale
	viewData.tweaksButtonHeight = 19 * viewData.viewScale
	viewData.defaultInputHeight = 19 * viewData.viewScale

	viewData.rarityFilterIndex = array.find(rarityFilters, userState.specOptions.rarity) - 1
	viewData.itemFormatIndex = array.find(itemFormatOptions, userState.specOptions.itemFormat) - 1
	viewData.keepSeedIndex = array.find(keepSeedOptions, userState.specOptions.keepSeed) - 1

	viewData.specHistoryList = array.map(userState.specHistory, gui.formatHistoryEntry)
end

function gui.onOverlayOpen()
	userState.showWindow = true
end

function gui.onOverlayClose()
	userState.showWindow = false
end

function gui.onDrawEvent()
	if not userState.showWindow then
		return
	end

	ImGui.SetNextWindowPos(0, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(viewData.windowWidth + (viewData.windowPadding * 2), viewData.windowHeight)

	userState.showWindow, userState.expandWindow = ImGui.Begin('Respector', true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)

	if userState.showWindow and userState.expandWindow then
		-- Quick Tweaks Button

		ImGui.SetCursorPos(viewData.windowOffsetX + viewData.windowWidth - viewData.tweaksButtonWidth , viewData.windowOffsetY + 1)

		local windowX, windowY = ImGui.GetItemRectMin()

		ImGui.PushClipRect(windowX, windowY, windowX + viewData.windowOffsetX + viewData.windowWidth, windowY + viewData.windowOffsetY + viewData.tweaksButtonHeight - 1, false)
		ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, viewData.tabRounding)
		ImGui.PushStyleColor(ImGuiCol.Button, userState.showTweaker and 0xff51a600 or 0xff518900)
		ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0xff67bc16)

		if ImGui.Button('Quick Tweaks', viewData.tweaksButtonWidth, viewData.tweaksButtonHeight) then
			tweaksGui.onToggleTweaker()
		end

		ImGui.PopStyleColor(2)
		ImGui.PopStyleVar()
		ImGui.PopClipRect()

		ImGui.SetCursorPos(viewData.windowOffsetX, viewData.windowOffsetY)

		-- Main Tabs

		ImGui.BeginTabBar('Respector Tabs')

		if ImGui.BeginTabItem('Save Spec') then
			ImGui.Spacing()

			-- Saving: Spec Name
			ImGui.Text('Spec name:')
			ImGui.SetNextItemWidth(viewData.gridTwoThirdsWidth)
			userState.specNameSave = ImGui.InputText('##Save Spec Name', userState.specNameSave, viewData.maxInputLen)

			-- Saving: Save Button
			ImGui.SameLine(viewData.windowOffsetX + viewData.gridTwoThirdsWidth + viewData.gridGutter)
			if ImGui.Button('Save', viewData.gridOneThirdWidth, viewData.defaultInputHeight) then
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
			for _, section in ipairs(viewData.specSections) do
				--ImGui.Spacing()
				userState.specOptions[section.option] = ImGui.Checkbox(section.label, userState.specOptions[section.option])

				if section.option == 'backpack' and userState.specOptions.backpack then
					ImGui.SameLine()
					ImGui.SetNextItemWidth(viewData.windowOffsetX + viewData.gridFullWidth - ImGui.GetCursorPosX())
					viewData.rarityFilterIndex = ImGui.Combo('##Backpack Filter', viewData.rarityFilterIndex, viewData.rarityFilterList, viewData.rarityFilterCount)
					userState.specOptions.rarity = rarityFilters[viewData.rarityFilterIndex + 1]
				elseif section.desc then
					ImGui.SameLine()
					ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
					ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 3, 5)
					if type(section.desc) == 'table' then
						for i, item in ipairs(section.desc) do
							if i > 1 then
								ImGui.SameLine()
								ImGui.Text('/')
								ImGui.SameLine()
							else
								ImGui.SameLine(ImGui.GetCursorPosX() - 2)
							end
							ImGui.Text(item)
						end
					else
						ImGui.SameLine()
						ImGui.Text(section.desc)
					end
					ImGui.PopStyleVar()
					ImGui.PopStyleColor()
				end
			end

			ImGui.Spacing()
			ImGui.Separator()

			-- Saving: Item Format & Keep Seed
			ImGui.BeginGroup()
			ImGui.Spacing()
			ImGui.Text('Item format:')
			ImGui.SetNextItemWidth(viewData.gridHalfWidth)
			viewData.itemFormatIndex = ImGui.Combo('##Item Format', viewData.itemFormatIndex, viewData.itemFormatList, viewData.itemFormatCount)
			userState.specOptions.itemFormat = itemFormatOptions[viewData.itemFormatIndex + 1]
			ImGui.EndGroup()

			ImGui.SameLine(viewData.windowOffsetX + viewData.gridHalfWidth + viewData.gridGutter)
			ImGui.BeginGroup()
			ImGui.Text('Keep seed:')
			ImGui.SetNextItemWidth(viewData.gridHalfWidth)
			viewData.keepSeedIndex = ImGui.Combo('##Keep Seed', viewData.keepSeedIndex, viewData.keepSeedList, viewData.keepSeedCount)
			userState.specOptions.keepSeed = keepSeedOptions[viewData.keepSeedIndex + 1]
			ImGui.EndGroup()

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem('Load Spec') then
			ImGui.Spacing()

			-- Loading: Spec Name
			ImGui.Text('Spec name:')
			ImGui.SetNextItemWidth(viewData.gridTwoThirdsWidth)
			userState.specNameLoad = ImGui.InputText('##Load Spec Name', userState.specNameLoad, viewData.maxInputLen)

			-- Loading: Load Button
			ImGui.SameLine(viewData.windowOffsetX + viewData.gridTwoThirdsWidth + viewData.gridGutter)
			if ImGui.Button('Load', viewData.gridOneThirdWidth, viewData.defaultInputHeight) then
				gui.onLoadSpecClick()
			end

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			-- Loading: Recent Specs
			ImGui.Text('Recently saved / loaded specs:')
			ImGui.Spacing()
			ImGui.SetNextItemWidth(viewData.gridFullWidth)
			ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			ImGui.PushStyleColor(ImGuiCol.FrameBg, 0)
			local recentSpecIndex = ImGui.ListBox('##Load Recent Specs', -1, viewData.specHistoryList, #viewData.specHistoryList, 14)
			ImGui.PopStyleColor()
			ImGui.PopStyleVar(2)
			if recentSpecIndex >= 0 then
				userState.specNameLoad = userState.specHistory[recentSpecIndex + 1].specName
				recentSpecIndex = -1
			end

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem('Options') then
			ImGui.Spacing()

			-- Options: Specs Dir
			ImGui.Text('Specs location:')
			ImGui.SetNextItemWidth(viewData.gridFullWidth)
			userState.globalOptions.specsDir = ImGui.InputText('##Specs Location', userState.globalOptions.specsDir, viewData.maxInputLen)

			ImGui.Spacing()

			-- Options: Default Spec
			ImGui.Text('Default spec name:')
			ImGui.SetNextItemWidth(viewData.gridFullWidth)
			userState.globalOptions.defaultSpec = ImGui.InputText('##Default Spec', userState.globalOptions.defaultSpec, viewData.maxInputLen)

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			-- Options: Saving Tip
			ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
			ImGui.Text('The changes will take effect after saving.')
			ImGui.PopStyleColor()

			ImGui.Spacing()

			-- Options: Save Button
			if ImGui.Button('Save options', viewData.gridHalfWidth, viewData.defaultInputHeight) then
				gui.onSaveConfigClick()
			end

			-- Options: Reset Button
			ImGui.SameLine(viewData.windowOffsetX + viewData.gridHalfWidth + viewData.gridGutter)
			if ImGui.Button('Reset to defaults', viewData.gridHalfWidth, viewData.defaultInputHeight) then
				gui.onResetConfigClick()
			end

			if mod.dev then
				ImGui.Spacing()
				ImGui.Separator()
				ImGui.Spacing()

				if ImGui.Button('Rehash TweakDB names', viewData.windowWidth, viewData.defaultInputHeight) then
					gui.onRehashTweakDbClick()
				end

				ImGui.Spacing()

				if ImGui.Button('Compile sample packs', viewData.windowWidth, viewData.defaultInputHeight) then
					gui.onCompileSamplesClick()
				end

				ImGui.Spacing()

				if ImGui.Button('Write default config', viewData.windowWidth, viewData.defaultInputHeight) then
					gui.onWriteDefaultConfigClick()
				end

				ImGui.Spacing()

				if ImGui.Button('Write default spec', viewData.windowWidth, viewData.defaultInputHeight) then
					gui.onWriteDefaultSpecClick()
				end
			end

			ImGui.EndTabItem()
		end

		ImGui.EndTabBar()
	end

	ImGui.End()

	tweaksGui.onDrawEvent()
end

function gui.onSaveSpecClick()
	respector:saveSpec(userState.specNameSave, userState.specOptions)

	persitentState:flush()
end

function gui.onLoadSpecClick()
	respector:loadSpec(userState.specNameLoad)

	persitentState:flush()
end

function gui.onSaveConfigClick()
	for optionName, optionValue in pairs(userState.globalOptions) do
		if str.isempty(optionValue) and viewData.defaultOptions[optionName] then
			optionValue = viewData.defaultOptions[optionName]
		end

		mod.config[optionName] = optionValue
	end

	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:writeConfig()

	respector:loadComponents()

	print(('Respector: Configuration saved.'))
end

function gui.onResetConfigClick()
	local Configuration = mod.require('mod/Configuration')
	local configuration = Configuration:new()

	configuration:resetConfig({ useGui = true })

	mod.loadConfig()

	respector:loadComponents()

	gui.initUserState(true)
	tweaksGui.initState(true)

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

function gui.onQuickSaveHotkey()
	local timestamp = userState.specOptions.timestamp
	userState.specOptions.timestamp = true

	respector:saveSpec(userState.specNameSave, userState.specOptions)

	userState.specOptions.timestamp = timestamp

	persitentState:flush()
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

	if #userState.specHistory > viewData.specHistoryMaxLen then
		table.remove(userState.specHistory)
		table.remove(viewData.specHistoryList)
	end

	persitentState:flush()
end

-- Helpers

function gui.formatHistoryEntry(entryData)
	return entryData.time .. ' ' .. (entryData.event == 'load' and 'L' or 'S') .. ' ' .. entryData.specName
end

return gui
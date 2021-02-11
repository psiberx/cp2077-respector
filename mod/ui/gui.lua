local mod = ...
local ImGuiX = mod.require('mod/ui/imguix')
local array = mod.require('mod/utils/array')
local RarityFilter = mod.require('mod/enums/RarityFilter')
local PersistentState = mod.require('mod/helpers/PersistentState')
local tweaksGui = mod.require('mod/ui/gui.tweaks')
local respecGui = mod.require('mod/ui/gui.respec')

local gui = {}

local respector, tweaker

local rarityFilters = RarityFilter.all()
local itemFormatOptions = { 'auto', 'hash', 'struct' }
local keepSeedOptions = { 'auto', 'always' }

local viewData = {
	justOpened = true,
	showWindow = false,
	selectedTab = nil,

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
	itemFormatList = { 'Hash name', 'Hash value', 'Hash struct' },
	itemFormatCount = #itemFormatOptions,

	keepSeedIndex = 0,
	keepSeedList = { 'Only if necessary', 'For all item' },
	keepSeedCount = #keepSeedOptions,

	specHistoryList = {},
	specHistoryMaxLen = 50,
}

local userState = {
	expandWindow = true,

	specNameSave = nil,
	specOptions = nil,

	specNameLoad = nil,
	specHistory = {},

	cheatMode = nil,
}

local persitentState

function gui.init(_respector, _tweaker)
	respector = _respector
	tweaker = _tweaker

	gui.initHandlers()
	gui.initPersistance()
	gui.initUserState()
	gui.initViewData()

	respecGui.init(respector, viewData, userState)
	tweaksGui.init(respector, tweaker, userState, persitentState)
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

function gui.initUserState()
	if not userState.specOptions then
		userState.specNameSave = mod.config.defaultSpec
		userState.specNameLoad = mod.config.defaultSpec

		userState.specOptions = respector:getSpecOptions()
		userState.specOptions.timestamp = false
	end

	if type(userState.cheatMode) ~= 'boolean' then
		userState.cheatMode = false
	end

	if type(userState.specOptions.cheat) ~= 'boolean' then
		userState.specOptions.cheat = userState.cheatMode
	end

	local existingSpecs = respector.specStore:listSpecs()

	if #existingSpecs > 0 then
		for entryIndex = #userState.specHistory, 1, -1 do
			local entryInfo = userState.specHistory[entryIndex]

			local existingSpecIndex = false

			for specIndex, specInfo in ipairs(existingSpecs) do
				if entryInfo.specName == specInfo.specName then
					existingSpecIndex = specIndex
					break
				end
			end

			if existingSpecIndex then
				table.remove(existingSpecs, existingSpecIndex)
			else
				table.remove(userState.specHistory, entryIndex)
			end
		end

		if #existingSpecs > 0 then
			for _, specInfo in ipairs(existingSpecs) do
				table.insert(userState.specHistory, {
					specName = specInfo.specName,
					time = specInfo.time,
					event = 'new',
				})
			end

			table.sort(userState.specHistory, function(a, b)
				return gui.parseDateTime(a.time) > gui.parseDateTime(b.time)
			end)
		end
	else
		for entryIndex = #userState.specHistory, 1, -1 do
			local entryData = userState.specHistory[entryIndex]

			if not respector.specStore:hasSpec(entryData.specName) then
				table.remove(userState.specHistory, entryIndex)
			end
		end
	end
end

function gui.initViewData()
	viewData.fontSize = ImGui.GetFontSize()
	viewData.viewScale = viewData.fontSize / 13
	viewData.viewScaleX = viewData.viewScale
	viewData.viewScaleY = viewData.viewScale

	if viewData.viewScale > 1 then
		viewData.viewScaleX = viewData.viewScaleX * 1.05
		viewData.viewScaleY = viewData.viewScaleY * 0.975
	end

	viewData.windowWidth = 340 * viewData.viewScaleX
	viewData.windowHeight = 373 * viewData.viewScaleY
	viewData.windowPadding = 8
	viewData.windowOffsetX = 8
	viewData.windowOffsetY = math.ceil(viewData.fontSize * 1.3846) + 9

	viewData.gridGutter = 8 * viewData.viewScaleX
	viewData.gridFullWidth = viewData.windowWidth
	viewData.gridHalfWidth = (viewData.gridFullWidth - viewData.gridGutter) / 2
	viewData.gridOneThirdWidth = math.floor((viewData.gridFullWidth - viewData.gridGutter * 2) / 3 + 0.5)
	viewData.gridTwoThirdsWidth = math.floor((viewData.gridFullWidth - viewData.gridGutter * 2) / 3 * 2 + viewData.gridGutter +  0.5)

	viewData.tabRounding = math.floor(viewData.fontSize * 0.35)
	viewData.tweaksButtonWidth = 100 * viewData.viewScaleX
	viewData.tweaksButtonHeight = 19 * viewData.viewScaleY
	viewData.buttonHeight = 19 * viewData.viewScaleY
	viewData.inputHeight = 19 * viewData.viewScaleY

	viewData.balancedModeHeight = 140 * viewData.viewScaleY
	viewData.unlimitedModeHeight = 162 * viewData.viewScaleY

	viewData.rarityFilterIndex = array.find(rarityFilters, userState.specOptions.rarity) - 1
	viewData.itemFormatIndex = array.find(itemFormatOptions, userState.specOptions.itemFormat) - 1
	viewData.keepSeedIndex = array.find(keepSeedOptions, userState.specOptions.keepSeed) - 1

	viewData.specHistoryList = array.map(userState.specHistory, gui.formatHistoryEntry)
end

-- GUI Event Handlers

function gui.onOverlayOpen()
	viewData.showWindow = true
	viewData.justOpened = true
end

function gui.onOverlayClose()
	viewData.showWindow = false
end

function gui.onDrawEvent()
	if not viewData.showWindow then
		return
	end

	ImGuiX.RestoreStack()

	ImGui.SetNextWindowPos(0, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(viewData.windowWidth + (viewData.windowPadding * 2), viewData.windowHeight)

	local showWindow, expandWindow = ImGui.Begin('Respector', true, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)

	if expandWindow ~= userState.expandWindow then
		userState.expandWindow = expandWindow
	end

	if showWindow ~= viewData.showWindow then
		viewData.justOpened = true
		viewData.showWindow = showWindow
		persitentState:flush()
	end

	if viewData.showWindow and userState.expandWindow then
		-- Quick Tweaks Button

		ImGui.SetCursorPos(viewData.windowOffsetX + viewData.windowWidth - viewData.tweaksButtonWidth , viewData.windowOffsetY + 1)

		local windowX, windowY = ImGui.GetItemRectMin()

		ImGuiX.PushClipRect(windowX, windowY, windowX + viewData.windowOffsetX + viewData.windowWidth, windowY + viewData.windowOffsetY + viewData.tweaksButtonHeight - 1, false)
		ImGuiX.PushStyleVar(ImGuiStyleVar.FrameRounding, viewData.tabRounding)
		ImGuiX.PushStyleColor(ImGuiCol.Button, userState.showTweaker and 0xff51a600 or 0xff518900)
		ImGuiX.PushStyleColor(ImGuiCol.ButtonHovered, 0xff67bc16)

		if ImGui.Button('Quick Tweaks', viewData.tweaksButtonWidth, viewData.tweaksButtonHeight) then
			tweaksGui.onToggleTweaker()
		end

		ImGuiX.PopStyleColor(2)
		ImGuiX.PopStyleVar()
		ImGuiX.PopClipRect()

		ImGui.SetCursorPos(viewData.windowOffsetX, viewData.windowOffsetY)

		-- Main Tabs

		ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 9, 3)
		ImGui.BeginTabBar('Respector Tabs')

		if ImGui.BeginTabItem('Save') then
			ImGuiX.PopStyleVar()
			ImGui.Spacing()

			-- Saving: Spec Name
			ImGui.Text('Spec name:')
			ImGui.SetNextItemWidth(viewData.gridTwoThirdsWidth)
			userState.specNameSave = ImGui.InputText('##SaveSpecName', userState.specNameSave, viewData.maxInputLen)

			-- Saving: Save Button
			ImGui.SameLine(viewData.windowOffsetX + viewData.gridTwoThirdsWidth + viewData.gridGutter)
			if ImGui.Button('Save', viewData.gridOneThirdWidth, viewData.inputHeight) then
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
					viewData.rarityFilterIndex = ImGui.Combo('##BackpackFilter', viewData.rarityFilterIndex, viewData.rarityFilterList, viewData.rarityFilterCount)
					userState.specOptions.rarity = rarityFilters[viewData.rarityFilterIndex + 1]
				elseif section.desc then
					ImGui.SameLine()
					ImGuiX.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
					ImGuiX.PushStyleVar(ImGuiStyleVar.ItemSpacing, 3, 5)
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
					ImGuiX.PopStyleVar()
					ImGuiX.PopStyleColor()
				end
			end

			ImGui.Spacing()
			ImGui.Separator()

			-- Saving: Item Format & Keep Seed
			ImGui.BeginGroup()
			ImGui.Spacing()
			ImGui.Text('Item format:')
			ImGui.SetNextItemWidth(viewData.gridHalfWidth)
			viewData.itemFormatIndex = ImGui.Combo('##ItemFormat', viewData.itemFormatIndex, viewData.itemFormatList, viewData.itemFormatCount)
			userState.specOptions.itemFormat = itemFormatOptions[viewData.itemFormatIndex + 1]
			ImGui.EndGroup()

			ImGui.SameLine(viewData.windowOffsetX + viewData.gridHalfWidth + viewData.gridGutter)
			ImGui.BeginGroup()
			ImGui.Text('Keep seed:')
			ImGui.SetNextItemWidth(viewData.gridHalfWidth)
			viewData.keepSeedIndex = ImGui.Combo('##KeepSeed', viewData.keepSeedIndex, viewData.keepSeedList, viewData.keepSeedCount)
			userState.specOptions.keepSeed = keepSeedOptions[viewData.keepSeedIndex + 1]
			ImGui.EndGroup()

			viewData.selectedTab = 'Save'

			ImGui.EndTabItem()
		else
			ImGuiX.PopStyleVar()
		end

		if ImGui.BeginTabItem('Load') then
			ImGui.Spacing()

			-- Loading: Spec Name
			ImGui.Text('Spec name:')
			ImGui.SetNextItemWidth(viewData.gridTwoThirdsWidth)
			userState.specNameLoad = ImGui.InputText('##LoadSpecName', userState.specNameLoad, viewData.maxInputLen)

			-- Loading: Load Button
			ImGui.SameLine(viewData.windowOffsetX + viewData.gridTwoThirdsWidth + viewData.gridGutter)
			if ImGui.Button('Load', viewData.gridOneThirdWidth, viewData.inputHeight) then
				gui.onLoadSpecClick()
			end

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			-- Loading: Recent Specs
			ImGui.Text('Recent specs:')
			ImGui.Spacing()
			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0)

			ImGui.BeginListBox('##RecentSpecs', viewData.gridFullWidth + .0, 237.0)
			local recentSpecIndex = -1
			for entryIndex, entryPreview in ipairs(viewData.specHistoryList) do
				if ImGui.Selectable(entryPreview, false) then
					recentSpecIndex = entryIndex - 1
				end
				if ImGui.IsItemClicked(ImGuiMouseButton.Middle) then
					gui.forgetHistoryEntry(entryIndex)
				end
			end
			ImGui.EndListBox()

			--ImGui.SetNextItemWidth(viewData.gridFullWidth)
			--local recentSpecIndex = ImGui.ListBox('##RecentSpecs', -1, viewData.specHistoryList, #viewData.specHistoryList, 14)

			ImGuiX.PopStyleColor()
			ImGuiX.PopStyleVar(2)
			if recentSpecIndex >= 0 then
				userState.specNameLoad = userState.specHistory[recentSpecIndex + 1].specName
				recentSpecIndex = -1
			end

			viewData.selectedTab = 'Load'

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem('Respec') then
			respecGui.onDrawEvent(viewData.justOpened or viewData.selectedTab ~= 'Respec')

			viewData.selectedTab = 'Respec'

			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem('Options') then
			ImGui.Spacing()

			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameRounding, 8)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 10, 9)
			ImGuiX.PushStyleColor(ImGuiCol.Border, 0xff483f3f)
			ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGui.BeginGroup()
			ImGui.BeginChildFrame(11, viewData.gridFullWidth, viewData.balancedModeHeight)
			ImGuiX.PopStyleColor(2)
			ImGuiX.PopStyleVar(3)

			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
			ImGuiX.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, 7, 0)
			ImGuiX.PushStyleColor(ImGuiCol.Border, 0xfffa9642)
			ImGuiX.PushStyleColor(ImGuiCol.Text, userState.cheatMode and 0xff9f9f9f or 0xffffffff)
			local balancedModeSelected = ImGui.RadioButton('Balanced Mode', not userState.cheatMode)
			ImGuiX.PopStyleColor(2)
			ImGuiX.PopStyleVar(2)

			if balancedModeSelected then
				gui.onCheatModeChange(false)
			end

			ImGui.Spacing()

			ImGuiX.PushStyleColor(ImGuiCol.Text, userState.cheatMode and 0xff5f5f5f or 0xffbfbfbf)
			ImGui.TextWrapped('Enforces valid states and combinations of Attributes, Skills, Perks, Attribute Points and Perk Points.')
			ImGui.Spacing()
			ImGui.TextWrapped('Items in Quick Tweaks can only be spawned with the quality obtainable in the game.')
			ImGui.Spacing()
			ImGui.TextWrapped('Validates and auto corrects loaded specs.')
			ImGuiX.PopStyleColor()

			ImGui.EndChildFrame()
			ImGui.EndGroup()

			ImGui.Spacing()

			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameRounding, 8)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 10, 9)
			ImGuiX.PushStyleColor(ImGuiCol.Border, 0xff483f3f)
			ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGui.BeginGroup()
			ImGui.BeginChildFrame(12, viewData.gridFullWidth, viewData.unlimitedModeHeight)
			ImGuiX.PopStyleColor(2)
			ImGuiX.PopStyleVar(3)

			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
			ImGuiX.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, 7, 0)
			ImGuiX.PushStyleColor(ImGuiCol.Border, 0xfffa9642) -- userState.cheatMode and 0xfffa9642 or 0xff4a2f1e
			ImGuiX.PushStyleColor(ImGuiCol.Text, userState.cheatMode and 0xffffffff or 0xff9f9f9f)
			local cheatModeSelected = ImGui.RadioButton('Unlimited Mode', userState.cheatMode)
			ImGuiX.PopStyleColor(2)
			ImGuiX.PopStyleVar(2)

			if cheatModeSelected then
				gui.onCheatModeChange(true)
			end

			ImGui.Spacing()

			ImGuiX.PushStyleColor(ImGuiCol.Text, userState.cheatMode and 0xffbfbfbf or 0xff5f5f5f)
			ImGui.TextWrapped('Disables all checks and limits.')
			ImGui.Spacing()
			ImGui.TextWrapped('Allows to respec all Attributes to the max level and to acquire all Perks at the max level at the same time.')
			ImGui.Spacing()
			ImGui.TextWrapped('Items in Quick Tweaks can be spawned with\nany quality, even unobtainable in the game.')
			ImGui.Spacing()
			ImGui.TextWrapped('Loaded specs are not validated.')
			ImGuiX.PopStyleColor()

			ImGui.EndChildFrame()
			ImGui.EndGroup()

			viewData.selectedTab = 'Options'

			ImGui.EndTabItem()
		end

		ImGui.EndTabBar()
	end

	ImGui.End()

	tweaksGui.onDrawEvent()

	viewData.justOpened = false
end

-- Action Handlers

function gui.onSaveSpecClick()
	respector:saveSpec(userState.specNameSave, userState.specOptions)

	persitentState:flush()
end

function gui.onLoadSpecClick()
	respector:loadSpec(userState.specNameLoad, userState.specOptions)

	persitentState:flush()
end

function gui.onCheatModeChange(cheatMode)
	userState.cheatMode = cheatMode
	userState.specOptions.cheat = cheatMode
	userState.tweakSearch = nil

	persitentState:flush()
end

function gui.forgetHistoryEntry(entryIndex)
	local entry = userState.specHistory[entryIndex]

	if respector.specStore:deleteSpec(entry.specName) then
		table.remove(userState.specHistory, entryIndex)
		table.remove(viewData.specHistoryList, entryIndex)

		persitentState:flush()
	end
end

-- Hotkey Handlers

function gui.onQuickSaveHotkey()
	local timestamp = userState.specOptions.timestamp
	userState.specOptions.timestamp = true

	respector:saveSpec(userState.specNameSave, userState.specOptions)

	userState.specOptions.timestamp = timestamp

	persitentState:flush()
end

-- Event Handlers

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
	local event = (entryData.event == 'load' and 'L' or (entryData.event == 'save' and 'S' or 'N'))

	return entryData.time .. ' ' .. event .. ' ' .. entryData.specName
end

function gui.parseDateTime(dateTime)
	local day, month, year, hour, min = dateTime:match('^(%d%d)%.(%d%d)%.(%d%d%d%d) (%d%d):(%d%d)')

	return os.time({
		day = tonumber(day),
		month = tonumber(month),
		year = tonumber(year),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = 0
	})
end

return gui
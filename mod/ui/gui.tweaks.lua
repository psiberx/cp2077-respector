local mod = ...
local ImGuiX = mod.require('mod/ui/imguix')
local str = mod.require('mod/utils/str')
local array = mod.require('mod/utils/array')
local Quality = mod.require('mod/enums/Quality')
local TweakDb = mod.require('mod/helpers/TweakDb')
local SimpleDb = mod.require('mod/helpers/SimpleDb')

local tweaksGui = {}

local respector, tweaker, tweakDb, equipAreaDb, persitentState

local viewData = {
	justOpened = true,
	
	tweakSearch = nil,
	tweakSearchMaxLen = 128,
	tweakSearchStarted = false,
	tweakSearchMaxResults = 50,
	tweakSearchResults = nil,
	tweakSearchPreviews = nil,

	activeTweakIndex = nil,
	activeTweakData = nil,

	qualityOptionList = nil,
	qualityOptionCount = nil,
	qualityOptionIndex = nil,

	questOptionList = nil,
	questOptionCount = nil,
	questOptionIndex = nil,

	resourceForm = {
		Money = {
			transactionLabel = 'Transaction amount:',
			transferAmount = 10000,
			transactionStep = 1000,
			transactionStepFast = 10000,
			balanceLabel = 'Current balance:',
			buttonLabel = 'Transfer money',
		},
		Component = {
			transactionLabel = 'Required quantity:',
			transferAmount = 1000,
			transactionStep = 100,
			transactionStepFast = 1000,
			balanceLabel = 'In the backpack:',
			buttonLabel = 'Acquire components',
		},
		Ammo = {
			transactionLabel = 'Required quantity:',
			transferAmount = 100,
			transactionStep = 10,
			transactionStepFast = 100,
			balanceLabel = 'In the backpack:',
			buttonLabel = 'Acquire ammo',
		},
	},
}

local userState = {
	showTweaker = nil,
	expandTweaker = nil,
	tweakSearch = nil,
}

function tweaksGui.init(_respector, _tweaker, _userState, _persitentState)
	respector = _respector
	tweaker = _tweaker
	userState = _userState
	persitentState = _persitentState

	tweakDb = TweakDb:new()
	equipAreaDb = SimpleDb:new()

	tweaksGui.initUserState()
	tweaksGui.initViewData()
end

function tweaksGui.initUserState(force)
	if not userState.tweakSearch or force then
		userState.showTweaker = false
		userState.expandTweaker = true
	end

	userState.tweakSearch = ''
end

function tweaksGui.initViewData()
	viewData.fontSize = ImGui.GetFontSize()
	viewData.viewScale = viewData.fontSize / 13

	viewData.windowWidth = 440 * viewData.viewScale
	viewData.windowHeight = 0 -- Auto Height
	viewData.windowPaddingX = 7.5
	viewData.windowPaddingY = 6
	viewData.windowOffsetX = 6

	viewData.gridGutter = 8
	viewData.gridFullWidth = viewData.windowWidth
	viewData.gridHalfWidth = (viewData.gridFullWidth - viewData.gridGutter) / 2

	viewData.buttonHeight = 21 * viewData.viewScale

	viewData.searchResultsHeight = (viewData.fontSize + 4) * 6.5

	viewData.tweakCloseBtnSize = 18 * viewData.viewScale
	viewData.tweakFactStateYesWidth = 32 * viewData.viewScale
	viewData.tweakFactStateNoWidth = 24 * viewData.viewScale
	viewData.tweakQtyInputWidth = 138 * viewData.viewScale
	viewData.tweakQualityInputWidth = 168 * viewData.viewScale
	viewData.tweakQuestInputWidth = 118 * viewData.viewScale
	viewData.tweakHashNameInputWidth = 296 * viewData.viewScale
	viewData.tweakHashHexInputWidth = 78 * viewData.viewScale

	viewData.tweakSearch = ''
	viewData.tweakSearchStarted = false

	viewData.tweakSearchResults = {}
	viewData.tweakSearchPreviews = {}

	viewData.activeTweakIndex = -1
	viewData.activeTweakData = nil
end

function tweaksGui.onDrawEvent()
	if not userState.showTweaker then
		return
	end

	ImGui.SetNextWindowPos(365, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(viewData.windowWidth + (viewData.windowPaddingX * 2), viewData.windowHeight)
	ImGuiX.PushStyleVar(ImGuiStyleVar.WindowPadding, viewData.windowPaddingX, viewData.windowPaddingY)

	local showTweaker, expandTweaker = ImGui.Begin('Quick Tweaks', userState.showTweaker, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)

	if expandTweaker ~= userState.expandTweaker then
		userState.expandTweaker = expandTweaker
	end

	if showTweaker ~= userState.showTweaker then
		userState.showTweaker = showTweaker
		persitentState:flush()
	end

	if userState.showTweaker and userState.expandTweaker then

		-- Gain focus on opening
		if viewData.justOpened then
			ImGui.SetKeyboardFocusHere()

			viewData.justOpened = false
		end

		ImGui.Spacing()
		ImGui.SetNextItemWidth(viewData.gridFullWidth)
		ImGuiX.PushStyleColor(ImGuiCol.TextDisabled, 0xffaaaaaa)
		viewData.tweakSearch = ImGui.InputTextWithHint('##TweakSearch', 'Search database...', viewData.tweakSearch, viewData.tweakSearchMaxLen)
		ImGuiX.PopStyleColor()

		if viewData.tweakSearch ~= userState.tweakSearch then
			viewData.tweakSearchResults = {}
			viewData.tweakSearchPreviews = {}
			viewData.activeTweakIndex = -1
			viewData.activeTweakData = nil

			userState.tweakSearch = viewData.tweakSearch

			tweaksGui.onTweakSearchChange()
		end

		ImGui.Spacing()

		ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
		ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
		ImGuiX.PushStyleColor(ImGuiCol.Border, 0xff483f3f)
		ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0)
		ImGui.BeginChildFrame(1, viewData.gridFullWidth, viewData.searchResultsHeight)

		if #viewData.tweakSearchResults > 0 then
			ImGuiX.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			ImGui.SetNextItemWidth(viewData.gridFullWidth)

			local tweakIndex, tweakChanged = ImGui.ListBox('##TweakSearchResults',
				viewData.activeTweakIndex,
				viewData.tweakSearchPreviews,
				#viewData.tweakSearchPreviews,
				#viewData.tweakSearchPreviews
			)

			ImGuiX.PopStyleVar(2)

			if tweakChanged then
				viewData.activeTweakIndex = tweakIndex
				viewData.activeTweakData = viewData.tweakSearchResults[tweakIndex + 1] or nil

				tweaksGui.onTweakSearchResultSelect()
			end
		else
			ImGuiX.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)

			if viewData.tweakSearchStarted then
				ImGui.TextWrapped('No results for your request.')
			else
				ImGui.TextWrapped('1. Start typing in the search bar (at least 2 characters)\n   to find items, vehicles, resources, facts.')
				ImGui.TextWrapped('2. Select entry to get the available tweaks.')
			end

			ImGuiX.PopStyleColor()
		end

		ImGui.EndChildFrame()
		ImGuiX.PopStyleColor(2)
		ImGuiX.PopStyleVar(2)

		if viewData.activeTweakData then
			local tweak = viewData.activeTweakData

			ImGui.Spacing()
			ImGui.Separator()
			ImGui.Spacing()

			local _, tweakPanelY = ImGui.GetCursorPos()

			ImGuiX.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 3)

			if tweak.entryMeta.quality then
				ImGuiX.PushStyleColor(ImGuiCol.Text, Quality.toColor(tweak.entryMeta.quality))
			end

			ImGui.Text(tweak.entryMeta.name)

			if tweak.entryMeta.quality then
				ImGui.SameLine()
				ImGui.Text('·')
				ImGui.SameLine()
				ImGui.Text(tweak.entryMeta.quality)

				if tweak.entryMeta.iconic then
					ImGui.SameLine()
					ImGui.Text('/')
					ImGui.SameLine()
					ImGui.Text('Iconic')
				end

				ImGuiX.PopStyleColor()
			end

			ImGuiX.PushStyleColor(ImGuiCol.Text, 0xffbf9f9f)
			ImGui.Text(tweak.entryMeta.kind)

			if tweak.entryMeta.group then
				ImGui.SameLine()
				ImGui.Text('/')
				ImGui.SameLine()
				ImGui.Text(tweak.entryMeta.group)

				if tweak.entryMeta.group2 then
					ImGui.SameLine()
					ImGui.Text('/')
					ImGui.SameLine()
					ImGui.Text(tweak.entryMeta.group2)
				end

				if tweak.showEntryTag then
					ImGui.SameLine()
					ImGui.Text('·')
					ImGui.SameLine()
					ImGui.Text(tweak.entryMeta.tag)
				end
			end

			ImGuiX.PopStyleColor()

			if tweak.entryMeta.comment then
				ImGuiX.PushStyleColor(ImGuiCol.Text, 0xff484ad5)
				ImGui.TextWrapped(tweak.entryMeta.comment:gsub('%%', '%%%%'))
				ImGuiX.PopStyleColor()
			end

			if tweak.entryMeta.desc then
				ImGuiX.PushStyleColor(ImGuiCol.Text, 0xffcccccc)
				ImGui.TextWrapped(tweak.entryMeta.desc:gsub('%%', '%%%%'))
				ImGuiX.PopStyleColor()
			end

			ImGuiX.PopStyleVar()

			ImGui.Spacing()

			-- Hacks
			if tweak.entryMeta.kind == 'Hack' then
				if ImGui.Button('Execute hack', viewData.gridFullWidth, viewData.buttonHeight) then
					tweaksGui.onExecuteHackClick()
				end

			-- Facts
			elseif tweak.entryMeta.kind == 'Fact' then
				ImGui.AlignTextToFramePadding()
				ImGuiX.PushStyleVar(ImGuiStyleVar.ItemSpacing, 5, 3)
				ImGui.Text('Current state:')
				ImGui.SameLine()
				if tweak.factState then
					ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0x7700ff00)
					ImGui.SetNextItemWidth(viewData.tweakFactStateYesWidth)
					ImGui.InputText('##FactYES', 'YES', 3, ImGuiInputTextFlags.ReadOnly)
					ImGuiX.PopStyleColor()
				else
					ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0x770000ee) -- 0xff484ad5
					ImGui.SetNextItemWidth(viewData.tweakFactStateNoWidth)
					ImGui.InputText('##FactNO', 'NO', 2, ImGuiInputTextFlags.ReadOnly)
					ImGuiX.PopStyleColor()
				end
				ImGuiX.PopStyleVar()

				ImGui.Spacing()

				if ImGui.Button(tweak.factState and 'Switch to NO' or 'Switch to YES', viewData.gridFullWidth, viewData.buttonHeight) then
					tweaksGui.onSwitchFactClick()
				end

				ImGui.Spacing()

				ImGui.TextWrapped('Be careful with manipulating facts.\nMake a manual save before making any changes.')

				-- Vehicles
			elseif tweak.entryMeta.kind == 'Vehicle' then
				ImGui.Spacing()

				if tweak.vehicleUnlockable then
					if tweak.vehicleUnlocked then
						ImGui.Text('You own this vehicle.')
					else
						ImGui.Text('You don\'t own this vehicle yet.')

						ImGui.Spacing()

						if ImGui.Button('Add to garage', viewData.gridFullWidth, viewData.buttonHeight) then
							tweaksGui.onUnlockVehicleClick()
						end
					end
				else
					ImGui.Text('Make sure there is space in front of you for a vehicle.')
					ImGui.TextWrapped('If it doesn\'t appear immediately, look in the other direction for a moment.')

					ImGui.Spacing()

					if ImGui.Button('Spawn vehicle', viewData.gridFullWidth, viewData.buttonHeight) then
						tweaksGui.onSpawnVehicleClick()
					end

					ImGui.Spacing()

					ImGui.Text('This vehicle cannot be added to the garage.')
				end

				-- Money / Ingredients
			elseif tweak.entryMeta.kind == 'Money' or tweak.entryMeta.kind == 'Component' or tweak.entryMeta.kind == 'Ammo' then
				local form = viewData.resourceForm[tweak.entryMeta.kind]

				ImGui.BeginGroup()
				ImGui.Spacing()
				ImGui.Text(form.transactionLabel)
				ImGui.SetNextItemWidth(viewData.gridHalfWidth)
				tweak.transferAmount = ImGui.InputInt('##TransferAmount', tweak.transferAmount, form.transactionStep, form.transactionStepFast)
				ImGui.EndGroup()

				tweak.transferAmount = math.max(tweak.transferAmount, 0)
				tweak.transferAmount = math.min(tweak.transferAmount, 9999999)

				ImGui.SameLine()
				ImGui.BeginGroup()
				ImGui.Text(form.balanceLabel)
				ImGui.SetNextItemWidth(viewData.gridHalfWidth)
				ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0.25)
				ImGui.InputText('##CurrentAmount', tostring(tweak.currentAmount), 32, ImGuiInputTextFlags.ReadOnly)
				ImGuiX.PopStyleColor()
				ImGui.EndGroup()

				ImGui.Spacing()

				if ImGui.Button(form.buttonLabel, viewData.gridFullWidth, viewData.buttonHeight) then
					tweaksGui.onTransferGoodsClick()
				end

				-- Items
			else
				ImGui.BeginGroup()
				ImGui.Spacing()
				ImGui.Text('Quantity:')
				ImGui.SetNextItemWidth(viewData.tweakQtyInputWidth)
				tweak.itemQty = ImGui.InputInt('##ItemQty', tweak.itemQty or 1)
				ImGui.EndGroup()

				ImGui.SameLine()
				ImGui.BeginGroup()
				ImGui.Text('Quality:')
				ImGui.SetNextItemWidth(viewData.tweakQualityInputWidth)
				if tweak.itemCanBeUpgraded then
					local optionIndex, optionChanged = ImGui.Combo('##ItemQuality', viewData.qualityOptionIndex, viewData.qualityOptionList, viewData.qualityOptionCount)
					if optionChanged then
						tweak.itemQuality = viewData.qualityOptionList[optionIndex + 1]
						viewData.qualityOptionIndex = optionIndex
					end
				else
					ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0.25)
					ImGui.InputText('##ItemQualityFixed', tweak.entryMeta.quality, 512, ImGuiInputTextFlags.ReadOnly)
					ImGuiX.PopStyleColor()
				end
				ImGui.EndGroup()

				ImGui.SameLine()
				ImGui.BeginGroup()
				ImGui.Text('Quest mark:')
				ImGui.SetNextItemWidth(viewData.tweakQuestInputWidth)
				if tweak.itemCanBeMarked then
					local optionIndex, optionChanged = ImGui.Combo('##ItemQuest', viewData.questOptionIndex, viewData.questOptionList, viewData.questOptionCount)
					if optionChanged then
						tweak.itemQuestMark = viewData.questOptionList[optionIndex + 1] == 'Yes'
						viewData.questOptionIndex = optionIndex
					end
				else
					ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0.25)
					ImGui.InputText('##ItemQuestFixed', 'N/A', 512, ImGuiInputTextFlags.ReadOnly)
					ImGuiX.PopStyleColor()
				end
				ImGui.EndGroup()

				if tweak.itemCanBeEquipped then
					ImGui.BeginGroup()
					ImGui.Spacing()
					ImGui.Text('Equip:')
					ImGui.SetNextItemWidth(viewData.tweakQtyInputWidth)

					local optionIndex, optionChanged = ImGui.Combo('##ItemEquip', viewData.equipOptionIndex, viewData.equipOptionList, viewData.equipOptionCount)
					if optionChanged then
						tweak.itemEquipSlot = optionIndex
						viewData.equipOptionIndex = optionIndex
					end
					ImGui.EndGroup()

					if tweak.itemCanRandomize then
						ImGui.SameLine()
						ImGui.BeginGroup()
						ImGui.Text('Random:')
						ImGui.SetNextItemWidth(viewData.tweakQualityInputWidth)

						local optionIndex, optionChanged = ImGui.Combo('##ItemRandomize', viewData.randomizeOptionIndex, viewData.randomizeOptionList, viewData.randomizeOptionCount)
						if optionChanged then
							tweak.itemMaxSlots = optionIndex == 1
							viewData.randomizeOptionIndex = optionIndex
						end
						ImGui.EndGroup()
					end
				end

				ImGui.Spacing()

				if ImGui.Button('Add to inventory', viewData.gridFullWidth, viewData.buttonHeight) then
					tweaksGui.onSpawnItemClick()
				end

				if tweak.itemCanBeCrafted then
					ImGui.Spacing()
					ImGui.Spacing()

					if tweak.itemRecipeKnown then
						ImGui.Text('You have crafting recipe for this item.')
					else
						ImGui.Text('This item can be crafted.')
						ImGui.Spacing()

						if ImGui.Button('Get crafting recipe', viewData.gridFullWidth, viewData.buttonHeight) then
							tweaksGui.onUnlockRecipeClick()
						end
					end
				end
			end

			ImGui.Spacing()
			ImGui.Separator()

			ImGui.AlignTextToFramePadding()

			ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGuiX.PushStyleColor(ImGuiCol.Text, 0xff555555)
			ImGuiX.PushStyleVar(ImGuiStyleVar.ItemSpacing, 1, 0)
			ImGui.Text('ID:')
			ImGui.SameLine()
			ImGui.SetNextItemWidth(viewData.tweakHashNameInputWidth)
			ImGui.InputText('##Tweak Hash Name', tweak.entryType, 512, ImGuiInputTextFlags.ReadOnly)
			ImGuiX.PopStyleVar()
			ImGui.SameLine()
			ImGuiX.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 0)
			ImGui.Text('Hash:')
			ImGui.SameLine()
			ImGui.SetNextItemWidth(viewData.tweakHashHexInputWidth)
			ImGui.InputText('##Tweak Hash Key', tweak.entryHash, 16, ImGuiInputTextFlags.ReadOnly)
			ImGuiX.PopStyleVar()
			ImGuiX.PopStyleColor(2)

			ImGui.SetCursorPos(viewData.windowOffsetX + viewData.gridFullWidth - viewData.tweakCloseBtnSize, tweakPanelY)
			ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			if ImGui.Button('X', viewData.tweakCloseBtnSize + 1, viewData.tweakCloseBtnSize) then
				viewData.activeTweakIndex = -1
				viewData.activeTweakData = nil
			end
			ImGuiX.PopStyleVar()
		end
	end

	ImGui.End()

	ImGuiX.PopStyleVar()
end

function tweaksGui.onTweakSearchChange()
	--persitentState:flush()

	local searchTerm = str.trim(userState.tweakSearch)

	if searchTerm == '`' then
		userState.tweakSearch = ''
		viewData.tweakSearch = ''
		searchTerm = ''
	end

	if searchTerm:len() < 2 then
		viewData.tweakSearchStarted = false
		return
	end

	viewData.tweakSearchStarted = true

	tweakDb:load('mod/data/tweakdb-meta')

	local searchResults = {}

	for entryKey, entryMeta, entryPos in tweakDb:search(searchTerm) do
		if entryMeta.name and entryMeta.tweak ~= false and entryMeta.kind ~= 'Slot' then
			table.insert(searchResults, {
				entryKey = entryKey,
				entryMeta = entryMeta,
				entryOrder = tweakDb:order(entryMeta, true, ('%04X'):format(entryPos)),
			})
		end
	end

	tweakDb:unload()

	array.sort(searchResults, 'entryOrder')
	array.limit(searchResults, viewData.tweakSearchMaxResults)

	-- View Data

	viewData.tweakSearchResults = array.map(searchResults, function(result)
		return {
			entryKey = result.entryKey,
			entryMeta = result.entryMeta,
			entryType = str.nonempty(result.entryMeta.type, 'N/A'),
			entryHash = TweakDb.isRealKey(result.entryKey) and ('%010X'):format(result.entryKey) or 'N/A',
			showEntryTag = tweakDb:isTaggedAsSet(result.entryMeta),
		}
	end)

	viewData.tweakSearchPreviews = array.map(searchResults, function(result)
		return tweakDb:describe(result.entryMeta, true, false, 30)
	end)
end

function tweaksGui.onTweakSearchResultSelect()
	local tweak = viewData.activeTweakData

	if tweak.entryMeta.kind == 'Hack' then
		--

	elseif tweak.entryMeta.kind == 'Fact' then
		tweak.factState = tweaksGui.getFactState(tweak.entryMeta.type)

	elseif tweak.entryMeta.kind == 'Vehicle' then
		tweak.vehicleUnlockable = (tweak.entryMeta.type):find('_player$')
		tweak.vehicleUnlocked = respector:usingModule('transport', function(transportModule)
			return transportModule:isVehicleUnlocked(tweak.entryMeta.type)
		end)

	elseif tweak.entryMeta.kind == 'Money' or tweak.entryMeta.kind == 'Component' or tweak.entryMeta.kind == 'Ammo' then
		tweak.transferAmount = viewData.resourceForm[tweak.entryMeta.kind].transferAmount
		tweak.currentAmount = tweaksGui.getItemAmount(tweak.entryMeta.kind, tweak.entryMeta.type)

	else
		-- Item Quantity

		tweak.itemQty = 1

		-- Item Quality

		if tweak.entryMeta.quality then
			tweak.itemCanBeUpgraded = false
			tweak.itemQuality = tweak.entryMeta.quality
		else
			tweak.itemCanBeUpgraded = true

			if type(tweak.entryMeta.max) == 'string' and not userState.cheatMode then
				tweak.itemQuality = tweak.entryMeta.max
			else
				tweak.itemQuality = 'Legendary'
			end
		end

		-- Item Quest Mark

		if tweak.entryMeta.quest then
			tweak.itemCanBeMarked = true
			tweak.itemQuestMark = false
		else
			tweak.itemCanBeMarked = false
			tweak.itemQuestMark = false
		end

		-- Item Equip

		tweak.itemEquipSlot = 0

		if tweakDb:match(tweak.entryMeta, { kind = { 'Weapon', 'Clothing', 'Cyberware', 'Grenade' } }) or tweakDb:match(tweak.entryMeta, { kind = 'Consumable', group = 'Meds' }) then
			tweak.itemCanBeEquipped = true

			equipAreaDb:load('mod/data/equipment-areas')

			local equipAreaCriteria = { kind = tweak.entryMeta.kind }

			if tweak.entryMeta.kind == 'Cyberware' then
				equipAreaCriteria.group = tweak.entryMeta.group
			end

			local equipArea = equipAreaDb:find(equipAreaCriteria)

			viewData.equipOptionList = { 'No', 'Yes' }

			if equipArea.max > 1 then
				for slotIndex = 1, equipArea.max do
					viewData.equipOptionList[slotIndex + 1] = 'Slot ' .. slotIndex
				end
			end

			equipAreaDb:unload()
		else
			tweak.itemCanBeEquipped = false
			viewData.equipOptionList = {}
		end

		viewData.equipOptionCount = #viewData.equipOptionList
		viewData.equipOptionIndex = 0

		-- Item Slots

		if tweak.entryMeta.kind == 'Clothing' then
			tweak.itemCanRandomize = true
			tweak.itemMaxSlots = true

			viewData.randomizeOptionList = { 'Get random slots', 'Get maximum slots' }
		else
			tweak.itemCanRandomize = false
			tweak.itemMaxSlots = false

			viewData.randomizeOptionList = { 'N/A' }
		end

		viewData.randomizeOptionCount = #viewData.randomizeOptionList
		viewData.randomizeOptionIndex = viewData.randomizeOptionCount - 1

		-- Item Crafting

		if tweak.entryMeta.craft then
			tweak.itemCanBeCrafted = true

			if tweak.entryMeta.craft == true then
				tweak.itemRecipeId = tweak.entryMeta.type
			else
				tweak.itemRecipeId = tweak.entryMeta.craft
			end

			tweak.itemRecipeKnown = respector:usingModule('crafting', function(craftingModule)
				return craftingModule:isRecipeKnown(tweak.itemRecipeId)
			end)
		else
			tweak.itemCanBeCrafted = false
			tweak.itemRecipeId = nil
			tweak.itemRecipeKnown = false
		end

		-- Item View Data

		if tweak.itemCanBeUpgraded then
			viewData.qualityOptionList = Quality.upTo(tweak.itemQuality)
		else
			viewData.qualityOptionList = { tweak.itemQuality }
		end

		viewData.qualityOptionCount = #viewData.qualityOptionList
		viewData.qualityOptionIndex = viewData.qualityOptionCount - 1

		if tweak.itemCanBeMarked then
			viewData.questOptionList = { 'Yes', 'No' }
		else
			viewData.questOptionList = { 'N/A' }
		end

		viewData.questOptionCount = #viewData.questOptionList
		viewData.questOptionIndex = tweak.itemQuestMark and 0 or 1
	end
end

function tweaksGui.onSpawnItemClick()
	local tweak = viewData.activeTweakData

	local itemSpec = {
		id = tweak.entryMeta.type,
		upgrade = tweak.itemQuality,
		qty = tweak.itemQty
	}

	if tweak.itemMaxSlots == true then
		itemSpec.slots = 'max'
	end

	if tweak.itemQuestMark == false then
		itemSpec.quest = false
	end

	if tweak.itemEquipSlot ~= 0 then
		itemSpec.equip = tweak.itemEquipSlot
	end

	respector:execSpec({ Inventory = { itemSpec } }, userState.specOptions)
end

function tweaksGui.onUnlockRecipeClick()
	local tweak = viewData.activeTweakData

	respector:usingModule('crafting', function(craftingModule)
		craftingModule:addRecipe(tweak.itemRecipeId)
	end)

	tweak.itemRecipeKnown = true
end

function tweaksGui.onUnlockVehicleClick()
	local tweak = viewData.activeTweakData

	respector:usingModule('transport', function(transportModule)
		return transportModule:unlockVehicle(tweak.entryMeta.type)
	end)

	tweak.vehicleUnlocked = true
end

function tweaksGui.onSpawnVehicleClick()
	local tweak = viewData.activeTweakData

	tweaker:execHack('SpawnVehicle', tweak.entryMeta.type)
end

function tweaksGui.onTransferGoodsClick()
	local tweak = viewData.activeTweakData

	tweaksGui.addItemAmount(tweak.entryMeta.kind, tweak.entryMeta.type, tweak.transferAmount)

	tweak.currentAmount = tweaksGui.getItemAmount(tweak.entryMeta.kind, tweak.entryMeta.type)
end

function tweaksGui.onSwitchFactClick()
	local tweak = viewData.activeTweakData

	tweak.factState = not tweak.factState

	tweaksGui.setFactState(tweak.entryMeta.type, tweak.factState)
end

function tweaksGui.onExecuteHackClick()
	local tweak = viewData.activeTweakData

	tweaker:execHack(tweak.entryMeta.type)
end

function tweaksGui.onToggleTweaker()
	userState.showTweaker = not userState.showTweaker
	viewData.justOpened = userState.showTweaker

	persitentState:flush()
end

function tweaksGui.getItemAmount(itemKind, itemId)
	if itemKind == 'Ammo' then
		itemId = TweakDb.toItemId(TweakDb.toTweakId(itemId), false)
	else
		itemId = TweakDb.toItemId(itemId, false)
	end

	return Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), itemId)
end

function tweaksGui.addItemAmount(itemKind, itemId, itemAmount)
	if itemKind == 'Ammo' then
		itemId = TweakDb.toItemId(TweakDb.toTweakId(itemId), false)
	else
		itemId = TweakDb.toItemId(itemId, false)
	end

	Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), itemId, itemAmount)
end

function tweaksGui.getFactState(factName)
	return Game.GetQuestsSystem():GetFactStr(factName) == 1
end

function tweaksGui.setFactState(factName, state)
	Game.GetQuestsSystem():SetFactStr(factName, state and 1 or 0)
end

return tweaksGui
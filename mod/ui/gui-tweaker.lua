local mod = ...
local str = mod.require('mod/utils/str')
local array = mod.require('mod/utils/array')
local Quality = mod.require('mod/enums/Quality')
local TweakDb = mod.require('mod/helpers/TweakDb')

local tweaker = {}

local respector
local tweakDb
local persitentState

local windowWidth = 440
local windowHeightShort = 152
local windowHeightFull = 426
local windowPadding = 7.5
local footerHeight = 32
local openKey

local viewData = {
	justOpened = true,

	tweakSearch = nil,
	tweakSearchMaxLen = 32,
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
}

local userState = {
	showTweaker = nil,
	expandTweaker = nil,
	tweakSearch = nil,
}

function tweaker.init(_respector, _userState, _persitentState)
	respector = _respector
	userState = _userState
	persitentState = _persitentState

	tweakDb = TweakDb:new()

	tweaker.initHotkeys()
	tweaker.initState()
end

function tweaker.initHotkeys()
	openKey = mod.config.openTweakerKey or 0x7B -- F12
end

function tweaker.initState(force)
	if not userState.tweakSearch or force then
		userState.showTweaker = false
		userState.expandTweaker = true
	--	viewData.tweakSearch = str.padnul('', viewData.tweakSearchMaxLen)
	--else
	--	viewData.tweakSearch = userState.tweakSearch
	end

	-- Trigger search
	userState.tweakSearch = ''

	viewData.tweakSearch = str.padnul('', viewData.tweakSearchMaxLen)
	viewData.tweakSearchStarted = false

	viewData.tweakSearchResults = {}
	viewData.tweakSearchPreviews = {}

	viewData.activeTweakIndex = -1
	viewData.activeTweakData = nil
end

function tweaker.onUpdateEvent()
	if ImGui.IsKeyPressed(openKey, false) then
		tweaker.onQuickButtonClick()
	end
end

function tweaker.onDrawEvent()
	if not userState.showTweaker then -- or not userState.showWindow
		return
	end

	local windowHeight = viewData.activeTweakData and windowHeightFull or windowHeightShort

	ImGui.SetNextWindowPos(365, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(windowWidth + (windowPadding * 2), windowHeight)
	--ImGui.SetNextWindowCollapsed(false)

	userState.showTweaker, userState.expandTweaker = ImGui.Begin('Quick Tweaks', userState.showTweaker, ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoScrollbar | ImGuiWindowFlags.NoScrollWithMouse)

	if userState.showTweaker and userState.expandTweaker then

		if viewData.justOpened then
			ImGui.SetKeyboardFocusHere()
			viewData.justOpened = false
		end

		ImGui.SetNextItemWidth(windowWidth)
		ImGui.PushStyleColor(ImGuiCol.TextDisabled, 0xffaaaaaa)
		viewData.tweakSearch = ImGui.InputTextWithHint('##TweakSearch', 'Search database...', viewData.tweakSearch, viewData.tweakSearchMaxLen)
		--ImGui.SetItemDefaultFocus(0)
		ImGui.PopStyleColor()

		if viewData.tweakSearch ~= userState.tweakSearch then
			viewData.tweakSearchResults = {}
			viewData.tweakSearchPreviews = {}
			viewData.activeTweakIndex = -1
			viewData.activeTweakData = nil

			userState.tweakSearch = viewData.tweakSearch

			tweaker.onTweakSearchChange()
		end

		ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
		ImGui.PushStyleColor(ImGuiCol.Border, 0xff483f3f)
		ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0) -- 0.16, 0.29, 0.48, 0.1

		if #viewData.tweakSearchResults > 0 then
			ImGui.SetNextItemWidth(windowWidth)
			local tweakIndex, tweakChanged = ImGui.ListBox('##TweakSearchResults', viewData.activeTweakIndex, viewData.tweakSearchPreviews, #viewData.tweakSearchPreviews, 5)

			if tweakChanged then
				viewData.activeTweakIndex = tweakIndex
				viewData.activeTweakData = viewData.tweakSearchResults[tweakIndex + 1] or nil

				tweaker.onTweakSearchResultSelect()
			end
		else
			ImGui.BeginChildFrame(1, windowWidth, 95) -- , ImGuiWindowFlags.NoBackgroun
			ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)

			if viewData.tweakSearchStarted then
				ImGui.TextWrapped('No results for your request.')
			else
				ImGui.TextWrapped('Start typing in the search bar (at least 2 characters) to find items, vehicles, valuables, quest facts, and more.')
				ImGui.TextWrapped('Then select an entry to get the available tweaks.')
			end

			ImGui.PopStyleColor()
			ImGui.EndChildFrame()
		end

		ImGui.PopStyleColor(2)
		ImGui.PopStyleVar()

		ImGui.SetCursorPos(8, 152) -- Fix for inconsistent height of ListBox

		ImGui.Separator()
		ImGui.Spacing()

		if viewData.activeTweakData then
			local tweak = viewData.activeTweakData

			ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 4, 2)

			if tweak.entryMeta.quality then
				ImGui.PushStyleColor(ImGuiCol.Text, Quality.toColor(tweak.entryMeta.quality))
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

				ImGui.PopStyleColor()
			end

			ImGui.PushStyleColor(ImGuiCol.Text, 0xffbf9f9f) -- 0xff484ae6
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
			end

			ImGui.PopStyleColor()

			if tweak.entryMeta.comment then
				ImGui.PushStyleColor(ImGuiCol.Text, 0xff484ad5) -- 0xff484ad5 0xff484ae6 0xff3c3dbd
				ImGui.TextWrapped(tweak.entryMeta.comment:gsub('%%', '%%%%'))
				ImGui.PopStyleColor()
			end

			if tweak.entryMeta.desc then
				ImGui.PushStyleColor(ImGuiCol.Text, 0xffcccccc)
				ImGui.TextWrapped(tweak.entryMeta.desc:gsub('%%', '%%%%'))
				ImGui.PopStyleColor()
			end

			ImGui.PopStyleVar()

			ImGui.Spacing()

			-- Facts
			if tweak.entryMeta.kind == 'Fact' then


				-- Vehicles
			elseif tweak.entryMeta.kind == 'Vehicle' then
				ImGui.Spacing()
				if tweak.vehicleUnlocked then
					ImGui.Text('You own this vehicle.')
				else
					ImGui.Text('You don\'t own this vehicle yet.')
					ImGui.Spacing()

					if ImGui.Button('Add to garage', windowWidth, 21) then
						tweaker.onUnlockVehicleClick()
					end
				end

				-- Money / Ingredients
			elseif tweak.entryMeta.kind == 'Money' or tweak.entryMeta.kind == 'Component' then
				local halfWidth = windowWidth / 2 - 4

				ImGui.BeginGroup()
				ImGui.Spacing()
				ImGui.Text(tweak.isMoney and 'Transaction amount:' or 'Transaction amount:')
				ImGui.SetNextItemWidth(halfWidth)
				tweak.transferAmount = ImGui.InputInt('##TransferAmount', tweak.transferAmount)
				ImGui.EndGroup()

				ImGui.SameLine()
				ImGui.BeginGroup()
				ImGui.Text(tweak.isMoney and 'Current balance:' or 'In backpack:')
				ImGui.SetNextItemWidth(halfWidth)
				ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0.25)
				ImGui.InputText('##CurrentAmount', tostring(tweak.currentAmount), 512, ImGuiInputTextFlags.ReadOnly)
				ImGui.PopStyleColor()
				ImGui.EndGroup()

				ImGui.Spacing()

				if ImGui.Button(tweak.isMoney and 'Transfer money' or 'Acquire components', windowWidth, 21) then
					tweaker.onTransferGoodsClick()
				end

				-- Items
			else
				ImGui.BeginGroup()
				ImGui.Spacing()
				ImGui.Text('Qty:')
				ImGui.SetNextItemWidth(138)
				tweak.itemQty = ImGui.InputInt('##ItemQty', tweak.itemQty or 1)
				ImGui.EndGroup()

				ImGui.SameLine()
				ImGui.BeginGroup()
				ImGui.Text('Quality:')
				ImGui.SetNextItemWidth(168)
				if tweak.itemCanBeUpgraded then
					local optionIndex, optionChanged = ImGui.Combo('##ItemQuality', viewData.qualityOptionIndex, viewData.qualityOptionList, viewData.qualityOptionCount)
					if optionChanged then
						tweak.itemQuality = viewData.qualityOptionList[optionIndex + 1]
						viewData.qualityOptionIndex = optionIndex
					end
				else
					ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0.25)
					ImGui.InputText('##ItemQualityFixed', tweak.entryMeta.quality, 512, ImGuiInputTextFlags.ReadOnly)
					ImGui.PopStyleColor()
				end
				ImGui.EndGroup()

				ImGui.SameLine()
				ImGui.BeginGroup()
				ImGui.Text('Quest mark:')
				ImGui.SetNextItemWidth(118)
				if tweak.itemCanBeMarked then
					local optionIndex, optionChanged = ImGui.Combo('##ItemQuest', viewData.questOptionIndex, viewData.questOptionList, viewData.questOptionCount)
					if optionChanged then
						tweak.itemQuestMark = viewData.questOptionList[optionIndex + 1] == 'YES'
						viewData.questOptionIndex = optionIndex
					end
				else
					ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.16, 0.29, 0.48, 0.25)
					ImGui.InputText('##ItemQuestFixed', 'N/A', 512, ImGuiInputTextFlags.ReadOnly)
					ImGui.PopStyleColor()
				end
				ImGui.EndGroup()

				ImGui.Spacing()

				if ImGui.Button('Add to inventory', windowWidth, 21) then
					tweaker.onSpawnItemClick()
				end

				if tweak.itemCanBeCrafted then
					ImGui.Spacing()
					ImGui.Spacing()

					if tweak.itemRecipeKnown then
						ImGui.Text('You have crafting recipe for this item.')
					else
						ImGui.Text('This item can be crafted.')
						ImGui.Spacing()

						if ImGui.Button('Get crafting recipe', windowWidth, 21) then
							tweaker.onUnlockRecipeClick()
						end
					end
				end
			end

			local cursorX, _ = ImGui.GetCursorPos()
			ImGui.SetCursorPos(cursorX, windowHeight - footerHeight)

			ImGui.Spacing()
			ImGui.Separator()

			ImGui.AlignTextToFramePadding()

			ImGui.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGui.PushStyleColor(ImGuiCol.Text, 0xff555555)
			--ImGui.PushStyleColor(ImGuiCol.Border, 0xff483f3f)
			--ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
			ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 0)
			ImGui.Text('ID:')
			ImGui.SameLine()
			ImGui.SetNextItemWidth(296)
			ImGui.InputText('##Tweak Hash Name', tweak.entryMeta.type or 'N/A', 512, ImGuiInputTextFlags.ReadOnly)
			ImGui.PopStyleVar()
			ImGui.SameLine()
			ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 2, 0)
			ImGui.Text('Hash:')
			ImGui.SameLine()
			ImGui.SetNextItemWidth(78)
			ImGui.InputText('##Tweak Hash Key', tweak.entryHash, 16, ImGuiInputTextFlags.ReadOnly)
			ImGui.PopStyleVar()
			ImGui.PopStyleColor(2)
		end
	end

	ImGui.End()
end

function tweaker.onTweakSearchChange()
	--persitentState:flush()

	local searchTerm = str.stripnul(userState.tweakSearch)

	if searchTerm:len() < 2 then
		viewData.tweakSearchStarted = false
		return
	end

	viewData.tweakSearchStarted = true

	tweakDb:load('mod/data/tweakdb-meta')

	local searchResults = {}

	for entryKey, entryMeta, entryPos in tweakDb:search(searchTerm) do
		if entryMeta.name and entryMeta.kind ~= 'Slot' then
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
			entryHash = ('%010X'):format(result.entryKey),
		}
	end)

	viewData.tweakSearchPreviews = array.map(searchResults, function(result)
		return tweakDb:describe(result.entryMeta, true, false, 25)
	end)
end

function tweaker.onTweakSearchResultSelect()
	local tweak = viewData.activeTweakData

	if tweak.entryMeta.kind == 'Fact' then

	elseif tweak.entryMeta.kind == 'Vehicle' then
		tweak.vehicleUnlocked = respector:usingModule('transport', function(transportModule)
			return transportModule:isVehicleUnlocked(tweak.entryMeta.type)
		end)

	elseif tweak.entryMeta.kind == 'Money' or tweak.entryMeta.kind == 'Component' then
		tweak.isMoney = tweak.entryMeta.kind == 'Money'
		tweak.transferAmount = tweak.isMoney and 100000 or 1000
		tweak.currentAmount = tweaker.getItemAmount(tweak.entryMeta.type)

	else
		-- Item Quantity

		tweak.itemQty = 1

		-- Item Quality

		if tweak.entryMeta.quality then
			tweak.itemCanBeUpgraded = false
			tweak.itemQuality = tweak.entryMeta.quality
		else
			tweak.itemCanBeUpgraded = true

			-- Set max quality by default
			if tweakDb:match(tweak.entryMeta, { kind = 'Mod', group = { 'Clothing', 'Ranged', 'Scope' } }) then
				tweak.itemQuality = 'Epic'
			else
				tweak.itemQuality = 'Legendary'
			end
		end

		-- Item Quest Mark

		if tweak.entryMeta.quest then
			tweak.itemCanBeMarked = true
			tweak.itemQuestMark = true
		else
			tweak.itemCanBeMarked = false
			tweak.itemQuestMark = false
		end

		-- Item Crafting

		if tweak.entryMeta.craft then
			tweak.itemCanBeCrafted = true

			if tweak.entryMeta.craft == true then
				tweak.itemRecipeId = tweak.entryMeta.type
			else
				tweak.itemRecipeId = tweak.entryMeta.craft
			end

			tweak.itemRecipeKnown = respector:usingModule('crafting', function(craftingModule)
				return craftingModule:isRecipeKnown(craftableId)
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
		viewData.questOptionIndex = 0
	end
end

function tweaker.onSpawnItemClick()
	local tweak = viewData.activeTweakData

	local itemSpec = {
		id = tweak.entryMeta.type,
		upgrade = tweak.itemQuality,
		qty = tweak.itemQty
	}

	if not tweak.itemQuestMark then
		itemSpec.quest = false
	end

	respector:applySpecData({ Backpack = { itemSpec } })
end

function tweaker.onUnlockRecipeClick()
	local tweak = viewData.activeTweakData

	respector:usingModule('crafting', function(craftingModule)
		craftingModule:addRecipe(tweak.itemRecipeId)
	end)

	tweak.itemRecipeKnown = true
end

function tweaker.onUnlockVehicleClick()
	local tweak = viewData.activeTweakData

	respector:usingModule('transport', function(transportModule)
		return transportModule:unlockVehicle(tweak.entryMeta.type)
	end)

	tweak.vehicleUnlocked = true
end

function tweaker.onTransferGoodsClick()
	local tweak = viewData.activeTweakData

	tweaker.addItemAmount(tweak.entryMeta.type, tweak.transferAmount)

	tweak.currentAmount = tweaker.getItemAmount(tweak.entryMeta.type)
end

function tweaker.onQuickButtonClick()
	userState.showTweaker = not userState.showTweaker
	viewData.justOpened = userState.showTweaker

	persitentState:flush()
end

function tweaker.getItemAmount(itemId)
	itemId = TweakDb.toItemId(itemId, false)

	return Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), itemId)
end

function tweaker.addItemAmount(itemId, itemAmount)
	itemId = TweakDb.toItemId(itemId, false)

	Game.GetTransactionSystem():GiveItem(Game.GetPlayer(), itemId, itemAmount)
end

return tweaker
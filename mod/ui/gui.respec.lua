local mod = ...
local ImGuiX = mod.require('mod/ui/imguix')

local respecGui = {}

local respector, viewData, userState

function respecGui.init(_respector, _viewData, _userState)
	respector = _respector
	viewData = _viewData
	userState = _userState

	respecGui.initViewState()
end

function respecGui.initViewData()
	viewData.respecAttrGroupWidth = viewData.gridOneThirdWidth
	viewData.respecAttrGroupHeight = 46 * viewData.viewScaleY
	viewData.respecAttrInputWidth = 70 * viewData.viewScaleX

	viewData.respecAttrs = {
		{ attr = 'Body', label = 'Body', offsetX = 0 },
		{ attr = 'Reflexes', label = 'Reflexes' },
		{ attr = 'TechnicalAbility', label = 'Tech Ability' },
		{ attr = 'Intelligence', label = 'Intelligence', offsetX = (viewData.gridOneThirdWidth + viewData.gridGutter) / 2 },
		{ attr = 'Cool', label = 'Cool' },
	}
end

function respecGui.initViewState()
	viewData.respecAttrsActive = false

	respector:usingModule('character', function(character)
		viewData.respecAttrsData = character:getAttributeLevels()
		viewData.respecAttrPoints = character:getAttributeEarnedPoints(userState.cheatMode)
	end)
end

-- GUI Event Handlers

function respecGui.onDrawEvent(justOpened)
	if justOpened then
		respecGui.initViewData()
		respecGui.initViewState()
	end

	ImGui.Spacing()

	-- Reset Perks
	ImGui.Text('Reset Perks')
	ImGuiX.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
	ImGui.TextWrapped('Restore all spent Perk Points, allowing you to redistribute them. Has the same effect as from buying the TABULA E-RASA shard.')
	ImGuiX.PopStyleColor()
	ImGui.Spacing()

	if ImGui.Button('Reset Perks', viewData.gridFullWidth, viewData.buttonHeight) then
		respecGui.onResetPerksClick()
	end

	ImGui.Spacing()
	ImGui.Separator()
	ImGui.Spacing()

	-- Respec Attributes
	ImGui.Text('Respec Attributes')
	ImGuiX.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
	ImGui.TextWrapped('Adjust Attributes levels. Lowering an Attribute will lower corresponding Skills and reset Perks, which requirements are no longer met.')
	ImGuiX.PopStyleColor()

	local respecAttrUnusedPoints = viewData.respecAttrPoints

	for _, respecAttr in ipairs(viewData.respecAttrs) do
		local attrLevel = viewData.respecAttrsData[respecAttr.attr]

		respecAttrUnusedPoints = respecAttrUnusedPoints - attrLevel
	end

	ImGui.Spacing()

	local attrPointsText = ('Attribute Points: %-2d'):format(respecAttrUnusedPoints)
	local attrPointsTextWidth = ImGui.CalcTextSize(attrPointsText)

	ImGui.SetCursorPos(viewData.windowOffsetX + (viewData.gridFullWidth / 2) - (attrPointsTextWidth / 2), ImGui.GetCursorPosY())
	ImGui.Text(attrPointsText)

	for i, respecAttr in ipairs(viewData.respecAttrs) do
		local attrLevel = viewData.respecAttrsData[respecAttr.attr]
		local labelWidth = ImGui.CalcTextSize(respecAttr.label)
		local valueWidth = viewData.respecAttrsActive and viewData.respecAttrInputWidth or (ImGui.CalcTextSize(tostring(attrLevel)) + 8)

		if respecAttr.offsetX then
			ImGui.Spacing()
			ImGui.SetCursorPos(viewData.windowOffsetX + respecAttr.offsetX, ImGui.GetCursorPosY())
		else
			ImGui.SameLine()
		end

		ImGui.BeginGroup()
		ImGuiX.PushStyleVar(ImGuiStyleVar.FrameRounding, 8)
		ImGuiX.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 2 * viewData.viewScaleY)
		ImGui.BeginChildFrame(i, viewData.respecAttrGroupWidth, viewData.respecAttrGroupHeight)
		ImGuiX.PopStyleVar(2)

		ImGui.Spacing()

		ImGui.SetCursorPos((viewData.respecAttrGroupWidth / 2) - (labelWidth / 2), ImGui.GetCursorPosY())
		ImGui.Text(respecAttr.label)

		ImGui.SetCursorPos((viewData.respecAttrGroupWidth / 2) - (valueWidth / 2), ImGui.GetCursorPosY())
		ImGui.SetNextItemWidth(valueWidth)
		ImGuiX.PushStyleColor(ImGuiCol.FrameBg, 0)
		if viewData.respecAttrsActive then
			local attrNewLevel, attrChanged = ImGui.InputInt('##Respec' .. respecAttr.attr, attrLevel, 1, 3)

			if attrChanged and attrNewLevel ~= attrLevel then
				if attrNewLevel - attrLevel > respecAttrUnusedPoints then
					attrNewLevel = attrLevel + respecAttrUnusedPoints
					ImGui.SetWindowFocus()
				end

				attrNewLevel = math.max(attrNewLevel, 3)
				attrNewLevel = math.min(attrNewLevel, 20)

				viewData.respecAttrsData[respecAttr.attr] = attrNewLevel
			end
		else
			ImGui.InputText('##Respec' .. respecAttr.attr, tostring(attrLevel), 2, ImGuiInputTextFlags.ReadOnly)
		end
		ImGuiX.PopStyleColor()

		ImGui.EndChildFrame()
		ImGui.EndGroup()
	end

	ImGui.Spacing()

	if viewData.respecAttrsActive then
		ImGuiX.PushStyleColor(ImGuiCol.Button, 0xaa60ae27)
		ImGuiX.PushStyleColor(ImGuiCol.ButtonHovered, 0xee60ae27)
		if ImGui.Button('Save Attributes', viewData.gridHalfWidth, viewData.buttonHeight) then
			respecGui.onSaveAttrsClick()
		end
		ImGuiX.PopStyleColor(2)

		ImGui.SameLine()

		ImGuiX.PushStyleColor(ImGuiCol.Button, 0xaa3c4ce7)
		ImGuiX.PushStyleColor(ImGuiCol.ButtonHovered, 0xee3c4ce7)
		if ImGui.Button('Discard Changes', viewData.gridHalfWidth, viewData.buttonHeight) then
			respecGui.onDiscardAttrsClick()
		end
		ImGuiX.PopStyleColor(2)
	else
		if ImGui.Button('Respec Attributes', viewData.gridFullWidth, viewData.buttonHeight) then
			respecGui.onRespecAttrsClick()
		end
	end
end

-- GUI Action Handlers

function respecGui.onResetPerksClick()
	respector:execSpec({ Character = { Perks = {} }	}, userState.specOptions)
end

function respecGui.onRespecAttrsClick()
	respecGui.initViewState()

	viewData.respecAttrsActive = true
end

function respecGui.onSaveAttrsClick()
	respector:execSpec({ Character = { Attributes = viewData.respecAttrsData } }, userState.specOptions)

	viewData.respecAttrsActive = false
end

function respecGui.onDiscardAttrsClick()
	respecGui.initViewState()
end

return respecGui
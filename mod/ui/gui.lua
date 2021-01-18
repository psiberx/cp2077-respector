local mod = ...
local str = mod.require('mod/utils/str')

local gui = {}

local respector

local drawWindow = false
local maxInputLen = 256
local openKey = 0x70
local saveKey = 0x71

local itemFormatList = { 'auto', 'hash' }
local keepSeedList = { 'auto', 'always' }
local textOptions = { ['specsDir'] = 'specs/', ['defaultSpec'] = 'V' }
local keyCodes = mod.load('mod/data/virtual-key-codes')

local inputData = {
	specNameSave = '',
	specNameLoad = '',

	specOptions = {},

	globalOptions = {},

	itemFormatIndex = 0,
	itemFormatList = 'Auto (use name if possible)\0Hash (always use hash value)\0',
	itemFormatCount = #itemFormatList,

	keepSeedIndex = 0,
	keepSeedList = 'Auto (only if necessary)\0Always (keep for all items)\0',
	keepSeedCount = #keepSeedList,

	openKeyIndex = 0,
	saveKeyIndex = 0,
	keyCodeList = '',
	keyCodeCount = #keyCodes,
}

function gui.init(_respector)
	if mod.debug then
		print(('[DEBUG] Respector: Initializing GUI.'))
	end

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

	for index, option in ipairs(itemFormatList) do
		if option == inputData.globalOptions.itemFormat then
			inputData.itemFormatIndex = index - 1
			break
		end
	end

	for index, option in ipairs(keepSeedList) do
		if option == inputData.globalOptions.keepSeed then
			inputData.keepSeedIndex = index - 1
			break
		end
	end

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

function gui.onOverlayOpen()
	drawWindow = true
end

function gui.onOverlayClose()
	drawWindow = false
end

function gui.onUpdate()
	if ImGui.IsKeyPressed(openKey, false) then
		drawWindow = not drawWindow
	end

	if ImGui.IsKeyPressed(saveKey, false) then
		gui.saveSnap()
	end
end

function gui.onDraw()
	if not drawWindow then
		return
	end

	ImGui.SetNextWindowPos(0, 400, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(355, 294) -- 340 x 300

	ImGui.Begin('Respector', true, ImGuiWindowFlags.NoResize)
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
		inputData.specOptions.timestamp = ImGui.Checkbox('With timestamp (snapshot)', inputData.specOptions.timestamp)

		ImGui.Spacing()
		ImGui.Separator()
		ImGui.Spacing()

		-- Saving: Item Format
		ImGui.Text('Item format:')
		ImGui.PushItemWidth(233)
		inputData.itemFormatIndex = ImGui.Combo('##Item Format', inputData.itemFormatIndex, inputData.itemFormatList, inputData.itemFormatCount)
		inputData.specOptions.itemFormat = itemFormatList[inputData.itemFormatIndex + 1]

		ImGui.Spacing()

		-- Saving: Keep Seed
		ImGui.Text('Keep seed:')
		ImGui.PushItemWidth(233)
		inputData.keepSeedIndex = ImGui.Combo('##Keep Seed', inputData.keepSeedIndex, inputData.keepSeedList, inputData.keepSeedCount)
		inputData.specOptions.keepSeed = keepSeedList[inputData.keepSeedIndex + 1]

		ImGui.Spacing()

		-- Saving: Export Crafting Components
		inputData.specOptions.exportComponents = ImGui.Checkbox('Export crafting components', inputData.specOptions.exportComponents)

		-- Saving: Export Crafting Recipes
		inputData.specOptions.exportRecipes = ImGui.Checkbox('Export crafting recipes', inputData.specOptions.exportRecipes)

		-- Saving: Export All Perks
		inputData.specOptions.exportAllPerks = ImGui.Checkbox('Export all perks', inputData.specOptions.exportAllPerks)

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
		local lastSpecIndex = ImGui.ListBox('##Load Recent Specs', -1, respector.recentSpecsInfo, #respector.recentSpecsInfo, 9)
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

return gui
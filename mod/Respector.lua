local mod = ...

local Respector = { version = '0.9.5' }
Respector.__index = Respector

local asyncWait = false

local components = {
	modules = {
		{ name = 'character', source = 'mod/modules/Character' },
		{ name = 'inventory', source = 'mod/modules/Inventory' .. (mod.env.is183() and '183' or '') },
		{ name = 'crafting', source = 'mod/modules/Crafting' },
		{ name = 'transport', source = 'mod/modules/Transport' },
	},
	stores = {
		{ name = 'specStore', source = 'mod/stores/SpecStore' },
	}
}

function Respector:new()
	local this = { eventHandlers = {} }

	setmetatable(this, self)

	this:loadComponents()

	return this
end

function Respector:loadComponents()
	for _, componentList in pairs(components) do
		for _, component in ipairs(componentList) do
			if mod.debug then
				print(('[DEBUG] Respector: Loading %q component...'):format(component.name))
			end

			local componentType = mod.require(component.source)

			if componentType then
				self[component.name] = componentType:new()
			end
		end
	end
end

function Respector:prepareModules()
	for _, module in ipairs(components.modules) do
		self[module.name]:prepare()
	end
end

function Respector:releaseModules()
	for _, module in ipairs(components.modules) do
		self[module.name]:release()
	end
end

function Respector:releaseModulesAsync(waitTime)
	asyncWait = true

	if not waitTime then
		waitTime = 1.0
	end

	mod.defer(waitTime, function()
		self:releaseModules()

		asyncWait = false
	end)
end

function Respector:saveSpec(specName, specOptions)
	print() -- hotfix: Temporary fix for CET 1.8.4

	if asyncWait then
		return false
	end

	specOptions = self:getSpecOptions(specOptions)

	self:prepareModules()

	local specData = {}

	for _, module in ipairs(components.modules) do
		if mod.debug then
			print(('[DEBUG] Respector: Filling spec using %q module...'):format(module.name))
		end

		self[module.name]:fillSpec(specData, specOptions)
	end

	self:releaseModulesAsync(1.5)

	if not specData then
		print(('Respector: Failed to create spec.'))
		return false
	end

	local success, specName = self.specStore:writeSpec(specName, specData, specOptions.timestamp)

	if success then
		self:triggerEvent('save', specName)

		print(('Respector: Spec %q saved.'):format(specName))
	else
		print(('Respector: Failed to save %q spec.'):format(specName))
	end

	return success
end

function Respector:loadSpec(specName)
	print() -- hotfix: Temporary fix for CET 1.8.4

	if asyncWait then
		return false
	end

	local specData, specName = self.specStore:readSpec(specName)

	if not specData then
		print(('Respector: Can\'t load %q spec.'):format(specName))
		return false
	end

	self:prepareModules()

	for _, module in ipairs(components.modules) do
		if mod.debug then
			print(('[DEBUG] Respector: Applying spec using %q module...'):format(module.name))
		end

		self[module.name]:applySpec(specData)
	end

	self:releaseModulesAsync()

	self:triggerEvent('load', specName)

	print(('Respector: Spec %q loaded.'):format(specName))

	return true
end

function Respector:getSpecOptions(specOptions)
	if not specOptions then
		specOptions = {}
	elseif specOptions == true then
		specOptions = { timestamp = true }
	end

	for optionName, optionDefault in pairs(mod.config.defaultOptions) do
		if specOptions[optionName] == nil then
			specOptions[optionName] = optionDefault
		end
	end

	return specOptions
end

function Respector:addEventHandler(handler)
	table.insert(self.eventHandlers, handler)
end

function Respector:triggerEvent(event, specName)
	if #self.eventHandlers > 0 then
		local eventData = {
			event = event,
			time = os.date('%d.%m.%Y %H:%M'),
			specName = specName,
		}

		for _, eventHandler in ipairs(self.eventHandlers) do
			eventHandler(eventData)
		end
	end
end

return Respector
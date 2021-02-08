local mod = ...
local export = mod.require('mod/utils/export')

local PersistentState = {}
PersistentState.__index = PersistentState

function PersistentState:new(path)
	local this = { path = nil, state = nil }

	setmetatable(this, self)

	if path then
		this:load(path)
	end

	return this
end

function PersistentState:load(path)
	self.path = mod.path(path)
	self.state = mod.load(path)

	if mod.debug then
		print(('[DEBUG] Respector: Initialized persitent state %q.'):format(self.path))
	end
end

function PersistentState:unload()
	self.state = nil
end

function PersistentState:isEmpty()
	return self.state == nil
end

function PersistentState:setState(state)
	self.state = state
end

function PersistentState:getState(prop)
	return prop and self.state[prop] or self.state
end

function PersistentState:flush()
	local stateFile = io.open(self.path, 'w')

	if stateFile ~= nil then
		stateFile:write('return ' .. export.table(self.state))
		stateFile:close()

		if mod.debug then
			print(('[DEBUG] Respector: Updated persitent state %q.'):format(self.path))
		end
	else
		if mod.debug then
			print(('[DEBUG] Respector: Failed to update persitent state %q.'):format(self.path))
		end
	end
end

return PersistentState
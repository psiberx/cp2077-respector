local mod = ...

local Tweaker = {}
Tweaker.__index = Tweaker

function Tweaker:new(respector)
	local this = { respector = respector }

	setmetatable(this, self)

	return this
end

function Tweaker:execHack(tweakName, ...)
	local tweakFunc = mod.load('mod/hacks/' .. tweakName)

	if type(tweakFunc) == 'function' then
		tweakFunc(select(1, ...))
	end
end

return Tweaker
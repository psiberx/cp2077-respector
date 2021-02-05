local mod = ...

local perks = mod.load('mod/data/perks')
local indexed = {}

for _, perk in ipairs(perks) do
	indexed[perk.alias] = perk
end

return indexed
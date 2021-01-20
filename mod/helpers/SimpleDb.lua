local mod = ...

local SimpleDb = {}
SimpleDb.__index = SimpleDb

function SimpleDb:new(path)
	local this = {}

	setmetatable(this, self)

	if path then
		this:load(path)
	end

	return this
end

function SimpleDb:load(path)
	self.db = mod.load(path)
end

function SimpleDb:unload()
	self.db = nil
end

function SimpleDb:get(index)
	return self.db and self.db[index] or nil
end

function SimpleDb:has(index)
	return self.db[index] ~= nil
end

function SimpleDb:each()
	return pairs(self.db)
end

function SimpleDb:find(criteria)
	local key, item

	while true do
		key, item = next(self.db, key)

		if item == nil then
			return nil
		end

		local match = self:match(item, criteria)

		if match then
			return item
		end
	end
end

function SimpleDb:filter(criteria)
	local key, item

	return function()
		while true do
			key, item = next(self.db, key)

			if item == nil then
				return nil
			end

			local match = self:match(item, criteria)

			if match then
				return item
			end
		end
	end
end

function SimpleDb:filtered(criteria)
	local result = {}

	for _, item in pairs(self.db) do
		if self:match(item, criteria) then
			table.insert(result, item)
		end
	end

	return result
end

function SimpleDb:match(item, criteria)
	local match = true

	for field, condition in pairs(criteria) do
		if type(condition) == 'table' then
			match = false
			for _, value in ipairs(condition) do
				if item[field] == value then
					match = true
					break
				end
			end
		elseif type(condition) == 'boolean' then
			if (item[field] and true or false) ~= condition then
				match = false
				break
			end
		else
			if item[field] ~= condition then
				match = false
				break
			end
		end
	end

	return match
end

return SimpleDb
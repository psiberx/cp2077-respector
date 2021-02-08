local mod = ...

local SimpleDb = {}
SimpleDb.__index = SimpleDb

local shared = {}

function SimpleDb:new(path, key)
	local this = {
		path = nil,
		key = nil,
		data = nil,
		indexed = nil,
	}

	setmetatable(this, self)

	if path then
		this:load(path, key)
	end

	return this
end

function SimpleDb:load(path, key)
	if path == self.path then
		return
	end

	if self.path ~= nil then
		self:unload()
	end

	self.path = path

	if not shared[self.path] then
		shared[self.path] = {
			data = mod.load(path),
			refs = 1
		}
	else
		shared[self.path].refs = shared[self.path].refs + 1
	end

	self.data = shared[self.path].data

	if key then
		self:index(key)
	end

	if mod.debug then
		print(('[DEBUG] Respector: Shared DB %q used by %d client(s).'):format(self.path, shared[self.path].refs))
	end
end

function SimpleDb:index(key)
	self.key = key
	self.indexed = {}

	for _, item in pairs(self.data) do
		self.indexed[item[key]] = item
	end
end

function SimpleDb:unload()
	if shared[self.path] then
		shared[self.path].refs = shared[self.path].refs - 1

		if shared[self.path].refs < 1 then
			shared[self.path] = nil
		end
	end

	if mod.debug then
		if shared[self.path] then
			print(('[DEBUG] Respector: Shared DB %q used by %d client(s).'):format(self.path, shared[self.path].refs))
		else
			print(('[DEBUG] Respector: Shared DB %q disposed.'):format(self.path))
		end
	end

	self.path = nil
	self.data = nil
	self.key = nil
	self.indexed = nil
end

function SimpleDb:get(key)
	return self.data[key] or self.indexed[key]
end

function SimpleDb:has(key)
	return self.data[key] ~= nil or self.indexed[key] ~= nil
end

function SimpleDb:each()
	return pairs(self.data)
end

function SimpleDb:find(criteria)
	local key, item

	while true do
		key, item = next(self.data, key)

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
			key, item = next(self.data, key)

			if item == nil then
				return nil
			end

			local match = self:match(item, criteria)

			if match then
				return key, item
			end
		end
	end
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

function SimpleDb:search(term, schema)
	term = term:upper()

	local termEsc = term:gsub('([^%w])', '%%%1')
	local termRe = termEsc:gsub('%s+', '.* ') .. '.*'

	local key, item

	return function()
		while true do
			key, item = next(self.data, key)

			if item == nil then
				return nil
			end

			for _, param in ipairs(schema) do
				if item[param.field] then
					local value = item[param.field]:upper()

					if term == value then
						return key, item, param.weight
					end
				end
			end

			for _, param in ipairs(schema) do
				if item[param.field] then
					local value = item[param.field]:upper()
					local position = value:find(termEsc)

					if not position then
						position = value:find(termRe)
					end

					if position then
						return key, item, position * param.weight
					end
				end
			end
		end
	end
end

function SimpleDb:sort(items, field)
	table.sort(items, function(a, b)
		if field then
			return a[field] < b[field]
		end

		return a < b
	end)
end

function SimpleDb:limit(items, limit)
	while #items > limit do
		table.remove(items)
	end
end

function SimpleDb.unloadAll()
	-- Not eloquent but ok for now
	shared = {}
end

return SimpleDb
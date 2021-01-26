local mod = ...

local SimpleDb = {}
SimpleDb.__index = SimpleDb

local shared = {}

function SimpleDb:new(path)
	local this = { path = nil, db = nil }

	setmetatable(this, self)

	if path then
		this:load(path)
	end

	return this
end

function SimpleDb:load(path)
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

	self.db = shared[self.path].data

	if mod.debug then
		print(('[DEBUG] Respector: Shared DB %q used by %d client(s).'):format(self.path, shared[self.path].refs))
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

function SimpleDb:search(term, fields)
	--local dmp = mod.require('mod/vendor/diff_match_patch')
	--
	--dmp.settings({
	--	Match_Threshold = 0.1,
	--	Match_Distance = 250,
	--})

	term = term:upper()

	local termRe = term:gsub('%s+', '.* ') .. '.*'

	local key, item

	return function()
		while true do
			key, item = next(self.db, key)

			if item == nil then
				return nil
			end

			for weight, field in ipairs(fields) do
				if item[field] then
					local value = item[field]:upper()

					if term == value then
						return key, item, weight
					end
				end
			end

			for weight, field in ipairs(fields) do
				if item[field] then
					local value = item[field]:upper()
					local position = value:find(term)

					if not position then
						position = value:find(termRe)
					end

					if position then
						return key, item, position * weight
					end
				end
			end

			--if term:len() < 8 then
			--	for weight, field in ipairs(fields) do
			--		if item[field] then
			--			local value = item[field]:upper()
			--			local position = dmp.match_main(value, term, 1)
			--
			--			if position > 0 then
			--				return key, item, position * weight
			--			end
			--		end
			--	end
			--end
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
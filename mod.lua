local mod = {
	baseReq = (...) and string.gsub(({...})[1], '[/.]mod$', '') or '',
	baseDir = (...) and string.gsub(({...})[2], '/mod%.lua$', ''):gsub('\\', '/') .. '/' or '',
	config = {},
	debug = false,
}

local loaded = {}
local timers = {}
local counter = 0

function mod.init(debugMode)
	mod.debug = debugMode

	mod.configure()
end

function mod.configure()
	mod.config = mod.load('config') or {}
end

function mod.dir(path)
	local result = path

	if not result:find('[\\/]$') then
		result = result .. '/'
	end

	if not result:find('^[./]') and not result:find('^%a:') then
		result = mod.baseDir .. result
	end

	return result
end

function mod.path(path)
	local result = path

	if not result:find('[^/]%.(%w?%w?%w?%w?)$') then
		result = result .. '.lua'
	end

	if not result:find('^[./]') and not result:find('^%a:') then
		result = mod.baseDir .. result
	end

	return result
end

function mod.load(path)
	local chunk = loadfile(mod.path(path))

	return chunk and chunk(mod) or nil
end

function mod.require(path)
	if not loaded[path] then
		loaded[path] = mod.load(path)
	end

	return loaded[path]
end

---@param timeout number
---@param recurring boolean
---@param callback function
---@param data
---@return any
local function addTimer(timeout, recurring, callback, data)
	if type(timeout) ~= 'number' then
		return
	end

	if timeout <= 0 then
		return
	end

	if type(recurring) ~= 'boolean' then
		return
	end

	if type(callback) ~= 'function' then
		return
	end

	counter = counter + 1

	local timer = {
		id = counter,
		callback = callback,
		recurring = recurring,
		timeout = timeout,
		delay = timeout,
		data = data,
	}

	table.insert(timers, timer)

	return timer.id
end

---@param timeout number
---@param callback function
---@param data
---@return any
function mod.after(timeout, callback, data)
	return addTimer(timeout, false, callback, data)
end

---@param timeout number
---@param callback function
---@param data
---@return any
function mod.every(timeout, callback, data)
	return addTimer(timeout, true, callback, data)
end

---@param timerId any
---@return void
function mod.halt(timerId)
	for i, timer in ipairs(timers) do
		if timer.id == timerId then
			table.remove(timers, i)
			break
		end
	end
end

---@param delta number
---@return void
function mod.onUpdateEvent(delta)
	if #timers > 0 then
		for i, timer in ipairs(timers) do
			timer.delay = timer.delay - delta

			if timer.delay <= 0 then
				if timer.recurring then
					timer.delay = timer.delay + timer.timeout
				else
					table.remove(timers, i)
					i = i - 1
				end

				timer.callback(timer)
			end
		end
	end
end

return mod
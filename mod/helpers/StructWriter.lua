local StructWriter = {}
StructWriter.__index = StructWriter

function StructWriter:new(structSchema)
	local this = {}

	this.structSchema = structSchema

	setmetatable(this, self)

	return this
end

function StructWriter:writeStruct(structPath, structData)
	local structFile = io.open(structPath, 'w')
	
	if structFile == nil then
		return false
	end

	self:writeNodeData(structFile, self.structSchema, structData)

	io.close(structFile)
	
	return true
end

function StructWriter:writeNodeData(structFile, nodeSchema, nodeData, depth, inline, index)
	if depth == nil then
		depth = 0
	elseif depth > 32 then
		return
	end

	if nodeData == nil and nodeSchema.default ~= nil then
		nodeData = nodeSchema.default
	end

	local br = inline and ' ' or '\n'
	local indent = string.rep('\t', depth)

	local istable = type(nodeData) == 'table'
	local comment = (istable and nodeData._comment) or nodeSchema.comment

	if depth == 0 then
		if comment then
			self:writeCommentBlock(structFile, nodeSchema, nodeData, comment, indent)
			comment = nil
		end
		structFile:write('return ')
	end

	if nodeData ~= nil or nodeSchema.nullable then
		if not inline and nodeSchema.margin and (index > 1 or nodeSchema.margin == 'always') then
			structFile:write(br)
		end

		if comment and (istable or type(comment) == 'table') then
			if not inline then
				structFile:write(indent)
			end
			self:writeCommentBlock(structFile, nodeSchema, nodeData, comment, indent)
			if inline then
				structFile:write(indent)
			end
			comment = nil
		end

		if not inline then
			structFile:write(indent)
		end

		if nodeSchema.name ~= nil then
			structFile:write(nodeSchema.name)
			structFile:write(' = ')
		end

		if istable then
			structFile:write('{')
			structFile:write(br)
			if nodeSchema.children then
				local childIndex = 0
				for _, childSchema in ipairs(nodeSchema.children) do
					local childNames = { childSchema.name }
					if childSchema.aliases then
						for _, childAlias in ipairs(childSchema.aliases) do
							table.insert(childNames, childAlias)
						end
					end
					for _, childName in ipairs(childNames) do
						local childData = nodeData[childName]
						if childData ~= nil or childSchema.nullable or childSchema.default ~= nil then
							childIndex = childIndex + 1
							childSchema.name = childName
							local childInline = inline or childSchema.inline
							if not inline and childInline then
								structFile:write(indent .. '\t')
							end
							self:writeNodeData(structFile, childSchema, childData, depth + 1, childInline, childIndex)
							if not inline and childInline then
								structFile:write(br)
							end
						end
					end
					-- Restore original name
					childSchema.name = childNames[1]
				end
				if not inline then
					structFile:write(indent)

					-- fix line break if table is empty
					--if childIndex == 0 then
					--	structFile:seek('cur', -2)
					--end
				else
					-- fix trailing comma
					structFile:seek('cur', -2)
					structFile:write(br)
				end
			elseif nodeSchema.table then
				local childSchema = { children = nodeSchema.table }
				local childIndex = 0
				for _, childData in ipairs(nodeData) do
					if childData ~= nil then
						childIndex = childIndex + 1
						local childInline = (childData._inline == nil or childData._inline)
						if not inline then
							if (nodeSchema.spacing or childData._spacing) and childIndex > 1 then
								structFile:write(br)
							end
							if childInline then
								structFile:write(indent .. '\t')
							end
						end
						self:writeNodeData(structFile, childSchema, childData, depth + 1, childInline, childIndex)
						if not inline and childInline then
							structFile:write(br)
						end
					end
				end
				if not inline then
					structFile:write(indent)
				end
			else
				local childIndex = 0
				local childSchema = { format = nodeSchema.format }
				for _, childData in ipairs(nodeData) do
					if childData ~= nil then
						childIndex = childIndex + 1
						if type(childData) == 'table' then
							childSchema.comment = childData._comment
							self:writeNodeData(structFile, childSchema, childData[1], depth + 1, inline, childIndex)
						else
							self:writeNodeData(structFile, childSchema, childData, depth + 1, inline, childIndex)
						end
					end
				end
				if not inline then
					structFile:write(indent)
				end
			end
			structFile:write('}')
		elseif nodeSchema.nullable and nodeSchema.children then
			structFile:write('{}')
		else
			self:writeScalarValue(structFile, nodeSchema, nodeData)
		end

		if depth > 0 then
			structFile:write(',')
		end

		if not inline then
			local comment2 = comment or nodeSchema.comment2

			if comment2 then
				self:writeCommentAfter(structFile, nodeSchema, nodeData, comment2)
			end
		end

		if depth > 0 then
			structFile:write(br)
		end
	end
end

function StructWriter:writeScalarValue(structFile, nodeSchema, nodeData)
	if nodeSchema then
		local format
		if type(nodeSchema.format) == 'string' then
			format = nodeSchema.format
		elseif type(nodeSchema.format) == 'table' then
			format = nodeSchema.format[type(nodeData)] or nodeSchema.format.default
		end

		if format then
			structFile:write(string.format(format, nodeData))
			return
		end
	end

	if type(nodeData) == 'string' then
		structFile:write(string.format('%q', nodeData))
		return
	end

	structFile:write(tostring(nodeData))
end

function StructWriter:writeCommentBlock(structFile, nodeSchema, nodeData, comment, indent)
	if type(comment) == 'function' then
		comment = comment(nodeData, nodeSchema)
	end

	if type(comment) == 'table' then
		for i, line in ipairs(comment) do
			if i > 1 then
				structFile:write(indent)
			end
			structFile:write('-- ')
			structFile:write(line)
			structFile:write('\n')
		end
	elseif comment ~= '' then
		comment = comment:gsub('\n', '\n' .. indent .. '-- ')
		structFile:write('-- ')
		structFile:write(comment)
		structFile:write('\n')
	end
end

function StructWriter:writeCommentAfter(structFile, nodeSchema, nodeData, comment)
	if type(comment) == 'function' then
		comment = comment(nodeData, nodeSchema)
	end

	if comment ~= '' then
		comment = comment:gsub('\n', ' ')

		structFile:write(' -- ')
		structFile:write(comment)
	end
end

return StructWriter
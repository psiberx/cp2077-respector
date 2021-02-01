local ImGuiX = {}

local varStackDepth = 0
local colorStackDepth = 0
local clipStackDepth = 0

-- Style Var

function ImGuiX.PushStyleVar(...)
	ImGui.PushStyleVar(select(1, ...))

	varStackDepth = varStackDepth + 1
end

function ImGuiX.PopStyleVar(depth)
	ImGui.PopStyleVar(depth or 1)

	varStackDepth = varStackDepth - (depth or 1)
end

-- Style Color

function ImGuiX.PushStyleColor(...)
	ImGui.PushStyleColor(select(1, ...))

	colorStackDepth = colorStackDepth + 1
end

function ImGuiX.PopStyleColor(depth)
	ImGui.PopStyleColor(depth or 1)

	colorStackDepth = colorStackDepth - (depth or 1)
end

-- Clip Rect

function ImGuiX.PushClipRect(...)
	ImGui.PushClipRect(select(1, ...))

	clipStackDepth = clipStackDepth + 1
end

function ImGuiX.PopClipRect(depth)
	ImGui.PopClipRect(depth or 1)

	clipStackDepth = clipStackDepth - (depth or 1)
end

-- Restore Stack

function ImGuiX.RestoreStyleStack()
	if varStackDepth > 0 then
		ImGui.PopStyleVar(varStackDepth)

		varStackDepth = 0
	end

	if colorStackDepth > 0 then
		ImGui.PopStyleColor(colorStackDepth)

		colorStackDepth = 0
	end

	if clipStackDepth > 0 then
		ImGui.PopClipRect(clipStackDepth)

		clipStackDepth = 0
	end
end

return ImGuiX
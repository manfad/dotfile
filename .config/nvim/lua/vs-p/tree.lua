-- vs-p/tree.lua - File tree scanning and rendering with icons
local M = {}

-- Try to load nvim-web-devicons for file icons
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

-- Icons (Nerd Font with ASCII fallback)
local nerd_icons = {
	folder_closed = "",
	folder_open = "",
	file = "",
}

local ascii_icons = {
	folder_closed = "[+]",
	folder_open = "[-]",
	file = " * ",
}

-- Detect if devicons loaded successfully (indicates Nerd Font likely available)
local icons = has_devicons and nerd_icons or ascii_icons

function M.get_icon(name, is_directory, is_expanded)
	if is_directory then
		local folder = is_expanded and icons.folder_open or icons.folder_closed
		return folder, "Directory"
	end

	if has_devicons then
		local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
		if icon and icon ~= "" then
			return icon, hl
		end
	end

	return icons.file, "Normal"
end

function M.scan_directory(root, expanded, depth)
	depth = depth or 0
	local items = {}

	-- Get directory contents
	local handle = vim.loop.fs_scandir(root)
	if not handle then
		return items
	end

	local entries = {}
	while true do
		local name, type = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end
		-- Skip hidden files starting with .
		table.insert(entries, { name = name, type = type })
	end

	-- Sort: directories first, then alphabetically
	table.sort(entries, function(a, b)
		if a.type == "directory" and b.type ~= "directory" then
			return true
		elseif a.type ~= "directory" and b.type == "directory" then
			return false
		end
		return a.name:lower() < b.name:lower()
	end)

	-- Build items
	for _, entry in ipairs(entries) do
		local path = root .. "/" .. entry.name
		local is_dir = entry.type == "directory"
		local is_expanded = expanded[path] == true

		table.insert(items, {
			name = entry.name,
			path = path,
			type = is_dir and "directory" or "file",
			depth = depth,
			is_expanded = is_expanded,
		})

		-- Recursively add children if expanded
		if is_dir and is_expanded then
			local children = M.scan_directory(path, expanded, depth + 1)
			for _, child in ipairs(children) do
				table.insert(items, child)
			end
		end
	end

	return items
end

function M.render(items, root)
	local lines = {}
	local highlights = {}

	-- Build tree structure info for proper connectors
	local tree_info = M.build_tree_info(items)

	for i, item in ipairs(items) do
		local prefix = M.get_tree_prefix(item, i, items, tree_info)
		local icon, hl_group = M.get_icon(item.name, item.type == "directory", item.is_expanded)
		local line = prefix .. icon .. " " .. item.name

		table.insert(lines, line)

		-- Add highlight for tree characters
		local prefix_len = #prefix
		table.insert(highlights, {
			line = i - 1,
			col_start = 0,
			col_end = prefix_len,
			group = "NonText",
		})

		-- Add highlight for icon
		local icon_start = prefix_len
		local icon_end = icon_start + #icon + 1
		if hl_group then
			table.insert(highlights, {
				line = i - 1,
				col_start = icon_start,
				col_end = icon_end,
				group = hl_group,
			})
		end

		-- Add highlight for directory names
		if item.type == "directory" then
			table.insert(highlights, {
				line = i - 1,
				col_start = icon_end,
				col_end = -1,
				group = "Directory",
			})
		end
	end

	if #lines == 0 then
		lines = { "  Empty directory" }
	end

	return lines, highlights
end

-- Build info about which items are last in their parent
function M.build_tree_info(items)
	local info = {}
	local last_at_depth = {}

	-- First pass: find the last item at each depth for each parent
	for i = #items, 1, -1 do
		local item = items[i]
		local depth = item.depth

		if not last_at_depth[depth] then
			last_at_depth[depth] = {}
		end

		-- Find parent path
		local parent = vim.fn.fnamemodify(item.path, ":h")
		if not last_at_depth[depth][parent] then
			last_at_depth[depth][parent] = i
		end
	end

	-- Second pass: mark items
	for i, item in ipairs(items) do
		local parent = vim.fn.fnamemodify(item.path, ":h")
		info[i] = {
			is_last = last_at_depth[item.depth] and last_at_depth[item.depth][parent] == i,
		}
	end

	return info
end

-- Get the tree prefix (├──, └──, │, etc.)
function M.get_tree_prefix(item, index, items, tree_info)
	if item.depth == 0 then
		if tree_info[index] and tree_info[index].is_last then
			return "└── "
		else
			return "├── "
		end
	end

	local prefix = ""

	-- Build prefix for each depth level
	for d = 0, item.depth - 1 do
		-- Check if there are more siblings at this depth after current item
		local has_more = false
		for j = index + 1, #items do
			if items[j].depth < d then
				break
			end
			if items[j].depth == d then
				has_more = true
				break
			end
		end

		-- Check ancestors
		local ancestor_has_more = false
		for j = index + 1, #items do
			local check_item = items[j]
			if check_item.depth <= d then
				if check_item.depth == d then
					ancestor_has_more = true
				end
				break
			end
		end

		if ancestor_has_more then
			prefix = prefix .. "│   "
		else
			prefix = prefix .. "    "
		end
	end

	-- Add connector for current item
	if tree_info[index] and tree_info[index].is_last then
		prefix = prefix .. "└── "
	else
		prefix = prefix .. "├── "
	end

	return prefix
end

return M

-- ex/tree.lua - Directory scanning and rendering with file details
local M = {}

local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local nerd_icons = { folder_closed = "", folder_open = "", file = "" }
local ascii_icons = { folder_closed = "[+]", folder_open = "[-]", file = " * " }
local icons = has_devicons and nerd_icons or ascii_icons

function M.get_icon(name, is_directory, is_expanded)
	if is_directory then
		return is_expanded and icons.folder_open or icons.folder_closed, "Directory"
	end
	if has_devicons then
		local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
		if icon and icon ~= "" then
			return icon, hl
		end
	end
	return icons.file, "Normal"
end

-- Format helpers

function M.format_size(bytes)
	if bytes < 1024 then
		return string.format("%dB", bytes)
	end
	if bytes < 1024 * 1024 then
		return string.format("%.1fK", bytes / 1024)
	end
	if bytes < 1024 * 1024 * 1024 then
		return string.format("%.1fM", bytes / (1024 * 1024))
	end
	return string.format("%.1fG", bytes / (1024 * 1024 * 1024))
end

function M.format_time(mtime)
	return os.date("%b %d %H:%M", mtime.sec)
end

function M.format_permissions(mode)
	local perm = mode % 512
	local result = ""
	local chars = { "x", "w", "r" }
	for i = 8, 0, -1 do
		local bit_val = math.floor(perm / (2 ^ i)) % 2
		result = result .. (bit_val == 1 and chars[(i % 3) + 1] or "-")
	end
	return result
end

local function count_items(path)
	local handle = vim.loop.fs_scandir(path)
	if not handle then
		return 0
	end
	local count = 0
	while true do
		if not vim.loop.fs_scandir_next(handle) then
			break
		end
		count = count + 1
	end
	return count
end

-- Directory scanning with full metadata

function M.scan_directory(root, expanded, depth)
	depth = depth or 0
	local items = {}

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

	for _, entry in ipairs(entries) do
		local path = root .. "/" .. entry.name
		local is_dir = entry.type == "directory"
		local is_expanded = expanded[path] == true
		local stat = vim.loop.fs_stat(path)

		table.insert(items, {
			name = entry.name,
			path = path,
			type = is_dir and "directory" or "file",
			depth = depth,
			is_expanded = is_expanded,
			size = stat and stat.size or 0,
			mtime = stat and stat.mtime or { sec = 0 },
			mode = stat and stat.mode or 0,
			item_count = is_dir and count_items(path) or nil,
		})

		if is_dir and is_expanded then
			local children = M.scan_directory(path, expanded, depth + 1)
			for _, child in ipairs(children) do
				table.insert(items, child)
			end
		end
	end

	return items
end

-- Tree structure helpers

function M.build_tree_info(items)
	local info = {}
	local last_at_depth = {}

	for i = #items, 1, -1 do
		local item = items[i]
		local depth = item.depth
		if not last_at_depth[depth] then
			last_at_depth[depth] = {}
		end
		local parent = vim.fn.fnamemodify(item.path, ":h")
		if not last_at_depth[depth][parent] then
			last_at_depth[depth][parent] = i
		end
	end

	for i, item in ipairs(items) do
		local parent = vim.fn.fnamemodify(item.path, ":h")
		info[i] = {
			is_last = last_at_depth[item.depth] and last_at_depth[item.depth][parent] == i,
		}
	end

	return info
end

function M.get_tree_prefix(item, index, items, tree_info)
	if item.depth == 0 then
		if tree_info[index] and tree_info[index].is_last then
			return "└── "
		else
			return "├── "
		end
	end

	local prefix = ""
	for d = 0, item.depth - 1 do
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

	if tree_info[index] and tree_info[index].is_last then
		prefix = prefix .. "└── "
	else
		prefix = prefix .. "├── "
	end

	return prefix
end

-- Render tree with details: permissions, size/items, date

function M.render(items, win_width)
	local lines = {}
	local highlights = {}
	win_width = win_width or 40

	local tree_info = M.build_tree_info(items)

	for i, item in ipairs(items) do
		local line_idx = i - 1 -- 0-indexed line number
		local prefix = M.get_tree_prefix(item, i, items, tree_info)
		local icon, hl_group = M.get_icon(item.name, item.type == "directory", item.is_expanded)

		local display_name = item.name
		if item.type == "directory" then
			display_name = display_name .. "/"
		end
		local name_part = prefix .. icon .. " " .. display_name

		-- Build detail columns: perms  size/items  date
		local perms = M.format_permissions(item.mode)
		local size_or_count
		if item.type == "directory" then
			local c = item.item_count or 0
			size_or_count = string.format("%d item%s", c, c == 1 and "" or "s")
		else
			size_or_count = M.format_size(item.size)
		end
		local date = M.format_time(item.mtime)

		local detail = string.format("%s  %7s  %s", perms, size_or_count, date)

		-- Pad to right-align details
		local name_width = vim.fn.strdisplaywidth(name_part)
		local detail_width = vim.fn.strdisplaywidth(detail)
		local padding = win_width - name_width - detail_width - 1
		if padding < 2 then
			padding = 2
		end

		local line = name_part .. string.rep(" ", padding) .. detail
		table.insert(lines, line)

		-- Highlights
		local prefix_len = #prefix
		table.insert(highlights, { line = line_idx, col_start = 0, col_end = prefix_len, group = "NonText" })

		local icon_start = prefix_len
		local icon_end = icon_start + #icon + 1
		if hl_group then
			table.insert(
				highlights,
				{ line = line_idx, col_start = icon_start, col_end = icon_end, group = hl_group }
			)
		end

		if item.type == "directory" then
			table.insert(highlights, {
				line = line_idx,
				col_start = icon_end,
				col_end = icon_end + #display_name,
				group = "Directory",
			})
		end

		-- Detail highlight (dimmed)
		local detail_start = #name_part + padding
		table.insert(highlights, { line = line_idx, col_start = detail_start, col_end = -1, group = "Comment" })
	end

	if #items == 0 then
		table.insert(lines, "  (empty directory)")
		table.insert(highlights, { line = 0, col_start = 0, col_end = -1, group = "Comment" })
	end

	return lines, highlights
end

return M

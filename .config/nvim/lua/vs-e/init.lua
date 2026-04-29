-- vs-e - Buffer-based file explorer with preview and project details
local M = {}

local ui = require("vs-e.ui")
local tree = require("vs-e.tree")
local preview = require("vs-e.preview")

M.state = {
	is_open = false,
	is_closing = false,
	cwd = nil,
	tree_data = {},
	expanded = {},
}

-- Detail pane helpers

local function get_project_size(cwd)
	local output = vim.fn.systemlist({ "du", "-sh", cwd })
	if output and #output > 0 then
		return output[1]:match("^(%S+)") or "?"
	end
	return "?"
end

local function get_git_branch(cwd)
	local output = vim.fn.systemlist({ "git", "-C", cwd, "branch", "--show-current" })
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return (output and #output > 0) and output[1] or nil
end

local function get_git_remotes(cwd)
	local output = vim.fn.systemlist({ "git", "-C", cwd, "remote", "-v" })
	if vim.v.shell_error ~= 0 then
		return {}
	end
	local remotes = {}
	local seen = {}
	for _, line in ipairs(output) do
		local name, url = line:match("^(%S+)\t(%S+)")
		if name and url and not seen[name] then
			seen[name] = true
			table.insert(remotes, { name = name, url = url })
		end
	end
	return remotes
end

local function detect_languages(cwd)
	local cmd
	if vim.fn.executable("fd") == 1 then
		cmd = { "fd", "--type", "f", "--exclude", ".git", "--exclude", "node_modules", "--exclude", "target", ".", cwd }
	else
		cmd = { "find", cwd, "-type", "f", "-not", "-path", "*/.git/*", "-not", "-path", "*/node_modules/*" }
	end
	local output = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 or not output then
		return {}
	end

	local ext_counts = {}
	local total = 0
	for _, file in ipairs(output) do
		local ext = vim.fn.fnamemodify(file, ":e"):lower()
		if ext ~= "" then
			ext_counts[ext] = (ext_counts[ext] or 0) + 1
			total = total + 1
		end
	end

	local sorted = {}
	for ext, count in pairs(ext_counts) do
		table.insert(sorted, { ext = ext, count = count })
	end
	table.sort(sorted, function(a, b)
		return a.count > b.count
	end)

	local lang_map = {
		lua = "Lua",
		js = "JavaScript",
		ts = "TypeScript",
		py = "Python",
		java = "Java",
		json = "JSON",
		html = "HTML",
		css = "CSS",
		scss = "SCSS",
		vue = "Vue",
		tsx = "TSX",
		jsx = "JSX",
		md = "Markdown",
		yaml = "YAML",
		yml = "YAML",
		toml = "TOML",
		sh = "Shell",
		bash = "Shell",
		rs = "Rust",
		go = "Go",
		rb = "Ruby",
		php = "PHP",
		c = "C",
		cpp = "C++",
		h = "C",
		xml = "XML",
		sql = "SQL",
		kt = "Kotlin",
		swift = "Swift",
	}

	local result = {}
	for i = 1, math.min(5, #sorted) do
		local item = sorted[i]
		local lang = lang_map[item.ext] or item.ext:upper()
		local pct = math.floor(item.count / total * 100 + 0.5)
		if pct > 0 then
			table.insert(result, lang .. " " .. pct .. "%")
		end
	end

	return result
end

local function detail_label(name)
	return "   " .. string.format("%-10s", name) .. " "
end

function M.populate_detail()
	local cwd = M.state.cwd
	local lines = {}
	local highlights = {}
	local label_end = 14 -- length of detail_label output

	-- Path
	table.insert(lines, detail_label("Path") .. cwd)
	table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = label_end, group = "Comment" })

	-- Size
	local size = get_project_size(cwd)
	table.insert(lines, detail_label("Size") .. size)
	table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = label_end, group = "Comment" })

	-- Modified
	local stat = vim.loop.fs_stat(cwd)
	local mtime = stat and tree.format_time(stat.mtime) or "unknown"
	table.insert(lines, detail_label("Modified") .. mtime)
	table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = label_end, group = "Comment" })

	-- Git branch
	local branch = get_git_branch(cwd)
	if branch then
		table.insert(lines, "")
		table.insert(lines, detail_label("Branch") .. branch)
		local ln = #lines - 1
		table.insert(highlights, { line = ln, col_start = 0, col_end = label_end, group = "Comment" })
		table.insert(highlights, { line = ln, col_start = label_end, col_end = -1, group = "String" })
	end

	-- Git remotes
	local remotes = get_git_remotes(cwd)
	for i, remote in ipairs(remotes) do
		local label = i == 1 and detail_label("Remote") or ("   " .. string.rep(" ", 11))
		local line = label .. remote.name .. "  " .. remote.url
		table.insert(lines, line)
		local ln = #lines - 1
		table.insert(highlights, { line = ln, col_start = 0, col_end = label_end, group = "Comment" })
	end

	-- Languages
	local langs = detect_languages(cwd)
	if #langs > 0 then
		table.insert(lines, "")
		table.insert(lines, detail_label("Languages") .. table.concat(langs, "  "))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = label_end, group = "Comment" })
	end

	ui.set_detail(lines, highlights)
end

-- Tree

function M.refresh_tree()
	M.state.tree_data = tree.scan_directory(M.state.cwd, M.state.expanded)
	M.render()
end

function M.render()
	local lines, highlights = tree.render(M.state.tree_data, ui.get_results_width())
	ui.set_results(lines, highlights)
end

-- Preview

function M.update_preview()
	local item = M.get_current_item()
	if item and item.type == "file" then
		preview.show(ui.get_preview_win(), item.path)
		ui.set_preview_label(vim.fn.fnamemodify(item.path, ":t"))
	else
		preview.show_empty(ui.get_preview_win())
		ui.set_preview_label(nil)
	end
end

-- Navigation

function M.get_current_item()
	local win = ui.get_results_win()
	if not win or not vim.api.nvim_win_is_valid(win) then
		return nil
	end
	local line = vim.api.nvim_win_get_cursor(win)[1]
	if line < 1 or line > #M.state.tree_data then
		return nil
	end
	return M.state.tree_data[line]
end

function M.jump_to_file(filepath)
	for i, item in ipairs(M.state.tree_data) do
		if item.path == filepath then
			local win = ui.get_results_win()
			if win and vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_set_cursor(win, { i, 0 })
			end
			break
		end
	end
end

function M.expand_to_file(filepath)
	local relative = filepath:gsub("^" .. vim.pesc(M.state.cwd) .. "/?", "")
	local parts = {}
	for part in string.gmatch(relative, "[^/]+") do
		table.insert(parts, part)
	end
	local current_path = M.state.cwd
	for i = 1, #parts - 1 do
		current_path = current_path .. "/" .. parts[i]
		M.state.expanded[current_path] = true
	end
end

-- Actions

function M.on_enter()
	local item = M.get_current_item()
	if not item then
		return
	end

	if item.type == "directory" then
		if M.state.expanded[item.path] then
			M.state.expanded[item.path] = nil
		else
			M.state.expanded[item.path] = true
		end
		M.refresh_tree()
	else
		M.state.is_open = false
		ui.close_and_open(item.path)
	end
end

function M.on_cursor_move()
	M.update_preview()
end

-- Open / Close

function M.open(dir)
	-- Check if we're in another explorer (vs-p or vs-f) and close it first
	local current_ft = vim.bo.filetype
	if current_ft == "vs-p" or current_ft == "vs-p_search" or current_ft == "vs-f" or current_ft == "vs-f_search" then
		pcall(require("vs-p").close)
		vim.schedule(function()
			M.open(dir)
		end)
		return
	end

	if M.state.is_open then
		M.close()
	end

	M.state.is_open = true
	M.state.cwd = dir or vim.fn.getcwd()
	M.state.cwd = vim.fn.fnamemodify(M.state.cwd, ":p"):gsub("/$", "")
	M.state.expanded = {}

	-- Get current file (may be empty if opened as directory)
	local current_file = vim.fn.expand("%:p")
	if current_file == "" or vim.fn.isdirectory(current_file) == 1 then
		current_file = nil
	end

	-- Expand to current file if it's in this directory
	if current_file and current_file:find(M.state.cwd, 1, true) == 1 then
		M.expand_to_file(current_file)
	end

	-- Create layout
	ui.create_layout()
	ui.set_results_winbar(M.state.cwd)

	-- Set up keymaps first
	M.setup_keymaps()

	-- Show tree + detail
	M.refresh_tree()
	M.populate_detail()

	-- Focus tree and jump to current file
	ui.focus_results()
	if current_file then
		vim.defer_fn(function()
			M.jump_to_file(current_file)
			M.update_preview()
		end, 50)
	elseif #M.state.tree_data > 0 then
		vim.api.nvim_win_set_cursor(ui.get_results_win(), { 1, 0 })
		M.update_preview()
	end
end

function M.close()
	if M.state.is_closing then
		return
	end
	M.state.is_closing = true
	M.state.is_open = false
	ui.close_layout()
	M.state.is_closing = false
end

-- Keymaps

function M.setup_keymaps()
	local results_buf = ui.get_results_buf()
	local opts = { buffer = results_buf, nowait = true, silent = true }

	vim.keymap.set("n", "q", M.close, opts)
	vim.keymap.set("n", "<Esc>", M.close, opts)
	vim.keymap.set("n", "<CR>", M.on_enter, opts)
	vim.keymap.set("n", "l", M.on_enter, opts)
	vim.keymap.set("n", "h", function()
		local item = M.get_current_item()
		if item and item.type == "directory" and M.state.expanded[item.path] then
			M.state.expanded[item.path] = nil
			M.refresh_tree()
		end
	end, opts)

	-- Go to parent directory
	vim.keymap.set("n", "-", function()
		local parent = vim.fn.fnamemodify(M.state.cwd, ":h")
		if parent == M.state.cwd then
			return
		end
		M.state.cwd = parent
		M.state.expanded = {}
		M.refresh_tree()
		M.populate_detail()
		ui.set_results_winbar(M.state.cwd)
	end, opts)

	-- Jump to next/prev directory
	vim.keymap.set("n", "J", function()
		local win = ui.get_results_win()
		if not win then
			return
		end
		local current_line = vim.api.nvim_win_get_cursor(win)[1]
		for i = current_line + 1, #M.state.tree_data do
			if M.state.tree_data[i].type == "directory" then
				vim.api.nvim_win_set_cursor(win, { i, 0 })
				M.update_preview()
				return
			end
		end
	end, opts)

	vim.keymap.set("n", "K", function()
		local win = ui.get_results_win()
		if not win then
			return
		end
		local current_line = vim.api.nvim_win_get_cursor(win)[1]
		for i = current_line - 1, 1, -1 do
			if M.state.tree_data[i].type == "directory" then
				vim.api.nvim_win_set_cursor(win, { i, 0 })
				M.update_preview()
				return
			end
		end
	end, opts)

	-- Create file/directory
	vim.keymap.set("n", "a", function()
		local item = M.get_current_item()
		local base_dir = M.state.cwd

		if item then
			if item.type == "directory" then
				base_dir = item.path
				M.state.expanded[item.path] = true
			else
				base_dir = vim.fn.fnamemodify(item.path, ":h")
			end
		end

		vim.ui.input({ prompt = "Create (end with / for directory): " }, function(name)
			if not name or name == "" then
				return
			end

			local full_path = base_dir .. "/" .. name
			if name:sub(-1) == "/" then
				full_path = full_path:sub(1, -2)
				vim.fn.mkdir(full_path, "p")
			else
				local parent = vim.fn.fnamemodify(full_path, ":h")
				if vim.fn.isdirectory(parent) == 0 then
					vim.fn.mkdir(parent, "p")
				end
				local f = io.open(full_path, "w")
				if f then
					f:close()
				end
			end

			M.refresh_tree()
			vim.defer_fn(function()
				M.jump_to_file(full_path)
				M.update_preview()
			end, 50)
		end)
	end, opts)

	-- Rename
	vim.keymap.set("n", "r", function()
		local item = M.get_current_item()
		if not item then
			return
		end
		local old_name = vim.fn.fnamemodify(item.path, ":t")
		vim.ui.input({ prompt = "Rename: ", default = old_name }, function(new_name)
			if not new_name or new_name == "" or new_name == old_name then
				return
			end
			local parent = vim.fn.fnamemodify(item.path, ":h")
			local new_path = parent .. "/" .. new_name
			if vim.fn.filereadable(new_path) == 1 or vim.fn.isdirectory(new_path) == 1 then
				vim.notify("Target already exists!", vim.log.levels.ERROR)
				return
			end
			vim.fn.rename(item.path, new_path)
			M.refresh_tree()
			vim.defer_fn(function()
				M.jump_to_file(new_path)
				M.update_preview()
			end, 50)
		end)
	end, opts)

	-- Delete
	vim.keymap.set("n", "d", function()
		local item = M.get_current_item()
		if not item then
			return
		end
		local name = vim.fn.fnamemodify(item.path, ":t")
		vim.ui.input({ prompt = "Delete '" .. name .. "'? (y/n): " }, function(confirm)
			if confirm ~= "y" and confirm ~= "Y" then
				return
			end
			if item.type == "directory" then
				vim.fn.delete(item.path, "rf")
			else
				vim.fn.delete(item.path)
			end
			M.refresh_tree()
			M.update_preview()
		end)
	end, opts)

	-- Yank path
	vim.keymap.set("n", "y", function()
		local item = M.get_current_item()
		if not item then
			return
		end
		vim.fn.setreg("+", item.path)
		vim.notify("Copied: " .. item.path)
	end, opts)

	-- Refresh
	vim.keymap.set("n", "R", function()
		M.refresh_tree()
		M.populate_detail()
		M.update_preview()
	end, opts)

	-- Cursor move for preview
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = results_buf,
		callback = M.on_cursor_move,
	})

	-- Re-render on resize
	vim.api.nvim_create_autocmd("WinResized", {
		buffer = results_buf,
		callback = function()
			M.render()
		end,
	})

	-- Detail pane keymaps (just q/Esc to close)
	local detail_buf = ui.get_detail_buf()
	if detail_buf then
		local d_opts = { buffer = detail_buf, nowait = true, silent = true }
		vim.keymap.set("n", "q", M.close, d_opts)
		vim.keymap.set("n", "<Esc>", M.close, d_opts)
	end

	-- Handle external window close
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(args)
			if not M.state.is_open then
				return
			end
			local closed_win = tonumber(args.match)
			if ui.is_explorer_win(closed_win) then
				vim.schedule(function()
					M.close()
				end)
			end
		end,
	})
end

-- Setup

function M.setup(opts)
	opts = opts or {}

	vim.g.loaded_netrw = 1
	vim.g.loaded_netrwPlugin = 1

	vim.keymap.set("n", opts.keymap or "<leader>e", function()
		M.open()
	end, { desc = "File explorer" })

	vim.api.nvim_create_user_command("Ex", function(cmd_opts)
		local dir = cmd_opts.args ~= "" and cmd_opts.args or nil
		M.open(dir)
	end, { nargs = "?", complete = "dir", desc = "File explorer" })

	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function(args)
			if not vim.api.nvim_buf_is_valid(args.buf) then
				return
			end
			local bufname = vim.api.nvim_buf_get_name(args.buf)
			if bufname ~= "" and vim.fn.isdirectory(bufname) == 1 then
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(args.buf) then
						pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
					end
					M.open(bufname)
				end)
			end
		end,
	})
end

return M

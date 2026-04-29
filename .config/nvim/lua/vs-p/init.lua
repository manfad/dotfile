-- vs-p - VS Code style file explorer with search-first UI
local M = {}

local ui = require("vs-p.ui")
local tree = require("vs-p.tree")
local preview = require("vs-p.preview")
local search = require("vs-p.search")

M.state = {
	is_open = false,
	mode = "search", -- "tree" or "search"
	cwd = nil,
	tree_data = {},
	expanded = {},
	cursor_line = 1,
	search_query = "",
	search_results = {},
}

function M.open()
	if M.state.is_open then
		M.close()
		return
	end

	-- Check if we're in an explorer (ex or vs-p) buffer and close it first
	local current_ft = vim.bo.filetype
	if current_ft == "ex-explorer" or current_ft == "vs-p" or current_ft == "vs-p_search" or current_ft == "vs-f" or current_ft == "vs-f_search" then
		-- Close the explorer first
		if current_ft == "ex-explorer" then
			pcall(require("ex").close)
		else
			M.close()
			return
		end
		vim.schedule(function()
			M.open()
		end)
		return
	end

	M.state.is_open = true
	M.state.cwd = vim.fn.getcwd()
	M.state.mode = "tree"
	M.state.cursor_line = 1
	M.state.search_query = ""
	M.state.expanded = { [M.state.cwd] = true }

	-- Get current file and expand its parent directories
	local current_file = vim.fn.expand("%:p")
	if current_file and current_file ~= "" and current_file:find(M.state.cwd, 1, true) == 1 then
		M.expand_to_file(current_file)
	end

	-- Create UI
	ui.create_layout()

	-- Set up keymaps
	M.setup_keymaps()

	-- Start with search focused (like VS Code)
	ui.focus_search()

	-- Deferred refresh so the tree renders after layout is stable
	vim.schedule(function()
		M.refresh_tree()
		if current_file and current_file ~= "" then
			M.jump_to_file(current_file)
			M.update_preview()
		end
	end)
end

-- Expand all parent directories of a file
function M.expand_to_file(filepath)
	local relative = filepath:gsub("^" .. vim.pesc(M.state.cwd) .. "/?", "")
	local parts = {}
	for part in string.gmatch(relative, "[^/]+") do
		table.insert(parts, part)
	end

	-- Expand each parent directory
	local current_path = M.state.cwd
	for i = 1, #parts - 1 do -- Exclude the file itself
		current_path = current_path .. "/" .. parts[i]
		M.state.expanded[current_path] = true
	end
end

-- Jump cursor to a specific file in the tree
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

function M.close()
	M.state.is_open = false
	ui.close_layout()
end

function M.refresh_tree()
	M.state.tree_data = tree.scan_directory(M.state.cwd, M.state.expanded)
	M.render()
end

function M.render()
	if M.state.mode == "tree" then
		local lines, highlights = tree.render(M.state.tree_data, M.state.cwd)
		ui.set_results(lines, highlights)
	else
		local lines, highlights = search.render_results(M.state.search_results)
		ui.set_results(lines, highlights)
	end
end

function M.update_preview()
	local item = M.get_current_item()
	if item and item.type == "file" then
		preview.show(ui.get_preview_win(), item.path)
	else
		preview.show_empty(ui.get_preview_win())
	end
end

function M.get_current_item()
	local win = ui.get_results_win()
	if not win or not vim.api.nvim_win_is_valid(win) then
		return nil
	end

	local line = vim.api.nvim_win_get_cursor(win)[1]
	if M.state.mode == "tree" then
		return M.state.tree_data[line]
	else
		return M.state.search_results[line]
	end
end

function M.on_enter()
	local item = M.get_current_item()
	if not item then
		return
	end

	if item.type == "directory" then
		-- Toggle expand/collapse
		if M.state.expanded[item.path] then
			M.state.expanded[item.path] = nil
		else
			M.state.expanded[item.path] = true
		end
		M.refresh_tree()
	else
		-- Open file
		M.close()
		vim.cmd("edit " .. vim.fn.fnameescape(item.path))
	end
end

function M.on_cursor_move()
	M.update_preview()
end

function M.enter_search_mode()
	M.state.mode = "search"
	local search_buf = ui.get_search_buf()
	if search_buf then
		vim.api.nvim_set_option_value("modifiable", true, { buf = search_buf })
	end
	ui.focus_search()
end

function M.exit_search_mode()
	M.state.mode = "tree"
	M.state.search_query = ""
	ui.clear_search()
	ui.focus_results()
	M.refresh_tree()
end

function M.on_search_change(query)
	M.state.search_query = query
	if query == "" then
		M.state.mode = "tree"
		M.refresh_tree()
	else
		M.state.mode = "search"
		M.state.search_results = search.find_files(M.state.cwd, query)
		M.render()
	end
end

function M.setup_keymaps()
	local results_buf = ui.get_results_buf()
	local search_buf = ui.get_search_buf()
	local opts = { buffer = results_buf, nowait = true }

	-- Results pane keymaps
	vim.keymap.set("n", "q", M.close, opts)
	vim.keymap.set("n", "<Esc>", M.close, opts)
	vim.keymap.set("n", "<CR>", M.on_enter, opts)
	vim.keymap.set("n", "l", M.on_enter, opts)
	vim.keymap.set("n", "/", M.enter_search_mode, opts)
	vim.keymap.set("n", "<Tab>", M.enter_search_mode, opts) -- Tab to go to search
	vim.keymap.set("n", "h", function()
		local item = M.get_current_item()
		if item and item.type == "directory" and M.state.expanded[item.path] then
			M.state.expanded[item.path] = nil
			M.refresh_tree()
		end
	end, opts)

	-- Shift+J: Jump to next directory
	vim.keymap.set("n", "J", function()
		local win = ui.get_results_win()
		if not win then
			return
		end
		local current_line = vim.api.nvim_win_get_cursor(win)[1]
		local items = M.state.mode == "tree" and M.state.tree_data or M.state.search_results

		for i = current_line + 1, #items do
			if items[i] and items[i].type == "directory" then
				vim.api.nvim_win_set_cursor(win, { i, 0 })
				M.update_preview()
				return
			end
		end
	end, opts)

	-- Shift+K: Jump to previous directory
	vim.keymap.set("n", "K", function()
		local win = ui.get_results_win()
		if not win then
			return
		end
		local current_line = vim.api.nvim_win_get_cursor(win)[1]
		local items = M.state.mode == "tree" and M.state.tree_data or M.state.search_results

		for i = current_line - 1, 1, -1 do
			if items[i] and items[i].type == "directory" then
				vim.api.nvim_win_set_cursor(win, { i, 0 })
				M.update_preview()
				return
			end
		end
	end, opts)

	-- a: Add new file or directory
	vim.keymap.set("n", "a", function()
		local item = M.get_current_item()
		local base_dir = M.state.cwd

		-- If on a directory, create inside it; if on file, create in same directory
		if item then
			if item.type == "directory" then
				base_dir = item.path
				-- Auto-expand the directory
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
			local is_directory = name:sub(-1) == "/"

			if is_directory then
				-- Create directory
				full_path = full_path:sub(1, -2) -- Remove trailing /
				vim.fn.mkdir(full_path, "p")
			else
				-- Create file (and parent directories if needed)
				local parent = vim.fn.fnamemodify(full_path, ":h")
				if vim.fn.isdirectory(parent) == 0 then
					vim.fn.mkdir(parent, "p")
				end
				-- Create empty file
				local f = io.open(full_path, "w")
				if f then
					f:close()
				end
			end

			M.refresh_tree()
			-- Jump to new item
			vim.defer_fn(function()
				M.jump_to_file(full_path)
				M.update_preview()
			end, 50)
		end)
	end, opts)

	-- r: Rename file or directory
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

			-- Check if target exists
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

	-- d: Delete file or directory
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
				vim.fn.delete(item.path, "rf") -- Recursive delete
			else
				vim.fn.delete(item.path)
			end

			M.refresh_tree()
			M.update_preview()
		end)
	end, opts)

	-- c: Copy file path to clipboard
	vim.keymap.set("n", "y", function()
		local item = M.get_current_item()
		if not item then
			return
		end
		vim.fn.setreg("+", item.path)
		vim.notify("Copied: " .. item.path)
	end, opts)

	-- Cursor move handler
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = results_buf,
		callback = M.on_cursor_move,
	})

	-- Search input keymaps
	local search_opts = { buffer = search_buf, nowait = true }

	-- Normal mode in search
	vim.keymap.set("n", "<Esc>", function()
		M.exit_search_mode()
	end, search_opts)
	vim.keymap.set("n", "q", M.close, search_opts)
	vim.keymap.set("n", "<CR>", function()
		ui.focus_results()
	end, search_opts)
	vim.keymap.set("n", "<Tab>", function()
		ui.focus_results()
	end, search_opts)
	vim.keymap.set("n", "j", function()
		ui.focus_results()
	end, search_opts)
	vim.keymap.set("n", "k", function()
		ui.focus_results()
	end, search_opts)

	-- Insert mode in search
	vim.keymap.set("i", "<Esc>", function()
		vim.cmd("stopinsert")
		M.exit_search_mode()
	end, search_opts)
	vim.keymap.set("i", "<CR>", function()
		vim.cmd("stopinsert")
		-- If exactly 1 result, open it directly
		if #M.state.search_results == 1 then
			local item = M.state.search_results[1]
			if item.type == "file" then
				M.close()
				vim.cmd("edit " .. vim.fn.fnameescape(item.path))
				return
			end
		end
		ui.focus_results()
	end, search_opts)
	vim.keymap.set("i", "<Tab>", function()
		vim.cmd("stopinsert")
		ui.focus_results()
	end, search_opts)
	vim.keymap.set("i", "<Down>", function()
		vim.cmd("stopinsert")
		ui.focus_results()
		vim.cmd("normal! j")
	end, search_opts)
	vim.keymap.set("i", "<Up>", function()
		vim.cmd("stopinsert")
		ui.focus_results()
	end, search_opts)

	-- Make search buffer modifiable
	vim.api.nvim_set_option_value("modifiable", true, { buf = search_buf })

	-- Search text change handler
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = search_buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(search_buf, 0, 1, false)
			M.on_search_change(lines[1] or "")
		end,
	})
end

function M.setup(opts)
	opts = opts or {}
	vim.keymap.set("n", opts.keymap or "<leader>e", M.open, { desc = "File explorer" })
end

return M

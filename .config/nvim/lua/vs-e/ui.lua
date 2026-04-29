-- ex/ui.lua - Split-based layout: tree (top-left), detail (bottom-left), preview (right)
local M = {}

local wins = {
	results = nil,
	preview = nil,
	detail = nil,
}

local bufs = {
	results = nil,
	preview = nil,
	detail = nil,
}

local saved = {
	prev_buf = nil,
}

local ns_id = vim.api.nvim_create_namespace("ex-explorer")
local ns_detail = vim.api.nvim_create_namespace("ex-detail")

function M.create_layout()
	saved.prev_buf = vim.api.nvim_get_current_buf()
	local orig_win = vim.api.nvim_get_current_win()

	-- Results buffer in current window
	bufs.results = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufs.results })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufs.results })
	vim.api.nvim_set_option_value("filetype", "ex-explorer", { buf = bufs.results })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufs.results })
	vim.api.nvim_win_set_buf(orig_win, bufs.results)

	-- Vertical split on right for preview
	vim.cmd("rightbelow vsplit")
	wins.preview = vim.api.nvim_get_current_win()
	bufs.preview = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufs.preview })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufs.preview })
	vim.api.nvim_win_set_buf(wins.preview, bufs.preview)
	vim.api.nvim_win_set_width(wins.preview, math.floor(vim.o.columns * 0.55))

	-- Preview window options
	vim.api.nvim_set_option_value("number", true, { win = wins.preview })
	vim.api.nvim_set_option_value("relativenumber", false, { win = wins.preview })
	vim.api.nvim_set_option_value("wrap", false, { win = wins.preview })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = wins.preview })
	vim.api.nvim_set_option_value("cursorline", false, { win = wins.preview })

	-- Go back to left window
	vim.api.nvim_set_current_win(orig_win)

	-- Horizontal split below for detail pane
	vim.cmd("belowright split")
	wins.detail = vim.api.nvim_get_current_win()
	bufs.detail = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufs.detail })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufs.detail })
	vim.api.nvim_set_option_value("filetype", "ex-explorer", { buf = bufs.detail })
	vim.api.nvim_set_option_value("swapfile", false, { buf = bufs.detail })
	vim.api.nvim_win_set_buf(wins.detail, bufs.detail)

	-- Detail window options
	vim.api.nvim_win_set_height(wins.detail, 10)
	vim.api.nvim_set_option_value("number", false, { win = wins.detail })
	vim.api.nvim_set_option_value("relativenumber", false, { win = wins.detail })
	vim.api.nvim_set_option_value("cursorline", false, { win = wins.detail })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = wins.detail })
	vim.api.nvim_set_option_value("winfixheight", true, { win = wins.detail })
	vim.api.nvim_set_option_value("wrap", false, { win = wins.detail })

	-- Go back to results (top-left)
	vim.cmd("wincmd k")
	wins.results = vim.api.nvim_get_current_win()

	-- Results window options
	vim.api.nvim_set_option_value("number", false, { win = wins.results })
	vim.api.nvim_set_option_value("relativenumber", false, { win = wins.results })
	vim.api.nvim_set_option_value("cursorline", true, { win = wins.results })
	vim.api.nvim_set_option_value("wrap", false, { win = wins.results })
	vim.api.nvim_set_option_value("signcolumn", "no", { win = wins.results })
	vim.api.nvim_set_option_value("winhighlight", "CursorLine:Visual", { win = wins.results })
end

function M.close_layout()
	for _, name in ipairs({ "detail", "preview" }) do
		if wins[name] and vim.api.nvim_win_is_valid(wins[name]) then
			vim.api.nvim_win_close(wins[name], true)
		end
		wins[name] = nil
	end

	if wins.results and vim.api.nvim_win_is_valid(wins.results) then
		vim.api.nvim_set_current_win(wins.results)
		if saved.prev_buf and vim.api.nvim_buf_is_valid(saved.prev_buf) then
			vim.api.nvim_set_current_buf(saved.prev_buf)
		else
			vim.cmd("enew")
		end
	end
	wins.results = nil

	for name, buf in pairs(bufs) do
		if buf and vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
		bufs[name] = nil
	end
end

function M.close_and_open(path)
	for _, name in ipairs({ "detail", "preview" }) do
		if wins[name] and vim.api.nvim_win_is_valid(wins[name]) then
			vim.api.nvim_win_close(wins[name], true)
		end
		wins[name] = nil
	end

	if wins.results and vim.api.nvim_win_is_valid(wins.results) then
		vim.api.nvim_set_current_win(wins.results)
	end
	vim.cmd("edit " .. vim.fn.fnameescape(path))
	wins.results = nil

	for name, buf in pairs(bufs) do
		if buf and vim.api.nvim_buf_is_valid(buf) then
			pcall(vim.api.nvim_buf_delete, buf, { force = true })
		end
		bufs[name] = nil
	end
end

function M.set_results(lines, highlights)
	if not bufs.results or not vim.api.nvim_buf_is_valid(bufs.results) then
		return
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = bufs.results })
	vim.api.nvim_buf_set_lines(bufs.results, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufs.results })

	vim.api.nvim_buf_clear_namespace(bufs.results, ns_id, 0, -1)
	for _, hl in ipairs(highlights or {}) do
		vim.api.nvim_buf_add_highlight(bufs.results, ns_id, hl.group, hl.line, hl.col_start, hl.col_end)
	end
end

function M.set_detail(lines, highlights)
	if not bufs.detail or not vim.api.nvim_buf_is_valid(bufs.detail) then
		return
	end

	vim.api.nvim_set_option_value("modifiable", true, { buf = bufs.detail })
	vim.api.nvim_buf_set_lines(bufs.detail, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = bufs.detail })

	vim.api.nvim_buf_clear_namespace(bufs.detail, ns_detail, 0, -1)
	for _, hl in ipairs(highlights or {}) do
		vim.api.nvim_buf_add_highlight(bufs.detail, ns_detail, hl.group, hl.line, hl.col_start, hl.col_end)
	end

	-- Resize to fit content
	if wins.detail and vim.api.nvim_win_is_valid(wins.detail) then
		vim.api.nvim_win_set_height(wins.detail, math.max(#lines, 3))
	end
end

function M.set_results_winbar(cwd)
	if wins.results and vim.api.nvim_win_is_valid(wins.results) then
		vim.api.nvim_set_option_value(
			"winbar",
			"%#Title#   " .. vim.fn.fnamemodify(cwd, ":~") .. "%*",
			{ win = wins.results }
		)
	end
end

function M.set_preview_label(name)
	if wins.preview and vim.api.nvim_win_is_valid(wins.preview) then
		local label = name and ("  " .. name) or "  Preview"
		vim.api.nvim_set_option_value("winbar", "%#Comment#" .. label .. "%*", { win = wins.preview })
	end
end

function M.get_results_win()
	return wins.results
end

function M.get_results_buf()
	return bufs.results
end

function M.get_results_width()
	if wins.results and vim.api.nvim_win_is_valid(wins.results) then
		return vim.api.nvim_win_get_width(wins.results)
	end
	return 40
end

function M.get_preview_win()
	return wins.preview
end

function M.get_detail_win()
	return wins.detail
end

function M.get_detail_buf()
	return bufs.detail
end

function M.focus_results()
	if wins.results and vim.api.nvim_win_is_valid(wins.results) then
		vim.api.nvim_set_current_win(wins.results)
	end
end

function M.is_explorer_win(win_id)
	return win_id == wins.results or win_id == wins.preview or win_id == wins.detail
end

return M

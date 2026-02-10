-- vs-f/ui.lua - Floating window layout
local M = {}

local wins = {
  results = nil,
  preview = nil,
  search = nil,
}

local bufs = {
  results = nil,
  preview = nil,
  search = nil,
}

local ns_id = vim.api.nvim_create_namespace("vs-f")

local function update_border_highlights(focused_win)
  -- Update search window border
  if wins.search and vim.api.nvim_win_is_valid(wins.search) then
    local hl = focused_win == "search" and "FocusedBorder" or "UnfocusedBorder"
    vim.api.nvim_set_option_value("winhighlight", "FloatBorder:" .. hl, { win = wins.search })
  end
  -- Update results window border
  if wins.results and vim.api.nvim_win_is_valid(wins.results) then
    local hl = focused_win == "results" and "FocusedBorder" or "UnfocusedBorder"
    vim.api.nvim_set_option_value("winhighlight", "CursorLine:Visual,FloatBorder:" .. hl, { win = wins.results })
  end
  -- Update preview window border
  if wins.preview and vim.api.nvim_win_is_valid(wins.preview) then
    vim.api.nvim_set_option_value("winhighlight", "FloatBorder:UnfocusedBorder", { win = wins.preview })
  end
end

function M.create_layout()
  -- Calculate dimensions
  local width = vim.o.columns
  local height = vim.o.lines
  local dialog_width = math.floor(width * 0.85)
  local dialog_height = math.floor(height * 0.8)
  local start_col = math.floor((width - dialog_width) / 2)
  local start_row = math.floor((height - dialog_height) / 2) - 1

  local results_width = math.floor(dialog_width * 0.4)
  local preview_width = dialog_width - results_width - 2
  local search_height = 1
  local content_height = dialog_height - search_height - 2

  -- Create search buffer and window (TOP)
  bufs.search = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufs.search })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufs.search })
  vim.api.nvim_set_option_value("filetype", "vs-f_search", { buf = bufs.search })
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufs.search })

  wins.search = vim.api.nvim_open_win(bufs.search, false, {
    relative = "editor",
    width = results_width,
    height = search_height,
    col = start_col,
    row = start_row,
    style = "minimal",
    border = "rounded",
    title = "   Grep ",
    title_pos = "center",
  })

  -- Create results buffer and window (left side, below search)
  bufs.results = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufs.results })
  vim.api.nvim_set_option_value("filetype", "vs-f", { buf = bufs.results })

  wins.results = vim.api.nvim_open_win(bufs.results, true, {
    relative = "editor",
    width = results_width,
    height = content_height,
    col = start_col,
    row = start_row + search_height + 2,
    style = "minimal",
    border = "rounded",
    title = " Results ",
    title_pos = "center",
  })
  vim.api.nvim_set_option_value("cursorline", true, { win = wins.results })
  vim.api.nvim_set_option_value("wrap", false, { win = wins.results })
  vim.api.nvim_set_option_value("winhighlight", "CursorLine:Visual", { win = wins.results })

  -- Create preview buffer and window (right side, full height)
  bufs.preview = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufs.preview })

  wins.preview = vim.api.nvim_open_win(bufs.preview, false, {
    relative = "editor",
    width = preview_width,
    height = dialog_height,
    col = start_col + results_width + 2,
    row = start_row,
    style = "minimal",
    border = "rounded",
    title = " Preview ",
    title_pos = "center",
  })
  vim.api.nvim_set_option_value("number", true, { win = wins.preview })
  vim.api.nvim_set_option_value("relativenumber", false, { win = wins.preview })
  vim.api.nvim_set_option_value("wrap", false, { win = wins.preview })
  vim.api.nvim_set_option_value("cursorline", true, { win = wins.preview })

  -- Set initial border highlights (results focused by default)
  update_border_highlights("results")
end

function M.close_layout()
  for name, win in pairs(wins) do
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    wins[name] = nil
  end
  for name, buf in pairs(bufs) do
    if buf and vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    bufs[name] = nil
  end
end

function M.set_results(lines, highlights)
  if not bufs.results or not vim.api.nvim_buf_is_valid(bufs.results) then return end

  vim.api.nvim_set_option_value("modifiable", true, { buf = bufs.results })
  vim.api.nvim_buf_set_lines(bufs.results, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufs.results })

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(bufs.results, ns_id, 0, -1)
  for _, hl in ipairs(highlights or {}) do
    pcall(vim.api.nvim_buf_add_highlight, bufs.results, ns_id, hl.group, hl.line, hl.col_start, hl.col_end)
  end
end

function M.get_results_win()
  return wins.results
end

function M.get_results_buf()
  return bufs.results
end

function M.get_preview_win()
  return wins.preview
end

function M.get_preview_buf()
  return bufs.preview
end

function M.get_search_buf()
  return bufs.search
end

function M.focus_results()
  if wins.results and vim.api.nvim_win_is_valid(wins.results) then
    vim.api.nvim_set_current_win(wins.results)
    update_border_highlights("results")
  end
end

function M.focus_search()
  if wins.search and vim.api.nvim_win_is_valid(wins.search) then
    vim.api.nvim_set_current_win(wins.search)
    update_border_highlights("search")
    if bufs.search and vim.api.nvim_buf_is_valid(bufs.search) then
      vim.api.nvim_set_option_value("modifiable", true, { buf = bufs.search })
    end
    vim.cmd("startinsert!")
  end
end

return M

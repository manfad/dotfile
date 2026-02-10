-- vs-f - VS Code style text search with ripgrep
local M = {}

local ui = require("vs-f.ui")
local rg = require("vs-f.rg")
local preview = require("vs-f.preview")

M.state = {
  is_open = false,
  cwd = nil,
  query = "",
  results = {},       -- { type, path, line, col, text }
  file_indices = {},  -- indices of file headers for J/K navigation
  cursor_line = 1,
}

function M.open()
  if M.state.is_open then
    M.close()
    return
  end

  M.state.is_open = true
  M.state.cwd = vim.fn.getcwd()
  M.state.query = ""
  M.state.results = {}
  M.state.cursor_line = 1

  -- Create UI
  ui.create_layout()

  -- Set up keymaps
  M.setup_keymaps()

  -- Focus search and start insert mode
  ui.focus_search()
end

function M.close()
  M.state.is_open = false
  ui.close_layout()
end

function M.on_search_change(query)
  M.state.query = query
  if query == "" or #query < 2 then
    M.state.results = {}
    M.state.file_indices = {}
    M.render()
    preview.show_empty(ui.get_preview_win())
    return
  end

  M.state.results, M.state.file_indices = rg.search(M.state.cwd, query)
  M.render()

  -- Preview first result
  if #M.state.results > 0 then
    M.update_preview()
  else
    preview.show_empty(ui.get_preview_win())
  end
end

function M.render()
  local lines, highlights = rg.render_results(M.state.results, M.state.query)
  ui.set_results(lines, highlights)
end

function M.update_preview()
  local item = M.get_current_item()
  if item then
    if item.type == "file" then
      -- On file header, show first line of file
      preview.show(ui.get_preview_win(), item.path, 1, M.state.query)
    else
      -- On match, show that line
      preview.show(ui.get_preview_win(), item.path, item.line, M.state.query)
    end
  else
    preview.show_empty(ui.get_preview_win())
  end
end

function M.get_current_item()
  local win = ui.get_results_win()
  if not win or not vim.api.nvim_win_is_valid(win) then return nil end

  local line = vim.api.nvim_win_get_cursor(win)[1]
  return M.state.results[line]
end

function M.on_enter()
  local item = M.get_current_item()
  if not item then return end

  local path = item.path
  local line = item.line or 1
  local col = item.col or 1

  M.close()

  -- Open file and jump to line
  pcall(function()
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.api.nvim_win_set_cursor(0, { line, math.max(0, col - 1) })
    vim.cmd("normal! zz") -- Center the line
  end)
end

function M.on_cursor_move()
  M.update_preview()
end

function M.setup_keymaps()
  local results_buf = ui.get_results_buf()
  local search_buf = ui.get_search_buf()

  -- Results pane keymaps
  local opts = { buffer = results_buf, nowait = true }
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  vim.keymap.set("n", "<CR>", M.on_enter, opts)
  vim.keymap.set("n", "l", M.on_enter, opts)
  vim.keymap.set("n", "<Tab>", function() ui.focus_search() end, opts)
  vim.keymap.set("n", "/", function() ui.focus_search() end, opts)

  -- Shift+J: Jump to next file
  vim.keymap.set("n", "J", function()
    local win = ui.get_results_win()
    if not win then return end
    local current_line = vim.api.nvim_win_get_cursor(win)[1]

    for _, idx in ipairs(M.state.file_indices) do
      if idx > current_line then
        vim.api.nvim_win_set_cursor(win, { idx, 0 })
        M.update_preview()
        return
      end
    end
  end, opts)

  -- Shift+K: Jump to previous file
  vim.keymap.set("n", "K", function()
    local win = ui.get_results_win()
    if not win then return end
    local current_line = vim.api.nvim_win_get_cursor(win)[1]

    for i = #M.state.file_indices, 1, -1 do
      local idx = M.state.file_indices[i]
      if idx < current_line then
        vim.api.nvim_win_set_cursor(win, { idx, 0 })
        M.update_preview()
        return
      end
    end
  end, opts)

  -- Cursor move handler
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = results_buf,
    callback = M.on_cursor_move,
  })

  -- Search input keymaps
  local search_opts = { buffer = search_buf, nowait = true }

  -- Normal mode in search
  vim.keymap.set("n", "<Esc>", M.close, search_opts)
  vim.keymap.set("n", "q", M.close, search_opts)
  vim.keymap.set("n", "<CR>", function() ui.focus_results() end, search_opts)
  vim.keymap.set("n", "<Tab>", function() ui.focus_results() end, search_opts)
  vim.keymap.set("n", "j", function() ui.focus_results() end, search_opts)
  vim.keymap.set("n", "k", function() ui.focus_results() end, search_opts)

  -- Insert mode in search
  vim.keymap.set("i", "<Esc>", function()
    vim.cmd("stopinsert")
    M.close()
  end, search_opts)
  vim.keymap.set("i", "<CR>", function()
    vim.cmd("stopinsert")
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

  -- Search text change handler (debounced)
  local timer = nil
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = search_buf,
    callback = function()
      if timer then
        vim.fn.timer_stop(timer)
      end
      timer = vim.fn.timer_start(150, function()
        vim.schedule(function()
          local lines = vim.api.nvim_buf_get_lines(search_buf, 0, 1, false)
          M.on_search_change(lines[1] or "")
        end)
      end)
    end,
  })
end

function M.setup(opts)
  opts = opts or {}
  vim.keymap.set("n", opts.keymap or "<leader>f", M.open, { desc = "Find in files" })
end

return M

-- vs-f/preview.lua - File preview with line highlighting
local M = {}

local ns_id = vim.api.nvim_create_namespace("vs-f_preview")

function M.show(win, path, target_line, query)
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  -- Check if file exists
  local stat = vim.loop.fs_stat(path)
  if not stat then
    M.show_message(win, { "  File not found" })
    return
  end

  -- Check file size
  if stat.size > 1024 * 1024 then
    M.show_message(win, { "  File too large to preview" })
    return
  end

  -- Read file content
  local lines = {}
  local file = io.open(path, "r")
  if file then
    for line in file:lines() do
      table.insert(lines, line)
      if #lines > 2000 then
        table.insert(lines, "... (truncated)")
        break
      end
    end
    file:close()
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })

  -- Set buffer in window
  vim.api.nvim_win_set_buf(win, buf)

  -- Enable syntax highlighting
  local ext = vim.fn.fnamemodify(path, ":e")
  local ft_map = {
    java = "java", lua = "lua", py = "python", js = "javascript",
    ts = "typescript", json = "json", xml = "xml", yml = "yaml",
    yaml = "yaml", md = "markdown", html = "html", css = "css",
    sh = "sh", bash = "bash", zsh = "zsh", vim = "vim",
    properties = "jproperties", gradle = "groovy", kt = "kotlin",
    rs = "rust", go = "go", rb = "ruby", php = "php", c = "c",
    cpp = "cpp", h = "c", hpp = "cpp", jsx = "javascriptreact",
    tsx = "typescriptreact", vue = "vue", svelte = "svelte",
    sql = "sql", graphql = "graphql", toml = "toml",
  }
  local ft = ft_map[ext]
  if ft then
    vim.api.nvim_set_option_value("syntax", ft, { buf = buf })
  end

  -- Jump to target line and center it
  if target_line and target_line > 0 and target_line <= #lines then
    vim.api.nvim_win_set_cursor(win, { target_line, 0 })
    -- Center the view
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! zz")
    end)
  end

  -- Highlight matching text on the target line
  if query and query ~= "" and target_line and target_line <= #lines then
    local line_text = lines[target_line]
    if line_text then
      -- Find all matches on the line (case insensitive)
      local lower_line = line_text:lower()
      local lower_query = query:lower()
      local start_pos = 1

      while true do
        local match_start, match_end = lower_line:find(lower_query, start_pos, true)
        if not match_start then break end

        vim.api.nvim_buf_add_highlight(buf, ns_id, "Search", target_line - 1, match_start - 1, match_end)
        start_pos = match_end + 1
      end

      -- Also highlight the entire line subtly
      vim.api.nvim_buf_add_highlight(buf, ns_id, "CursorLine", target_line - 1, 0, -1)
    end
  end
end

function M.show_empty(win)
  M.show_message(win, { "", "  Type to search in files..." })
end

function M.show_message(win, lines)
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_win_set_buf(win, buf)
end

return M

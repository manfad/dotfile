-- vs-p/preview.lua - File preview functionality
local M = {}

local current_preview_buf = nil

function M.show(win, path)
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  -- Check if file exists and is readable
  local stat = vim.loop.fs_stat(path)
  if not stat then
    M.show_message(win, { "  File not found" })
    return
  end

  -- Check file size (skip large files)
  if stat.size > 1024 * 1024 then -- 1MB limit
    M.show_message(win, { "  File too large to preview", "  Size: " .. M.format_size(stat.size) })
    return
  end

  -- Check if it's a binary file
  if M.is_binary(path) then
    M.show_message(win, { "  Binary file", "  " .. vim.fn.fnamemodify(path, ":t") })
    return
  end

  -- Read file content directly (avoid triggering ftplugins like jdtls)
  local lines = {}
  local file = io.open(path, "r")
  if file then
    for line in file:lines() do
      table.insert(lines, line)
      if #lines > 1000 then -- Limit preview lines
        table.insert(lines, "... (truncated)")
        break
      end
    end
    file:close()
  end

  -- Create a scratch buffer for preview
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })

  -- Set buffer in preview window
  vim.api.nvim_win_set_buf(win, buf)

  -- Enable syntax highlighting without triggering ftplugin
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

  -- Scroll to top
  vim.api.nvim_win_set_cursor(win, { 1, 0 })

  current_preview_buf = buf
end

function M.show_empty(win)
  M.show_message(win, { "", "  Select a file to preview" })
end

function M.show_message(win, lines)
  if not win or not vim.api.nvim_win_is_valid(win) then return end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
  vim.api.nvim_win_set_buf(win, buf)
end

function M.is_binary(path)
  local f = io.open(path, "rb")
  if not f then return true end

  local chunk = f:read(1024)
  f:close()

  if not chunk then return false end

  -- Check for null bytes (common in binary files)
  if chunk:find("\0") then
    return true
  end

  return false
end

function M.format_size(bytes)
  local units = { "B", "KB", "MB", "GB" }
  local i = 1
  while bytes >= 1024 and i < #units do
    bytes = bytes / 1024
    i = i + 1
  end
  return string.format("%.1f %s", bytes, units[i])
end

return M

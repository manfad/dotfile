-- vs-p/search.lua - Fuzzy file search functionality
local M = {}

local has_devicons, devicons = pcall(require, "nvim-web-devicons")

local icons = {
  file = "",
}

function M.get_icon(name)
  if has_devicons then
    local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
    return icon or icons.file, hl
  end
  return icons.file, "Normal"
end

-- Shorten path to show only last N directories
-- e.g., "app/book/component/forms/BookForm.tsx" with depth=3 becomes "../component/forms/BookForm.tsx"
function M.shorten_path(path, depth)
  local parts = {}
  for part in string.gmatch(path, "[^/]+") do
    table.insert(parts, part)
  end

  if #parts <= depth then
    return path
  end

  -- Take last 'depth' parts and prepend with ".."
  local shortened = {}
  for i = #parts - depth + 1, #parts do
    table.insert(shortened, parts[i])
  end

  return "../" .. table.concat(shortened, "/")
end

function M.find_files(cwd, query)
  local results = {}

  if not query or query == "" then
    return results
  end

  -- Escape special characters for shell
  local escaped_query = query:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "\\%1")

  -- Use fd (preferred)
  local cmd
  if vim.fn.executable("fd") == 1 then
    cmd = {
      "fd",
      "--type", "f",
      "--hidden",
      "--follow",
      "--exclude", ".git",
      "--exclude", "node_modules",
      "--exclude", "target",
      "--exclude", ".class",
      escaped_query,
      cwd,
    }
  else
    -- Fallback to find
    cmd = {
      "find", cwd,
      "-type", "f",
      "-iname", "*" .. escaped_query .. "*",
      "-not", "-path", "*/.git/*",
      "-not", "-path", "*/node_modules/*",
    }
  end

  -- Run command synchronously
  local output = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 then
    return results
  end

  -- Parse results (limit to 100)
  local count = 0
  for _, line in ipairs(output) do
    if line and line ~= "" then
      count = count + 1
      if count > 100 then break end

      local name = vim.fn.fnamemodify(line, ":t")
      local relative_path = line:gsub("^" .. vim.pesc(cwd) .. "/?", "")

      -- Shorten to 3 directory levels: ../dir2/dir3/file.ext
      local short_path = M.shorten_path(relative_path, 3)

      table.insert(results, {
        name = name,
        path = line,
        type = "file",
        relative_path = relative_path,
        display_path = short_path,
      })
    end
  end

  -- Sort by relevance (exact match in filename first, then shorter paths)
  table.sort(results, function(a, b)
    local a_name_match = a.name:lower():find(query:lower(), 1, true)
    local b_name_match = b.name:lower():find(query:lower(), 1, true)

    -- Exact filename matches first
    if a_name_match == 1 and b_name_match ~= 1 then return true end
    if b_name_match == 1 and a_name_match ~= 1 then return false end

    -- Then any filename match
    if a_name_match and not b_name_match then return true end
    if b_name_match and not a_name_match then return false end

    -- Then by path length
    return #a.relative_path < #b.relative_path
  end)

  return results
end

function M.render_results(results)
  local lines = {}
  local highlights = {}

  if #results == 0 then
    return { "  No results found" }, {}
  end

  for i, item in ipairs(results) do
    local icon, hl_group = M.get_icon(item.name)
    local display = item.display_path or item.relative_path
    local line = "  " .. icon .. " " .. display

    table.insert(lines, line)

    -- Highlight icon
    if hl_group then
      table.insert(highlights, {
        line = i - 1,
        col_start = 2,
        col_end = 2 + #icon + 1,
        group = hl_group,
      })
    end

    -- Dim the path prefix, highlight the filename
    local name_pos = line:find(item.name, 1, true)
    if name_pos then
      -- Dim path before filename
      table.insert(highlights, {
        line = i - 1,
        col_start = 2 + #icon + 1,
        col_end = name_pos - 1,
        group = "Comment",
      })
      -- Highlight filename
      table.insert(highlights, {
        line = i - 1,
        col_start = name_pos - 1,
        col_end = name_pos - 1 + #item.name,
        group = "Title",
      })
    end
  end

  return lines, highlights
end

return M

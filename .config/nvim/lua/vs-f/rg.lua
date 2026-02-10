-- vs-f/rg.lua - Ripgrep search integration (grouped by file)
local M = {}

local has_devicons, devicons = pcall(require, "nvim-web-devicons")

function M.get_icon(name)
  if has_devicons then
    local icon, hl = devicons.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
    return icon or "", hl
  end
  return "*", "Normal"
end

-- Shorten path to last N directories
function M.shorten_path(path, depth)
  local parts = {}
  for part in string.gmatch(path, "[^/]+") do
    table.insert(parts, part)
  end

  if #parts <= depth then
    return path
  end

  local shortened = {}
  for i = #parts - depth + 1, #parts do
    table.insert(shortened, parts[i])
  end

  return "../" .. table.concat(shortened, "/")
end

function M.search(cwd, query)
  local results = {}

  if not query or query == "" then
    return results, {}
  end

  -- Check if rg is available
  if vim.fn.executable("rg") ~= 1 then
    return results, {}
  end

  -- Run ripgrep
  local cmd = {
    "rg",
    "--line-number",
    "--column",
    "--no-heading",
    "--color=never",
    "--smart-case",
    "--max-count=50",  -- Limit matches per file
    "--max-filesize=1M",
    "-g", "!.git",
    "-g", "!node_modules",
    "-g", "!target",
    "-g", "!*.class",
    "-g", "!*.jar",
    query,
    cwd,
  }

  local output = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 and vim.v.shell_error ~= 1 then
    return results, {}
  end

  -- Group results by file
  local grouped = {}
  local file_order = {}

  for _, line in ipairs(output) do
    if line and line ~= "" then
      local path, lnum, col, text = line:match("^(.+):(%d+):(%d+):(.*)$")

      if path and lnum then
        if not grouped[path] then
          grouped[path] = {
            path = path,
            name = vim.fn.fnamemodify(path, ":t"),
            relative_path = path:gsub("^" .. vim.pesc(cwd) .. "/?", ""),
            matches = {},
          }
          table.insert(file_order, path)
        end

        -- Limit matches per file
        if #grouped[path].matches < 20 then
          table.insert(grouped[path].matches, {
            line = tonumber(lnum),
            col = tonumber(col) or 1,
            text = text or "",
          })
        end
      end
    end
  end

  -- Build flat list with file headers
  local file_indices = {} -- Track which lines are file headers

  for _, file_path in ipairs(file_order) do
    local file = grouped[file_path]
    local short_path = M.shorten_path(file.relative_path, 3)

    -- Add file header
    table.insert(results, {
      type = "file",
      path = file.path,
      name = file.name,
      display_path = short_path,
      match_count = #file.matches,
    })
    table.insert(file_indices, #results)

    -- Add matches under this file
    for _, match in ipairs(file.matches) do
      table.insert(results, {
        type = "match",
        path = file.path,
        name = file.name,
        line = match.line,
        col = match.col,
        text = match.text,
      })
    end

    -- Limit total files
    if #file_order > 30 then break end
  end

  return results, file_indices
end

function M.render_results(results, query)
  local lines = {}
  local highlights = {}

  if #results == 0 then
    return { "  Type to search..." }, {}
  end

  for i, item in ipairs(results) do
    if item.type == "file" then
      -- File header line
      local icon, hl_group = M.get_icon(item.name)
      local line = " " .. icon .. " " .. item.display_path .. "  (" .. item.match_count .. " matches)"

      table.insert(lines, line)

      -- Highlight icon
      if hl_group then
        table.insert(highlights, {
          line = i - 1,
          col_start = 1,
          col_end = 1 + #icon + 1,
          group = hl_group,
        })
      end

      -- Highlight file path (bold)
      table.insert(highlights, {
        line = i - 1,
        col_start = 1 + #icon + 1,
        col_end = 1 + #icon + 1 + #item.display_path,
        group = "Title",
      })

      -- Dim match count
      table.insert(highlights, {
        line = i - 1,
        col_start = 1 + #icon + 1 + #item.display_path,
        col_end = -1,
        group = "Comment",
      })

    else
      -- Match line (indented)
      local line_num = string.format("%4d", item.line)
      local text_preview = item.text:sub(1, 60):gsub("^%s+", "")
      if #item.text > 60 then
        text_preview = text_preview .. "..."
      end

      local line = "    " .. line_num .. ": " .. text_preview

      table.insert(lines, line)

      -- Dim line number
      table.insert(highlights, {
        line = i - 1,
        col_start = 4,
        col_end = 4 + #line_num + 1,
        group = "LineNr",
      })

      -- Highlight matching text
      if query and query ~= "" then
        local text_start = 4 + #line_num + 2
        local match_start, match_end = text_preview:lower():find(query:lower(), 1, true)
        if match_start then
          table.insert(highlights, {
            line = i - 1,
            col_start = text_start + match_start - 1,
            col_end = text_start + match_end,
            group = "Search",
          })
        end
      end
    end
  end

  return lines, highlights
end

return M

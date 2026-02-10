-- Kuroyukihime colorscheme
vim.g.colors_name = "kuroyukihime"

local c = {
	bg = "#0b0012",
	bg_dark = "#050009",
	bg_float = "#14001f",
	bg_light = "#1a0033",
	fg = "#e8d9ff",
	fg_dim = "#c4a1ff",
	purple = "#9c27b0",
	magenta = "#c2185b",
	hotpink = "#ff4081",
	violet_glow = "#d500f9",
	comment = "#9575cd",
	gray = "#4a148c",
	green = "#69f0ae",
	red = "#ff1744",
	yellow = "#ffea00",
}

local hl = vim.api.nvim_set_hl

-- Editor basics
hl(0, "Normal", { fg = c.fg, bg = c.bg })
hl(0, "NormalFloat", { fg = c.fg, bg = c.bg_float })
hl(0, "FloatBorder", { fg = c.purple, bg = c.bg_float })
hl(0, "Comment", { fg = c.comment, italic = true })
hl(0, "Constant", { fg = c.violet_glow })
hl(0, "String", { fg = c.hotpink })
hl(0, "Character", { fg = c.hotpink })
hl(0, "Number", { fg = c.magenta })
hl(0, "Boolean", { fg = c.magenta })
hl(0, "Identifier", { fg = c.fg_dim })
hl(0, "Function", { fg = c.purple })
hl(0, "Statement", { fg = c.magenta })
hl(0, "Operator", { fg = c.violet_glow })
hl(0, "Keyword", { fg = c.purple, bold = true })
hl(0, "PreProc", { fg = c.magenta })
hl(0, "Type", { fg = c.purple })
hl(0, "Special", { fg = c.hotpink })
hl(0, "Underlined", { fg = c.hotpink, underline = true })
hl(0, "Error", { fg = c.red, bold = true })
hl(0, "WarningMsg", { fg = c.yellow })
hl(0, "Delimiter", { fg = c.fg_dim })

-- UI
hl(0, "LineNr", { fg = c.gray })
hl(0, "CursorLineNr", { fg = c.hotpink, bold = true })
hl(0, "CursorLine", { bg = c.bg_light })
hl(0, "ColorColumn", { bg = c.bg_light })
hl(0, "SignColumn", { bg = c.bg })
hl(0, "VertSplit", { fg = c.gray })
hl(0, "WinSeparator", { fg = c.gray })
hl(0, "StatusLine", { fg = c.fg_dim, bg = c.bg_dark })
hl(0, "StatusLineNC", { fg = c.gray, bg = c.bg_dark })
hl(0, "Pmenu", { fg = c.fg, bg = c.bg_float })
hl(0, "PmenuSel", { fg = c.bg, bg = c.hotpink })
hl(0, "PmenuSbar", { bg = c.bg_light })
hl(0, "PmenuThumb", { bg = c.purple })
hl(0, "Visual", { bg = c.gray })
hl(0, "Search", { fg = c.bg, bg = c.hotpink })
hl(0, "IncSearch", { fg = c.bg, bg = c.violet_glow })
hl(0, "MatchParen", { fg = c.hotpink, bold = true })
hl(0, "Directory", { fg = c.purple })
hl(0, "Title", { fg = c.hotpink, bold = true })
hl(0, "EndOfBuffer", { fg = c.bg })
hl(0, "NonText", { fg = c.gray })
hl(0, "TabLine", { fg = c.gray, bg = c.bg_dark })
hl(0, "TabLineSel", { fg = c.hotpink, bg = c.bg })
hl(0, "TabLineFill", { bg = c.bg_dark })

-- Treesitter
hl(0, "@keyword", { fg = c.purple, bold = true })
hl(0, "@keyword.return", { fg = c.magenta, bold = true })
hl(0, "@keyword.function", { fg = c.purple, bold = true })
hl(0, "@keyword.operator", { fg = c.violet_glow })
hl(0, "@conditional", { fg = c.purple, bold = true })
hl(0, "@repeat", { fg = c.purple, bold = true })
hl(0, "@string", { fg = c.hotpink })
hl(0, "@string.escape", { fg = c.magenta })
hl(0, "@function", { fg = c.purple })
hl(0, "@function.call", { fg = c.purple })
hl(0, "@function.builtin", { fg = c.violet_glow })
hl(0, "@method", { fg = c.purple })
hl(0, "@method.call", { fg = c.purple })
hl(0, "@variable", { fg = c.fg_dim })
hl(0, "@variable.builtin", { fg = c.violet_glow })
hl(0, "@parameter", { fg = c.fg_dim })
hl(0, "@comment", { fg = c.comment, italic = true })
hl(0, "@property", { fg = c.fg_dim })
hl(0, "@field", { fg = c.fg_dim })
hl(0, "@type", { fg = c.magenta })
hl(0, "@type.builtin", { fg = c.magenta })
hl(0, "@constant", { fg = c.violet_glow })
hl(0, "@constant.builtin", { fg = c.violet_glow })
hl(0, "@constructor", { fg = c.purple })
hl(0, "@punctuation", { fg = c.fg_dim })
hl(0, "@punctuation.bracket", { fg = c.fg_dim })
hl(0, "@punctuation.delimiter", { fg = c.fg_dim })
hl(0, "@tag", { fg = c.hotpink })
hl(0, "@tag.attribute", { fg = c.purple })
hl(0, "@tag.delimiter", { fg = c.gray })
hl(0, "@operator", { fg = c.violet_glow })
hl(0, "@number", { fg = c.magenta })
hl(0, "@boolean", { fg = c.magenta })

-- LSP Diagnostics
hl(0, "DiagnosticError", { fg = c.red })
hl(0, "DiagnosticWarn", { fg = c.yellow })
hl(0, "DiagnosticInfo", { fg = c.purple })
hl(0, "DiagnosticHint", { fg = c.comment })
hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = c.red })
hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = c.yellow })
hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = c.purple })
hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = c.comment })

-- Git Signs
hl(0, "GitSignsAdd", { fg = c.green })
hl(0, "GitSignsChange", { fg = c.purple })
hl(0, "GitSignsDelete", { fg = c.red })
hl(0, "DiffAdd", { bg = "#1a3320" })
hl(0, "DiffChange", { bg = "#1a1a33" })
hl(0, "DiffDelete", { bg = "#331a1a" })

-- Telescope
hl(0, "TelescopeNormal", { fg = c.fg, bg = c.bg })
hl(0, "TelescopeBorder", { fg = c.purple, bg = c.bg })
hl(0, "TelescopeSelection", { bg = c.bg_light })
hl(0, "TelescopeSelectionCaret", { fg = c.hotpink })
hl(0, "TelescopeMatching", { fg = c.hotpink, bold = true })
hl(0, "TelescopePromptPrefix", { fg = c.hotpink })
hl(0, "TelescopePromptNormal", { fg = c.fg, bg = c.bg })
hl(0, "TelescopePromptBorder", { fg = c.purple, bg = c.bg })
hl(0, "TelescopeResultsNormal", { fg = c.fg, bg = c.bg })
hl(0, "TelescopeResultsBorder", { fg = c.purple, bg = c.bg })
hl(0, "TelescopePreviewNormal", { fg = c.fg, bg = c.bg })
hl(0, "TelescopePreviewBorder", { fg = c.purple, bg = c.bg })

-- Blink.cmp
hl(0, "BlinkCmpMenu", { fg = c.fg, bg = c.bg_float })
hl(0, "BlinkCmpMenuBorder", { fg = c.purple, bg = c.bg_float })
hl(0, "BlinkCmpMenuSelection", { bg = c.bg_light })
hl(0, "BlinkCmpLabel", { fg = c.fg })
hl(0, "BlinkCmpLabelMatch", { fg = c.hotpink, bold = true })
hl(0, "BlinkCmpKind", { fg = c.purple })

-- Custom border highlights for explorer/finder
hl(0, "FocusedBorder", { fg = c.hotpink, bold = true })
hl(0, "UnfocusedBorder", { fg = c.gray })

vim.opt.termguicolors = true

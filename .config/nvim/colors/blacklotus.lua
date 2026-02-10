local colors = {
	bg = "#0D0D12",
	fg = "#E0E0E0",
	fg_dim = "#c4a1ff", -- From kuroyukihime
	black = "#1A1A24",
	magenta = "#FF007C", -- The bright wing pink
	purple = "#BD00FF", -- The glowing eye/armor purple
	purple_kuro = "#9c27b0", -- From kuroyukihime (for imports)
	grey = "#5C5C70", -- Comments
	white = "#FFFFFF",
	selection = "#3A2A4D",
}

-- Clear highlights
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
	vim.cmd("syntax reset")
end
vim.g.colors_name = "blacklotus"

local hl = function(group, opts)
	vim.api.nvim_set_hl(0, group, opts)
end

-- Editor UI
hl("Normal", { fg = colors.fg, bg = colors.bg })
hl("NormalFloat", { fg = colors.fg, bg = colors.bg })
hl("FloatBorder", { fg = colors.purple, bg = colors.bg })
hl("CursorLine", { bg = colors.black })
hl("Visual", { bg = colors.selection })
hl("LineNr", { fg = colors.purple })
hl("CursorLineNr", { fg = colors.magenta, bold = true })
hl("EndOfBuffer", { fg = colors.bg })
hl("SignColumn", { bg = colors.bg })
hl("VertSplit", { fg = colors.black })
hl("WinSeparator", { fg = colors.black })
hl("Pmenu", { fg = colors.fg, bg = colors.black })
hl("PmenuSel", { fg = colors.white, bg = colors.selection })
hl("Search", { fg = colors.bg, bg = colors.magenta })
hl("IncSearch", { fg = colors.bg, bg = colors.purple })
hl("StatusLine", { fg = colors.purple, bg = colors.black })
hl("StatusLineNC", { fg = colors.red, bg = colors.black })
hl("TabLine", { fg = colors.grey, bg = colors.black })
hl("TabLineSel", { fg = colors.magenta, bg = colors.bg })
hl("TabLineFill", { bg = colors.black })
hl("MatchParen", { fg = colors.magenta, bold = true })
hl("Directory", { fg = colors.purple })
hl("Title", { fg = colors.magenta, bold = true })

-- Syntax Highlighting
hl("Comment", { fg = colors.grey, italic = true })
hl("Keyword", { fg = colors.magenta, bold = true })
hl("Function", { fg = colors.purple, bold = true })
hl("String", { fg = "#D48BFF" }) -- Soft purple-pink
hl("Constant", { fg = colors.magenta })
hl("Number", { fg = colors.magenta })
hl("Boolean", { fg = colors.magenta })
hl("Type", { fg = colors.purple })
hl("Identifier", { fg = colors.fg_dim })
hl("Statement", { fg = colors.magenta })
hl("Operator", { fg = colors.purple })
hl("PreProc", { fg = colors.magenta })
hl("Special", { fg = colors.white })
hl("Delimiter", { fg = colors.fg })
hl("Error", { fg = "#FF5555" })
hl("WarningMsg", { fg = "#FFAA00" })

-- Treesitter
hl("@variable", { fg = colors.fg_dim })
hl("@parameter", { fg = colors.fg })
hl("@field", { fg = colors.purple })
hl("@property", { fg = colors.purple })
hl("@function", { fg = colors.purple, bold = true })
hl("@function.call", { fg = colors.purple })
hl("@method", { fg = colors.purple, bold = true })
hl("@keyword", { fg = colors.magenta, bold = true })
hl("@keyword.return", { fg = colors.magenta, bold = true })
hl("@keyword.function", { fg = colors.magenta, bold = true })
hl("@conditional", { fg = colors.magenta, bold = true })
hl("@repeat", { fg = colors.magenta, bold = true })
hl("@string", { fg = "#D48BFF" })
hl("@type", { fg = colors.purple })
hl("@type.builtin", { fg = colors.purple })
hl("@constant", { fg = colors.magenta })
hl("@constant.builtin", { fg = colors.magenta })
hl("@constructor", { fg = colors.purple })
hl("@punctuation", { fg = colors.fg })
hl("@punctuation.bracket", { fg = colors.fg })
hl("@punctuation.delimiter", { fg = colors.fg })
hl("@tag", { fg = colors.magenta })
hl("@tag.attribute", { fg = colors.purple })
hl("@tag.delimiter", { fg = colors.grey })

-- TSX/JSX specific
hl("@tag.tsx", { fg = colors.magenta })
hl("@tag.jsx", { fg = colors.magenta })
hl("@tag.attribute.tsx", { fg = colors.purple })
hl("@tag.attribute.jsx", { fg = colors.purple })
hl("@constructor.tsx", { fg = colors.fg_dim })
hl("@constructor.jsx", { fg = colors.fg_dim })

-- Import/Export (multiple formats for compatibility)
hl("@keyword.import", { fg = "#ff4081", bold = true })
hl("@keyword.export", { fg = "#ff4081", bold = true })
hl("@include", { fg = "#ff4081", bold = true })
hl("@namespace", { fg = colors.fg_dim })

-- TypeScript/JavaScript vim syntax groups
hl("typescriptImport", { fg = "#ff4081", bold = true })
hl("typescriptExport", { fg = "#ff4081", bold = true })
hl("typescriptImportType", { fg = "#ff4081", bold = true })
hl("typescriptDefaultImportName", { fg = colors.fg_dim })
hl("typescriptIdentifierName", { fg = colors.fg_dim })
hl("typescriptTypeBlock", { fg = colors.fg_dim })
hl("typescriptBlock", { fg = colors.fg })
hl("typescriptVariable", { fg = colors.magenta, bold = true })
hl("typescriptOperator", { fg = colors.purple })
hl("typescriptBraces", { fg = colors.fg })
hl("typescriptEndColons", { fg = colors.fg })
hl("typescriptModule", { fg = colors.fg_dim })
hl("typescriptPredefinedType", { fg = colors.purple })
hl("typescriptTypeReference", { fg = colors.fg_dim })
hl("typescriptObjectLabel", { fg = colors.purple })
hl("typescriptCall", { fg = colors.fg_dim })
hl("typescriptArrowFunc", { fg = colors.purple })
hl("typescriptStatementKeyword", { fg = "#ff4081", bold = true }) -- hotpink for const/let/return etc
hl("typescriptConditionalParen", { fg = colors.fg })
hl("typescriptParenExp", { fg = colors.fg })
hl("typescriptBOMWindowProp", { fg = colors.purple })

-- TSX/JSX vim syntax groups
hl("tsxTag", { fg = colors.magenta })
hl("tsxTagName", { fg = colors.magenta })
hl("tsxIntrinsicTagName", { fg = colors.magenta })
hl("tsxCloseTag", { fg = colors.magenta })
hl("tsxCloseTagName", { fg = colors.magenta })
hl("tsxCloseString", { fg = colors.grey })
hl("tsxRegion", { fg = colors.fg })
hl("tsxAttrib", { fg = colors.purple })
hl("tsxEqual", { fg = colors.purple })
hl("tsxString", { fg = "#D48BFF" })
hl("htmlTag", { fg = colors.grey })
hl("htmlTagName", { fg = colors.magenta })
hl("htmlArg", { fg = colors.purple })

-- Diagnostics
hl("DiagnosticError", { fg = "#FF5555" })
hl("DiagnosticWarn", { fg = "#FFAA00" })
hl("DiagnosticInfo", { fg = colors.purple })
hl("DiagnosticHint", { fg = colors.grey })

-- Git signs
hl("GitSignsAdd", { fg = "#50FA7B" })
hl("GitSignsChange", { fg = colors.purple })
hl("GitSignsDelete", { fg = "#FF5555" })

-- Telescope
hl("TelescopeNormal", { fg = colors.fg, bg = colors.bg })
hl("TelescopeBorder", { fg = colors.purple, bg = colors.bg })
hl("TelescopeSelection", { bg = colors.selection })
hl("TelescopeMatching", { fg = colors.magenta, bold = true })
hl("TelescopePromptPrefix", { fg = colors.magenta })

-- LSP Semantic Tokens (override treesitter)
hl("@lsp.type.class", { fg = colors.fg_dim })
hl("@lsp.type.type", { fg = colors.fg_dim })
hl("@lsp.type.interface", { fg = colors.fg_dim })
hl("@lsp.type.namespace", { fg = colors.fg_dim })
hl("@lsp.type.enum", { fg = colors.fg_dim })
hl("@lsp.type.enumMember", { fg = colors.magenta })
hl("@lsp.type.variable", { fg = colors.fg_dim })
hl("@lsp.type.property", { fg = colors.purple })
hl("@lsp.type.function", { fg = colors.purple, bold = true })
hl("@lsp.type.method", { fg = colors.purple, bold = true })
hl("@lsp.type.parameter", { fg = colors.fg })
hl("@lsp.type.keyword", { fg = colors.magenta, bold = true })
hl("@lsp.type.string", { fg = "#D48BFF" })
hl("@lsp.type.number", { fg = colors.magenta })
hl("@lsp.type.operator", { fg = colors.purple })
hl("@lsp.typemod.variable.readonly", { fg = colors.magenta })
hl("@lsp.typemod.property.readonly", { fg = colors.magenta })

-- Custom border highlights for explorer/finder
hl("FocusedBorder", { fg = colors.magenta, bold = true })
hl("UnfocusedBorder", { fg = colors.grey })

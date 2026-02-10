-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Basic settings
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true

-- Transparent background (set terminal opacity to 0.85)
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "FloatBorder", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
		vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
	end,
})

-- Auto-change working directory to opened folder (VSCode-like behavior)
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		local arg = vim.fn.argv(0)
		if arg ~= "" and vim.fn.isdirectory(arg) == 1 then
			vim.cmd.cd(arg)
		end
	end,
})

-- Load plugins
require("lazy").setup({
	-- Colorscheme (blacklotus - custom theme in colors/blacklotus.lua)
	{
		"nyoom-engineering/oxocarbon.nvim", -- keep as fallback
		lazy = true,
	},

	-- Fuzzy finder (like Cmd-P in VSCode)
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			require("telescope").setup({
				defaults = {
					prompt_prefix = "   ",
					selection_caret = " ",
					path_display = { "smart" },
					file_ignore_patterns = { "node_modules", ".git/", "target/" },
					layout_strategy = "horizontal",
					layout_config = {
						preview_width = 0.55,
					},
					preview = {
						filesize_limit = 0.5,
					},
				},
			})
		end,
		keys = {
			{
				"<leader>p",
				function()
					require("telescope.builtin").find_files({ hidden = true })
				end,
				desc = "Find files",
			},
			{
				"<leader>b",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>s",
				function()
					require("telescope.builtin").lsp_document_symbols()
				end,
				desc = "Document symbols",
			},
		},
	},

	-- Syntax highlighting & code understanding
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({
				ensure_installed = {
					-- Web
					"html",
					"css",
					"scss",
					"javascript",
					"typescript",
					"tsx",
					"vue",
					"json",
					"jsonc",
					"yaml",
					"toml",
					-- Programming
					"lua",
					"vim",
					"vimdoc",
					"java",
					"python",
					-- Docs
					"markdown",
					"markdown_inline",
					-- Other
					"bash",
					"regex",
					"sql",
					"graphql",
					"dockerfile",
					"xml",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
			vim.g.matchup_matchparen_offscreen = { method = "popup" }
			vim.g.matchup_matchparen_deferred = 1
		end,
	},
	-- Multi-cursor (like Ctrl+D in VSCode)
	{
		"mg979/vim-visual-multi",
		branch = "master",
		init = function()
			vim.g.VM_maps = {
				["Find Under"] = "<C-n>",
				["Find Subword Under"] = "<C-n>",
				["Add Cursor Down"] = "<C-Down>",
				["Add Cursor Up"] = "<C-Up>",
				["Select All"] = "<C-a>",
			}
			vim.g.VM_theme = "iceblue"
		end,
	},
	-- Auto-close and Auto-rename HTML/JSX/TSX tags
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		config = function()
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
			})
		end,
	},

	-- Mason: LSP/DAP/Linter installer
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},

	-- Mason-LSPconfig bridge
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls", -- Lua
					"ts_ls", -- TypeScript/JavaScript
					"tailwindcss", -- Tailwind CSS
					"cssls", -- CSS
					"html", -- HTML
					"jsonls", -- JSON
					"yamlls", -- YAML
					"eslint", -- ESLint
					-- jdtls handled separately via nvim-jdtls
				},
			})
		end,
	},

	-- JSON/YAML Schemas
	{
		"b0o/schemastore.nvim",
		lazy = true,
	},

	-- LSP setup using native Neovim 0.11+ API
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp", "b0o/schemastore.nvim" },
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Lua LSP
			vim.lsp.config("lua_ls", {
				capabilities = capabilities,
				settings = {
					Lua = {
						diagnostics = { globals = { "vim" } },
					},
				},
			})
			vim.lsp.enable("lua_ls")

			-- TypeScript/JavaScript LSP
			vim.lsp.config("ts_ls", {
				capabilities = capabilities,
				init_options = {
					plugins = {
						{
							name = "@vue/typescript-plugin",
							location = vim.fn.stdpath("data")
								.. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
							languages = { "vue" },
						},
					},
				},
				filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
			})
			vim.lsp.enable("ts_ls")

			-- Vue LSP (Volar)
			vim.lsp.config("volar", {
				capabilities = capabilities,
				filetypes = { "vue" },
				init_options = {
					vue = {
						hybridMode = true,
					},
				},
			})
			vim.lsp.enable("volar")

			-- Tailwind CSS LSP
			vim.lsp.config("tailwindcss", {
				capabilities = capabilities,
				filetypes = {
					"html",
					"css",
					"scss",
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"vue",
				},
			})
			vim.lsp.enable("tailwindcss")

			-- CSS LSP
			vim.lsp.config("cssls", {
				capabilities = capabilities,
			})
			vim.lsp.enable("cssls")

			-- HTML LSP
			vim.lsp.config("html", {
				capabilities = capabilities,
			})
			vim.lsp.enable("html")

			-- JSON LSP with schemas
			vim.lsp.config("jsonls", {
				capabilities = capabilities,
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})
			vim.lsp.enable("jsonls")

			-- YAML LSP with schemas
			vim.lsp.config("yamlls", {
				capabilities = capabilities,
				settings = {
					yaml = {
						schemas = require("schemastore").yaml.schemas(),
						schemaStore = { enable = false, url = "" },
					},
				},
			})
			vim.lsp.enable("yamlls")

			-- ESLint LSP
			vim.lsp.config("eslint", {
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					-- Auto-fix on save
					vim.api.nvim_create_autocmd("BufWritePre", {
						buffer = bufnr,
						command = "EslintFixAll",
					})
				end,
			})
			vim.lsp.enable("eslint")

			-- LSP Keymaps (set when LSP attaches)
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local opts = { buffer = args.buf }
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "gr", function()
						require("telescope.builtin").lsp_references()
					end, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
					vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
					vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
				end,
			})
		end,
	},
	-- 1. Git Gutter Signs & Blame (GitLens style)
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				current_line_blame = true, -- Shows who changed the line (GitLens style)
			})
		end,
	},

	-- 2. Auto-close Brackets (), {}, []
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		config = true,
	},

	-- 3. Comment with gcc (line) or gc (selection)
	{
		"numToStr/Comment.nvim",
		event = "VeryLazy",
		config = true,
	},

	-- 4. Conform - Code formatter
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
		keys = {
			{
				"<leader>pf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				desc = "Format file",
			},
		},
		opts = {
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				vue = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				lua = { "stylua" },
				java = { "google-java-format" },
				xml = { "xmlformat" },
				sql = { "sql_formatter" },
			},
			format_on_save = {
				timeout_ms = 1000,
				lsp_fallback = true,
			},
		},
	},

	-- 5. Indent guides (like VSCode)
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = "BufReadPost",
		opts = {
			indent = { char = "│" },
			scope = { enabled = true, show_start = false, show_end = false },
		},
	},

	-- 6. Mini.surround - Surround text (sa, sd, sr)
	{
		"echasnovski/mini.surround",
		event = "VeryLazy",
		opts = {
			mappings = {
				add = "sa", -- Add surrounding (sa" to surround with ")
				delete = "sd", -- Delete surrounding (sd")
				replace = "sr", -- Replace surrounding (sr"')
				find = "sf", -- Find surrounding
				find_left = "sF", -- Find surrounding to the left
				highlight = "sh", -- Highlight surrounding
				update_n_lines = "sn", -- Update n_lines
			},
		},
	},

	-- 6. Harpoon - Quick file marks
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup()

			vim.keymap.set("n", "<leader>m", function()
				harpoon:list():add()
			end, { desc = "Harpoon mark file" })
			vim.keymap.set("n", "<leader>M", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon menu" })
			vim.keymap.set("n", "<leader>1", function()
				harpoon:list():select(1)
			end, { desc = "Harpoon file 1" })
			vim.keymap.set("n", "<leader>2", function()
				harpoon:list():select(2)
			end, { desc = "Harpoon file 2" })
			vim.keymap.set("n", "<leader>3", function()
				harpoon:list():select(3)
			end, { desc = "Harpoon file 3" })
			vim.keymap.set("n", "<leader>4", function()
				harpoon:list():select(4)
			end, { desc = "Harpoon file 4" })
		end,
	},

	-- 7. Color preview for hex/rgb (shows actual color)
	{
		"norcalli/nvim-colorizer.lua",
		event = "BufReadPost",
		config = function()
			require("colorizer").setup({
				"*", -- all filetypes
			}, {
				RGB = true,
				RRGGBB = true,
				names = false,
				RRGGBBAA = true,
				rgb_fn = true,
				hsl_fn = true,
				css = true,
				css_fn = true,
			})
		end,
	},

	-- Auto-completion (blink.cmp - faster alternative to nvim-cmp)
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			enabled = function()
				local disabled_filetypes = { "vs-p", "vs-p_search", "vs-f", "vs-f_search" }
				return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
			end,
			keymap = {
				preset = "default",
				["<CR>"] = { "accept", "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				documentation = { auto_show = true },
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			signature = { enabled = true },
		},
	},

	-- Java LSP (nvim-jdtls)
	{
		"mfussenegger/nvim-jdtls",
		ft = "java",
	},

	-- Spring Boot support
	{
		"elmcgill/springboot-nvim",
		ft = "java",
		dependencies = {
			"neovim/nvim-lspconfig",
			"mfussenegger/nvim-jdtls",
		},
		config = function()
			local springboot = require("springboot")
			springboot.setup({})

			-- Spring Boot keymaps
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = function()
					vim.keymap.set("n", "<leader>jr", springboot.boot_run, { buffer = true, desc = "Spring Boot Run" })
					vim.keymap.set(
						"n",
						"<leader>jg",
						springboot.generate_class,
						{ buffer = true, desc = "Generate Class" }
					)
					vim.keymap.set(
						"n",
						"<leader>jG",
						springboot.generate_interface,
						{ buffer = true, desc = "Generate Interface" }
					)
				end,
			})
		end,
	},

	-- Trouble - Better diagnostics list
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
			{ "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
			{ "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix List" },
		},
		opts = {},
	},

	-- TODO comments highlighting
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "BufReadPost",
		keys = {
			{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "TODOs" },
		},
		opts = {},
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- Custom theme combining kuroyukihime + blacklotus
			local colors = {
				bg = "#0D0D12",
				bg_dark = "#050009",
				fg = "#E0E0E0",
				fg_dim = "#c4a1ff",
				purple = "#9c27b0", -- kuroyukihime normal mode
				magenta = "#FF007C",
				hotpink = "#ff4081",
				green = "#00ff87", -- insert mode (brighter green)
				blue = "#00bfff", -- visual mode (brighter blue)
				red = "#ff1744", -- replace/command mode
				grey = "#5C5C70",
			}

			local blacklotus_theme = {
				normal = {
					a = { fg = colors.bg, bg = colors.purple, gui = "bold" },
					b = { fg = colors.fg_dim, bg = colors.bg_dark },
					c = { fg = colors.grey, bg = colors.bg },
				},
				insert = {
					a = { fg = colors.bg, bg = colors.green, gui = "bold" },
					b = { fg = colors.green, bg = colors.bg_dark },
					c = { fg = colors.grey, bg = colors.bg },
				},
				visual = {
					a = { fg = colors.bg, bg = colors.blue, gui = "bold" },
					b = { fg = colors.blue, bg = colors.bg_dark },
					c = { fg = colors.grey, bg = colors.bg },
				},
				replace = {
					a = { fg = colors.bg, bg = colors.red, gui = "bold" },
					b = { fg = colors.red, bg = colors.bg_dark },
					c = { fg = colors.grey, bg = colors.bg },
				},
				command = {
					a = { fg = colors.bg, bg = colors.hotpink, gui = "bold" },
					b = { fg = colors.hotpink, bg = colors.bg_dark },
					c = { fg = colors.grey, bg = colors.bg },
				},
				inactive = {
					a = { fg = colors.grey, bg = colors.bg },
					b = { fg = colors.grey, bg = colors.bg },
					c = { fg = colors.grey, bg = colors.bg },
				},
			}

			require("lualine").setup({
				options = {
					theme = blacklotus_theme,
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					globalstatus = true,
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch" },
					lualine_c = { { "filename", path = 1 } },
					lualine_x = { "filetype" },
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
			})
		end,
	},
})

-- Load colorscheme
vim.cmd.colorscheme("blacklotus")

-- Load vs-p (file explorer with search-first UI)
require("vs-p").setup({ keymap = "<leader>e" })

-- Load vs-f (text search with ripgrep)
require("vs-f").setup({ keymap = "<leader>f" })

-- Move lines up/down with Alt+Up/Down
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
-- Duplicate line up/down with Shift+Alt+Up/Down
vim.keymap.set("n", "<S-A-Up>", "yyP", { noremap = true, silent = true })
vim.keymap.set("n", "<S-A-Down>", "yyp", { noremap = true, silent = true })
vim.keymap.set("v", "<S-A-Up>", "y`>pgv", { noremap = true, silent = true })
vim.keymap.set("v", "<S-A-Down>", "y`<Pgv", { noremap = true, silent = true })
vim.keymap.set("v", "<leader>i", [[<Esc><C-v>gv$A]], { desc = "Insert at end of multi-selection" })

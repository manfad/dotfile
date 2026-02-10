-- Java LSP configuration (nvim-jdtls)
local jdtls = require("jdtls")

-- Find project root
local root_markers = { "pom.xml", "build.gradle", "gradlew", ".git" }
local root_dir = require("jdtls.setup").find_root(root_markers) or vim.fn.getcwd()

-- Workspace directory for this project
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspace/" .. project_name

-- Mason installs jdtls here
local mason_path = vim.fn.stdpath("data") .. "/mason/packages"
local jdtls_path = mason_path .. "/jdtls"
local java_debug_path = mason_path .. "/java-debug-adapter"
local java_test_path = mason_path .. "/java-test"

-- Find the launcher jar
local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- Detect OS for config folder
local os_config = "linux"
if vim.fn.has("mac") == 1 then
  os_config = "mac"
elseif vim.fn.has("win32") == 1 then
  os_config = "win"
end

local config_path = jdtls_path .. "/config_" .. os_config

-- Build bundles for debugging
local bundles = {}

-- Add java-debug-adapter
local debug_jar = vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar")
if debug_jar ~= "" then
  table.insert(bundles, debug_jar)
end

-- Add java-test jars
local test_jars = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n")
for _, jar in ipairs(test_jars) do
  if jar ~= "" then
    table.insert(bundles, jar)
  end
end

local config = {
  cmd = {
    "java",
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens", "java.base/java.util=ALL-UNNAMED",
    "--add-opens", "java.base/java.lang=ALL-UNNAMED",
    "-jar", launcher_jar,
    "-configuration", config_path,
    "-data", workspace_dir,
  },

  root_dir = root_dir,

  settings = {
    java = {
      home = os.getenv("JAVA_HOME"),
      eclipse = { downloadSources = true },
      configuration = { updateBuildConfiguration = "interactive" },
      maven = { downloadSources = true },
      implementationsCodeLens = { enabled = true },
      referencesCodeLens = { enabled = true },
      references = { includeDecompiledSources = true },
      format = { enabled = true },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },
      completion = {
        favoriteStaticMembers = {
          "org.junit.Assert.*",
          "org.junit.jupiter.api.Assertions.*",
          "org.mockito.Mockito.*",
          "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
          "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
        },
        importOrder = {
          "java",
          "javax",
          "org",
          "com",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  },

  capabilities = require("blink.cmp").get_lsp_capabilities(),

  init_options = {
    bundles = bundles,
  },

  on_attach = function(client, bufnr)
    -- Enable debugging (defer to avoid errors during startup)
    vim.defer_fn(function()
      pcall(function()
        jdtls.setup_dap({ hotcodereplace = "auto" })
      end)
      pcall(function()
        require("jdtls.dap").setup_dap_main_class_configs()
      end)
    end, 1000)

    -- Java-specific keymaps
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "<leader>jo", jdtls.organize_imports, opts)
    vim.keymap.set("n", "<leader>jv", jdtls.extract_variable, opts)
    vim.keymap.set("v", "<leader>jv", function() jdtls.extract_variable(true) end, opts)
    vim.keymap.set("n", "<leader>jc", jdtls.extract_constant, opts)
    vim.keymap.set("v", "<leader>jc", function() jdtls.extract_constant(true) end, opts)
    vim.keymap.set("v", "<leader>jm", function() jdtls.extract_method(true) end, opts)
    vim.keymap.set("n", "<leader>jt", jdtls.test_nearest_method, opts)
    vim.keymap.set("n", "<leader>jT", jdtls.test_class, opts)
  end,
}

-- Start or attach jdtls
jdtls.start_or_attach(config)

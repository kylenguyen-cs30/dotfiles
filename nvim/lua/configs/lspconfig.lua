-- Load NVChad default LSP settings
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local nvlsp = require "nvchad.configs.lspconfig"

-- Create the LspFormatting autocommand group
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

-- Setup Mason to install both LSP servers and formatters/linters
require("mason").setup()

-- Install formatters and linters
require("mason").setup({
  ensure_installed = {
    "shellcheck", -- Linter for shell scripts
    "shfmt",      -- Formatter for shell scripts
    "black",      -- Formatter for Python
    -- Add other formatters or linters here
  },
})

-- Install LSP servers via Mason LSPConfig
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",      -- Lua LSP
    "tailwindcss", -- Tailwind CSS LSP
    "ts_ls",       -- TypeScript/JavaScript LSP
    "cssls",       -- CSS LSP
    "clangd",      -- C/C++ LSP
    "svelte",      -- Svelte LSP
    "pyright",     -- Python LSP
    "prismals",    -- Prisma LSP
    "marksman",    -- Markdown LSP
    "ruff_lsp",    -- Ruff LSP for Python linting
  },
})

-- Define LSP servers to setup
local servers = { "html", "cssls", "tailwindcss", "ts_ls", "pyright", "svelte", "clangd", "marksman", "prismals" }

-- Setup LSP servers with NVChad defaults
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

-- Pyright (Python LSP) with autoformatting
lspconfig.pyright.setup {
  on_attach = function(client, bufnr)
    if client.name == "pyright" then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            async = false,
            filter = function(client)
              return client.name == "pyright"
            end,
            timeout_ms = 5000,
          })
        end,
      })
    end
    nvlsp.on_attach(client, bufnr)
  end,
}

-- Lua LS with autoformatting
lspconfig.lua_ls.setup {
  on_attach = function(client, bufnr)
    if client.name == "lua_ls" then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({
            async = false,
            filter = function(client)
              return client.name == "lua_ls"
            end,
            timeout_ms = 5000,
          })
        end,
      })
    end
    nvlsp.on_attach(client, bufnr)
  end,
  settings = {
    Lua = {
      format = {
        enable = true, -- Enable LSP-based formatting
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
        },
      },
    },
  },
}
-- DAP (Debugging)
-- require("nvim-dap")
-- require("dapui").setup()

-- vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { noremap = true, silent = true })
-- vim.keymap.set("n", "<leader>dpr", function()
--   require("dap-python").test_method()
-- end, { noremap = true, silent = true })
--
-- local dap = require("dap")
-- dap.listeners.after.event_initialized["dapui_config"] = function()
--   require("dapui").open()
-- end
-- dap.listeners.before.event_terminated["dapui_config"] = function()
--   require("dapui").close()
-- end
-- dap.listeners.before.event_exited["dapui_config"] = function()
--   require("dapui").close()
-- end

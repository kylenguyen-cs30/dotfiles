return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },


  -- Mason and Mason-LSPConfig setup
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" }, -- Ensure mason.nvim is installed
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- List the LSP servers you want to install automatically
          "pyright",     -- Python
          "ts_ls",       -- TypeScript/JavaScript (replaced tsserver with ts_ls)
          "tailwindcss", -- TailwindCSS
          "cssls",       -- CSS
          "clangd",      -- C/C++
          "lua_ls",      -- Lua
          -- Add any other LSPs you want to install with Mason here
        },
      })
    end,
  },


  -- Install nvim-dap for debugging
  -- {
  --   "mfussenegger/nvim-dap",
  --   config = function()
  --     local dap = require("dap")
  --     -- Additional DAP configuration can go here
  --   end,
  -- },
  --
  -- {
  --   "rcarriga/nvim-dap-ui",
  --   dependencies = "mfussenegger/nvim-dap",
  --   config = function()
  --     local dapui = require("dapui")
  --     dapui.setup()
  --     -- Optional DAP UI setup, open/close automatically
  --     local dap = require("dap")
  --     dap.listeners.after.event_initialized["dapui_config"] = function()
  --       dapui.open()
  --     end
  --     dap.listeners.before.event_terminated["dapui_config"] = function()
  --       dapui.close()
  --     end
  --     dap.listeners.before.event_exited["dapui_config"] = function()
  --       dapui.close()
  --     end
  --   end,
  -- },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },
}

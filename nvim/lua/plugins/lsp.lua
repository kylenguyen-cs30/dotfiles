local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

return {
  -- tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "luacheck",
        "shellcheck",
        "shfmt",
        "tailwindcss-language-server",
        "typescript-language-server",
        "css-lsp",
        "clangd",
        "svelte-language-server",
        "black",
        "pyright",
        "prisma-language-server",
        "marksman",
        "ruff-lsp", -- add ruff-lsp again
      })
    end,
  },

  -- lsp servers
  {
    "nvim-neotest/nvim-nio",
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = { enabled = false },
      ---@type lspconfig.options
      servers = {

        -- pyright lsp
        pyright = {
          enabled = vim.g.lazyvim_python_lsp ~= "basedpyright",
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
              -- if client.server_capabilities.inlayHintsProvider then
              --   vim.lsp.buf.inlay_hint(bufnr, true)
              -- end
            end
          end,
        },

        -- C/C++ inlayHints
        -- clangd = {
        --   keys = {
        --     { "<leader>cR", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch Source/Header (C/C++)" },
        --   },
        --   root_dir = function(fname)
        --     return require("lspconfig.util").root_pattern(
        --       "Makefile",
        --       "configure.ac",
        --       "configure.in",
        --       "config.h.in",
        --       "meson.build",
        --       "meson_options.txt",
        --       "build.ninja"
        --     )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(
        --       fname
        --     ) or require("lspconfig.util").find_git_ancestor(fname)
        --   end,
        --   capabilities = {
        --     offsetEncoding = { "utf-16" },
        --   },
        --   cmd = {
        --     "clangd",
        --     "--background-index",
        --     "--clang-tidy",
        --     "--header-insertion=iwyu",
        --     "--completion-style=detailed",
        --     "--function-arg-placeholders",
        --     "--fallback-style=llvm",
        --   },
        --   init_options = {
        --     usePlaceholders = true,
        --     completeUnimported = true,
        --     clangdFileStatus = true,
        --   },
        -- },

        marksman = {},
        prismals = {},

        svelte = {
          keys = {
            { "<leader>co", LazyVim.lsp.action["source.organizeImports"], desc = "Organize Imports" },
          },
          capabilities = {
            workspace = {
              didChangeWatchedFiles = vim.fn.has("nvim-0.10") == 0 and { dynamicRegistration = true },
            },
          },
        },

        cssls = {},
        tailwindcss = {
          root_dir = function(...)
            return require("lspconfig.util").root_pattern("tailwind.config.js", ".git")(...)
          end,
          settings = {
            tailwindCSS = {
              lint = {
                cssConflict = "warning",
                invalidApply = "error",
                invalidScreen = "error",
                invalidVariant = "error",
                invalidConfigPath = "error",
                invalidTailwindDirective = "error",
                recommendedVariantOrder = "warning",
              },
              validate = true,
            },
          },
        },

        tsserver = {
          root_dir = function(...)
            return require("lspconfig.util").root_pattern(".git")(...)
          end,
          single_file_support = false,
          settings = {
            typescript = {
              inlayHints = {
                -- includeInlayParameterNameHints = "literal",
                enabled = false,
                includeInlayParameterNameHints = "none",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = false,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = false,
                includeInlayFunctionLikeReturnTypeHints = false,
                includeInlayEnumMemberValueHints = false,
              },
            },
            javascript = {
              inlayHints = {
                -- includeInlayParameterNameHints = "all",
                enabled = false,
                includeInlayParameterNameHints = "none",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = false,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = false,
                includeInlayFunctionLikeReturnTypeHints = false,
                includeInlayEnumMemberValueHints = false,
              },
            },
          },
        },
        html = {
          filetypes = { "html", "htm" },
          settings = {
            html = {
              suggest = {
                html5 = true,
                angular1 = false,
                ionic = false,
                jquery = false,
              },
            },
          },
        },

        lua_ls = {
          single_file_support = true,
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              completion = {
                workspaceWord = true,
                callSnippet = "Both",
              },
              diagnostics = {
                disable = { "incomplete-signature-doc", "trailing-space" },
                groupSeverity = { strong = "Warning", strict = "Warning" },
              },
              format = {
                enable = false,
                defaultConfig = { indent_style = "space", indent_size = "2" },
              },
            },
          },
        },
      },
      setup = {
        clangd = function(_, opts)
          local clangd_ext_opts = require("lazyvim.util").opts("clangd_extensions.nvim")
          require("clangd_extensions").setup(vim.tbl_deep_extend("force", clangd_ext_opts or {}, { server = opts }))
          return false
        end,
      },
    },
  },
  {
    "p00f/clangd_extensions.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("clangd_extensions").setup({})
    end,
  },
  {
    "nvim-cmp",
    dependencies = { "hrsh7th/cmp-emoji" },
    opts = function(_, opts)
      table.insert(opts.sources, { name = "emoji" })
      table.insert(opts.sorting.comparators, 1, require("clangd_extensions.cmp_scores"))
    end,
  },

  {
    "mfussenegger/nvim-dap",
    config = function(_, opts)
      -- Set DAP key mappings directly here
      vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { noremap = true, silent = true })
      vim.keymap.set("n", "<leader>dpr", function()
        require("dap-python").test_method()
      end, { noremap = true, silent = true })

      -- Optionally load other DAP settings or configurations
    end,
  },

  {
    "rcarriga/nvim-dap-ui",
    dependencies = "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
}

return {
  -- Hihglight colors
  {
    "echasnovski/mini.hipatterns",
    event = "BufReadPre",
    opts = {},
  },
  {
    "telescope.nvim",
    priority = 1000,
    dependencies = {
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-telescope/telescope-file-browser.nvim",
    },
    keys = {
      {
        -- Keybinding to find files in the current working directory
        -- Press ";f" to trigger Telescope's 'find_files' function
        -- 'no_ignore = false' ensures that files listed in '.gitignore' are still respected
        -- 'hidden = true' allows hidden files (dotfiles) to be shown
        ";f",
        function()
          local builtin = require("telescope.builtin")
          builtin.find_files({
            no_ignore = false,
            hidden = true,
          })
        end,
        desc = "Lists files in your current working directory, respects .gitignore",
      },
      {
        -- Keybinding to search for a string within the current working directory
        -- Press ";r" to trigger live_grep, which searches for text in files
        -- Results appear dynamically as you type
        ";r",
        function()
          local builtin = require("telescope.builtin")
          builtin.live_grep()
        end,
        desc =
        "Search for a string in your current working directory and get results live as you type, respects .gitignore",
      },
      {
        -- Keybinding to list open buffers. all buffer available
        -- Press "\\\\" to show a list of all currently open buffers
        "\\\\",
        function()
          local builtin = require("telescope.builtin")
          builtin.buffers()
        end,
        desc = "Lists open buffers",
      },
      {
        -- Keybinding to resume the last used Telescope picker
        -- Press ";;" to bring up the previous Telescope search window (useful to resume searches)
        ";;",
        function()
          local builtin = require("telescope.builtin")
          builtin.resume()
        end,
        desc = "Resume the previous telescope picker",
      },
      {
        -- Keybinding to list diagnostics for all open buffers or a specific buffer
        -- Press ";e" to display LSP diagnostic messages (errors, warnings, etc.)
        ";e",
        function()
          local builtin = require("telescope.builtin")
          builtin.diagnostics()
        end,
        desc = "Lists Diagnostics for all open buffers or a specific buffer",
      },
      {
        -- Keybinding to list function names and variables using Treesitter
        -- Press ";s" to display a Treesitter-based symbol list of functions, variables, etc.
        ";s",
        function()
          local builtin = require("telescope.builtin")
          builtin.treesitter() --adding treesitter
        end,
        desc = "Lists Function names, variables, from Treesitter",
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local fb_actions = require("telescope").extensions.file_browser.actions

      opts.defaults = vim.tbl_deep_extend("force", opts.defaults, {
        wrap_results = true,
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          n = {},
        },
      })
      opts.pickers = {
        diagnostics = {
          theme = "ivy",
          initial_mode = "normal",
          layout_config = {
            preview_cutoff = 9999,
          },
        },
      }
      opts.extensions = {
        file_browser = {
          theme = "dropdown",
          -- disables netrw and use telescope-file-browser in its place
          hijack_netrw = true,
          mappings = {
            -- your custom insert mode mappings
            ["n"] = {
              -- your custom normal mode mappings
              ["N"] = fb_actions.create,
              ["h"] = fb_actions.goto_parent_dir,
              ["<C-u>"] = function(prompt_bufnr)
                for i = 1, 10 do
                  actions.move_selection_previous(prompt_bufnr)
                end
              end,
              ["<C-d>"] = function(prompt_bufnr)
                for i = 1, 10 do
                  actions.move_selection_next(prompt_bufnr)
                end
              end,
            },
          },
        },
      }
      telescope.setup(opts)
      require("telescope").load_extension("fzf")
      require("telescope").load_extension("file_browser")
    end,
  },
}

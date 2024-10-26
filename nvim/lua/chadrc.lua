-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}


-- Base46 theme settings
M.base46 = {
  theme = "onedark",
  hl_add = {},
  hl_override = {},
  transparency = false,
  theme_toggle = { "onedark", "one_light" },
}

-- UI and plugin settings
M.ui = {
  cmp = {
    icons_left = false,
    lspkind_text = true,
    style = "default",
    format_colors = {
      tailwind = false,
      icon = "󱓻",
    },
  },

  telescope = { style = "borderless" },

  statusline = {
    enabled = true,
    theme = "vscode",
    separator_style = "round",
  },

  tabufline = {
    enabled = true,
    lazyload = true,
    order = { "treeOffset", "buffers", "tabs", "btns" },
  },
}

-- Dashboard settings
M.nvdash = {
  load_on_startup = true,
  header = {
    "                            ",
    "     ▄▄         ▄ ▄▄▄▄▄▄▄   ",
    "   ▄▀███▄     ▄██ █████▀    ",
    "   ██▄▀███▄   ███           ",
    "   ███  ▀███▄ ███           ",
    "   ███    ▀██ ███           ",
    "   ███      ▀ ███           ",
    "   ▀██ █████▄▀█▀▄██████▄    ",
    "     ▀ ▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀   ",
    "                            ",
    "     Powered By  eovim    ",
    "                            ",
  },

  buttons = {
    { txt = "  Find File", keys = "ff", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "fo", cmd = "Telescope oldfiles" },
    { txt = "󰈭  Find Word", keys = "fw", cmd = "Telescope live_grep" },
    { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },
  },
}

-- Terminal configuration
M.term = {
  winopts = { number = false, relativenumber = false },
  sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
  float = {
    relative = "editor",
    row = 0.3,
    col = 0.25,
    width = 0.5,
    height = 0.4,
    border = "single",
  },
}

-- LSP settings
M.lsp = { signature = true }

-- Cheatsheet settings
M.cheatsheet = {
  theme = "grid",
  excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" },
}

-- Mason package settings
M.mason = { pkgs = {} }

-- Colorify settings
M.colorify = {
  enabled = true,
  mode = "virtual",
  virt_text = "󱓻 ",
  highlight = { hex = true, lspvars = true },
}

-- Plugin specifications
M.plugins = {


  {
    "NvChad/ui",
    lazy = false,
    config = function()
      require("nvchad_ui")
    end
  },
  -- LazyGit integration
  {
    "kdheepak/lazygit.nvim",
    keys = {
      { ";c", ":LazyGit<Return>", silent = true, noremap = true },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Nvim Tree for file explorer
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set("n", "t", api.node.open.tab, { buffer = bufnr, noremap = true, silent = true })
        end,
        actions = { open_file = { quit_on_open = true } },
        view = { width = 30, relativenumber = true },
        renderer = { group_empty = true },
        filters = { dotfiles = true },
      })
    end,
  },
}

return M

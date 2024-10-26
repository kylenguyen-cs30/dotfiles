require "nvchad.mappings"

-- Custom keymaps
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Custom mappings
keymap("n", "x", '"_x')

-- Increment/decrement
keymap("n", "+", "<C-a>")
keymap("n", "-", "<C-x>")

-- Select all
keymap("n", "<C-a>", "gg<S-v>G")

-- Save File
-- vim.keymap.set('n', '<C-S>', ':w<CR>', { noremap = true, silent = true }) -- old version
vim.keymap.set('i', '<C-s>', function()
  vim.cmd("stopinsert") -- Exit insert mode
  vim.cmd(":w")         -- Save the file
  vim.lsp.buf.format()  -- Autoformat the file using LSP
end, { noremap = true, silent = true })

-- Save file and quit
keymap("n", "<Leader>w", ":update<Return>", opts)
keymap("n", "<Leader>q", ":quit<Return>", opts)
keymap("n", "<Leader>Q", ":qa<Return>", opts)

-- File explorer with NvimTree
keymap("n", "<Leader>f", ":NvimTreeFindFile<Return>", opts)
keymap("n", "<Leader>t", ":NvimTreeToggle<Return>", opts)

-- Tabs
keymap("n", "te", ":tabedit")
keymap("n", "<tab>", ":tabnext<Return>", opts)
keymap("n", "<s-tab>", ":tabprev<Return>", opts)
keymap("n", "tw", ":tabclose<Return>", opts)

-- Split window
keymap("n", "ss", ":split<Return>", opts)
keymap("n", "sv", ":vsplit<Return>", opts)

-- Move window
keymap("n", "sh", "<C-w>h")
keymap("n", "sk", "<C-w>k")
keymap("n", "sj", "<C-w>j")
keymap("n", "sl", "<C-w>l")

-- Resize window
keymap("n", "<C-S-h>", "<C-w><")
keymap("n", "<C-S-l>", "<C-w>>")
keymap("n", "<C-S-k>", "<C-w>+")
keymap("n", "<C-S-j>", "<C-w>-")

-- Diagnostics
keymap("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- Tmux Navigator Key Mappings
keymap("n", "<C-h>", ":TmuxNavigateLeft<CR>", opts)
keymap("n", "<C-j>", ":TmuxNavigateDown<CR>", opts)
keymap("n", "<C-k>", ":TmuxNavigateUp<CR>", opts)
keymap("n", "<C-l>", ":TmuxNavigateRight<CR>", opts)
keymap("n", "<C-\\>", ":TmuxNavigatePrevious<CR>", opts)

-- Additional Custom Mappings
keymap("n", ";", ":", { desc = "CMD enter command mode" })
keymap("i", "jk", "<ESC>")

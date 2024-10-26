local options = {
  formatters_by_ft = {
    lua = { "stylua" },          -- Lua: Use 'stylua' for formatting
    css = { "prettier" },        -- CSS: Use 'prettier'
    html = { "prettier" },       -- HTML: Use 'prettier'
    typescript = { "prettier" }, -- TypeScript: Use 'prettier'
    javascript = { "prettier" }, -- JavaScript: Use 'prettier'
    python = { "black" },        -- Python: Use 'black'
    svelte = { "prettier" },     -- Svelte: Use 'prettier'
    prisma = { "prisma-fmt" },   -- Prisma: Use 'prisma-fmt'
    dockerfile = { "dockfmt" },  -- Docker: Use 'dockfmt' (or 'prettier' if not installed)
    json = { "prettier" },       -- JSON: Use 'prettier' (optional)
    yaml = { "prettier" },       -- YAML: Use 'prettier' (optional)
    -- Add more formatters as needed for other file types
  },

  -- Enable format on save
  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,    -- Set timeout for formatting to 500 milliseconds
    lsp_fallback = true, -- Use the LSP formatter if no Conform formatter is available
  },
}

return options

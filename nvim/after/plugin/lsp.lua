local lsp = require('lsp-zero')
lsp.extend_lspconfig()

lsp.preset('recommend')

require('mason').setup({})
local mason_lsp = require('mason-lspconfig')

mason_lsp.setup({
  ensure_installed = { 'cssls', 'tailwindcss', 'jsonls', 'html', 'tsserver', 'rust_analyzer', 'eslint', 'lua_ls' },
  handlers = {
    lsp.default_setup
  },
  automatic_installation = true
})

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
  ['<C-i>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-u>'] = cmp.mapping.select_next_item(cmp_select),
  ['<CR>'] = cmp.mapping.confirm({ select = true }),
  ['<C-Space>'] = cmp.mapping.complete(),
})

lsp.set_preferences({
  sign_icons = {}
})


cmp.setup({
  mapping = cmp_mappings,
  completion = {
    completeopt = 'menu,menuone,noinsert'
  }
})

lsp.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set("n", 'gd', function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set('n', 'K', function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set('n', '<leader>vws', function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set('n', '<leader>vd', function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set('n', '[d', function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set('n', ']d', function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set('n', '<leader>vca', function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set('n', '<leader>vrr', function() vim.lsp.buf.references() end, opts)
  vim.keymap.set('n', '<leader>vrn', function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set('i', '<C-h>', function() vim.lsp.buf.signature_help() end, opts)
end)

lsp.setup()

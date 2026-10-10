-- ~/.config/nvim/lua/lsp.lua
vim.lsp.config('clangd', {
  cmd = {
    'clangd',
    '--clang-tidy',
    '--background-index',
    '--completion-style=detailed',
    '--compile-commands-dir=build'
  },
  root_markers = { '.clangd', 'compile_commands.json', 'CMakeLists.txt', '.git' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
})

vim.lsp.enable('clangd')

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf, desc = 'LSP: Go to definition' }
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  end,
})

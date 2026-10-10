-- ~/.config/nvim/lua/treesitter.lua
require('nvim-treesitter.install').compilers = {
  'clang',
  'clang++'
}
require('nvim-treesitter').install({ 'c', 'cpp' })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'cpp' },
  callback = function()
    vim.treesitter.start()
  end,
})

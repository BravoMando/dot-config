-- ~/.config/nvim/lua/mini-files.lua
vim.cmd.packadd('mini.nvim')

local MiniFiles = require('mini.files')

MiniFiles.setup({
  mappings = {
    close = 'q',
    go_in = 'l',
    go_in_plus = 'L',
    go_out = 'h',
    go_out_plus = 'H',
    toggle_hidden = 'g.',
    synchronize = 'gs',
    reset = 'gr',
    show_help = 'g?',
  },
  windows = {
    preview = true,
    width_preview = 80,
  },
})

vim.keymap.set('n', '<leader>e', function()
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file ~= '' and vim.fn.filereadable(current_file) == 1 then
    MiniFiles.open(vim.fn.fnamemodify(current_file, ':p:h'))
  else
    MiniFiles.open(vim.fn.getcwd())
  end
end, { desc = '打开文件浏览器 (当前目录)' })

vim.keymap.set('n', '<leader>E', function()
  MiniFiles.open(vim.fn.getcwd())
end, { desc = '打开文件浏览器 (工作目录)' })


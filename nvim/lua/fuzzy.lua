-- ~/.config/nvim/lua/fuzzy.lua
local fzf_lua = require('fzf-lua')

fzf_lua.setup({
  files = {
    file_icons = "devicons",
    cmd = "fd --type f --hidden --exclude .git",
  },
  grep = {
    file_icons = "devicons",
    cmd = "rg --column --line-number --no-heading --color=always --smart-case",
  },
  buffers = {
    file_icons = "devicons",
    color_icons = true,
  },
})

vim.keymap.set('n', '<leader>ff', fzf_lua.files, { desc = 'Fuzzy find files' })
vim.keymap.set('n', '<leader>fg', fzf_lua.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fb', fzf_lua.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fh', fzf_lua.help_tags, { desc = 'Find help tags' })


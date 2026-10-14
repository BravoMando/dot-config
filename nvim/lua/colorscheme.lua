-- ~/.config/nvim/lua/colorscheme.lua
vim.pack.add({
  "https://github.com/catppuccin/nvim.git",
})
require("catppuccin").setup({
  flavor = "mocha" -- latte, frappe, macchiato, mocha
})
vim.cmd.colorscheme("catppuccin")
